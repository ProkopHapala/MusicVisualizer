

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


uniform vec2 Const;

//
// From  Julia - Distance 3  -   https://www.shadertoy.com/view/4dXGDX
//
// Created by inigo quilez - iq/2013
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Distance computation for the Julia set of the
// rational function
//
// f(z) = (z-(1+i)/10)(z-i)(z-1)^4 / (z+1)(z-(1+i)) + c
//
// More info:
// https://iquilezles.org/www/articles/distancefractals/distancefractals.htm

// Related:
//
// Julia - Distance 1 : https://www.shadertoy.com/view/Mss3R8
// Julia - Distance 2 : https://www.shadertoy.com/view/3llyzl
// Julia - Distance 3 : https://www.shadertoy.com/view/4dXGDX


//------------------------------------------------------------
// complex number operations
vec2 cadd( vec2 a, float s ) { return vec2( a.x+s, a.y ); }
vec2 cmul( vec2 a, vec2 b )  { return vec2( a.x*b.x - a.y*b.y, a.x*b.y + a.y*b.x ); }
vec2 cdiv( vec2 a, vec2 b )  { float d = dot(b,b); return vec2( dot(a,b), a.y*b.x - a.x*b.y ) / d; }
vec2 csqr( vec2 a ) { return vec2(a.x*a.x-a.y*a.y, 2.0*a.x*a.y ); }
vec2 csqrt( vec2 z ) { float m = length(z); return sqrt( 0.5*vec2(m+z.x, m-z.x) ) * vec2( 1.0, sign(z.y) ); }
vec2 conj( vec2 z ) { return vec2(z.x,-z.y); }
vec2 cpow( vec2 z, float n ) { float r = length( z ); float a = atan( z.y, z.x ); return pow( r, n )*vec2( cos(a*n), sin(a*n) ); }
//------------------------------------------------------------


vec2 f( vec2 z, vec2 c )
{
	//return csqr(z) + c;   // tradicional z -> z^2 + c Julia set

	return c + cdiv( cmul( z-vec2(0.0,1.0), cmul( cpow(z-1.0,4.0), (z-vec2(-0.1)) ) ), 
					 cmul( z-vec2(1.0,1.0), z+1.0));
}

vec2 df( vec2 z, vec2 c )
{
	vec2 e = vec2(0.001,0.0);
    return cdiv( f(z,c) - f(z+e,c), e );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 q = fragCoord.xy / iResolution.xy;
    vec2 p = -1.0 + 2.0 * q;
	p.y *= iResolution.y/iResolution.x;
	p = 2.5*(p+vec2(0.25,0.37));
	
	float time = iTime*0.3;
	vec2 c = vec2(0.2,0.2) +
             0.30*vec2( cos(0.31*time), sin(0.37*time) ) - 
		     0.15*vec2( sin(1.17*time), cos(2.31*time) );
	

	// iterate		
	vec2 dz = vec2( 1.0, 0.0 );
	vec2 z = p;
	float g = 1e10;
	for( int i=0; i<100; i++ )
	{
		if( dot(z,z)>10000.0 ) continue;

        // chain rule for derivative		
		dz = cmul( dz, df( z, c ) );

        // function		
		z = f( z, c );
		
		g = min( g, dot(z-1.0,z-1.0) );
	}

    // distance estimator
	float h = 0.5*log(dot(z,z))*sqrt( dot(z,z)/dot(dz,dz) );
	
	h = clamp( h*250.0, 0.0, 1.0 );
	
	
	vec3 col = 0.6 + 0.4*cos( log(log(1.0+g))*0.5 + 4.5 + vec3(0.0,0.5,1.0) );
	col *= h;
	fragColor = vec4( col, 1.0 );

}


