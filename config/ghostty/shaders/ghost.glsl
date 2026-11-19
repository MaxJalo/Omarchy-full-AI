// Ghostty Smoke & Ghost Shader (based on paulrobello/ghostty-shaders/smoke-and-ghost.glsl)
// Adapted for Omarchy themes (uses iBackgroundColor) while keeping terminal text 100% crisp.
#define COLOR_TOLERANCE 0.04

// Smoke effect settings
#define SMOKE_COLOR vec3(0.45, 0.78, 0.72)
#define SMOKE_RADIUS 0.012
#define SMOKE_SPEED 0.45
#define SMOKE_SCALE 22.0
#define SMOKE_INTENSITY 0.16
#define SMOKE_RISE_HEIGHT 0.16
#define ALPHA_MAX 0.92
#define VERTICAL_BIAS 1.0

// Ghost face settings
#define FACE_COUNT 1
#define FACE_SCALE vec2(0.028, 0.044)
#define FACE_DURATION 3.2
#define FACE_TRANSITION 0.9
#define FACE_COLOR vec3(0.06, 0.10, 0.09)
#define GHOST_BG_COLOR vec3(0.76, 0.92, 0.88)
#define GHOST_BG_SCALE vec2(0.030, 0.055)

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float random1(float n) {
    return fract(sin(n) * 43758.5453123);
}

vec2 random2(float n) {
    return vec2(random1(n), random1(n + 1234.5678));
}

float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float cartoonEllipse(vec2 uv, vec2 center, vec2 scale) {
    vec2 d = (uv - center) / scale;
    return smoothstep(1.0, 0.75, length(d));
}

float ghostBackground(vec2 uv, vec2 center) {
    vec2 d = (uv - center) / GHOST_BG_SCALE;
    float baseShape = length(d * vec2(1.0, 0.8));
    float wave = sin(d.x * 6.28 + iTime * 2.0) * 0.18;
    float bottomWave = smoothstep(0.0, -0.45, d.y + wave) * step(abs(d.x), 1.05) * step(d.y, 0.1);
    return clamp(smoothstep(1.0, 0.78, baseShape) + bottomWave * 0.75, 0.0, 1.0);
}

float ghostFace(vec2 uv, vec2 center, float seed) {
    vec2 faceUV = (uv - center) / FACE_SCALE;
    float eyeSize = 0.24 + random1(seed) * 0.04;
    float eyeSpacing = 0.34;
    vec2 leftEyePos = vec2(-eyeSpacing, 0.18);
    vec2 rightEyePos = vec2(eyeSpacing, 0.18);

    float leftEye = cartoonEllipse(faceUV, leftEyePos, vec2(eyeSize));
    float rightEye = cartoonEllipse(faceUV, rightEyePos, vec2(eyeSize));

    vec2 mouthUV = faceUV - vec2(0.0, -0.55);
    float mouth = cartoonEllipse(mouthUV, vec2(0.0), vec2(0.32, 0.42));

    float face = max(max(leftEye, rightEye), mouth);
    face *= smoothstep(1.15, 0.75, length(faceUV));
    return face;
}

float calculateSmoke(vec2 uv, vec2 sourcePos) {
    float verticalDisp = (uv.y - sourcePos.y) * VERTICAL_BIAS;
    vec2 smokeUV = uv * SMOKE_SCALE;
    smokeUV.y -= iTime * SMOKE_SPEED * (1.0 + verticalDisp);
    smokeUV.x += sin(iTime * 0.5 + uv.y * 4.0) * 0.1;

    float n = noise(smokeUV) * 0.5 + 0.5;
    n += noise(smokeUV * 2.0 + iTime * 0.1) * 0.25;
    float verticalFalloff = 1.0 - smoothstep(0.0, SMOKE_RISE_HEIGHT, verticalDisp);
    return n * verticalFalloff;
}

bool isBackgroundPixel(vec4 color) {
    return all(lessThan(abs(color.rgb - iBackgroundColor), vec3(COLOR_TOLERANCE)));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 originalColor = texture(iChannel0, uv);

    // Keep terminal text/foreground glyphs 100% crisp and untouched
    if (!isBackgroundPixel(originalColor)) {
        fragColor = originalColor;
        return;
    }

    float smokeAccum = 0.0;
    float targetInfluence = 0.0;
    float stepSize = SMOKE_RADIUS / 3.0;

    for (float x = -SMOKE_RADIUS; x <= SMOKE_RADIUS; x += stepSize) {
        for (float y = -SMOKE_RADIUS; y <= 0.0; y += stepSize) {
            vec2 offset = vec2(x, y);
            vec2 sampleUV = clamp(uv + offset, vec2(0.0), vec2(1.0));
            if (isBackgroundPixel(texture(iChannel0, sampleUV))) {
                float dist = length(offset);
                float falloff = 1.0 - smoothstep(0.0, SMOKE_RADIUS, dist);
                smokeAccum += calculateSmoke(uv, sampleUV) * falloff;
                targetInfluence += falloff;
            }
        }
    }

    smokeAccum /= max(targetInfluence, 1.0);
    targetInfluence = smoothstep(0.0, 1.0, targetInfluence);
    float smokePresence = smokeAccum * targetInfluence;

    float faceAccum = 0.0;
    float bgAccum = 0.0;
    float timeBlock = floor(iTime / FACE_DURATION);

    if (smokePresence > 0.15) {
        for (int i = 0; i < FACE_COUNT; i++) {
            vec2 facePos = random2(timeBlock + float(i) * 1234.5);
            facePos = facePos * 0.7 + 0.15;

            float faceTime = mod(iTime, FACE_DURATION);
            float fadeFactor = smoothstep(0.0, FACE_TRANSITION, faceTime) *
                              (1.0 - smoothstep(FACE_DURATION - FACE_TRANSITION, FACE_DURATION, faceTime));

            bgAccum = max(bgAccum, ghostBackground(uv, facePos) * fadeFactor);
            faceAccum = max(faceAccum, ghostFace(uv, facePos, timeBlock + float(i) * 100.0) * fadeFactor);
        }
        bgAccum *= smoothstep(0.15, 0.35, smokePresence);
        faceAccum *= smoothstep(0.15, 0.35, smokePresence);
    }

    vec3 smokeEffect = mix(originalColor.rgb, SMOKE_COLOR, smokeAccum * SMOKE_INTENSITY * targetInfluence * (1.0 - faceAccum));
    vec3 withBackground = mix(smokeEffect, GHOST_BG_COLOR, bgAccum * 0.28);
    vec3 finalColor = mix(withBackground, FACE_COLOR, faceAccum * 0.7);

    float alpha = mix(originalColor.a, ALPHA_MAX, clamp(smokePresence * 0.15, 0.0, 0.2));
    fragColor = vec4(finalColor, alpha);
}
