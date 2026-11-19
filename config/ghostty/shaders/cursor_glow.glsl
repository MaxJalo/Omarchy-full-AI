// Smooth GPU cursor-blaze / trail shader using Ghostty's native Shadertoy extensions
float sdBox(vec2 p, vec2 b) {
    vec2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 base = texture(iChannel0, uv);

    // Subtle cursor trail glow when cursor moves
    float elapsed = clamp(iTime - iTimeCursorChange, 0.0, 1.0);
    float fade = exp(-elapsed * 10.0);

    vec2 curCenter = iCurrentCursor.xy + vec2(iCurrentCursor.z, -iCurrentCursor.w) * 0.5;
    vec2 prevCenter = iPreviousCursor.xy + vec2(iPreviousCursor.z, -iPreviousCursor.w) * 0.5;
    vec2 delta = curCenter - prevCenter;
    float distMoved = length(delta);

    if (iFocus > 0 && fade > 0.01 && distMoved > 2.0 && distMoved < iResolution.x * 0.9) {
        vec2 pa = fragCoord - prevCenter;
        vec2 ba = curCenter - prevCenter;
        float h = clamp(dot(pa, ba) / max(dot(ba, ba), 1e-4), 0.0, 1.0);
        float d = length(pa - ba * h);
        float beam = smoothstep(max(iCurrentCursor.w * 0.55, 6.0), 0.0, d) * fade * 0.28;
        vec3 glowCol = mix(iCurrentCursorColor.rgb, vec3(0.39, 0.71, 0.64), 0.45);
        base.rgb += glowCol * beam;
    }

    // Very soft ambient halo around active cursor
    if (iFocus > 0 && iCursorVisible.x > 0.5) {
        float cd = sdBox(fragCoord - curCenter, iCurrentCursor.zw * 0.5);
        float halo = exp(-max(cd, 0.0) * 0.14) * 0.10;
        base.rgb += iCurrentCursorColor.rgb * halo;
    }

    fragColor = base;
}
