#version 120

/* DRAWBUFFERS:0 */

#include "/lib/water_material.glsl"
#include "/lib/water_normal.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex1;
#if WATER_HAS_DOWNSAMPLED_SSR == 1
uniform sampler2D colortex2;
uniform sampler2D colortex3;
#endif
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;

const bool colortex1Clear = true;
const vec4 colortex1ClearColor =
    vec4(0.0, 0.0, 0.0, 0.0);
#if WATER_HAS_DOWNSAMPLED_SSR == 1
const bool colortex3Clear = true;
const vec4 colortex3ClearColor =
    vec4(0.0, 0.0, 0.0, 0.0);
#endif

uniform int isEyeInWater;

uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;

varying vec2 texCoord;

// Underwater post-process for Source-style water.

float linearizeDepth(float depth) {
    float z = depth * 2.0 - 1.0;

    return (2.0 * near * far) /
        (far + near - z * (far - near));
}

vec2 clampSceneUv(vec2 uv) {
    vec2 halfTexel =
        vec2(
            0.5 / viewWidth,
            0.5 / viewHeight
        );

    return clamp(
        uv,
        halfTexel,
        vec2(1.0) - halfTexel
    );
}

#if WATER_HAS_DOWNSAMPLED_SSR == 1
vec4 sampleReflectionData(vec2 uv) {
    vec2 resolution =
        max(
            floor(
                vec2(viewWidth, viewHeight) *
                SSR_RESOLUTION_SCALE
            ),
            vec2(1.0)
        );

    vec2 pixelPosition =
        clampSceneUv(uv) * resolution -
        vec2(0.5);

    vec2 basePixel =
        floor(pixelPosition);

    vec2 pixelFraction =
        fract(pixelPosition);

    vec2 maxPixel =
        resolution - vec2(1.0);

    vec2 uv00 =
        (clamp(basePixel, vec2(0.0), maxPixel) +
            vec2(0.5)) /
        resolution;

    vec2 uv10 =
        (clamp(
            basePixel + vec2(1.0, 0.0),
            vec2(0.0),
            maxPixel
        ) + vec2(0.5)) /
        resolution;

    vec2 uv01 =
        (clamp(
            basePixel + vec2(0.0, 1.0),
            vec2(0.0),
            maxPixel
        ) + vec2(0.5)) /
        resolution;

    vec2 uv11 =
        (clamp(
            basePixel + vec2(1.0),
            vec2(0.0),
            maxPixel
        ) + vec2(0.5)) /
        resolution;

    vec4 data00 =
        texture2D(colortex2, uv00);

    vec4 data10 =
        texture2D(colortex2, uv10);

    vec4 data01 =
        texture2D(colortex2, uv01);

    vec4 data11 =
        texture2D(colortex2, uv11);

    return mix(
        mix(data00, data10, pixelFraction.x),
        mix(data01, data11, pixelFraction.x),
        pixelFraction.y
    );
}
#endif

vec3 sampleSceneColor(vec2 uv) {
    vec3 color =
        texture2D(colortex0, uv).rgb;

#if WATER_HAS_DOWNSAMPLED_SSR == 1
    if (
        isEyeInWater != 1
    ) {
        vec4 waterData =
            texture2D(colortex1, uv);

        float ssrContribution =
            max(
                (waterData.a - 0.5) * 2.0,
                0.0
            );

        if (ssrContribution > 0.01) {
            float fullDepth =
                texture2D(depthtex0, uv).r;

            float opaqueDepth =
                texture2D(depthtex1, uv).r;

            bool hasVisibleWaterSurface =
                fullDepth + 0.000001 < opaqueDepth;

            if (hasVisibleWaterSurface) {
                vec3 environmentColor =
                    texture2D(colortex3, uv).rgb;

                vec4 reflectionData =
                    sampleReflectionData(uv);

                float reflectionOverbright = mix(
                    1.0,
                    REFLECTION_OVERBRIGHT,
                    step(0.001, SURFACE_REFRACTION_BLUR)
                );

                color +=
                    (reflectionData.rgb -
                        environmentColor * reflectionData.a) *
                    ssrContribution *
                    reflectionOverbright;
            }
        }
    }
#endif

    return color;
}

