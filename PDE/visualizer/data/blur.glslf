/*


schroedinger eqation

 i*dF/dt = a*V*F  - b*Lapalce(F) 
 
 https://en.wikipedia.org/wiki/Schr%C3%B6dinger_equation#Time-dependent_equation

*/



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

uniform float K;

uniform sampler2D iChannel0;
uniform sampler2D iChannel1;

void main( void ) {
    vec2 p = ( gl_FragCoord.xy / iResolution.xy );
    vec3 d = vec3( 1.0/iResolution.xy, 0.0  );
    gl_FragColor = (
    (texture2D(iChannel0, p-d.xz ) +
     texture2D(iChannel0, p+d.xz ) +
     texture2D(iChannel0, p-d.zy ) +
     texture2D(iChannel0, p+d.zy ))*K +
    texture2D(iChannel0, p      )*(1-4.*K) );
}

