#ifndef WATER_MATERIAL_GLSL
#define WATER_MATERIAL_GLSL

// Source Water VMT pairs, shared by the surface and underwater pass.

#define WATER_BLOCK_ID 10001.0

#define WATER_PRESET 0 // [0 1 2 3 4 5 6 7 8]

// 0 = Episode Two static normal with three UV flows.
// 1 = Half-Life 2 animated normal with the original single UV flow.
#define WATER_NORMAL_MODE 0 // [0 1]

// 0 = Source distance blend, 1 = force expensive, 2 = force cheap.
#define WATER_QUALITY 0 // [0 1 2]

// SSR is a Minecraft adaptation for Source's planar reflection render target.
#define SSR_QUALITY 1 // [3 4 0 1 2]
#define SSR_RESOLUTION 3 // [0 1 2 3]

#if SSR_RESOLUTION == 0
#define SSR_RESOLUTION_SCALE 0.25
#elif SSR_RESOLUTION == 1
#define SSR_RESOLUTION_SCALE 0.5
#elif SSR_RESOLUTION == 2
#define SSR_RESOLUTION_SCALE 0.75
#elif SSR_RESOLUTION == 3
#define SSR_RESOLUTION_SCALE 1.0
#else
#error SSR_RESOLUTION must be 0, 1, 2, or 3
#endif

#if SSR_QUALITY == 3
#define SSR_ENABLED 0
#define WATER_REFLECTIONS_ENABLED 1
#define SSR_MAX_STEPS 1
#define SSR_REFINE_STEPS 0
#define SSR_TARGET_PIXELS 3.0
#elif SSR_QUALITY == 4
#define SSR_ENABLED 0
#define WATER_REFLECTIONS_ENABLED 0
#define SSR_MAX_STEPS 1
#define SSR_REFINE_STEPS 0
#define SSR_TARGET_PIXELS 3.0
#elif SSR_QUALITY == 0
#define SSR_ENABLED 1
#define WATER_REFLECTIONS_ENABLED 1
#define SSR_MAX_STEPS 40
#define SSR_REFINE_STEPS 3
#define SSR_TARGET_PIXELS 3.0
#elif SSR_QUALITY == 1
#define SSR_ENABLED 1
#define WATER_REFLECTIONS_ENABLED 1
#define SSR_MAX_STEPS 64
#define SSR_REFINE_STEPS 4
#define SSR_TARGET_PIXELS 2.0
#elif SSR_QUALITY == 2
#define SSR_ENABLED 1
#define WATER_REFLECTIONS_ENABLED 1
#define SSR_MAX_STEPS 96
#define SSR_REFINE_STEPS 5
#define SSR_TARGET_PIXELS 1.5
#else
#error SSR_QUALITY must be 0, 1, 2, 3, or 4
#endif

// Automatic mode reaches fully cheap water at this many Minecraft chunks.
#define EXPENSIVE_WATER_DISTANCE 2 // [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32]

// Minecraft adaptations. A multiplier of 1.0 preserves the VMT value.
#define REFRACTION_MULTIPLIER 1.0 // [0.0 0.25 0.5 0.75 1.0 1.25 1.5 2.0]
#define REFLECTION_MULTIPLIER 1.0 // [0.0 0.25 0.5 0.75 1.0 1.25 1.5 2.0]
#define WATER_NORMAL_SCALE 0.08 // [0.02 0.04 0.06 0.08 0.10 0.12 0.16 0.20]
#define WATER_SPEED_MULTIPLIER 1.0 // [0.25 0.5 0.75 1.0 1.25 1.5 2.0]
#define REFLECTION_OVERBRIGHT 1.0 // [1.0 1.25 1.5 1.75 2.0 2.5 3.0]
#define SURFACE_REFRACTION_BLUR 0.0 // [0.0 0.1 0.25 0.5 0.75 1.0 2.0 3.0 5.0]

