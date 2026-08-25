#version 120

#include "/lib/water_material.glsl"

#if WATER_HAS_DOWNSAMPLED_SSR == 1
/* DRAWBUFFERS:013 */
#else
/* DRAWBUFFERS:01 */
#endif

#include "/lib/water_normal.glsl"

uniform sampler2D colortex4;
uniform sampler2D depthtex1;
uniform sampler2D texture;
uniform sampler2D lightmap;

uniform float viewWidth;
uniform float viewHeight;

uniform float near;
uniform float far;

uniform vec3 cameraPosition;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;

uniform vec3 skyColor;
uniform vec4 entityColor;

uniform float blindness;

varying vec3 worldPos;
varying vec4 color;
varying vec2 coord0;
varying vec2 coord1;
varying float isSourceWater;
varying vec3 surfaceNormal;

uniform int isEyeInWater;

#if SSR_ENABLED == 1 && SSR_RESOLUTION == 3 && WATER_ABOVE_HAS_REFLECTION == 1 && WATER_QUALITY != 2
#include "/lib/water_ssr.glsl"
#endif

// Backport of Source 2007 water_ps2x_helper.h.

vec4 renderTranslucentMaterial() {
    vec3 light =
        (1.0 - blindness) *
        texture2D(lightmap, coord1).rgb;

    vec4 materialColor =
        color *
        vec4(light, 1.0) *
        texture2D(texture, coord0);

    materialColor.rgb = mix(
        materialColor.rgb,
        entityColor.rgb,
        entityColor.a
    );

    float fog =
        (isEyeInWater == 1)
            ? 0.0
            : (isEyeInWater > 1)
                ? 1.0 - exp(
                    -gl_FogFragCoord * gl_Fog.density
                )
                : clamp(
                    (gl_FogFragCoord - gl_Fog.start) *
                        gl_Fog.scale,
                    0.0,
                    1.0
                );

    materialColor.rgb = mix(
        materialColor.rgb,
        gl_Fog.color.rgb,
        fog
    );

    return materialColor;
}

float linearizeDepth(float depth) {
    float z = depth * 2.0 - 1.0;

    return (2.0 * near * far) /
        (far + near - z * (far - near));
}

vec3 sampleRefraction(vec2 uv) {
    if (SURFACE_REFRACTION_BLUR <= 0.0) {
        return texture2D(colortex4, uv).rgb;
    }

    vec2 stepUv =
        vec2(
            1.0 / viewWidth,
            1.0 / viewHeight
        ) * SURFACE_REFRACTION_BLUR;

    vec3 color = vec3(0.0);

    for (int x = -2; x <= 2; ++x) {
        for (int y = -2; y <= 2; ++y) {
            color += texture2D(
                colortex4,
                uv + vec2(float(x), float(y)) * stepUv
            ).rgb;
        }
    }

    return color / 25.0;
}

void sourceWaterSurfaceBasis(
    vec3 geometryNormal,
    out vec3 tangent,
    out vec3 bitangent
) {
    vec3 axis = abs(geometryNormal);

    if (axis.y >= axis.x && axis.y >= axis.z) {
        float side =
            geometryNormal.y >= 0.0 ? 1.0 : -1.0;

        tangent = vec3(1.0, 0.0, 0.0);
        bitangent = vec3(0.0, 0.0, side);
    } else if (axis.x >= axis.z) {
        float side =
            geometryNormal.x >= 0.0 ? 1.0 : -1.0;

        tangent = vec3(0.0, 0.0, -side);
        bitangent = vec3(0.0, 1.0, 0.0);
    } else {
        float side =
            geometryNormal.z >= 0.0 ? 1.0 : -1.0;

        tangent = vec3(side, 0.0, 0.0);
        bitangent = vec3(0.0, 1.0, 0.0);
    }
}

mat3 sourceUpperLeftMat3(mat4 value) {
    return mat3(
        value[0].xyz,
        value[1].xyz,
        value[2].xyz
    );
}

