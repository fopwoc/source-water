#version 120

/* DRAWBUFFERS:2 */

#include "/lib/water_material.glsl"

uniform sampler2D colortex1;
uniform sampler2D colortex4;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;

const bool colortex2Clear = true;
const vec4 colortex2ClearColor =
    vec4(0.0, 0.0, 0.0, 0.0);

uniform int isEyeInWater;

uniform float viewWidth;
uniform float viewHeight;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;

varying vec2 texCoord;

#include "/lib/water_ssr.glsl"

vec3 reconstructViewPosition(
    vec2 uv,
    float depth
) {
    vec4 viewPos =
        gbufferProjectionInverse *
        vec4(
            uv * 2.0 - 1.0,
            depth * 2.0 - 1.0,
            1.0
        );

    return viewPos.xyz / viewPos.w;
}

void main() {
    vec4 waterData =
        texture2D(colortex1, texCoord);

    // Water occupies alpha [0.5, 1.0]: 0.5 is the surface marker and
    // the remaining half stores the normalized SSR contribution.
    float ssrContribution =
        max(
            (waterData.a - 0.5) * 2.0,
            0.0
        );

    if (
        isEyeInWater == 1 ||
        waterData.a < 0.49 ||
        ssrContribution <= 0.01
    ) {
        gl_FragData[0] = vec4(0.0);
        return;
    }

    float waterRawDepth =
        texture2D(depthtex0, texCoord).r;

    vec3 viewPos =
        reconstructViewPosition(
            texCoord,
            waterRawDepth
        );

    vec3 viewNormal =
        normalize(waterData.rgb * 2.0 - 1.0);

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

    gl_FragData[0] =
        vec4(
            tracedReflection * reflectionConfidence,
            reflectionConfidence
        );
}