vec3 sampleUnderwaterSceneTexel(vec2 pixelCoord) {
    vec2 resolution =
        vec2(viewWidth, viewHeight);

    vec2 safePixelCoord =
        clamp(
            pixelCoord,
            vec2(0.0),
            resolution - vec2(1.0)
        );

    vec2 sampleUv =
        (safePixelCoord + vec2(0.5)) /
        resolution;

    vec3 color =
        sampleSceneColor(sampleUv);

    float fullDepth =
        texture2D(depthtex0, sampleUv).r;

    float opaqueDepth =
        texture2D(depthtex1, sampleUv).r;

    bool hasTranslucentSurface =
        fullDepth + 0.000001 < opaqueDepth;

    bool hasSourceWaterSurface =
        hasTranslucentSurface &&
        texture2D(colortex1, sampleUv).a > 0.49;

    if (!hasSourceWaterSurface) {
        float sceneRawDepth =
            hasTranslucentSurface
                ? fullDepth
                : opaqueDepth;

        float sceneDepth =
            linearizeDepth(sceneRawDepth);

        float distanceFog =
            sourceBelowWaterFogFactor(sceneDepth);

        color =
            mix(
                color,
                WATER_BELOW_FOG_COLOR,
                distanceFog
            );
    }

    return color;
}

vec3 sampleUnderwaterScene(vec2 uv) {
    vec2 resolution =
        vec2(viewWidth, viewHeight);

    vec2 pixelPosition =
        clampSceneUv(uv) * resolution -
        vec2(0.5);

    vec2 basePixel =
        floor(pixelPosition);

    vec2 pixelFraction =
        fract(pixelPosition);

    vec3 color00 =
        sampleUnderwaterSceneTexel(basePixel);

    vec3 color10 =
        sampleUnderwaterSceneTexel(
            basePixel + vec2(1.0, 0.0)
        );

    vec3 color01 =
        sampleUnderwaterSceneTexel(
            basePixel + vec2(0.0, 1.0)
        );

    vec3 color11 =
        sampleUnderwaterSceneTexel(
            basePixel + vec2(1.0, 1.0)
        );

    return mix(
        mix(color00, color10, pixelFraction.x),
        mix(color01, color11, pixelFraction.x),
        pixelFraction.y
    );
}

vec3 sampleWaterWarp01(vec2 uv) {
    // sdk_refract_ps2x.fxc BLUR=1 polyphase kernel.
    const float blurFraction = 1.0 / 512.0;
    const float halfBlurFraction = 0.5 / 512.0;

    vec3 color =
        sampleUnderwaterScene(
            uv - vec2(halfBlurFraction)
        ) * 0.4444444;

    color +=
        sampleUnderwaterScene(
            uv + vec2(
                blurFraction,
                -halfBlurFraction
            )
        ) * 0.2222222;

    color +=
        sampleUnderwaterScene(
            uv + vec2(
                -halfBlurFraction,
                blurFraction
            )
        ) * 0.2222222;

    color +=
        sampleUnderwaterScene(
            uv + vec2(blurFraction)
        ) * 0.1111111;

    return color;
}

void main() {
    vec2 sceneUv = texCoord;

#if WATER_HAS_UNDERWATER_OVERLAY == 1
    if (isEyeInWater == 1) {
        const float overlayAngle =
            0.7853981633974483;

        vec2 overlayScroll =
            vec2(
                cos(overlayAngle),
                sin(overlayAngle)
            ) * 0.1 *
            frameTimeCounter *
            WATER_SPEED_MULTIPLIER;

        vec2 overlayUv =
            texCoord *
            UNDERWATER_OVERLAY_SCALE +
            overlayScroll;

        vec4 overlayNormal =
            sampleUnderwaterOverlayNormal(overlayUv);

        vec2 overlayOffset =
            (overlayNormal.xy * 2.0 - 1.0) *
            overlayNormal.a *
            0.04 *
            UNDERWATER_OVERLAY_MULTIPLIER;

        sceneUv = clampSceneUv(
            texCoord + overlayOffset
        );
    }
#endif

    vec3 color;

#if WATER_HAS_UNDERWATER_OVERLAY == 1
    color =
        (isEyeInWater == 1)
            ? sampleWaterWarp01(sceneUv)
            : sampleSceneColor(sceneUv);
#else
    color =
        (isEyeInWater == 1)
            ? sampleUnderwaterScene(sceneUv)
            : sampleSceneColor(sceneUv);
#endif

    gl_FragData[0] =
        vec4(color, 1.0);
}
