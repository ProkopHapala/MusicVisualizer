

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


// From     Fractal lines of symmetry  https://www.shadertoy.com/view/Md2GRc

// I'm not sure if there is a name for this yet, but there's been some similar things floating around on the GLSL Sandbox Gallery. 
// You can get lots of interesting results by changing bits of the algorithm.


vec3 hsv(in float h, in float s, in float v)
{
	return mix(vec3(1.0), clamp((abs(fract(h + vec3(3, 2, 1) / 3.0) * 6.0 - 3.0) - 1.0), 0.0 , 1.0), s) * v;
}

vec3 formula(in vec2 p, in vec2 c)
{
	const float n = 2.0;
	//const int Niters = 12;
	//const int Niters = 8;
	const int Niters = 4;
	float dN = 12.0/Niters;

	float time = iTime*0.1;
	vec3 col = vec3(0);
	float t = 1.0;
	float dpp = dot(p, p);
	float lp = sqrt(dpp);
	float r = smoothstep(0.0, 0.2, lp);
	
	for (int i = 0; i < Niters; i++) {
		// The transformation
		p = abs(mod(p/dpp + c, n) - n/2.0);
		
		dpp = dot(p, p);
		lp = sqrt(dpp);

		//Shade the lines of symmetry black
#if 0
		// Get constant width lines with fwidth()
		float nd = fwidth(dpp);
		float md = fwidth(lp);
		t *= smoothstep(0.0, 0.5, abs((n/2.0-p.x)/nd*n))
		   * smoothstep(0.0, 0.5, abs((n/2.0-p.y)/nd*n))
		   * smoothstep(0.0, 0.5, abs(p.x/md))
		   * smoothstep(0.0, 0.5, abs(p.y/md));
#else
		// Variable width lines
		t *= smoothstep(0.0, 0.01, abs(n/2.0-p.x)*lp)
		   * smoothstep(0.0, 0.01, abs(n/2.0-p.y)*lp)
		   * smoothstep(0.0, 0.01, abs(p.x)*2.0) 
		   * smoothstep(0.0, 0.01, abs(p.y)*2.0);
#endif

		// Fade out the high density areas, they just look like noise
		r *= smoothstep(0.0, 0.2, lp);
		
		// Add to colour using hsv
		col += hsv(1.0 - max(p.x, p.y) + t*2.0 + time, 2.0-lp+t, r) * dN;
		
	}
	
	return (-cos(col/4.0)*0.5 + 0.5)*(t);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
	vec2 p = -1.0 + 2.0 * fragCoord.xy / iResolution.xy;
	p.x *= iResolution.x / iResolution.y;
	p *= 2.0;
	const vec2 e = vec2(0.06545465634, -0.05346356485);
	//vec2 c = iTime*e;
	vec2 c = Const*5.;
	//c = 8.0*iMouse.xy/iResolution.xy;
	float d = 1.0;
	vec3 col = vec3(0.0);
	const float blursamples = 4.0;
	float sbs = sqrt(blursamples);
	float mbluramount = 1.0/iResolution.x/length(e)/blursamples*2.0;
	float aabluramount = 1.0/iResolution.x/sbs*4.0;
	for (float b = 0.0; b < blursamples; b++) {
		col += formula(
			p + vec2(mod(b, sbs)*aabluramount, b/sbs*aabluramount), 
			c + e*mbluramount*b);
	}
	col /= blursamples;
	fragColor = vec4(col, 1.0);
}