void main() {
    if (isSourceWater < 0.5) {
        gl_FragData[0] =
            renderTranslucentMaterial();

        gl_FragData[1] =
            vec4(0.0);

#if WATER_HAS_DOWNSAMPLED_SSR == 1
        gl_FragData[2] =
            vec4(0.0);
#endif

        return;
    }

    vec2 screenUv =
        gl_FragCoord.xy / vec2(viewWidth, viewHeight);

    bool underwater =
        isEyeInWater == 1;

    float sourceWaterTime =
        frameTimeCounter * WATER_SPEED_MULTIPLIER;

    vec3 geometryNormal =
        normalize(surfaceNormal);

    vec3 surfaceTangent;
    vec3 surfaceBitangent;

    sourceWaterSurfaceBasis(
        geometryNormal,
        surfaceTangent,
        surfaceBitangent
    );

    vec2 baseUv =
        vec2(
            dot(worldPos, surfaceTangent),
            dot(worldPos, surfaceBitangent)
        ) * WATER_NORMAL_SCALE;

    float scrollAngle;
    float scrollRate;

    scrollAngle =
        radians(sourceWaterTextureScrollAngle(underwater));
    scrollRate =
        sourceWaterTextureScrollRate(underwater);

    vec2 scroll =
        vec2(cos(scrollAngle), sin(scrollAngle)) *
        scrollRate *
        sourceWaterTime;

    float f45x =
        baseUv.x + baseUv.y;

    float f45y =
        baseUv.y - baseUv.x;

    vec2 uv0 =
        baseUv + scroll;

    vec2 uv1 =
        vec2(f45x, f45y) * 0.1 +
        sourceWaterScroll1(underwater) * sourceWaterTime;

    vec2 uv2 =
        vec2(baseUv.y, baseUv.x) * 0.45 +
        sourceWaterScroll2(underwater) * sourceWaterTime;

#if WATER_NORMAL_MODE == 1
    vec4 sourceNormal =
        sampleWaterNormal(
            uv0,
            sourceWaterNormalFrameRate(underwater)
        );
#else
    vec4 normal0 =
        sampleWaterNormal(uv0, 0.0);

    vec4 normal1 =
        sampleWaterNormal(uv1, 0.0);

    vec4 normal2 =
        sampleWaterNormal(uv2, 0.0);

    vec4 sourceNormal =
        (normal0 + normal1 + normal2) / 3.0;
#endif

    sourceNormal.xyz =
        sourceNormal.xyz * 2.0 - 1.0;

    vec3 normal =
        sourceNormal.xyz;

    float normalStrength =
        sourceNormal.a;

    vec3 materialNormal =
        normalize(
            surfaceTangent * normal.x +
            surfaceBitangent * normal.y +
            geometryNormal * normal.z
        );

    vec3 viewDir =
        normalize(cameraPosition - worldPos);

    float ndotv =
        clamp(
            dot(materialNormal, viewDir),
            0.0,
            1.0
        );

    float sourceFresnel =
        pow(1.0 - ndotv, 5.0);

    float cheapNdotv =
        clamp(
            abs(dot(materialNormal, viewDir)),
            0.0,
            1.0
        );

    float cheapSourceFresnel =
        pow(1.0 - cheapNdotv, 5.0);

    float cheapWaterFresnel =
        mix(
            CHEAP_WATER_FRESNEL_F0,
            1.0,
            cheapSourceFresnel
        );

    vec3 environmentLight =
        (1.0 - blindness) *
        texture2D(lightmap, coord1).rgb;

    environmentLight *=
        environmentLight;

    vec3 localEnvironmentColor =
        skyColor * environmentLight;

    vec3 playerPos =
        worldPos - cameraPosition;

    // WaterCheap_ps20: fog color plus an envmap reflection
    // modulated only by the Source Fresnel term. Minecraft has
    // no local env_cubemaps, so lightmapped skyColor is the envmap fallback.
    vec3 cheapWaterColor =
        (underwater
            ? WATER_BELOW_FOG_COLOR
            : WATER_ABOVE_FOG_COLOR) +
        localEnvironmentColor *
            cheapWaterFresnel *
            float(WATER_REFLECTIONS_ENABLED);

#if WATER_QUALITY == 0
    float cheapWaterBlend =
        sourceCheapWaterBlend(
            length(playerPos)
        );

    if (cheapWaterBlend >= 1.0) {
        gl_FragData[0] =
            vec4(cheapWaterColor, 1.0);

#if WATER_HAS_DOWNSAMPLED_SSR == 1
        gl_FragData[1] =
            vec4(0.0, 0.0, 0.0, 0.5);

        gl_FragData[2] =
            vec4(localEnvironmentColor, 1.0);
#else
        gl_FragData[1] =
            vec4(1.0);
#endif

        return;
    }
#elif WATER_QUALITY == 2
    gl_FragData[0] =
        vec4(cheapWaterColor, 1.0);

#if WATER_HAS_DOWNSAMPLED_SSR == 1
    // RGB stores the view-space normal. Alpha packs the water marker and
    // normalized SSR contribution into [0.5, 1.0].
    gl_FragData[1] =
        vec4(0.0, 0.0, 0.0, 0.5);

    // Local lightmapped envmap fallback used by the fullscreen resolve.
    gl_FragData[2] =
        vec4(localEnvironmentColor, 1.0);
#else
    gl_FragData[1] =
        vec4(1.0);
#endif

    return;
#endif

    vec2 refractionNormal = normal.xy;

    if (abs(geometryNormal.y) < 0.8) {
        vec2 projectedTangent =
            (sourceUpperLeftMat3(gbufferModelView) *
                surfaceTangent).xy;

        vec2 projectedBitangent =
            (sourceUpperLeftMat3(gbufferModelView) *
                surfaceBitangent).xy;

        projectedTangent =
            length(projectedTangent) > 0.0001
                ? normalize(projectedTangent)
                : vec2(1.0, 0.0);

        projectedBitangent =
            length(projectedBitangent) > 0.0001
                ? normalize(projectedBitangent)
                : vec2(0.0, 1.0);

        refractionNormal =
            projectedTangent * normal.x +
            projectedBitangent * normal.y;
    }

    float waterDepth =
        linearizeDepth(gl_FragCoord.z);

    float unwarpedSceneRawDepth =
        texture2D(depthtex1, screenUv).r;

    float unwarpedSceneDepth =
        linearizeDepth(unwarpedSceneRawDepth);

    float unwarpedWaterThickness =
        max(unwarpedSceneDepth - waterDepth, 0.0);

    float distortionDepthFactor =
        underwater
            ? 1.0
            : sourceAboveWaterFogFactor(
                unwarpedWaterThickness
            );

    vec2 distortedUv = clamp(
        screenUv +
            refractionNormal *
            normalStrength *
            distortionDepthFactor *
            sourceWaterRefractAmount(underwater),
        vec2(0.001),
        vec2(0.999)
    );

    float sceneRawDepth =
        texture2D(depthtex1, distortedUv).r;

    float sceneDepth =
        linearizeDepth(sceneRawDepth);

    const float depthBias = 0.05;

    bool distortedIntoSky =
        underwater &&
        sceneRawDepth >= 0.9999 &&
        unwarpedSceneRawDepth < 0.9999;

    if (
        sceneDepth < waterDepth - depthBias ||
        distortedIntoSky
    ) {
        distortedUv = screenUv;

        sceneRawDepth =
            unwarpedSceneRawDepth;

        sceneDepth =
            unwarpedSceneDepth;
    }

    vec3 refracted =
        sampleRefraction(distortedUv);

    float waterThickness =
        max(sceneDepth - waterDepth, 0.0);

    float waterDepthFactor =
        sourceAboveWaterFogFactor(waterThickness);

    float fogAmount =
        underwater
            ? sourceBelowWaterFogFactor(waterDepth)
            : waterDepthFactor;

    vec3 waterFogColor =
        underwater
            ? WATER_BELOW_FOG_COLOR
            : WATER_ABOVE_FOG_COLOR;

    refracted =
        mix(refracted, waterFogColor, fogAmount);

    float reflectionStrength =
        sourceFresnel *
        float(WATER_ABOVE_HAS_REFLECTION) *
        float(WATER_REFLECTIONS_ENABLED) *
        REFLECTION_MULTIPLIER;

    if (underwater) {
        reflectionStrength = 0.0;
    }

    reflectionStrength =
        clamp(reflectionStrength, 0.0, 1.0);

    // Source applies overbright only with blurry refraction.
    float reflectionOverbright = mix(
        1.0,
        REFLECTION_OVERBRIGHT,
        step(0.001, SURFACE_REFRACTION_BLUR)
    );

    vec3 fallbackReflection =
        localEnvironmentColor *
        reflectionOverbright;

    vec3 viewNormal =
        normalize(
            sourceUpperLeftMat3(gbufferModelView) *
            normalize(
                surfaceTangent * normal.x *
                    WATER_ABOVE_REFLECT_AMOUNT +
                surfaceBitangent * normal.y *
                    WATER_ABOVE_REFLECT_AMOUNT +
                geometryNormal * normal.z
            )
        );

    vec3 reflected =
        fallbackReflection;

#if SSR_ENABLED == 1 && SSR_RESOLUTION == 3 && WATER_ABOVE_HAS_REFLECTION == 1 && WATER_QUALITY != 2
    const float minReflectionTraceStrength =
        0.01;

    if (
        !underwater &&
        reflectionStrength >
            minReflectionTraceStrength
    ) {
        vec3 viewPos =
            (gbufferModelView *
                vec4(playerPos, 1.0)).xyz;

        vec3 incidentDir =
            normalize(viewPos);

        vec3 reflectedDir =
            normalize(
                reflect(
                    incidentDir,
                    viewNormal
                )
            );

        float reflectionConfidence;

        vec3 tracedReflection =
            sourceTraceReflection(
                viewPos + reflectedDir * 0.15,
                reflectedDir,
                reflectionConfidence
            );

        reflected =
            mix(
                localEnvironmentColor,
                tracedReflection,
                reflectionConfidence
            ) * reflectionOverbright;
    }
#endif

    float ssrContribution =
        reflectionStrength;

    vec3 color =
        mix(
            refracted,
            reflected,
            reflectionStrength
        );

#if WATER_QUALITY == 0
    ssrContribution *=
        1.0 - cheapWaterBlend;

    color =
        mix(
            color,
            cheapWaterColor,
            cheapWaterBlend
        );
#endif

    gl_FragData[0] =
        vec4(color, 1.0);

#if WATER_HAS_DOWNSAMPLED_SSR == 1
    gl_FragData[1] =
        vec4(
            viewNormal * 0.5 + 0.5,
            0.5 + 0.5 * ssrContribution
        );

    gl_FragData[2] =
        vec4(localEnvironmentColor, 1.0);
#else
    gl_FragData[1] =
        vec4(1.0);
#endif
}
