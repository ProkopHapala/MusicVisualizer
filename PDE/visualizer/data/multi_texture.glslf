// Conway's game of life

#ifdef GL_ES
precision highp float;
#endif

#define PROCESSING_COLOR_SHADER

//uniform float time;
//uniform vec2  mouse;
//uniform vec2  resolution;
uniform float iTime;
uniform vec2  iMouse;
uniform vec2  iResolution;

uniform sampler2D iChannel0;
uniform sampler2D iChannel1;

void main( void ) {
    vec2 pos   = ( gl_FragCoord.xy / resolution.xy );
    vec2 pixel = mouse*0.0001 + (1./resolution);
    
    pixel += sin(pos*10.2);
    
    vec4 sum;
    sum  = texture2D(iChannel0, pos+pixel );
    //sum += texture2D(iChannel1, pos+pixel );
    //sum*=0.5+0.01*sin(time);
    gl_FragColor = sum;
}
