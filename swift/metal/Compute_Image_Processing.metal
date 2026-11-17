#include <metal_stdlib>
using namespace metal;

// ----------------------------------------------------------------------------
// 1. Procedural Test Pattern Generator
// Generates geometric high-contrast test target (circles, grid, gradients)
// ----------------------------------------------------------------------------
kernel void generate_pattern(
    texture2d<float, access::write> outTex [[texture(0)]],
    uint2                          gid    [[thread_position_in_grid]])
{
    if (gid.x >= outTex.get_width() || gid.y >= outTex.get_height()) return;

    float2 uv = float2(gid) / float2(outTex.get_width(), outTex.get_height());

    // Concentric rings + checkerboard + sharp diagonal stripes
    float dist = length(uv - float2(0.5));
    float rings = sin(dist * 50.0);
    float checker = step(0.5, fract(uv.x * 8.0)) == step(0.5, fract(uv.y * 8.0)) ? 0.8 : 0.2;
    float stripe = step(0.9, fract((uv.x + uv.y) * 10.0));

    float val = mix(checker, rings, 0.4) + stripe * 0.5;
    float3 col = float3(val, val * 0.9, val * 1.1);

    outTex.write(float4(col, 1.0), gid);
}

// ----------------------------------------------------------------------------
// 2. Sobel Edge Detection Filter
// ----------------------------------------------------------------------------
kernel void sobel_filter(
    texture2d<float, access::read>  inTex  [[texture(0)]],
    texture2d<float, access::write> outTex [[texture(1)]],
    uint2                           gid    [[thread_position_in_grid]])
{
    uint w = inTex.get_width();
    uint h = inTex.get_height();
    if (gid.x >= w || gid.y >= h) return;

    // Sobel 3x3 Kernels
    // Gx: [[-1, 0, 1], [-2, 0, 2], [-1, 0, 1]]
    // Gy: [[-1, -2, -1], [0, 0, 0], [1, 2, 1]]

    float gx = 0.0;
    float gy = 0.0;

    for (int dy = -1; dy <= 1; ++dy) {
        for (int dx = -1; dx <= 1; ++dx) {
            uint cx = clamp(int(gid.x) + dx, 0, int(w) - 1);
            uint cy = clamp(int(gid.y) + dy, 0, int(h) - 1);

            float4 pixel = inTex.read(uint2(cx, cy));
            float lum = dot(pixel.rgb, float3(0.299, 0.587, 0.114)); // Rec.601 Luma

            int kx = dx * (dy == 0 ? 2 : 1);
            int ky = dy * (dx == 0 ? 2 : 1);

            gx += float(kx) * lum;
            gy += float(ky) * lum;
        }
    }

    float magnitude = sqrt(gx * gx + gy * gy);
    float3 edgeCol = float3(magnitude * 2.0f, magnitude * 1.5f, magnitude * 0.8f);
    outTex.write(float4(edgeCol, 1.0f), gid);
}

// ----------------------------------------------------------------------------
// 3. Separable 1D Gaussian Blur Pass (Horizontal / Vertical)
// 9-tap 1D filter kernel (sigma ~ 2.5)
// ----------------------------------------------------------------------------
constant float weights[5] = { 0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216 };

kernel void gaussian_blur_1d(
    texture2d<float, access::read>  inTex     [[texture(0)]],
    texture2d<float, access::write> outTex    [[texture(1)]],
    constant uint2&                 direction [[buffer(0)]], // (1,0) = Horiz, (0,1) = Vert
    uint2                           gid       [[thread_position_in_grid]])
{
    uint w = inTex.get_width();
    uint h = inTex.get_height();
    if (gid.x >= w || gid.y >= h) return;

    float4 result = inTex.read(gid) * weights[0];

    for (int i = 1; i < 5; ++i) {
        int2 offset = int2(direction) * i;

        uint2 posPlus = uint2(clamp(int2(gid) + offset, int2(0), int2(w - 1, h - 1)));
        uint2 posMinus = uint2(clamp(int2(gid) - offset, int2(0), int2(w - 1, h - 1)));

        result += inTex.read(posPlus) * weights[i];
        result += inTex.read(posMinus) * weights[i];
    }

    outTex.write(result, gid);
}
