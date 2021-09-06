

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



// Created by evilryu - evilryu/2017
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//

vec2 cmul( vec2 a, vec2 b )  { return vec2( a.x*b.x - a.y*b.y, a.x*b.y + a.y*b.x ); } // from iq

vec2 rot(vec2 p, float r)
{
    vec2 q;
    q.x = p.x * cos(r) - p.y * sin(r);
    q.y = p.x * sin(r) + p.y * cos(r);
    return q;
}



vec3 apollonian(vec2 p)
{
    p = rot(p, iTime*0.1 + Const.x*10.0) * (1.0 + Const.y);

    float scale = 1.0;
    float t0 = 1e20, t1 = 1e20;
    for(int i = 0; i < 4; ++i)
    {
        
        p= p*(1.-Const.y) + cmul(p,p)*Const.y + Const*0.;
        p = -1.0 + 2.0*fract(p*0.5+0.5 );
        float k=(1.54 + (Const.x+0.8)*0.0 )/dot(p,p);
        p*=k;
        
        t0 = min(t0, dot(p,p));
        t1 = min(t1, max(abs(p.x), abs(p.y)));
        scale*=k;

    }
    float d=0.25*abs(p.y)/scale;
    d=smoothstep(0.001, 0.002,d);
    
    float c0=pow(clamp(t0, 0.0, 1.0), 1.5); 
    float c1=pow(clamp(t1, 0.0, 1.0), 2.);
    vec3 col0=0.5+0.5*sin(1.0+3.4*c0+vec3(2.,1.3, 0.)); 
	vec3 col1=0.5+0.5*sin(3.7*c1+vec3(2.,1.5, 0.)); 

    vec3 col = sqrt(d*col1*col0)*3.;
    
    return col;
}


vec2 getsubpixel(int id,vec2 fragCoord)
{
	vec2 aa=vec2(floor((float(id)+0.1)*0.5),mod(float(id),2.0));
	return vec2((2.0*fragCoord.xy+aa-iResolution.xy)/iResolution.y);
}



void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    //vec2 q = fragCoord.xy / iResolution.xy;
    //vec2 p = q * 2.0 - 1.0;
    vec2 p = fragCoord.xy - iResolution.xy*.5;
    p /= iResolution.x;
    
    p.x *= iResolution.x/iResolution.y;
    
    vec3 col = vec3(0.0);
    for(int i=0;i<4;++i)
    {
        vec2 p = getsubpixel(i,fragCoord);
        p*=exp(sin(iTime*0.2)*0.2);
        col += apollonian(p);
    }
    col/=4.0;
    //col=col*0.6+0.4*col*col*(3.0-2.0*col);  // contrast
   	//col*=0.5+.5*pow(16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.25);  // vigneting
    fragColor = vec4(col,1.0);
    //fragColor = vec4(p,0.0,1.0);
}


/*
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
*/
