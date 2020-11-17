

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


//  Dodecahedralis VII      https://www.shadertoy.com/view/wtXcDB


// Copyright 2020 Google LLC
// SPDX-License-Identifier: Apache-2.0
// NOT an official Google project; see Google Open Source guidelines for more info on copyright transfer
// written by William Cadegan-Schlieper 

float tau = 6.283185307179586;

bool flip(inout vec3 z, in vec2 c, in float r, inout int t, in int k) {
    z.xy -= c;
    bool res = (dot(z,z) < r*r) ^^ (r < 0.0);
    if (res) {
        z *= r * r / dot(z,z);
        t = k - t;
    }
    z.xy += c;
    return res;
}

bool inside(in vec3 z, in vec2 c, in float r, inout float t) {
    vec3 p = z - vec3(c,0.0);
    float res = (dot(p,p)-r*r) / (2.0 * abs(r) * p.z);
    t = min(t, abs(res));
    return res < 0.0;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 z0 = 2.0 * (fragCoord - iResolution.xy * 0.5)/iResolution.y;
    float ds = 1.0 / iResolution.y;
    vec3 z = vec3(z0,ds);
    
    vec2[12] c; float[12] r;
    float r1 = pow(1.5 + 0.5 * sqrt(5.0) - sqrt(1.5 * sqrt(5.0) + 2.5), 0.5);
    r[0] = r1; c[0] = vec2(0.0);
    float r2 = r1 * sqrt(sqrt(5.0));
    float x2 = sqrt(r1*r1+r2*r2);
    float r3 = r2 / ( x2 * x2 - r2 * r2);
    float x3 = -x2 / ( x2 * x2 - r2 * r2);
    for (int i=0; i<5; i++) {
        float theta = tau * 0.2 * float(i);
        vec2 eit = vec2(cos(theta), sin(theta));
        r[i+1] = r2;
        c[i+1] = x2 * eit;
        r[i+6] = r3;
        c[i+6] = x3 * eit;
    }
    float r4 = -1.0 / r1;
    r[11] = r4; c[11] = vec2(0.0);
    
    float period = -8.0 * log(r1);
    float d = mod(iTime * 0.2 + Const.y*5.0, period) - period * 0.5;
    z *= exp(-d);
    
    bool fl = false;
    float yellow = 0.0;
    int t = 1;
    int s1 = 0;
    int s2 = 0;
    int s3 = 0;
    //int s1 = 0 + int( sin(Const.x*1000.0)*1.5 );
    //int s2 = 0 + int( sin(Const.x*300.0)*1.5 );
    //int s3 = 0 + int( sin(Const.x*500.0)*1.5 );
    bool fl1 = false; bool fl2 = false; bool fl3 = false;
    
    float f0 =  3.0;
    float fi =  1.0;
    int signs[12];
    for (int i=0; i<6; i++) {
        signs[i  ] = int( fract(Const.x*(f0+i*fi))*2 +0.95)*2 - 1;
        signs[i+6] = int( fract(Const.y*(f0+i*fi))*2 +0.95)*2 - 1;
    }
    
    
    for (int i=0; i<7; i++) {
        
        fl1 = fl1 ^^ flip(z, c[0], r[0], s1, signs[0] );
        fl1 = fl1 ^^ flip(z, c[1], r[1], s1, signs[1] );
        fl3 = fl3 ^^ flip(z, c[2], r[2], s3, signs[2] );
        fl2 = fl2 ^^ flip(z, c[3], r[3], s2, signs[3] );
        fl2 = fl2 ^^ flip(z, c[4], r[4], s2, signs[4] );
        fl3 = fl3 ^^ flip(z, c[5], r[5],   s3, -signs[5] );
        fl1 = fl1 ^^ flip(z, c[6], r[6],   s1, -signs[6] );
        fl3 = fl3 ^^ flip(z, c[7], r[7],   s3, -signs[7] );
        fl2 = fl2 ^^ flip(z, c[8], r[8],   s2, -signs[8] );
        fl2 = fl2 ^^ flip(z, c[9], r[9],   s2, -signs[9] );
        fl3 = fl3 ^^ flip(z, c[10], r[10], s3,  signs[10]);
        fl1 = fl1 ^^ flip(z, c[11], r[11], s1, -signs[11]);
        
        //fl1 = fl1 ^^ flip(z, c[0], r[0], s1, 1);
        //fl1 = fl1 ^^ flip(z, c[1], r[1], s1, 1);
        //fl3 = fl3 ^^ flip(z, c[2], r[2], s3, 1);
        //fl2 = fl2 ^^ flip(z, c[3], r[3], s2, 1);
        //fl2 = fl2 ^^ flip(z, c[4], r[4], s2, 1);
        //fl3 = fl3 ^^ flip(z, c[5], r[5], s3, -1);
        //fl1 = fl1 ^^ flip(z, c[6], r[6], s1, -1);
        //fl3 = fl3 ^^ flip(z, c[7], r[7], s3, -1);
        //fl2 = fl2 ^^ flip(z, c[8], r[8], s2, -1);
        //fl2 = fl2 ^^ flip(z, c[9], r[9], s2, -1);
        //fl3 = fl3 ^^ flip(z, c[10], r[10], s3, 1);
        //fl1 = fl1 ^^ flip(z, c[11], r[11], s1, -1);
        
        //fl1 = fl1 ^^ flip(z, c[0], r[0], s1, signs[0] );
        //fl1 = fl1 ^^ flip(z, c[1], r[1], s1, signs[1] );
        //fl3 = fl3 ^^ flip(z, c[2], r[2], s3, signs[2] );
        //fl2 = fl2 ^^ flip(z, c[3], r[3], s2, signs[3] );
        //fl2 = fl2 ^^ flip(z, c[4], r[4], s2, signs[4] );
        //fl3 = fl3 ^^ flip(z, c[5], r[5], s3, signs[5] );
        //fl1 = fl1 ^^ flip(z, c[6], r[6], s1,  signs[6] );
        //fl3 = fl3 ^^ flip(z, c[7], r[7], s3,  signs[7] );
        //fl2 = fl2 ^^ flip(z, c[8], r[8], s2,  signs[8] );
        //fl2 = fl2 ^^ flip(z, c[9], r[9], s2,  signs[9] );
        //fl3 = fl3 ^^ flip(z, c[10], r[10], s3, signs[10]);
        //fl1 = fl1 ^^ flip(z, c[11], r[11], s1, signs[11]);
    }
    if (fl1) {s1=-s1;}
    if (fl2) {s2=-s2;}
    if (fl3) {s3=-s3;}
    vec3 s = vec3(float(s1+s2+s3) + 4.0 * d / period);
    
    s = s / (1.9 + abs(s));
    vec3 col = 0.5 + s * 0.45;
    col.rg*=0.8;
    fragColor = vec4(col,1.0);
    fragColor = pow(fragColor, vec4(1.0/2.2));
}