// effects/water_warp01.vmt uses $refractamount .04, $bluramount 1,
// $scale [1 1], and TextureScroll rate .1 at 45 degrees.
#define UNDERWATER_OVERLAY_MULTIPLIER 1.0 // [0.0 0.25 0.5 0.75 1.0 1.25 1.5 2.0]
#define UNDERWATER_OVERLAY_SCALE 1.0 // [0.5 1.0 1.5 2.0 3.0 4.0]

// Source characters are about 72 units tall; Minecraft's player is 1.8 blocks.
// This is the only unit conversion applied to VMT fog distances.
#define SOURCE_UNITS_PER_BLOCK 40.0

// Keep chunk units in the UI only. Shader math uses blocks and preserves a
// one-chunk linear transition between the expensive and cheap paths.
#define MINECRAFT_BLOCKS_PER_CHUNK 16.0
#define CHEAP_WATER_TRANSITION_DISTANCE 16.0

// Minecraft has no local env_cubemap contribution to keep Source's cheap
// surface readable at normal incidence. Use an adjustable Fresnel floor.
#define CHEAP_WATER_FRESNEL_F0 0.04 // [0.0 0.01 0.02 0.04 0.06 0.08 0.10 0.15 0.20]

// 0 = nature/water_riverbed01 + water_riverbed01_beneath
// 1 = nature/water_riverbed02 + water_riverbed02_beneath
// 2 = nature/water_silo_01 + water_silo_01_beneath
// 3 = nature/water_tunnels01 + water_tunnels01_beneath
// 4 = lostcoast/nature/water_ati + water_ati_beneath
// 5 = nature/water_canals03 + water_canals03_beneath
// 6 = nature/water_canals_water_clear + water_canals_waterbeneath_clear
// 7 = Episode One nature/water_riverbed01 + water_riverbed01_beneath
// 8 = Counter-Strike: Source liquids/militiawater + militiawaterbeneath

#if WATER_PRESET == 0

#define WATER_ABOVE_FOG_COLOR vec3(7.0, 16.0, 18.0) / 255.0
#define WATER_ABOVE_FOG_START 1.0
#define WATER_ABOVE_FOG_END 196.0
#define WATER_ABOVE_REFRACT_AMOUNT 2.0
#define WATER_ABOVE_REFLECT_AMOUNT 0.2
#define WATER_ABOVE_HAS_REFLECTION 1
#define WATER_ABOVE_TEXTURE_SCROLL_RATE 0.02
#define WATER_ABOVE_TEXTURE_SCROLL_ANGLE 25.0
#define WATER_ABOVE_NORMAL_FRAME_RATE 30.0
#define WATER_ABOVE_SCROLL1 vec2(0.01, 0.01)
#define WATER_ABOVE_SCROLL2 vec2(-0.025, 0.025)

#define WATER_BELOW_FOG_COLOR vec3(7.0, 16.0, 18.0) / 255.0
#define WATER_BELOW_FOG_START -256.0
#define WATER_BELOW_FOG_END 512.0
#define WATER_BELOW_REFRACT_AMOUNT 1.0
#define WATER_BELOW_TEXTURE_SCROLL_RATE 0.05
#define WATER_BELOW_TEXTURE_SCROLL_ANGLE 45.0
#define WATER_BELOW_NORMAL_FRAME_RATE 30.0
#define WATER_BELOW_SCROLL1 vec2(0.01, 0.01)
#define WATER_BELOW_SCROLL2 vec2(-0.025, 0.025)
#define WATER_HAS_UNDERWATER_OVERLAY 1

#elif WATER_PRESET == 1

#define WATER_ABOVE_FOG_COLOR vec3(15.0, 32.0, 36.0) / 255.0
#define WATER_ABOVE_FOG_START 1.0
#define WATER_ABOVE_FOG_END 128.0
#define WATER_ABOVE_REFRACT_AMOUNT 2.0
#define WATER_ABOVE_REFLECT_AMOUNT 0.0
#define WATER_ABOVE_HAS_REFLECTION 0
#define WATER_ABOVE_TEXTURE_SCROLL_RATE 0.02
#define WATER_ABOVE_TEXTURE_SCROLL_ANGLE 25.0
#define WATER_ABOVE_NORMAL_FRAME_RATE 30.0
#define WATER_ABOVE_SCROLL1 vec2(0.01, 0.01)
#define WATER_ABOVE_SCROLL2 vec2(-0.025, 0.025)

