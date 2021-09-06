
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

const float PI = 3.14159265359;

const float alpha = PI * 2./3.;

const float verticalWidth = 8.;
const float verticalWaveHeight = 200.;
const float verticalWaveWidth = 20.;

const float aa_width = 3.;
const float borderWidth = 4.;
const float bezelWidth = 20.;

const mat2x2 rot = mat2x2(cos(alpha), -sin(alpha),sin(alpha), cos(alpha));

const float timeScale = .2;

const float shearFactor = 0.1;

#define SHOWBEZEL

////////////////////////////
// COLORS
const vec3 gold = vec3(252. / 255., 186. / 255., 3. / 255.);
const vec3 green = vec3(111. / 255., 232. / 255., 84. / 255.);
const vec3 violet = vec3(77. / 255., 4. / 255., 212. / 255.);
const vec4 backgroundColor = vec4(82./255.);
const vec4 backgroundRed = vec4(240./255., 108./255., 0., 1.);
const vec4 backgroundLines2 = vec4(79./255., 36./255., 0., 1.);

const vec3 blue = vec3(21. / 255., 170. / 255., 230. / 255.);

mat2x2 getRotMatrix(float rad)
{
    float c = cos(rad);
    float s = sin(rad);
    return mat2x2(c, -s, s, c);
}

vec4 drawLine(vec2 coord, const float waveHeight, const float waveWidth, const float width)
{
    float verticalOffset = waveHeight * sin(alpha);
    vec2 origin = vec2(verticalOffset * .5, 0.);
    
    coord -= origin;
 	float verticalPosition = sin(coord.y /waveHeight *2.* PI)*waveWidth;
    
    float diff = abs(verticalPosition + verticalOffset/2. - mod(coord.x, verticalOffset) );
    vec4 color = vec4( smoothstep(diff, diff+aa_width, width), vec3(0.));
    
    // Bezel
    color += vec4(vec3(0.),smoothstep(diff+aa_width, diff+bezelWidth, width+ borderWidth));
    
    //shadow
    color += vec4(0., smoothstep(width, diff+aa_width, width + borderWidth), 0., 0.);
    
    return vec4(color);  
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec4 lines;
    
    float beta = PI/4. + sin(iTime*.25*timeScale) * sin(iTime*.3*timeScale + 1.);
    
    mat2x2 rotation = getRotMatrix(beta);
    
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;
    
    // toggle 3d effect with mouseclick
    if(iMouse.z > 0.)
    {
        vec2 fragDistFromCenter = uv - vec2(.8);
        // square it up
        fragDistFromCenter.y /= iResolution.x/iResolution.y;
        float dist = dot(fragDistFromCenter,fragDistFromCenter);

        fragCoord *= mix(1.0, 1.5 - dist, .5*(sin( iTime * .3 * timeScale)+1.));
    }
    
    // translation for eventual rotation around something around the middle of the screen
    vec2 rotationOrigin = iResolution.xy * mix(.4, .6, sin(iTime*.5*timeScale));
    fragCoord -= rotationOrigin; 
    
    // Some zooming in/out
    fragCoord *= 1.5 + sin(iTime*1.2*timeScale)*.5;
    
    /*
    mat2x2 shear = mat2x2(1., shearFactor * uv.y, 0., 1.);
    
    fragCoord *= shear;
    */
    
    // transform into rotated space
    vec2 fragTrafo;
    
    for(int i = 0; i < 3; ++i)
    {
        fragTrafo = rotation * fragCoord;
    	lines.b += drawLine(fragTrafo, verticalWaveHeight*.2, verticalWaveWidth*.2, verticalWidth*.4).r;
    	lines.b += drawLine(fragTrafo + vec2(0., verticalWaveHeight*.5), verticalWaveHeight*.2, verticalWaveWidth*.2, verticalWidth*.4).r;
    	rotation *= rot;
    }
    
    float waveHeight = verticalWaveHeight ;//* (1. +  sin(iTime)*.25);
    float waveWidth = verticalWaveWidth * (2. +  sin(iTime));
    
    // Easy curves
    for(int i = 0; i < 3; ++i)
    {
        fragTrafo = rotation * (fragCoord);
    	lines += drawLine(fragTrafo, waveHeight, waveWidth, verticalWidth);
    	lines += drawLine(fragTrafo + vec2(0., waveHeight*.5), waveHeight, waveWidth, verticalWidth);
    	rotation *= rot;
    }
    
    // No overshooting, clean colors
    lines = clamp(lines, 0.0, 1.0);
    
    vec3 baseColor = iMouse.z > 0. ? gold : blue;
    
    //Optional: Do HSV lerp
    vec3 gradientColorUpper = mix(violet, backgroundRed.rgb, (sin(iTime*5.*timeScale)+1.)*.5);
    vec3 gradientColor = mix(baseColor, gradientColorUpper, (uv.x+uv.y)*.5);
    
    vec4 background = mix(backgroundLines2, backgroundRed, lines.b);
    fragColor = mix(background - lines.g*vec4(.85), vec4(gradientColor, 1.), lines.r);
    
    #ifdef SHOWBEZEL
    // Sweet 3d effect with some good old grad stuff
    // looks like jank on 1080p but acceptable on 4k
    float bezel = lines.w; //clamp(lines.w, -1.0, 1.0);
    float grad = clamp((dFdx(bezel)+ dFdy(bezel))*.5, -1.0, 1.0);
    
    fragColor += vec4(grad)*.5;
    #endif
}
