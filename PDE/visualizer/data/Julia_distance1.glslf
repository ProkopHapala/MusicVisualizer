

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
//  From  Julia - Distance 1   https://www.shadertoy.com/view/Mss3R8
//
// The MIT License
// Copyright © 2013 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// Distance to a traditional Julia set for f(z)=z²+c 

// More info here:
// http://www.iquilezles.org/www/articles/distancefractals/distancefractals.htm	

// Related:
//
// Julia - Distance 1 : https://www.shadertoy.com/view/Mss3R8
// Julia - Distance 2 : https://www.shadertoy.com/view/3llyzl
// Julia - Distance 3 : https://www.shadertoy.com/view/4dXGDX


#define AA 2

float Julia_dist( vec2 z, vec2 C ){
    // only derivative length version
    float ld2 = 1.0;
    float lz2 = dot(z,z);
    for( int i=0; i<64; i++ ){
        ld2 *= 4.0*lz2;
        z = vec2( z.x*z.x - z.y*z.y, 2.0*z.x*z.y ) + C;
        lz2 = dot(z,z);
        if( lz2>200.0 ) break;
    }
    float d = sqrt(lz2/ld2)*log(lz2);
    return d;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    float scol = 0.0;
    for( int j=0; j<AA; j++ )for( int i=0; i<AA; i++ ){
        vec2 of = -0.5 + vec2( float(i), float(j) )/float(AA);
        
        float ltime = 0.5-0.5*cos(iTime*0.06);
        float zoom = pow( 0.9, 50.0*ltime );
        vec2  cen = vec2( 0.2655,0.301 ) + zoom*0.8*cos(4.0+2.0*ltime);
        //vec2 c = vec2( -0.745, 0.186 ) - 0.045*zoom*(1.0-ltime*0.5);
        
        vec2 p = fragCoord+of;
        p = (2.0*p-iResolution.xy)/iResolution.y;
        //p = cen + (p-cen)*zoom;
        //vec2 z = cen + (p-cen)*zoom;
        
        //float d = Julia_dist( p, c );
        float d = Julia_dist( p, Const );
        //float d = Julia_dist( p, Const + vec2(p.x*0.2*0,p.y*0.1) );
        
        //scol += sqrt( clamp( (150.0/zoom)*d, 0.0, 1.0 ) );
        //scol +=  clamp( pow( (1.0/zoom)*d, 0.25  ) , 0.0, 1.0 );
        scol +=  clamp( pow( 1.0*d, 0.25  ) , 0.0, 1.0 );
        //scol += pow( clamp( (150.0/zoom)*d, 0.0, 1.0 ), 1.0 ) * 1.0;
    }
    scol /= float(AA*AA);


    vec3 vcol = pow( vec3(scol), vec3(0.9,1.1,1.4) );

    vec2 uv = fragCoord/iResolution.xy;
    vcol *= 0.0 + 1.0*pow(16.0*uv.x*uv.y*(1.0-uv.x)*(1.0-uv.y),  0.25 );


    fragColor = vec4( vcol, 1.0 );
}
