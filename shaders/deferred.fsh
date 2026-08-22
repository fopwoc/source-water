#version 120

/* DRAWBUFFERS:4 */

uniform sampler2D colortex0;

varying vec2 texCoord;

void main() {
    gl_FragData[0] = texture2D(colortex0, texCoord);
}