#define WATER_BELOW_FOG_COLOR vec3(15.0, 32.0, 36.0) / 255.0
#define WATER_BELOW_FOG_START -256.0
#define WATER_BELOW_FOG_END 512.0
#define WATER_BELOW_REFRACT_AMOUNT 1.0
#define WATER_BELOW_TEXTURE_SCROLL_RATE 0.05
#define WATER_BELOW_TEXTURE_SCROLL_ANGLE 45.0
#define WATER_BELOW_NORMAL_FRAME_RATE 30.0
#define WATER_BELOW_SCROLL1 vec2(0.01, 0.01)
#define WATER_BELOW_SCROLL2 vec2(-0.025, 0.025)
#if WATER_NORMAL_MODE == 1
#define WATER_HAS_UNDERWATER_OVERLAY 1
#else
#define WATER_HAS_UNDERWATER_OVERLAY 0
#endif

#elif WATER_PRESET == 2

#define WATER_ABOVE_FOG_COLOR vec3(52.0, 49.0, 44.0) / 255.0
#define WATER_ABOVE_FOG_START -256.0
#define WATER_ABOVE_FOG_END 220.0
#define WATER_ABOVE_REFRACT_AMOUNT 2.2
#define WATER_ABOVE_REFLECT_AMOUNT 0.9
#define WATER_ABOVE_HAS_REFLECTION 1
#define WATER_ABOVE_TEXTURE_SCROLL_RATE 0.04
#define WATER_ABOVE_TEXTURE_SCROLL_ANGLE 75.0
#define WATER_ABOVE_NORMAL_FRAME_RATE 30.0
#define WATER_ABOVE_SCROLL1 vec2(0.02, 0.05)
#define WATER_ABOVE_SCROLL2 vec2(-0.025, 0.045)

#define WATER_BELOW_FOG_COLOR vec3(40.0, 34.0, 27.0) / 255.0
#define WATER_BELOW_FOG_START -300.0
#define WATER_BELOW_FOG_END 560.0
#define WATER_BELOW_REFRACT_AMOUNT 0.5
#define WATER_BELOW_TEXTURE_SCROLL_RATE 0.05
#define WATER_BELOW_TEXTURE_SCROLL_ANGLE 45.0
#define WATER_BELOW_NORMAL_FRAME_RATE 30.0
#define WATER_BELOW_SCROLL1 vec2(0.01, 0.01)
#define WATER_BELOW_SCROLL2 vec2(-0.025, 0.025)
#define WATER_HAS_UNDERWATER_OVERLAY 1

#elif WATER_PRESET == 3

#define WATER_ABOVE_FOG_COLOR vec3(7.0, 13.0, 9.0) / 255.0
#define WATER_ABOVE_FOG_START -256.0
#define WATER_ABOVE_FOG_END 512.0
#define WATER_ABOVE_REFRACT_AMOUNT 2.0
#define WATER_ABOVE_REFLECT_AMOUNT 1.0
#define WATER_ABOVE_HAS_REFLECTION 1
#define WATER_ABOVE_TEXTURE_SCROLL_RATE 0.01
#define WATER_ABOVE_TEXTURE_SCROLL_ANGLE 65.0
#define WATER_ABOVE_NORMAL_FRAME_RATE 30.0
#define WATER_ABOVE_SCROLL1 vec2(0.01, 0.01)
#define WATER_ABOVE_SCROLL2 vec2(-0.025, 0.025)

#define WATER_BELOW_FOG_COLOR vec3(7.0, 13.0, 9.0) / 255.0
#define WATER_BELOW_FOG_START -256.0
#define WATER_BELOW_FOG_END 512.0
#define WATER_BELOW_REFRACT_AMOUNT 0.5
#define WATER_BELOW_TEXTURE_SCROLL_RATE 0.01
#define WATER_BELOW_TEXTURE_SCROLL_ANGLE 65.0
#define WATER_BELOW_NORMAL_FRAME_RATE 30.0
#define WATER_BELOW_SCROLL1 vec2(0.01, 0.01)
#define WATER_BELOW_SCROLL2 vec2(-0.025, 0.025)
#define WATER_HAS_UNDERWATER_OVERLAY 1

