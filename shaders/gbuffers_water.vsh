#version 120

#include "/lib/water_material.glsl"

attribute float mc_Entity;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;

varying vec3 worldPos;
varying vec4 color;
varying vec2 coord0;
varying vec2 coord1;
varying float isSourceWater;
varying vec3 surfaceNormal;

void main() {
    vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
    vec3 playerPos = (gbufferModelViewInverse * viewPos).xyz;

    gl_Position =
        gl_ProjectionMatrix *
        gbufferModelView *
        vec4(playerPos, 1.0);

    worldPos = playerPos + cameraPosition;

    gl_FogFragCoord = length(playerPos);

    vec3 viewNormal =
        gl_NormalMatrix * gl_Normal;

    vec3 worldNormal =
        normalize(
            (gbufferModelViewInverse *
                vec4(viewNormal, 0.0)).xyz
        );

    float isWaterBlock =
        float(abs(mc_Entity - WATER_BLOCK_ID) < 0.5);

    isSourceWater = isWaterBlock;
    surfaceNormal = worldNormal;

    float light = min(
        worldNormal.x * worldNormal.x * 0.6 +
        worldNormal.y * worldNormal.y * 0.25 *
            (3.0 + worldNormal.y) +
        worldNormal.z * worldNormal.z * 0.8,
        1.0
    );

    color =
        vec4(gl_Color.rgb * light, gl_Color.a);

    coord0 =
        (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

    coord1 =
        (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;

}
