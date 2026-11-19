#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float fieldW;
    float fieldH;
    float fieldRadius;
    float pad;
    float engaged;
    float errorState;
};

layout(binding = 1) uniform sampler2D sourceTexture;

float roundedRectSdf(vec2 p, vec2 halfSize, float r) {
    float radius = min(r, min(halfSize.x, halfSize.y));
    vec2 q = abs(p) - (halfSize - vec2(radius));
    return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
}

vec2 roundedRectNormal(vec2 p, vec2 halfSize, float r) {
    float eps = 0.75;
    float dx = roundedRectSdf(p + vec2(eps, 0.0), halfSize, r) - roundedRectSdf(p - vec2(eps, 0.0), halfSize, r);
    float dy = roundedRectSdf(p + vec2(0.0, eps), halfSize, r) - roundedRectSdf(p - vec2(0.0, eps), halfSize, r);
    vec2 g = vec2(dx, dy);
    float len = length(g);
    return len > 0.0001 ? g / len : vec2(0.0, -1.0);
}

void main() {
    vec2 texSize = vec2(fieldW + pad * 2.0, fieldH + pad * 2.0);
    vec2 local = qt_TexCoord0 * texSize - vec2(pad, pad);
    vec2 halfSize = vec2(fieldW * 0.5, fieldH * 0.5);
    vec2 rel = local - halfSize;

    float d = roundedRectSdf(rel, halfSize, fieldRadius);
    vec2 normal = roundedRectNormal(rel, halfSize, fieldRadius);

    // Smooth anti-aliased pill mask + delicate outer drop shadow
    float fillMask = 1.0 - smoothstep(-0.7, 0.7, d);
    float shadowAlpha = (1.0 - fillMask) * exp(-max(d, 0.0) * 0.28) * 0.18;

    // Subtle Liquid Glass refraction along the curved rim
    float rimZone = smoothstep(-12.0, 0.0, d);
    float lensCurve = rimZone * rimZone;
    vec2 refractOffset = -normal * lensCurve * (0.018 + 0.006 * engaged);
    vec2 dispOffset = normal * lensCurve * 0.0025;

    vec2 uvG = clamp(qt_TexCoord0 + refractOffset, vec2(0.002), vec2(0.998));
    vec2 uvR = clamp(uvG + dispOffset, vec2(0.002), vec2(0.998));
    vec2 uvB = clamp(uvG - dispOffset, vec2(0.002), vec2(0.998));

    vec3 bg;
    bg.r = texture(sourceTexture, uvR).r;
    bg.g = texture(sourceTexture, uvG).g;
    bg.b = texture(sourceTexture, uvB).b;

    // Airy frosted glass tint
    float topGrad = clamp(0.5 - rel.y / max(fieldH, 1.0), 0.0, 1.0);
    vec3 tintColor = mix(vec3(0.96, 0.98, 1.0), vec3(1.0, 0.42, 0.42), errorState * 0.7);
    float tintStrength = 0.13 + 0.05 * engaged + 0.06 * topGrad + 0.08 * errorState;
    vec3 glass = mix(bg * 1.18, tintColor, tintStrength);

    // Delicate 1px specular rim & soft top highlight (macOS Liquid Glass style)
    float dirLight = max(0.0, dot(normal, normalize(vec2(-0.35, -0.94)))) * 0.9
                   + max(0.0, dot(normal, normalize(vec2(0.35, 0.94)))) * 0.35;
    float innerGlow = smoothstep(-5.5, 0.0, d) * (0.03 + 0.07 * dirLight);
    float crispBorder = smoothstep(-1.05, -0.15, d) * (0.14 + 0.34 * dirLight + 0.12 * engaged);

    vec3 rimTint = mix(vec3(1.0), vec3(1.0, 0.58, 0.58), errorState * 0.8);
    glass += rimTint * (innerGlow + crispBorder);

    vec3 finalRgb = glass * fillMask;
    float finalAlpha = clamp(fillMask + shadowAlpha, 0.0, 1.0) * qt_Opacity;
    fragColor = vec4(finalRgb, finalAlpha);
}
