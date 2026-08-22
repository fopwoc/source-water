#ifndef WATER_SSR_GLSL
#define WATER_SSR_GLSL

// Minecraft screen-space substitute for Source's planar reflection target.

vec3 sourceProjectToScreen(vec3 viewPos) {
    vec4 clipPos =
        gbufferProjection * vec4(viewPos, 1.0);

    vec3 ndc =
        clipPos.xyz / clipPos.w;

    return ndc * 0.5 + 0.5;
}

vec3 sourceTraceReflection(
    vec3 origin,
    vec3 direction,
    out float confidence
) {
    const int maxSteps = SSR_MAX_STEPS;
    const int refineSteps = SSR_REFINE_STEPS;

    const float maxDistance = 64.0;
    const float referenceViewHeight = 1440.0;

    float targetPixels =
        SSR_TARGET_PIXELS *
        max(
            viewHeight / referenceViewHeight,
            1.0
        );

    confidence = 0.0;

    float rayDistance = 0.15;
    float previousDistance = rayDistance;
    float previousDelta = -1.0;

    bool hasPrevious = false;

    for (int i = 0; i < maxSteps; ++i) {
        vec3 rayPos =
            origin + direction * rayDistance;

        vec3 projected =
            sourceProjectToScreen(rayPos);

        if (
            projected.x <= 0.001 ||
            projected.x >= 0.999 ||
            projected.y <= 0.001 ||
            projected.y >= 0.999 ||
            projected.z <= 0.0 ||
            projected.z >= 1.0
        ) {
            break;
        }

        float sceneRawDepth =
            texture2D(depthtex1, projected.xy).r;

        if (sceneRawDepth >= 0.9999) {
            float edgeDistance =
                min(
                    min(projected.x, 1.0 - projected.x),
                    min(projected.y, 1.0 - projected.y)
                );

            confidence =
                smoothstep(0.02, 0.12, edgeDistance);

            return texture2D(
                colortex4,
                projected.xy
            ).rgb;
        }

        float delta =
            projected.z - sceneRawDepth;

        if (
            hasPrevious &&
            previousDelta < 0.0 &&
            delta >= 0.0
        ) {
            float low = previousDistance;
            float high = rayDistance;

            for (int j = 0; j < refineSteps; ++j) {
                float middle =
                    (low + high) * 0.5;

                vec3 middlePos =
                    origin + direction * middle;

                vec3 middleProjected =
                    sourceProjectToScreen(middlePos);

                float middleSceneRawDepth =
                    texture2D(
                        depthtex1,
                        middleProjected.xy
                    ).r;

                float middleDelta =
                    middleProjected.z -
                    middleSceneRawDepth;

                if (middleDelta >= 0.0) {
                    high = middle;
                } else {
                    low = middle;
                }
            }

            vec3 hitPos =
                origin + direction * high;

            vec3 hitProjected =
                sourceProjectToScreen(hitPos);

            float edgeDistance =
                min(
                    min(
                        hitProjected.x,
                        1.0 - hitProjected.x
                    ),
                    min(
                        hitProjected.y,
                        1.0 - hitProjected.y
                    )
                );

            float edgeConfidence =
                smoothstep(
                    0.02,
                    0.12,
                    edgeDistance
                );

            float distanceConfidence =
                1.0 - smoothstep(
                    24.0,
                    maxDistance,
                    high
                );

            confidence =
                edgeConfidence *
                distanceConfidence;

            return texture2D(
                colortex4,
                hitProjected.xy
            ).rgb;
        }

        previousDelta = delta;
        previousDistance = rayDistance;
        hasPrevious = true;

        vec3 probeProjected =
            sourceProjectToScreen(rayPos + direction);

        vec2 pixelDelta =
            abs(
                (probeProjected.xy - projected.xy) *
                vec2(viewWidth, viewHeight)
            );

        float pixelsPerBlock =
            max(
                max(pixelDelta.x, pixelDelta.y),
                0.001
            );

        float stepSize =
            clamp(
                targetPixels / pixelsPerBlock,
                0.05,
                1.0
            );

        rayDistance += stepSize;

        if (rayDistance >= maxDistance) {
            break;
        }
    }

    return vec3(0.55, 0.65, 0.75);
}

#endif
