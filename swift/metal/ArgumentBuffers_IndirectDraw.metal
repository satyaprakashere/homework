#include <metal_stdlib>
using namespace metal;

// ----------------------------------------------------------------------------
// 1. MSL Argument Buffer Definition
// Resources are bundled into a single C-like struct with [[id(n)]] attributes.
// ----------------------------------------------------------------------------
struct Material {
    texture2d<float> albedoTexture [[id(0)]];
    sampler          albedoSampler [[id(1)]];
    float4           baseColor     [[id(2)]];
    float            roughness     [[id(3)]];
};

struct MeshData {
    device const float3* positions [[id(0)]];
    device const float3* normals   [[id(1)]];
    device const float2* uvs       [[id(2)]];
    uint                 vertexCount [[id(3)]];
};

struct InstanceUniforms {
    float4x4 modelMatrix;
    float4   tintColor;
};

// ----------------------------------------------------------------------------
// 2. Render Pipeline consuming Argument Buffers
// ----------------------------------------------------------------------------
struct VertexOut {
    float4 position [[position]];
    float2 uv;
    float4 color;
};

vertex VertexOut vertex_argbuffer(
    constant MeshData&         mesh      [[buffer(0)]],
    constant InstanceUniforms* instances [[buffer(1)]],
    uint                       vid       [[vertex_id]],
    uint                       iid       [[instance_id]])
{
    VertexOut out;
    float3 pos = mesh.positions[vid];
    float4 worldPos = instances[iid].modelMatrix * float4(pos, 1.0);
    out.position = worldPos;
    out.uv = mesh.uvs[vid];
    out.color = instances[iid].tintColor;
    return out;
}

fragment float4 fragment_argbuffer(
    VertexOut         in       [[stage_in]],
    constant Material& material [[buffer(0)]])
{
    float4 texColor = material.albedoTexture.sample(material.albedoSampler, in.uv);
    return texColor * material.baseColor * in.color;
}

// ----------------------------------------------------------------------------
// 3. Compute Kernel for GPU-Driven Culling & Indirect Command Generation
// ----------------------------------------------------------------------------
struct IndirectDrawArguments {
    uint vertexCountPerInstance;
    uint instanceCount;
    uint startVertexLocation;
    uint startInstanceLocation;
};

kernel void gpu_cull_and_draw(
    device const float4*           boundingSpheres [[buffer(0)]],
    device IndirectDrawArguments*  drawArgs        [[buffer(1)]],
    constant uint&                 totalInstances  [[buffer(2)]],
    uint                           gid             [[thread_position_in_grid]])
{
    if (gid >= totalInstances) return;

    // Simulate simple visibility check (e.g. radius check)
    float4 sphere = boundingSpheres[gid];
    bool isVisible = (sphere.w > 0.0f);

    // If visible, configure indirect draw parameters
    if (isVisible && gid == 0) {
        drawArgs[0].vertexCountPerInstance = 3;
        drawArgs[0].instanceCount = totalInstances;
        drawArgs[0].startVertexLocation = 0;
        drawArgs[0].startInstanceLocation = 0;
    }
}
