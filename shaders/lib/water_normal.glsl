#ifndef WATER_NORMAL_GLSL
#define WATER_NORMAL_GLSL

uniform sampler2D waterNormal;
uniform sampler2D waterNormalAtlas;
uniform float frameTimeCounter;

vec4 sampleWaterNormal(vec2 uv) {
#if WATER_NORMAL_MODE == 1
    const float frameCount = 29.0;
    const float frameRate = 30.0;
    const float frameSize = 256.0;
    const float atlasHeight = frameCount * frameSize;

    float frame =
        mod(
            floor(
                frameTimeCounter *
                WATER_SPEED_MULTIPLIER *
                frameRate
            ),
            frameCount
        );

    vec2 frameUv =
        (fract(uv) * (frameSize - 1.0) + 0.5) /
        vec2(frameSize, atlasHeight);

    frameUv.y +=
        frame * frameSize / atlasHeight;

    return texture2D(waterNormalAtlas, frameUv);
#else
    // water_frame01_normal is static and tileable. Movement comes from VMT
    // UV proxies; texture repeat and bilinear filtering belong to the sampler.
    return texture2D(waterNormal, uv);
#endif
}

vec4 sampleUnderwaterOverlayNormal(vec2 uv) {
    // effects/water_warp01 remains an Episode Two screen-space effect. The
    // surface generation toggle must not replace its static normal texture.
    return texture2D(waterNormal, uv);
}

#endif