#elif WATER_PRESET == 4

#define WATER_ABOVE_FOG_COLOR vec3(20.0, 42.0, 37.0) / 255.0
#define WATER_ABOVE_FOG_START 1.0
#define WATER_ABOVE_FOG_END 100.0
#define WATER_ABOVE_REFRACT_AMOUNT 0.75
#define WATER_ABOVE_REFLECT_AMOUNT 0.75
#define WATER_ABOVE_HAS_REFLECTION 1
#define WATER_ABOVE_TEXTURE_SCROLL_RATE 0.02
#define WATER_ABOVE_TEXTURE_SCROLL_ANGLE 65.0
#define WATER_ABOVE_NORMAL_FRAME_RATE 30.0
#define WATER_ABOVE_SCROLL1 vec2(0.02, 0.02)
#define WATER_ABOVE_SCROLL2 vec2(-0.05, 0.05)

#define WATER_BELOW_FOG_COLOR vec3(20.0, 42.0, 37.0) / 255.0
#define WATER_BELOW_FOG_START 1.0
#define WATER_BELOW_FOG_END 100.0
#define WATER_BELOW_REFRACT_AMOUNT 0.1
#define WATER_BELOW_TEXTURE_SCROLL_RATE 0.05
#define WATER_BELOW_TEXTURE_SCROLL_ANGLE 45.0
#define WATER_BELOW_NORMAL_FRAME_RATE 30.0
#define WATER_BELOW_SCROLL1 vec2(0.02, 0.02)
#define WATER_BELOW_SCROLL2 vec2(-0.1, 0.1)
#define WATER_HAS_UNDERWATER_OVERLAY 0

#elif WATER_PRESET == 5

#define WATER_ABOVE_FOG_COLOR vec3(18.0, 14.0, 12.0) / 255.0
#define WATER_ABOVE_FOG_START 0.0
#define WATER_ABOVE_FOG_END 330.0
#define WATER_ABOVE_REFRACT_AMOUNT 0.7
#define WATER_ABOVE_REFLECT_AMOUNT 0.5
#define WATER_ABOVE_HAS_REFLECTION 1
#define WATER_ABOVE_TEXTURE_SCROLL_RATE 0.05
#define WATER_ABOVE_TEXTURE_SCROLL_ANGLE 45.0
#define WATER_ABOVE_NORMAL_FRAME_RATE 30.0
#define WATER_ABOVE_SCROLL1 vec2(0.01, 0.01)
#define WATER_ABOVE_SCROLL2 vec2(-0.025, 0.025)

#define WATER_BELOW_FOG_COLOR vec3(18.0, 14.0, 12.0) / 255.0
#define WATER_BELOW_FOG_START -100.0
#define WATER_BELOW_FOG_END 400.0
#define WATER_BELOW_REFRACT_AMOUNT 0.5
#define WATER_BELOW_TEXTURE_SCROLL_RATE 0.05
#define WATER_BELOW_TEXTURE_SCROLL_ANGLE 45.0
#define WATER_BELOW_NORMAL_FRAME_RATE 30.0
#define WATER_BELOW_SCROLL1 vec2(0.01, 0.01)
#define WATER_BELOW_SCROLL2 vec2(-0.025, 0.025)
#define WATER_HAS_UNDERWATER_OVERLAY 0

#elif WATER_PRESET == 6

