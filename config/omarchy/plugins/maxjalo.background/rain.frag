#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float iTime;
    float iResX;
    float iResY;
};

layout(binding = 1) uniform sampler2D sourceTexture;

float N13(float p) {
    vec3 p3 = fract(vec3(p) * vec3(0.1031, 0.11369, 0.13787));
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 N22(vec2 p) {
    vec3 a = fract(p.xyx * vec3(123.34, 234.34, 345.65));
    a += dot(a, a + 34.45);
    return fract(vec2(a.x * a.y, a.y * a.z));
}

float saw(float b, float t) {
    return smoothstep(0.0, b, t) * smoothstep(1.0, b, t);
}

// Returns vec3(refractionOffset.xy, dropMask)
vec3 rainDropLayer(vec2 UV, float t, float scale) {
    vec2 uv = UV * scale;
    uv.y += t * 0.25;
    vec2 gv = fract(uv) - 0.5;
    vec2 id = floor(uv);

    vec2 n = N22(id);
    t += n.x * 6.2831;

    float w = UV.y * 10.0;
    float x = (n.x - 0.5) * 0.8;
    x += (0.4 - abs(x)) * sin(3.0 * w) * pow(sin(w), 6.0) * 0.45;

    float y = -sin(t + sin(t + sin(t) * 0.5)) * 0.45;
    y -= (gv.x - x) * (gv.x - x);

    vec2 dropPos = (gv - vec2(x, y)) / vec2(1.0, 1.45);
    float drop = smoothstep(0.055, 0.025, length(dropPos));

    vec2 trailPos = (gv - vec2(x, t * 0.25)) / vec2(1.0, 8.0);
    trailPos.y = (fract(trailPos.y * 8.0) - 0.5) / 8.0;
    float trail = smoothstep(0.032, 0.012, length(trailPos));
    float fogTrail = smoothstep(-0.05, 0.05, dropPos.y);
    fogTrail *= smoothstep(0.5, y, gv.y);
    trail *= fogTrail;
    fogTrail *= smoothstep(0.05, 0.04, abs(dropPos.x));

    vec2 offs = drop * dropPos + trail * trailPos;
    float mask = clamp(drop + trail * 0.7 + fogTrail * 0.25, 0.0, 1.0);
    return vec3(offs, mask);
}

// Falling overcast rain streaks in screen space
float fallingStreak(vec2 uv, float t, float slant, float density, float speed) {
    vec2 p = vec2(uv.x + uv.y * slant, uv.y);
    p.x *= density;
    float colId = floor(p.x);
    float rand = N13(colId * 13.7 + speed);
    float colX = fract(p.x) - 0.5;

    float y = fract(p.y * 1.4 + t * speed + rand * 10.0);
    float streak = smoothstep(0.18, 0.0, abs(colX)) * smoothstep(0.0, 0.15, y) * smoothstep(0.55, 0.12, y);
    float gate = step(0.62, fract(rand * 37.3));
    return streak * gate;
}

void main() {
    vec2 uv = qt_TexCoord0;
    float aspect = max(iResX, 1.0) / max(iResY, 1.0);
    vec2 aspectUv = vec2((uv.x - 0.5) * aspect, uv.y - 0.5);

    // Two layers of screen-glass water droplets
    vec3 d1 = rainDropLayer(aspectUv, iTime * 0.72, 6.5);
    vec3 d2 = rainDropLayer(aspectUv + vec2(0.37, 0.19), iTime * 0.92, 11.5);

    vec2 totalOffs = d1.xy * 0.55 + d2.xy * 0.35;
    float dropHighlight = clamp(d1.z * 0.08 + d2.z * 0.05, 0.0, 0.12);

    vec2 sampleUv = clamp(uv - totalOffs, vec2(0.002), vec2(0.998));
    vec3 col = texture(sourceTexture, sampleUv).rgb;

    // Slight overcast cool atmospheric grade
    col *= vec3(0.97, 0.99, 1.03);

    // Slanted falling rain streaks
    float s1 = fallingStreak(aspectUv, iTime, 0.16, 48.0, 1.85);
    float s2 = fallingStreak(aspectUv + vec2(0.13, 0.41), iTime, 0.14, 78.0, 2.35);
    float streaks = s1 * 0.12 + s2 * 0.07;

    col += vec3(0.78, 0.86, 0.96) * (streaks + dropHighlight);

    fragColor = vec4(col, qt_Opacity);
}
