
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

#define PI 3.14159265359

vec3 hsv2rgb( in vec3 c ) {
    float frac = fract(c.x)*6.0;
    vec3 col = smoothstep(vec3(3,0,3),vec3(2,2,4),vec3(frac));
    col += smoothstep(vec3(4,3,4),vec3(6,4,6),vec3(frac)) * vec3(1, -1, -1);
    return mix(vec3(1), col, c.y) * c.z;
}

float sdCapsule( vec2 p, vec2 a, vec2 b, float r ) {
	vec2 pa = p - a, ba = b - a;
	float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
	return length( pa - ba*h ) - r;
}

//#define N 360
#define N 200

float radius(float theta, float n) {
    theta += PI;
    return cos(PI/n)/cos(theta-2.0*PI/n*floor((n*theta+PI)/(2.0*PI)));
}

vec2 getPos(float n, float poly) {
    float theta = n / float(N) * 2.0 * PI;
    return vec2(cos(theta), sin(theta)) * radius(theta, poly);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
	vec2 uv = fragCoord.xy / iResolution.xy * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;
    uv *= 0.55;
    uv.xy = uv.yx;
    
    vec2 Mouse = (Const - vec2(0.8,0.0))*5.0;
    
    fragColor.rgb = vec3(0);
    fragColor.a = 1.0;
    
    // number of polygons
    float poly =  floor( 3.0 + abs(Mouse.y)*10.0 );
    //float poly = 3.0 + (iResolution.y-Mouse.y) * 0.05;
    
    // f table
    //float f = floor(iTime)*poly+1.0;
    //float f = floor(iTime + Mouse.x*10.0 );
    
    float f = iTime*0.02 + Mouse.x*1.0;
    
    // change size on polygon size
    float top =  radius(0.0, poly);
    float bot = -radius(PI, poly);
    float scale = top - bot;
    uv *= scale;
    uv.x += (top + bot) * 0.5;
    
    float acc = 0.0;
    
    // optimize a bit
    float theta = atan(uv.y, uv.x);
    float dist = length(uv) - radius(theta, poly);
    if (dist > 0.0) {
        acc = 1.0;
    } else {
        for (int i = 0 ; i <= N ; i++) {
            float fi = float(i);
            vec2 a = getPos(fi  , poly);
            vec2 b = getPos(fi*f, poly);
            float dist = sdCapsule(uv, a, b, 0.0);
            acc += exp(-dist*100.0);
        }

        acc *= 70.0;
        acc /= float(N);
        acc = mix(acc, 1.0, smoothstep(-0.05, 0.0, dist));
    }
    
    fragColor.rgb = hsv2rgb( vec3( acc*4.0, 1.0-acc, 1.0-acc));
    
}
