

#version 150

#define SAMPLER0 sampler2D // sampler2D, sampler3D, samplerCube
#define SAMPLER1 sampler2D // sampler2D, sampler3D, samplerCube
#define SAMPLER2 sampler2D // sampler2D, sampler3D, samplerCube
#define SAMPLER3 sampler2D // sampler2D, sampler3D, samplerCube

uniform SAMPLER0 iChannel0; // image/buffer/sound    Sampler for input textures 0
uniform SAMPLER1 iChannel1; // image/buffer/sound    Sampler for input textures 1
uniform SAMPLER2 iChannel2; // image/buffer/sound    Sampler for input textures 2
uniform SAMPLER3 iChannel3; // image/buffer/sound    Sampler for input textures 3

uniform vec3  iResolution;           // image/buffer          The viewport resolution (z is pixel aspect ratio, usually 1.0)
uniform float iTime;                 // image/sound/buffer    Current time in seconds
uniform float iTimeDelta;            // image/buffer          Time it takes to render a frame, in seconds
uniform int   iFrame;                // image/buffer          Current frame
uniform float iFrameRate;            // image/buffer          Number of frames rendered per second
uniform vec4  iMouse;                // image/buffer          xy = current pixel coords (if LMB is down). zw = click pixel
uniform vec4  iDate;                 // image/buffer/sound    Year, month, day, time in seconds in .xyzw
uniform float iSampleRate;           // image/buffer/sound    The sound sample rate (typically 44100)
uniform float iChannelTime[4];       // image/buffer          Time for channel (if video or sound), in seconds
uniform vec3  iChannelResolution[4]; // image/buffer/sound    Input texture resolution for each channel

uniform vec2  Const;
uniform vec2  CamRot;
uniform vec2  ColorShift;

// This shader should be a tutorial how to animate simple fractal in order to explore possibilities use it for music visualization
// everywere is used iTime can we can put filtered (e.g. smoothed) music-waveform to make it react on music

// It is slightly modified version of Grinning Fractal   https://www.shadertoy.com/view/Msf3WS
// The modifications are
// 1] addded comment to make it easier for new-commers to understand complex-numbered fractal shaders in general
// 2] added time-dependnet pahse shit into color-function in order to vary shading/coloring with time
// 3] added rotation into fractal iteration formula with time-varying agle so that it produce more broad span of patterns 


// Number of iterations for fractal transform  (more iterations produce more complicated fractal)
//#define Niter 10
//#define Niter 20
//#define Niter 40
#define Niter 60
//#define Niter 80


vec2 cmul(vec2 a, vec2 b){  // Complex multiplication  https://en.wikipedia.org/wiki/Complex_number#Multiplication_and_square
    return vec2( a.x*b.x - a.y*b.y,  
                 a.x*b.y + a.y*b.x);
}

vec2 rotate( vec2 z, float angle){
    vec2 cs = vec2(cos(angle),sin(angle));   // unitary complex number encode rotation 
	return cmul(z, cs);                      // multiplication of z by unitary complex number rotate it in complex plane
}

// This is some comlex-number mathematical equation of transformation
vec2 FractalTransform_GrinningF( vec2 z, vec2 C ){
    // I have now idea why this particual transformation procduce beautifull results
    //z = cmul(z,z);
    z = vec2(z.x,abs(z.y));             // abs(z.y) works like mirror => it looks like Kaleidoscope
    //vec2  a = vec2(z.x,    z.y );     // withouit abs() it is not so nice
	float b = atan(z.y, z.x);
	if(b > 0.0) b -= 6.283185307179586;
    z = vec2(log(dot(z,z))*0.5,b);      // Not sure why this particular transform looks good
    z += C;                             // ANIMATION 1] Add the constant shift - we use it for animation
    return z;
}

float fractal(vec2 z0, vec2 C) {	
	vec2 z = z0;      // starting pixel
	float mean = 0.0;
    // iteraive transform of the pixel
    // z = F(F(F(F(F(z)))))
    // every iteration branche it => produce fractal with many sub-domains
    float angle = sin(iTime*0.03)*0.15;  // ANIMATION 2] time dependnet rotation angle
    vec2  crot  = vec2(cos(angle),sin(angle)); // just to save some performance we store rotation as unitary complex number
 	for(int i = 0;i < Niter; i++) {
        z=cmul(z,crot);               // ANIMATION 2] rotate the compolex number
        z = FractalTransform_GrinningF( z, C );
        //vec2 d =z1-z; z=z1; mean+=length(d);
        mean+=length(z); // acumulate mean distance of transformed pixel from origin at each iteration
	}
    return mean/float(Niter);
    //vec3 color = colorFunc( mean );
    //return color;
}

// This generate color of pixel from calculated mean distance
vec3 colorFunc( float mean ){
    float ci = 1.0 - log2(.5*log2(mean/1.0));
    float freq = 6.0*ColorShift.y;
    float t    = ColorShift.x;   //  ANIMATION 3] time dependnet phase shift of color
    //float freq = 6.0;
    //float t  = iTime * 0.5 + Const.x*100. - Const.y*100.;   //  ANIMATION 3] time dependnet phase shift of color
    return vec3(
        0.5 + 0.5*cos( ci*freq + 0.0 + t),   // Red   - each color channel have different animation speed
        0.5 + 0.5*cos( ci*freq + 0.4 + t),   // Green
        0.5 + 0.5*cos( ci*freq + 0.8 + t*0.9)    // Blue
    );
    //return cos( vec3(ci)*6.0 + vec3(0.0,0.4,0.7) )*0.5 + 0.5;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    //  map pixel position (fragCoord)  to interval -1.0 .. 1.0
    vec2 uv = fragCoord.xy - iResolution.xy*.5; 
    //uv /= 0.25*iResolution.x;
    uv /= 0.4*iResolution.x;
    
    // rotate camera with time
    //uv = rotate( uv, sin(iTime*0.01 + Const.x*20. + Const.y*20.  )*2.7  );
    uv = rotate( uv, CamRot.x+1.57079632679 )*CamRot.y;

    // generate constant C for Julia set from sin,cos of current time to make fractal Animate with time
    float speed = 0.2;
    float juliax = sin(iTime * 0.5 *speed ) * 0.02 + 0.2;
    float juliay = cos(iTime * 0.13*speed ) * 0.04 + 5.7;
     // or you ma also try to set fixed constant parameter 
    //vec2 C = vec2(juliax, juliay);
    vec2 C = (Const-vec2(-0.7 ,0.0 ))*vec2( 1.0,  1.0) + vec2(0.2+juliax,5.7+juliax);
    //C = vec2(0.2,5.7-0.1);

    float meanDist = fractal( uv, C );       // evaluate fractal 
    vec3  col      = colorFunc( meanDist );  // map the fractal mean-distance into color
    fragColor = vec4( col ,1.0);             // output to screen
}

