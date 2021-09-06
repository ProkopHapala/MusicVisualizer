

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

const int iters = 64;

vec3 fractal(vec2 c, vec2 c2) {
    vec2 z = c;
    float ci = 0.0;
    float mean = 0.0;
    for(int i = 0;i < iters; i++) {
        vec2  a = vec2(z.x,abs(z.y));
        float b = atan(a.y, a.x);
        if(b > 0.0) b -= 6.283185307179586;
        z = vec2(log(length(a)),b) + c2;
        if (i>1) mean+=length(z);
    }
    mean/=float(62);
    ci =  1.0 - log2(.5*log2(mean/1.));
    return vec3( .5+.5*cos(6.*ci+0.0),.5+.5*cos(6.*ci + 0.4),.5+.5*cos(6.*ci +0.7) );
}


void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    vec2 uv = fragCoord.xy - iResolution.xy*.5;
    uv /= iResolution.x;
    vec2 tuv = uv;
    float rot=sin(iTime*0.02)*2.7;
    uv.x = tuv.x*cos(rot)-tuv.y*sin(rot);
    uv.y = tuv.x*sin(rot)+tuv.y*cos(rot);
    float t = iTime + 10.*Const.x;
    float juliax = sin(t       ) * 0.01 + 0.2;
    float juliay = cos(t * 0.23) * 0.02 + 5.7;
    //fragColor = vec4( fractal(uv, vec2(juliax, juliay)) ,1.0);
    fragColor = vec4( fractal(uv, (Const+vec2(+0.7,-0.0))*vec2(0.2,0.2) + vec2(juliax,juliay) ) ,1.0);
}


