
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

////////////////////////////////////////////////////////////////////////////////
//
// Inversive Kaleidoscope II
// mla, 2020
//
// <mouse>: move free inversion circle
// a: just animation
// c: show circles
// l: show lines
// x: lock x coordinate for free circle
//
////////////////////////////////////////////////////////////////////////////////

vec3 hsv2rgb(in vec3 c) {
  vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
  rgb = rgb*rgb*(3.0-2.0*rgb); // cubic smoothing	
  return c.z * mix( vec3(1.0), rgb, c.y);
}

#define key(code) (texelFetch(iChannel3, ivec2((code),2),0).x != 0.0)

const int CHAR_A = 65;
const int CHAR_C = 67;
const int CHAR_L = 76;
const int CHAR_M = 77;
const int CHAR_N = 78;
const int CHAR_R = 82;
const int CHAR_S = 83;
const int CHAR_T = 84;
const int CHAR_X = 88;

float kfact = 1.0;
float lwidth = 0.01;
vec3 draw(float d, vec3 col, vec3 ccol, float pwidth) {
  col = mix(ccol,col,mix(1.0,smoothstep(-pwidth,pwidth,d-lwidth),kfact));
  return col;
}

vec3 drawcircle(vec2 z, vec3 col, vec3 ccol, vec3 circle) {
  float d = abs(length(z-circle.xy) - sqrt(abs(circle.z)));
  return draw(d,col,ccol,fwidth(z.x));
}

vec3 drawline(vec2 z, vec3 col, vec3 ccol, vec2 line) {
  float d = abs(dot(z,line));
  return draw(d,col,ccol,fwidth(z.x));
}

vec2 invert(vec2 z, vec3 c) {
  z -= c.xy;
  float k = abs(c.z)/dot(z,z);
  z *= k;
  z += c.xy;
  return z;
}

bool inside(vec2 z, vec3 c) {
  z -= c.xy;
  if (c.z < 0.0) return dot(z,z) > abs(c.z);
  return dot(z,z) < abs(c.z);
}


const int NCIRCLES = 4;
const float AA = 2.0;
const float R = 4.0;

vec3 circles[NCIRCLES] =
  vec3[](vec3( 0,0,1),
         vec3(-2,1,R),
         vec3( 2,1,R),
         vec3( 0,0,-5));
         
vec3 getcolor(vec2 z0, vec2 w) {
  vec2 z = z0;
  int i, N = 40;
  bool found = true;
  for (i = 0; i < N && found; i++) {
    for (int j = 0; j < NCIRCLES; j++) {
      found = false;
      vec3 c = circles[j];
      if (inside(z,c)) {
        z = invert(z,c);
        found = true;
        break;
      }
    }
  }
  vec3 col = vec3(0);
  if (i < N) col = hsv2rgb(vec3(float(i)/10.0,1,1));
  if (!key(CHAR_L)) {
    vec3 ccol = vec3(0);
    for(int i = 0; i < NCIRCLES; i++) {
      col = drawcircle(z,col,ccol,circles[i]);
    }
  }
  if (!key(CHAR_C)) {
    vec3 ccol = vec3(1);
    for(int i = 0; i < NCIRCLES; i++) {
      col = drawcircle(z0,col,ccol,circles[i]);
    }
  }
  return col;
}

void mainImage(out vec4 fragColor, vec2 fragCoord) {
  vec3 color = vec3(0);
  float scale = 4.0;
  
  float Time1 = 0.618*iTime*0.1 + Const.x*3.0;
  float Time2 = 0.5  *iTime*0.1 + Const.y*3.0;
  
  vec2 w = vec2(0,-0.25) + vec2(0,cos(Time1));
  if (iMouse.x > 0.0 && !key(CHAR_A)) {
    w = (2.0*iMouse.xy-iResolution.xy)/iResolution.y;
    w *= scale;
    if (key(CHAR_X)) w.x = 0.0;
  }
  circles[0].xy = w;
  
  circles[1].x += sin(Time2);
  circles[2].x -= sin(Time2);
  
  
  for (float i = 0.0; i < AA; i++) {
    for (float j = 0.0; j < AA; j++) {
      vec2 z = (2.0*(fragCoord+vec2(i,j)/AA)-iResolution.xy)/iResolution.y;
      z *= scale;
      z.y += 1.0; 
      w.y += 1.0;
      color += getcolor(z,w);
    }
  }
  color /= AA*AA;
  color = pow(color,vec3(0.4545));
  fragColor = vec4(color,1.0);
}
