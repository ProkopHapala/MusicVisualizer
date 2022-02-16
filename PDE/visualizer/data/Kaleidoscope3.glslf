

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

//  Simple Kaleidoscope 3     From https://www.shadertoy.com/view/4tlGD2

const float tau = 6.2831853;

vec3 texture_func(vec2 uv, vec3 w){
    vec2 d; 
    d=uv-vec2(0.0,0.0); float r = dot(d,d)-1.0;
    d=uv-vec2(1.0,ColorShift.x*0.01); float g = dot(d,d)-0.5;
    d=uv-vec2(ColorShift.x*0.01,1.0); float b = dot(d,d)-1.5 ;
    vec3 v = vec3(r,g,b);
    return 1./(1.+v*v/(w*w));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    //float T = iTime*.3+10.0;
    float T  = 100.0 + Const.y*80.0 + iTime*0.1;
    float T2 = 100.0 + Const.x*80.0 + iTime*0.1;
    
    vec2 uv = (fragCoord.xy-.5*iResolution.xy) * 8.0 / iResolution.y;

    
    float r = 1.0;
    
    float a = T*.1;
    //float a = Const.x*5.0*.1;
    
    float c = cos(a)*r;
    float s = sin(a)*r;
    
    float q = iTime*.2 / tau;
    //float q = Const.x*5.0*.2 / tau;
    
    for ( int i=0; i<16; i++ ){
        float t = atan(uv.x,uv.y);
        t *= q;
        t = abs(fract(t*.5+.5)*2.0-1.0);
        t /= q;
        //q = q+.001;
        uv = length(uv)*vec2(sin(t),cos(t));
        uv -= .7;
        uv = uv*c + s*uv.yx*vec2(1,-1);
    }
        
    //fragColor = .5+.5*sin(T+vec4(13,17,23,1)*texture( iChannel0, uv*vec2(1,-1)+.5, -0.0 ));
    //vec3 col = cos( vec3(uv.x*1.5,(uv.x+uv.y)*0.5,uv.y*1.5) ) *  sin( vec3(uv.y*1.5,(uv.x-uv.y)*0.5,uv.x*1.5) );

    //vec3 col = vec3();
    //col*=col;
    //col *= sin( iTime * vec3(7,9,13)*0.1 );
    //col *= sin( T2 * vec3(7,9,13)*0.1 );
    //col*=col; col*=col; col*=col; col*=col;
    

    //float c = texture_func(uv);
    //vec3 col = texture_func(uv,vec3(0.2));
    vec3 col = texture_func(uv,vec3((1.+ColorShift.y)*0.1));
    fragColor = vec4( col, 1.0 );
    //fragColor = clamp( 0.5 + 1.5*vec4( col, 1.0 ), 0., 1.);
}