#define WATER_ABOVE_FOG_COLOR vec3(41.0, 36.0, 17.0) / 255.0
#define WATER_ABOVE_FOG_START 1.0
#define WATER_ABOVE_FOG_END 800.0
#define WATER_ABOVE_REFRACT_AMOUNT 0.2
#define WATER_ABOVE_REFLECT_AMOUNT 1.0
#define WATER_ABOVE_HAS_REFLECTION 1
#define WATER_ABOVE_TEXTURE_SCROLL_RATE 0.05
#define WATER_ABOVE_TEXTURE_SCROLL_ANGLE 45.0
#define WATER_ABOVE_NORMAL_FRAME_RATE 30.0
#define WATER_ABOVE_SCROLL1 vec2(0.01, 0.01)
#define WATER_ABOVE_SCROLL2 vec2(-0.025, 0.025)

#define WATER_BELOW_FOG_COLOR vec3(41.0, 36.0, 17.0) / 255.0
#define WATER_BELOW_FOG_START 1.0
#define WATER_BELOW_FOG_END 800.0
#define WATER_BELOW_REFRACT_AMOUNT 0.2
#define WATER_BELOW_TEXTURE_SCROLL_RATE 0.05
#define WATER_BELOW_TEXTURE_SCROLL_ANGLE 45.0
#define WATER_BELOW_NORMAL_FRAME_RATE 30.0
#define WATER_BELOW_SCROLL1 vec2(0.01, 0.01)
#define WATER_BELOW_SCROLL2 vec2(-0.025, 0.025)
#define WATER_HAS_UNDERWATER_OVERLAY 1

#elif WATER_PRESET == 7

#define WATER_ABOVE_FOG_COLOR vec3(20.0, 26.0, 20.0) / 255.0
#define WATER_ABOVE_FOG_START 1.0
#define WATER_ABOVE_FOG_END 40.0
#define WATER_ABOVE_REFRACT_AMOUNT 0.75
#define WATER_ABOVE_REFLECT_AMOUNT 0.75
#define WATER_ABOVE_HAS_REFLECTION 1
#define WATER_ABOVE_TEXTURE_SCROLL_RATE 0.02
#define WATER_ABOVE_TEXTURE_SCROLL_ANGLE 25.0
#define WATER_ABOVE_NORMAL_FRAME_RATE 15.0
#define WATER_ABOVE_SCROLL1 vec2(0.01, 0.01)
#define WATER_ABOVE_SCROLL2 vec2(-0.025, 0.025)

#define WATER_BELOW_FOG_COLOR vec3(20.0, 42.0, 37.0) / 255.0
#define WATER_BELOW_FOG_START 1.0
#define WATER_BELOW_FOG_END 100.0
#define WATER_BELOW_REFRACT_AMOUNT 0.1
#define WATER_BELOW_TEXTURE_SCROLL_RATE 0.05
#define WATER_BELOW_TEXTURE_SCROLL_ANGLE 45.0
#define WATER_BELOW_NORMAL_FRAME_RATE 30.0
#define WATER_BELOW_SCROLL1 vec2(0.01, 0.01)
#define WATER_BELOW_SCROLL2 vec2(-0.025, 0.025)
#define WATER_HAS_UNDERWATER_OVERLAY 0

#elif WATER_PRESET == 8

#define WATER_ABOVE_FOG_COLOR vec3(0.07, 0.14, 0.12)
#define WATER_ABOVE_FOG_START 5.0
#define WATER_ABOVE_FOG_END 80.0
#define WATER_ABOVE_REFRACT_AMOUNT 0.0
#define WATER_ABOVE_REFLECT_AMOUNT 0.0
#define WATER_ABOVE_HAS_REFLECTION 0
#define WATER_ABOVE_TEXTURE_SCROLL_RATE 0.05
#define WATER_ABOVE_TEXTURE_SCROLL_ANGLE 45.0
#define WATER_ABOVE_NORMAL_FRAME_RATE 16.0
#define WATER_ABOVE_SCROLL1 vec2(0.01, 0.01)
#define WATER_ABOVE_SCROLL2 vec2(-0.025, 0.025)

