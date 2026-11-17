#include <metal_stdlib>
using namespace metal;

// ----------------------------------------------------------------------------
// 1. Naive Matrix Multiplication (Baseline)
// Each thread computes one element C[row, col] by reading entire rows of A and cols of B.
// Bottleneck: Repeated slow global device memory reads.
// ----------------------------------------------------------------------------
kernel void gemm_naive(
    device const float* A        [[buffer(0)]],
    device const float* B        [[buffer(1)]],
    device float*       C        [[buffer(2)]],
    constant uint3&     dims     [[buffer(3)]], // M, N, K
    uint2               pos      [[thread_position_in_grid]])
{
    uint row = pos.y;
    uint col = pos.x;
    uint M = dims.x;
    uint N = dims.y;
    uint K = dims.z;

    if (row >= M || col >= N) return;

    float sum = 0.0f;
    for (uint k = 0; k < K; ++k) {
        sum += A[row * K + k] * B[k * N + col];
    }
    C[row * N + col] = sum;
}

// ----------------------------------------------------------------------------
// 2. Tiled Matrix Multiplication using Threadgroup Shared Memory
// Tile size: 16x16.
// Threads collaboratively load blocks of A and B into high-speed on-chip SRAM,
// synchronize with threadgroup_barrier, and accumulate products from shared memory.
// ----------------------------------------------------------------------------
#define TILE_DIM 16

kernel void gemm_tiled(
    device const float* A          [[buffer(0)]],
    device const float* B          [[buffer(1)]],
    device float*       C          [[buffer(2)]],
    constant uint3&     dims       [[buffer(3)]], // M, N, K
    uint2               thread_pos [[thread_position_in_threadgroup]],
    uint2               group_pos  [[threadgroup_position_in_grid]],
    uint2               global_pos [[thread_position_in_grid]])
{
    uint M = dims.x;
    uint N = dims.y;
    uint K = dims.z;

    threadgroup float tileA[TILE_DIM][TILE_DIM];
    threadgroup float tileB[TILE_DIM][TILE_DIM];

    uint row = global_pos.y;
    uint col = global_pos.x;

    float acc = 0.0f;
    uint numTiles = (K + TILE_DIM - 1) / TILE_DIM;

    for (uint t = 0; t < numTiles; ++t) {
        // Coalesced load into threadgroup memory
        uint aCol = t * TILE_DIM + thread_pos.x;
        uint bRow = t * TILE_DIM + thread_pos.y;

        if (row < M && aCol < K) {
            tileA[thread_pos.y][thread_pos.x] = A[row * K + aCol];
        } else {
            tileA[thread_pos.y][thread_pos.x] = 0.0f;
        }

        if (bRow < K && col < N) {
            tileB[thread_pos.y][thread_pos.x] = B[bRow * N + col];
        } else {
            tileB[thread_pos.y][thread_pos.x] = 0.0f;
        }

        // Synchronize threads in the threadgroup so all data is loaded
        threadgroup_barrier(mem_flags::mem_threadgroup);

        // Compute dot product of the tile from fast on-chip memory
        for (uint k = 0; k < TILE_DIM; ++k) {
            acc += tileA[thread_pos.y][k] * tileB[k][thread_pos.x];
        }

        // Wait until computation finishes before loading the next tile
        threadgroup_barrier(mem_flags::mem_threadgroup);
    }

    if (row < M && col < N) {
        C[row * N + col] = acc;
    }
}

// ----------------------------------------------------------------------------
// 3. 2D Register Blocked GEMM (Advanced Micro-kernel)
// Each thread computes a 4x4 sub-matrix of C held entirely in GPU private registers,
// boosting compute-to-memory ratio dramatically by 16x.
// ----------------------------------------------------------------------------
#define BLOCK_M 64
#define BLOCK_N 64
#define BLOCK_K 8
#define THREAD_M 4
#define THREAD_N 4

kernel void gemm_register_blocked(
    device const float* A          [[buffer(0)]],
    device const float* B          [[buffer(1)]],
    device float*       C          [[buffer(2)]],
    constant uint3&     dims       [[buffer(3)]], // M, N, K
    uint2               thread_pos [[thread_position_in_threadgroup]],
    uint2               group_pos  [[threadgroup_position_in_grid]])
{
    uint M = dims.x;
    uint N = dims.y;
    uint K = dims.z;

    // Registers to hold 4x4 results
    float c_reg[THREAD_M][THREAD_N] = { {0.0f} };

    threadgroup float tileA[BLOCK_M][BLOCK_K];
    threadgroup float tileB[BLOCK_K][BLOCK_N];

    uint groupRow = group_pos.y * BLOCK_M;
    uint groupCol = group_pos.x * BLOCK_N;

    uint tid = thread_pos.y * 16 + thread_pos.x; // 16x16 = 256 threads

    for (uint k_block = 0; k_block < K; k_block += BLOCK_K) {
        // Cooperatively load tileA (64 x 8 = 512 floats with 256 threads -> 2 per thread)
        for (uint i = 0; i < 2; ++i) {
            uint idx = tid * 2 + i;
            uint r = idx / BLOCK_K;
            uint c = idx % BLOCK_K;
            if ((groupRow + r) < M && (k_block + c) < K) {
                tileA[r][c] = A[(groupRow + r) * K + (k_block + c)];
            } else {
                tileA[r][c] = 0.0f;
            }
        }

        // Cooperatively load tileB (8 x 64 = 512 floats with 256 threads -> 2 per thread)
        for (uint i = 0; i < 2; ++i) {
            uint idx = tid * 2 + i;
            uint r = idx / BLOCK_N;
            uint c = idx % BLOCK_N;
            if ((k_block + r) < K && (groupCol + c) < N) {
                tileB[r][c] = B[(k_block + r) * N + (groupCol + c)];
            } else {
                tileB[r][c] = 0.0f;
            }
        }

        threadgroup_barrier(mem_flags::mem_threadgroup);

        // Compute outer-products in registers
        for (uint k = 0; k < BLOCK_K; ++k) {
            float a_reg[THREAD_M];
            float b_reg[THREAD_N];

            for (uint i = 0; i < THREAD_M; ++i) {
                a_reg[i] = tileA[thread_pos.y * THREAD_M + i][k];
            }
            for (uint j = 0; j < THREAD_N; ++j) {
                b_reg[j] = tileB[k][thread_pos.x * THREAD_N + j];
            }

            for (uint i = 0; i < THREAD_M; ++i) {
                for (uint j = 0; j < THREAD_N; ++j) {
                    c_reg[i][j] += a_reg[i] * b_reg[j];
                }
            }
        }

        threadgroup_barrier(mem_flags::mem_threadgroup);
    }

    // Write back accumulated registers to global memory
    for (uint i = 0; i < THREAD_M; ++i) {
        uint globalR = groupRow + thread_pos.y * THREAD_M + i;
        for (uint j = 0; j < THREAD_N; ++j) {
            uint globalC = groupCol + thread_pos.x * THREAD_N + j;
            if (globalR < M && globalC < N) {
                C[globalR * N + globalC] = c_reg[i][j];
            }
        }
    }
}
