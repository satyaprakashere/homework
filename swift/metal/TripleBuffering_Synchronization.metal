#include <metal_stdlib>
using namespace metal;

struct FrameUniforms {
    float4x4 modelViewProjection;
    float4   color;
    float    time;
    float3   _pad;
};

kernel void simulate_frame_physics(
    device float4*              particles [[buffer(0)]],
    constant FrameUniforms&     uniforms  [[buffer(1)]],
    uint                        gid       [[thread_position_in_grid]])
{
    float4 p = particles[gid];
    // Dynamic wave animation driven by CPU frame time
    p.y = sin(p.x * 2.0f + uniforms.time) * cos(p.z * 2.0f + uniforms.time) * 0.5f;
    particles[gid] = p;
}