#define WATER_BELOW_FOG_COLOR vec3(0.07, 0.14, 0.12)
#define WATER_BELOW_FOG_START 5.0
#define WATER_BELOW_FOG_END 150.0
#define WATER_BELOW_REFRACT_AMOUNT 1.0
#define WATER_BELOW_TEXTURE_SCROLL_RATE 0.05
#define WATER_BELOW_TEXTURE_SCROLL_ANGLE 45.0
#define WATER_BELOW_NORMAL_FRAME_RATE 16.0
#define WATER_BELOW_SCROLL1 vec2(0.01, 0.01)
#define WATER_BELOW_SCROLL2 vec2(-0.025, 0.025)
#define WATER_HAS_UNDERWATER_OVERLAY 0

#else

#error WATER_PRESET must be between 0 and 8

#endif

#if SSR_ENABLED == 1 && SSR_RESOLUTION < 3 && WATER_ABOVE_HAS_REFLECTION == 1 && WATER_QUALITY != 2
#define WATER_HAS_DOWNSAMPLED_SSR 1
#else
#define WATER_HAS_DOWNSAMPLED_SSR 0
#endif

float sourceWaterFogFactor(
    float distanceInBlocks,
    float fogStartInSourceUnits,
    float fogEndInSourceUnits
) {
    float fogStart =
        fogStartInSourceUnits / SOURCE_UNITS_PER_BLOCK;

    float fogEnd =
        fogEndInSourceUnits / SOURCE_UNITS_PER_BLOCK;

    return clamp(
        (distanceInBlocks - fogStart) /
            max(fogEnd - fogStart, 0.0001),
        0.0,
        1.0
    );
}

float sourceAboveWaterFogFactor(float distanceInBlocks) {
    return sourceWaterFogFactor(
        distanceInBlocks,
        WATER_ABOVE_FOG_START,
        WATER_ABOVE_FOG_END
    );
}

float sourceBelowWaterFogFactor(float distanceInBlocks) {
    return sourceWaterFogFactor(
        distanceInBlocks,
        WATER_BELOW_FOG_START,
        WATER_BELOW_FOG_END
    );
}

float sourceCheapWaterBlend(float distanceInBlocks) {
#if WATER_QUALITY == 0
    float cheapWaterEndDistance =
        float(EXPENSIVE_WATER_DISTANCE) *
        MINECRAFT_BLOCKS_PER_CHUNK;

    float cheapWaterStartDistance =
        max(
            cheapWaterEndDistance -
                CHEAP_WATER_TRANSITION_DISTANCE,
            0.0
        );

    return clamp(
        (distanceInBlocks -
            cheapWaterStartDistance) /
            max(
                cheapWaterEndDistance -
                    cheapWaterStartDistance,
                0.0001
            ),
        0.0,
        1.0
    );
#elif WATER_QUALITY == 1
    return 0.0;
#elif WATER_QUALITY == 2
    return 1.0;
#else
#error WATER_QUALITY must be 0, 1, or 2
#endif
}

float sourceWaterRefractAmount(bool underwater) {
    return (
        underwater
            ? WATER_BELOW_REFRACT_AMOUNT
            : WATER_ABOVE_REFRACT_AMOUNT
    ) * REFRACTION_MULTIPLIER;
}

float sourceWaterTextureScrollRate(bool underwater) {
    return underwater
        ? WATER_BELOW_TEXTURE_SCROLL_RATE
        : WATER_ABOVE_TEXTURE_SCROLL_RATE;
}

float sourceWaterTextureScrollAngle(bool underwater) {
    return underwater
        ? WATER_BELOW_TEXTURE_SCROLL_ANGLE
        : WATER_ABOVE_TEXTURE_SCROLL_ANGLE;
}

float sourceWaterNormalFrameRate(bool underwater) {
    return underwater
        ? WATER_BELOW_NORMAL_FRAME_RATE
        : WATER_ABOVE_NORMAL_FRAME_RATE;
}

vec2 sourceWaterScroll1(bool underwater) {
    return underwater
        ? WATER_BELOW_SCROLL1
        : WATER_ABOVE_SCROLL1;
}

vec2 sourceWaterScroll2(bool underwater) {
    return underwater
        ? WATER_BELOW_SCROLL2
        : WATER_ABOVE_SCROLL2;
}

#endif
