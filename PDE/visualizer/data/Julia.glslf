

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


//Curvature average by nimitz (stormoid.com) (twitter: @stormoid)

/*
	This is a somewhat old technique of coloring fractals, according to the paper
	(http://jussiharkonen.com/files/on_fractal_coloring_techniques(lo-res).pdf)
	the technique was devised by Damien Jones in 1999, the idea is to color based
	the sum of the angles of z as it's being iterated.  I am also using a sinus function
	in the loop to greate a more "hairy" look.
	
	Try also Triangle Inequality Colloring
	https://www.shadertoy.com/view/wlXyDX

	I should be converting to hsv to do color blending, but it looks good enough that way.
*/

//#define ITR 64.
//#define ITR 32.
#define ITR 16.
//#define ITR 8.
//#define ITR 8.
#define BAILOUT 1e10

#define R .35
#define G .2
#define B .15

#define time iTime
mat2 mm2(const in float a){float c=cos(a), s=sin(a);return mat2(c,-s,s,c);}



float fR( float x ){
    float f = 1 - min( x*x, 1.0);
    return f*f;
}

float fR2( float r2 ){
    float f = 1 - min( r2, 1.0);
    return f*f;
}





//lerp between 3 colors
//usage: 0=a | 0.33=b | 0.66=c | 1=a
vec3 wheel(in vec3 a, in vec3 b, in vec3 c, in float delta){
	return mix(mix(mix( a,b,clamp((delta-0.000)*3., 0., 1.)),
						  c,clamp((delta-0.333)*3., 0., 1.)),
						  a,clamp((delta-0.666)*3., 0., 1.));
}

//Reinhard based tone mapping (https://www.shadertoy.com/view/lslGzl)
vec3 tone(vec3 color, float gamma){
	float white = 2.;
	float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
	float toneMappedLuma = luma * (1. + luma / (white*white)) / (1. + luma);
	color *= toneMappedLuma / luma;
	color = pow(color, vec3(1. / gamma));
	return color;
}

vec2 render(in vec2 z, in vec2 C ){
    //init vars
	//vec2 c = p, z = p;
	vec2 oldz1 = vec2(1.);
	vec2 oldz2 = vec2(1.);
	float curv = 0.;
	float rz = 1., rz2 = 0.;
	float numitr = 0.;
    for( int i=0; i<int(ITR); i++ ){
		if (dot(z,z)<BAILOUT){
			z = vec2(z.x*z.x-z.y*z.y, 2.*z.x*z.y) + C;
			vec2 tmp = vec2(1.);
			if (i > 0){
			    tmp = (z-oldz1)/(oldz1-oldz2);
			}
			curv = abs(atan(tmp.y,tmp.x));
			curv = sin(curv*5.)*0.5+0.5;
			oldz2   = oldz1;
			oldz1   = z;
			rz2     = rz;
			rz     += (.95-curv);
			numitr += 1.;
			
		}
	}
	//Thanks to iq for the proper smoothing formula
	float f = 1.-log2( (log(dot(z,z))/log(BAILOUT)) );
	f = smoothstep(0.,1.,f);
	//linear interpolation
	rz  = rz  / numitr;
	rz2 = rz2 / (numitr-1.);
	rz  = mix(rz2,rz,f);
    return vec2(rz,rz2);
    
    // https://www.shadertoy.com/view/wlXyDX
    // Try Trinagle Inequality Colloring
}

//void mainImage( out vec4 fragColor, in vec2 fragCoord ){
void mainImage( out vec4 fragColor, in vec2 fragCoord ){
	//vec2 p = (fUV*4.0)+vec2(-2.0,-2.0);
	
	vec2 p = ( fragCoord.xy / iResolution.xy )*4.0 - 2.0;
	vec2 p_ = p;
	p*=0.8;
	p.x *= iResolution.x/iResolution.y;
    vec2 rz = vec2(0);
    
	//vec2 d = 0.5/iResolution;
	//rz += render( p+vec2( d.x,0.), Const );
	//rz += render( p+vec2(-d.x,0.), Const );
	//rz += render( p+vec2(0., d.y), Const );
	//rz += render( p+vec2(0.,-d.y), Const );
	//rz /= 4.;
	
	rz = render( p, Const);
	//rz = render( p, p.yx * Const );
    //rz = render( p, Const*p );
    //rz = render( p, iMouse.xy );
    
	//coloring
	
	
	rz.y      = smoothstep(0.,1.2,rz.x);
	vec3 col  = (sin(vec3(R,G,B)+6.*rz.y+2.9)*.5+0.51)*1.4;
	vec3 col2 = vec3(R*(sin(rz.x*5.+1.2)),G*sin(rz.x*5.+4.1),B*sin(rz.x*5.+4.4));
	col2      = clamp(col2,0.,1.);
    vec3 col3 = vec3(R,G,B)*smoothstep(0.5,1.,1.-rz.x);
    col3      = pow(col3,vec3(1.2))*2.6;
	col3      = clamp(col3,0.,1.);
	//col       = wheel(col,col2,col3,fract((time-20.)*0.015));
	col       = tanh( wheel(col,col2,col3, 0.35 )*2.3 );
	col       = tone(col,.8)*3.5;
	
	/*
	float c0= fR((rz.x-0.1)*5.0)*10.0;
	float c1= fR((rz.x-0.2)*4.0);
	float c2= fR((rz.x-0.6)*5.0);
	float c3= fR((rz.x-0.9)*5.0);
	vec3 col = vec3( c1*1.2+c2*0.7+c0, c2+c0, c0+c3 );
	*/
	
	//vec3 col = vec3(rz.x, rz.y, 0.0);
	
	//float f = 1/(1+dot(p,p)*0.25); f=f*f; f=f*f;
	float f = fR2(dot(p_,p_)/5.); f=f*f;
	col = col*f*1.2 + vec3(0.07,0.0,0.1)*(1-f);
	
	
	fragColor = vec4(col,1.);
	
	/*
	//p = rz;
	// Heart Formula // https://mathworld.wolfram.com/HeartCurve.html
	float f = ( p.x*p.x + p.y*p.y - 1.);
	float c = ( f*f*f - p.x*p.x*p.y*p.y*p.y - 0.001 ) * -1000;
	fragColor = vec4( c, 0, 0, 1.);
	*/
	
	//fragColor = vec4( sin(gl_FragCoord.xy), Const.x, 1.);
	//fragColor = vec4( sin(p*30.00), 1., 1.);
    
	//gl_FragColor = vec4(rz,0.,1.);

}


