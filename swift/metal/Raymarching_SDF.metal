#include <metal_stdlib>
using namespace metal;

struct Ray {
    float3 origin;
    float3 direction;
};

struct Camera {
    float3 position;
    float3 target;
    float  fov;
    float2 resolution;
};

// ----------------------------------------------------------------------------
// 1. SDF Primitives & CSG Operations
// ----------------------------------------------------------------------------
float sdSphere(float3 p, float radius) {
    return length(p) - radius;
}

float sdBox(float3 p, float3 b) {
    float3 d = abs(p) - b;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

float sdTorus(float3 p, float2 t) {
    float2 q = float2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}

float sdPlane(float3 p, float4 n) {
    // n must be normalized
    return dot(p, n.xyz) + n.w;
}

// Polynomial smooth minimum (smooth CSG union)
float opSmoothUnion(float d1, float d2, float k) {
    float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return mix(d2, d1, h) - k * h * (1.0 - h);
}

// Scene Distance Function
float sceneSDF(float3 p) {
    // Ground plane
    float ground = sdPlane(p, float4(0, 1, 0, 1.0));

    // Animated / blended shapes
    float3 spherePos = p - float3(0.0, 0.5, 0.0);
    float sphere = sdSphere(spherePos, 1.0);

    float3 torusPos = p - float3(0.0, 0.5, 0.0);
    float torus = sdTorus(torusPos, float2(1.5, 0.35));

    float3 boxPos = p - float3(1.8, 0.2, 0.5);
    float box = sdBox(boxPos, float3(0.6, 0.6, 0.6));

    // Smooth union of sphere and torus, standard union with box and floor
    float blendObject = opSmoothUnion(sphere, torus, 0.4);
    float objects = min(blendObject, box);

    return min(ground, objects);
}

// Compute normal via finite forward/tetrahedron differences
float3 calcNormal(float3 p) {
    const float eps = 0.001f;
    const float2 h = float2(eps, 0);
    return normalize(float3(
        sceneSDF(p + h.xyy) - sceneSDF(p - h.xyy),
        sceneSDF(p + h.yxy) - sceneSDF(p - h.yxy),
        sceneSDF(p + h.yyx) - sceneSDF(p - h.yyx)
    ));
}

// Soft Shadow Raymarcher
float calcSoftShadow(float3 ro, float3 rd, float mint, float maxt, float k) {
    float res = 1.0;
    float t = mint;
    for (int i = 0; i < 32 && t < maxt; ++i) {
        float h = sceneSDF(ro + rd * t);
        if (h < 0.001) return 0.0;
        res = min(res, k * h / t);
        t += clamp(h, 0.02, 0.2);
    }
    return clamp(res, 0.0, 1.0);
}

// Ambient Occlusion
float calcAO(float3 pos, float3 normal) {
    float occ = 0.0;
    float sca = 1.0;
    for (int i = 0; i < 5; ++i) {
        float h = 0.01 + 0.12 * float(i) / 4.0;
        float d = sceneSDF(pos + h * normal);
        occ += (h - d) * sca;
        sca *= 0.95;
    }
    return clamp(1.0 - 3.0 * occ, 0.0, 1.0);
}

// ----------------------------------------------------------------------------
// 2. Compute Kernel: Full-Screen Raymarching
// ----------------------------------------------------------------------------
kernel void raymarch_kernel(
    texture2d<float, access::write> outTexture [[texture(0)]],
    constant Camera&                cam        [[buffer(0)]],
    uint2                           gid        [[thread_position_in_grid]])
{
    if (gid.x >= uint(cam.resolution.x) || gid.y >= uint(cam.resolution.y)) return;

    // Normalized screen coordinates [-1, 1] corrected for aspect ratio
    float2 uv = (float2(gid) - 0.5 * cam.resolution) / cam.resolution.y;
    uv.y = -uv.y; // Flip Y for image orientation

    // Camera setup
    float3 ro = cam.position;
    float3 forward = normalize(cam.target - ro);
    float3 right = normalize(cross(forward, float3(0, 1, 0)));
    float3 up = cross(right, forward);
    float3 rd = normalize(uv.x * right + uv.y * up + forward * 1.5);

    // Sphere tracing loop
    float t = 0.0f;
    float maxDist = 50.0f;
    bool hit = false;

    for (int i = 0; i < 100; ++i) {
        float3 p = ro + rd * t;
        float d = sceneSDF(p);
        if (d < 0.001f) {
            hit = true;
            break;
        }
        t += d;
        if (t > maxDist) break;
    }

    float3 color = float3(0.05, 0.07, 0.12); // Background sky gradient
    color += float3(0.1, 0.15, 0.25) * (1.0 - uv.y);

    if (hit) {
        float3 pos = ro + rd * t;
        float3 normal = calcNormal(pos);
        float3 lightDir = normalize(float3(2.5, 4.0, -2.0));

        // Diffuse Lambertian
        float diff = max(dot(normal, lightDir), 0.0);
        float shadow = calcSoftShadow(pos + normal * 0.01, lightDir, 0.02, 10.0, 16.0);
        float ao = calcAO(pos, normal);

        // Specular Blinn-Phong
        float3 viewDir = -rd;
        float3 halfDir = normalize(lightDir + viewDir);
        float spec = pow(max(dot(normal, halfDir), 0.0), 32.0);

        // Material Color
        float3 albedo = (pos.y < -0.99) ?
            float3(0.3 + 0.1 * sin(pos.x * 3.0) * sin(pos.z * 3.0)) : // Checker ground
            float3(0.9, 0.45, 0.2);                                  // Warm orange shape

        float3 ambient = float3(0.08, 0.1, 0.15) * ao;
        float3 direct = albedo * diff * shadow + float3(spec * shadow);

        color = ambient + direct;
    }

    // Gamma correction
    color = pow(color, float3(1.0 / 2.2));

    outTexture.write(float4(color, 1.0), gid);
}
