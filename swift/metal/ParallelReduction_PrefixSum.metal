#include <metal_stdlib>
using namespace metal;

#define THREADS_PER_GROUP 256
#define SIMD_SIZE 32

// ----------------------------------------------------------------------------
// 1. Threadgroup Hierarchical Reduction (Sum)
// Multi-pass: Each threadgroup reduces a chunk of input down to 1 partial sum.
// ----------------------------------------------------------------------------
kernel void reduce_sum_stage1(
    device const float* input         [[buffer(0)]],
    device float*       partialSums   [[buffer(1)]],
    constant uint&      count         [[buffer(2)]],
    uint                tid           [[thread_index_in_threadgroup]],
    uint                groupId       [[threadgroup_position_in_grid]])
{
    threadgroup float sdata[THREADS_PER_GROUP];

    // Each threadgroup processes (THREADS_PER_GROUP * 2) elements
    uint base = groupId * (THREADS_PER_GROUP * 2);
    uint i = base + tid;

    float sum = (i < count) ? input[i] : 0.0f;
    if (i + THREADS_PER_GROUP < count) {
        sum += input[i + THREADS_PER_GROUP];
    }
    sdata[tid] = sum;
    threadgroup_barrier(mem_flags::mem_threadgroup);

    // Tree reduction in shared memory (power-of-two fold)
    for (uint s = THREADS_PER_GROUP / 2; s > 32; s >>= 1) {
        if (tid < s) {
            sdata[tid] += sdata[tid + s];
        }
        threadgroup_barrier(mem_flags::mem_threadgroup);
    }

    // Final warp/SIMD-group unrolled reduction without barriers
    if (tid < 32) {
        float val = sdata[tid] + sdata[tid + 32];
        val += simd_shuffle_down(val, 16);
        val += simd_shuffle_down(val, 8);
        val += simd_shuffle_down(val, 4);
        val += simd_shuffle_down(val, 2);
        val += simd_shuffle_down(val, 1);

        if (tid == 0) {
            partialSums[groupId] = val;
        }
    }
}

// ----------------------------------------------------------------------------
// 2. Blelloch Parallel Prefix Sum (Exclusive Scan)
// In-place scan on a power-of-two block using Up-Sweep (reduce) and Down-Sweep.
// ----------------------------------------------------------------------------
kernel void blelloch_scan_exclusive(
    device float*       data        [[buffer(0)]],
    device float*       blockSums   [[buffer(1)]],
    constant uint&      n           [[buffer(2)]],
    uint                tid         [[thread_index_in_threadgroup]],
    uint                groupId     [[threadgroup_position_in_grid]])
{
    threadgroup float temp[THREADS_PER_GROUP * 2];
    uint blockOffset = groupId * (THREADS_PER_GROUP * 2);

    // Load 2 elements per thread into shared memory
    uint idxA = blockOffset + 2 * tid;
    uint idxB = blockOffset + 2 * tid + 1;

    temp[2 * tid]     = (idxA < n) ? data[idxA] : 0.0f;
    temp[2 * tid + 1] = (idxB < n) ? data[idxB] : 0.0f;

    uint offset = 1;

    // Up-Sweep (Parallel Reduction) Phase
    for (uint d = THREADS_PER_GROUP; d > 0; d >>= 1) {
        threadgroup_barrier(mem_flags::mem_threadgroup);
        if (tid < d) {
            uint ai = offset * (2 * tid + 1) - 1;
            uint bi = offset * (2 * tid + 2) - 1;
            temp[bi] += temp[ai];
        }
        offset *= 2;
    }

    // Clear the last element and record total block sum
    if (tid == 0) {
        if (blockSums != nullptr) {
            blockSums[groupId] = temp[THREADS_PER_GROUP * 2 - 1];
        }
        temp[THREADS_PER_GROUP * 2 - 1] = 0.0f;
    }

    // Down-Sweep Phase
    for (uint d = 1; d <= THREADS_PER_GROUP; d *= 2) {
        offset >>= 1;
        threadgroup_barrier(mem_flags::mem_threadgroup);
        if (tid < d) {
            uint ai = offset * (2 * tid + 1) - 1;
            uint bi = offset * (2 * tid + 2) - 1;
            float t = temp[ai];
            temp[ai] = temp[bi];
            temp[bi] += t;
        }
    }
    threadgroup_barrier(mem_flags::mem_threadgroup);

    // Write back exclusive scanned results
    if (idxA < n) data[idxA] = temp[2 * tid];
    if (idxB < n) data[idxB] = temp[2 * tid + 1];
}
