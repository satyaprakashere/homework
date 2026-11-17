#include <metal_stdlib>
using namespace metal;

struct Particle {
    float4 position; // xyz: position, w: mass
    float4 velocity; // xyz: velocity, w: age/lifetime
};

struct Uniforms {
    float dt;
    float softening;
    float damping;
    uint  numParticles;
};

// ----------------------------------------------------------------------------
// 1. Tiled N-Body Compute Kernel
// Uses threadgroup memory to tile body loads, reducing memory bandwidth by TILE_SIZE.
// ----------------------------------------------------------------------------
#define TILE_SIZE 256

kernel void nbody_simulation_tiled(
    device const Particle* currentParticles [[buffer(0)]],
    device Particle*       nextParticles    [[buffer(1)]],
    constant Uniforms&     params           [[buffer(2)]],
    uint                   gid              [[thread_position_in_grid]],
    uint                   tid              [[thread_index_in_threadgroup]])
{
    threadgroup float4 sharedPos[TILE_SIZE];

    if (gid >= params.numParticles) return;

    Particle p = currentParticles[gid];
    float3 myPos = p.position.xyz;
    float3 acc = float3(0.0f);

    uint numTiles = (params.numParticles + TILE_SIZE - 1) / TILE_SIZE;

    for (uint tile = 0; tile < numTiles; ++tile) {
        uint loadIdx = tile * TILE_SIZE + tid;
        if (loadIdx < params.numParticles) {
            sharedPos[tid] = currentParticles[loadIdx].position;
        } else {
            sharedPos[tid] = float4(0.0f);
        }

        threadgroup_barrier(mem_flags::mem_threadgroup);

        // Interact with all particles in the current tile
        #pragma unroll 4
        for (uint j = 0; j < TILE_SIZE; ++j) {
            float4 other = sharedPos[j];
            float3 r = other.xyz - myPos;
            float distSq = dot(r, r) + params.softening;
            float invDist = rsqrt(distSq);
            float invDist3 = invDist * invDist * invDist;
            acc += r * (other.w * invDist3);
        }

        threadgroup_barrier(mem_flags::mem_threadgroup);
    }

    // Semi-implicit Euler integration
    p.velocity.xyz = (p.velocity.xyz + acc * params.dt) * params.damping;
    p.position.xyz += p.velocity.xyz * params.dt;

    nextParticles[gid] = p;
}

// ----------------------------------------------------------------------------
// 2. Vertex & Fragment Shaders for Particle Point Sprites
// ----------------------------------------------------------------------------
struct VertexOut {
    float4 position [[position]];
    float  pointSize [[point_size]];
    float4 color;
};

vertex VertexOut particle_vertex(
    device const Particle* particles [[buffer(0)]],
    uint                   vid       [[vertex_id]])
{
    VertexOut out;
    Particle p = particles[vid];

    // Orthographic projection to NDC space [-1, 1]
    out.position = float4(p.position.xyz * 0.1f, 1.0f);
    out.pointSize = 3.0f;

    // Color based on velocity speed (heat-map effect)
    float speed = length(p.velocity.xyz);
    out.color = float4(mix(float3(0.2, 0.5, 1.0), float3(1.0, 0.3, 0.1), clamp(speed * 0.5f, 0.0f, 1.0f)), 0.8f);
    return out;
}

fragment float4 particle_fragment(
    VertexOut in [[stage_in]],
    float2 pointCoord [[point_coord]])
{
    // Render smooth circular antialiased point sprite
    float dist = length(pointCoord - float2(0.5));
    if (dist > 0.5) {
        discard_fragment();
    }
    float alpha = smoothstep(0.5f, 0.2f, dist) * in.color.a;
    return float4(in.color.rgb, alpha);
}
