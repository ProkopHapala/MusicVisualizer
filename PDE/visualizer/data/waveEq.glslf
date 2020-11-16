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


uniform float Ka;
uniform float Kb;
uniform float dx;
uniform float dt;

uniform sampler2D iChannel0;
uniform sampler2D iChannel1;

void main( void ) {
    vec2 p = ( gl_FragCoord.xy / iResolution.xy );
    vec3 d = vec3( dx/iResolution.xy, 0.0  );
    vec2 W = texture2D(iChannel0, p ).xy;
    vec2 L = 
    texture2D(iChannel0, p-d.xz ).xy +
    texture2D(iChannel0, p+d.xz ).xy +
    texture2D(iChannel0, p-d.zy ).xy +
    texture2D(iChannel0, p+d.zy ).xy;
    
    vec2 dW = (Ka*W - Kb*(L-4.*W))*dt;
    dW.y*=-1.;
    
    gl_FragColor = vec4( W.xy + dW.yx, 0.0, 1.0 );
}

