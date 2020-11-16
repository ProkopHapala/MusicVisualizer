// Conway's game of life

#ifdef GL_ES
precision highp float;
#endif

#define PROCESSING_COLOR_SHADER

uniform float iTime;
uniform vec2  iMouse;
uniform vec2  iResolution;

uniform sampler2D iChannel0;
uniform sampler2D iChannel1;

void main( void ) {
    vec2 p    = ( gl_FragCoord.xy / iResolution.xy );
    vec4 sum  = texture2D(iChannel0, p );
    gl_FragColor = sum;
}
