

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


// From  Persian Carpet https://www.shadertoy.com/view/MdlXzM

vec2 fold = vec2(0.5, -0.5);
vec2 translate = vec2(1.5);
float scale = 1.3;

vec3 hsv(float h,float s,float v) {
	return mix(vec3(1.),clamp((abs(fract(h+vec3(3.,2.,1.)/3.)*6.-3.)-1.),0.,1.),s)*v;
}

vec2 rotate(vec2 p, float a){
	return vec2(p.x*cos(a)-p.y*sin(a), p.x*sin(a)+p.y*cos(a));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
	vec2 p = -1.0 + 2.0*fragCoord.xy/iResolution.xy;
	p.x *= iResolution.x/iResolution.y;
	p *= 0.003;
	float x = p.y;
	p = abs(mod(p, 8.0) - 4.0);
	for(int i = 0; i < 36; i++){
		p = abs(p - fold) + fold;
		p = p*scale - translate;
		//p = rotate(p, 3.14159/(8.0+sin(iTime*0.001+float(i)*0.1)*0.5+0.5));
		p = rotate(p, 3.14159/(8.0+sin(Const.x*0.1+float(i)*0.1)*0.5+0.5));
	}
	//float i = x*10.0 + atan(p.y, p.x) + iTime*0.5;
	float i = x*10.0 + atan(p.y, p.x) + Const.y*100.0;
	float h = floor(i*6.0)/5.0 + 0.07;
	h += smoothstep(0.0, 0.4, mod(i*6.0/5.0, 1.0/5.0)*5.0)/5.0 - 0.5;
	fragColor=vec4(hsv(h, 1.0, smoothstep(-1.0, 3.0, length(p))), 1.0);
}
