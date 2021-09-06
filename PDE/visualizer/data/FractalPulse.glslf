
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

#define MAXDIST 20.
#define GIFLENGTH 1.570795

struct Ray {
	vec3 ro;
    vec3 rd;
};

void pR(inout vec2 p, float a) {
	p = cos(a)*p + sin(a)*vec2(p.y, -p.x);
}

float length6( vec3 p )
{
	p = p*p*p; p = p*p;
	return pow( p.x + p.y + p.z, 1.0/6.0 );
}

float fractal(vec3 p)
{
   	float len = length(p);
    p=p.yxz;

    float scale = 1.25;
    const int iterations = 28;
    
    float Time = iTime * 0.01 + Const.x*5.0 + Const.y*5.0; 
    
    float a = Time;
	float l = 0.;
    
    vec2 rotationAnimAmp = vec2(0.05,0.04);
	vec2 rotationPhase = vec2(.45 + sin(Time*4. + len*0.4) * 0.025,0.15 + cos(-0.2+Time*4. + len*0.2) * 0.05);
	
    // uncomment this to find good spots with the mouse :)
    //m = iMouse.xy / iResolution.xy;
    
    //vec3 juliaOffset = vec3(-3.,-1.15,-.5);
    
    vec3 juliaOffset = vec3(-3.+ (Const.x+0.8),-1.15+Const.y,-.5 +Const.y*Const.x*10.0 );
    
    pR(p.xy,.5+sin(-0.25+Time*4.)*0.1);
    
    for (int i=0; i<iterations; i++) {
		p = abs(p);
        // scale and offset the position
		p = p*scale + juliaOffset;
        
        // Rotate the position
        pR(p.xz,rotationPhase.x*3.14 + cos(Time*4. + len)*rotationAnimAmp.y);
		pR(p.yz,rotationPhase.y*3.14 + sin(Time*4. + len)*rotationAnimAmp.x);		
        l=length6(p);
	}
	return l*pow(scale, -float(iterations))-.25;
}

vec2 map(vec3 pos) {

    float t = 0.05*iTime + Const.x;
    float ct = cos(t);
    float st = sin(t);
    pos.xy = mat2(ct,-st,st,ct)*pos.xy*(1+Const.y);
    float l = length(pos);

    float dist = fractal(pos);

    return vec2(dist, 0.);
}

vec2 march(Ray ray) 
{
    const int steps = 30;
    const float prec = 0.001;
    vec2 res = vec2(0.);
    
    for (int i = 0; i < steps; i++) 
    {        
        vec2 s = map(ray.ro + ray.rd * res.x);
        
        if (res.x > MAXDIST || s.x < prec) 
        {
        	break;    
        }
        
        res.x += s.x;
        res.y = s.y;
        
    }
   
    return res;
}

vec3 calcNormal(vec3 pos) 
{
	const vec3 eps = vec3(0.005, 0.0, 0.0);
                          
    return normalize(
        vec3(map(pos + eps).x - map(pos - eps).x,
             map(pos + eps.yxz).x - map(pos - eps.yxz).x,
             map(pos + eps.yzx).x - map(pos - eps.yzx).x ) 
    );
}

float calcAO( in vec3 pos, in vec3 nor )
{
float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float hr = 0.2*float(i)/4.0;
        vec3 aopos =  nor * hr + pos;
        float dd = map( aopos ).x;
        occ += -(dd-hr)*sca;
        sca *= .95;
    }
    return clamp( 1.0 - 2.0*occ, 0.0, 1.0 );    
}
vec4 render(Ray ray) 
{
    vec3 col = vec3(0.);
	vec2 res = march(ray);
   
    if (res.x > MAXDIST) 
    {
        return vec4(col, MAXDIST);
    }
    
    vec3 p = ray.ro+res.x*ray.rd;
    vec3 normal = calcNormal(p);
    vec3 pos = p;
    ray.ro = pos;
    // color with ambient occlusion
    float ao = pow(calcAO(p, normal), 3.2);
   	col = vec3(ao*3.,ao + ao*ao,0.2+ao-ao*ao)*0.5;
   
    col = mix(col, vec3(0.), clamp(res.x/MAXDIST, 0., 1.));
   	return vec4(col, res.x);
}
mat3 camera(in vec3 ro, in vec3 rd, float rot) 
{
	vec3 forward = normalize(rd - ro);
    vec3 worldUp = vec3(sin(rot), cos(rot), 0.0);
    vec3 x = normalize(cross(forward, worldUp));
    vec3 y = normalize(cross(x, forward));
    return mat3(x, y, forward);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;
    
    //float ct = cos(iTime);
    //float ct = cos(iTime);
    vec3 camPos = vec3(9., 6.5, 12.);
    vec3 camDir = camPos + vec3(-.85, -.5, -1. );
    mat3 cam = camera(camPos, camDir, 0.);
    
    vec3 rayDir = cam * normalize( vec3(uv, 1. + sin(iTime*4.*0.)*0.05) );
    
    Ray ray;
    ray.ro = camPos;
    ray.rd = rayDir;
    
    vec4 col = render(ray);
    col.xyz = pow(col.xyz, vec3(0.6));
	fragColor = vec4(col.xyz,clamp(1.-col.w/MAXDIST, 0., 1.));
}

