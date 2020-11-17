

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

//   Hyperbolic Square    From https://www.shadertoy.com/view/Mlsfzs

////////////////////////////////////////////////////////////////////////////////
//
// (c) Matthew Arcus 2017
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//
// Hyperbolic kaleidoscope mapped conformally in various ways,
// notably to a square with the Jacobi cn function.
//
// Keys 1-8 select various mappings, otherwise cycle through automatically.
//
// Mouse controls position of image centre (click on image 
// after resize to recentre).
//
// 'p','q': kaleidoscope parameters
// 'd': combine fundamental regions in pairs
// 'c': chiral mapping
// 'f': display principal region only
// 'm': display outside disc/halfplane
// 'g': centre on 4-vertex
// 'b': show fundamental region edges
//
////////////////////////////////////////////////////////////////////////////////

int P = 7;   // Faces at central vertex
int Q = 3;   // Faces at second vertex
//int R = 4; // Faces at third vertex, always 4

const int NN = 200; // Number of folding iterations

const float PI = 3.141592654;
const float TWOPI = 2.0*PI;

/// Complex arithmetic ///

// Normal vec2 operations work for
// addition, subtraction and
// multiplication by a scalar.
      
// Multiplication
vec2 cmul(vec2 z0, vec2 z1) {
  float x0 = z0.x; float y0 = z0.y; 
  float x1 = z1.x; float y1 = z1.y;
  return vec2(x0*x1-y0*y1,x0*y1+x1*y0);
}

// Reciprocal
vec2 cinv(vec2 z) {
  float x = z.x; float y = z.y;
  float n = 1.0/(x*x + y*y);
  return vec2(n*x,-n*y);
}

// Division
vec2 cdiv(vec2 z0, vec2 z1) {
  return cmul(z0,cinv(z1));
}

// Exponentiation - e^ix
vec2 expi(float x) {
  return vec2(cos(x),sin(x));
}

// e^iz
vec2 cexp(vec2 z) {
  return exp(z.x) * expi(z.y);
}

vec2 csqrt(vec2 z) {
  float r = length(z);
  return vec2(sqrt(0.5*(r+z.x)),sign(z.y)*sqrt(0.5*(r-z.x)));
}

vec2 clog(vec2 z) {
  return vec2(log(length(z)),atan(z.y,z.x));
}

vec2 csin(vec2 z) {
  float x = z.x, y = z.y;
  return cdiv(cexp(vec2(-y,x))-cexp(vec2(y,-x)), vec2(0,2.0));
}

// Taken from NR, simplified by using a fixed number of
// iterations and removing negative modulus case.
// Modulus is passed in as k^2 (_not_ 1-k^2 as in NR).
void sncndn(float u, float k2,
            out float sn, out float cn, out float dn) {
  float emc = 1.0-k2;
  float a,b,c;
  const int N = 4;
  float em[N],en[N];
  a = 1.0;
  dn = 1.0;
  for (int i = 0; i < N; i++) {
    em[i] = a;
    emc = sqrt(emc);
    en[i] = emc;
    c = 0.5*(a+emc);
    emc = a*emc;
    a = c;
  }
  // Nothing up to here depends on u, so
  // could be precalculated.
  u = c*u; sn = sin(u); cn = cos(u);
  if (sn != 0.0) {
    a = cn/sn; c = a*c;
    for(int i = N-1; i >= 0; i--) {
      b = em[i];
      a = c*a;
      c = dn*c;
      dn = (en[i]+a)/(b+a);
      a = c/b;
    }
    a = 1.0/sqrt(c*c + 1.0);
    if (sn < 0.0) sn = -a;
    else sn = a;
    cn = c*sn;
  }
}

// Complex sn. uv are coordinates in a rectangle, map to
// the upper half plane with a Jacobi elliptic function.
// Note: uses k^2 as parameter.
vec2 sn(vec2 z, float k2) {
  float snu,cnu,dnu,snv,cnv,dnv;
  sncndn(z.x,k2,snu,cnu,dnu);
  sncndn(z.y,1.0-k2,snv,cnv,dnv);
  float a = 1.0/(1.0-dnu*dnu*snv*snv);
  return a*vec2(snu*dnv, cnu*dnu*snv*cnv);
}

vec2 cn(vec2 z, float k2) {
  float snu,cnu,dnu,snv,cnv,dnv;
  sncndn(z.x,k2,snu,cnu,dnu);
  sncndn(z.y,1.0-k2,snv,cnv,dnv);
  float a = 1.0/(1.0-dnu*dnu*snv*snv);
  return a*vec2(cnu*cnv,-snu*dnu*snv*dnv);
}

vec2 dn(vec2 z, float k2) {
  float snu,cnu,dnu,snv,cnv,dnv;
  sncndn(z.x,k2,snu,cnu,dnu);
  sncndn(z.y,1.0-k2,snv,cnv,dnv);
  float a = 1.0/(1.0-dnu*dnu*snv*snv);
  return a*vec2(dnu*cnv*dnv,-k2*snu*cnu*snv);
}

#if __VERSION__ < 300
bool isnan(float x) {
  return x != x;
}
bool isnan(vec2 z) {
  return isnan(z.x) || isnan(z.y);
}

#if 0
float atanh(float r) {
  return 0.5*log((1.0+r)/(1.0-r));
}

float tanh(float x) {
  return (exp(2.0*x)-1.0)/(exp(2.0*x)+1.0);
}
#endif
#endif

// Invert z in circle radius r, centre w
vec2 invert(vec2 z, vec2 w, float r2) {
  vec2 z1 = z - w;
  float k = r2/dot(z1,z1);
  return z1*k+w;
}

// Overloading for p on x-axis
vec2 invert(vec2 z, float x, float r2) {
  return invert(z,vec2(x,0),r2);
}

// Invert z in circle p, r2, if it is inside
int tryinvert(inout vec2 z, vec2 p, float r2) {
  vec2 z1 = z - p;
  float d2 = dot(z1,z1);
  if (d2 >= r2) return 0;
  z = z1*r2/d2 + p;
  return 1;
}

int tryreflect(inout vec2 z, vec2 norm) {
  float k = dot(z,norm);
  if (k <= 0.0) {
    return 0;
  } else {
    z -= 2.0*k*norm;
    return 1;
  }
}

vec2 translate(vec2 z, float radius, float s) {
  // Do hyperbolic translation, ie. an inversion
  // Translate s (on x axis) to origin of hyperbolic disk with
  // given radius.
  if (abs(s) < 1e-4) {
    z.x = -z.x;
  } else {
    // p*(p-s) = r*r = p*p - radius*radius
    // p*p - p*s = p*p - rad*rad
    // p = s/(rad*rad)
    float p = radius*radius/s;
    float r2 = p*(p-s);
    z = invert(z,p,r2);
  }
  return z;
}

// Compute the radius of the disk.
// p is the centre of the inversion
// circle for the hyperbolic triangle, r is its radius,
// so use Pythagoras to find the right angle for a tangent
// with the disk (this needs a picture).
float diskradius(vec2 p, float r) {
  return sqrt((length(p)+r)*(length(p)-r));
}

// For ES 2.0
int imod(int n, int m) {
    return n-n/m*m;
}

bool keypress(int code) {
#if __VERSION__ < 300
    return false;
#else
    return texelFetch(iChannel1, ivec2(code,2),0).x != 0.0;
#endif
}

int numbertoggle() {
#if __VERSION__ < 300
    return 0;
#else
    int i = int(texelFetch(iChannel2,ivec2(0,0),0).x);
    if (i < 0) return 0;
    return i;
#endif
}
    
const int CHAR_0 = 48;
const int CHAR_A = 65;
const int CHAR_B = 66;
const int CHAR_C = 67;
const int CHAR_D = 68;
const int CHAR_F = 70;
const int CHAR_G = 71;
const int CHAR_M = 77;
    
void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
  float rrepeat = 0.005* iTime; // Makes texture mapping radius dependent
  //int display = numbertoggle();
  int display = 0;
  int NDISPLAYS = 8;
  //if (display == 0) 
  //display = 1+imod(int(  iTime/10.0 + Const.x*50.0),NDISPLAYS);
  display = 1+int(  NDISPLAYS * fract(iTime/100.0 + Const.x*0.5) );
  
  float T  = 100.0 + Const.y*80.0 + iTime*0.1;
  float T2 = 100.0 + Const.x*80.0 + iTime*0.1;

  // Join 2 fundamental regions together
  bool doubleup = keypress(CHAR_D);
  bool chiral = keypress(CHAR_C);
  // Just show one fundamental region
  bool fundamental = keypress(CHAR_F);
  bool mask = !keypress(CHAR_M);
  
#if 0
  if (keypress(CHAR_0+1)) display = 1;
  else if (keypress(CHAR_0+2)) display = 2;
  else if (keypress(CHAR_0+3)) display = 3;
  else if (keypress(CHAR_0+4)) display = 4;
  else if (keypress(CHAR_0+5)) display = 5;
#endif
      
  fragColor = vec4(0,0,0,1); // Background
    
  float theta = PI/float(P); // Central angle of triangle
  float phi = PI/float(Q); // Other angle of triangle
  // Need picture of hyperbolic region
  // Third side of hyperbolic triangle is an inversion circle.
  // ODBC are on x-axis, A is height 1 above B, so OBA is a right angle and BA = 1
  // BOA = COA = theta, OAD = phi, CAB = theta+phi
  // Maybe should scale to make radius 1 always.
  vec2 p = vec2(cos(theta)/sin(theta) + sin(theta+phi)/cos(theta+phi),0.0);
  float r = 1.0/cos(theta+phi);
  float r2 = r*r;
  float offset = p.x - r;

  // norm and norm2 are normals to the radial axes
  // norm2 is second radial axis, either x-axis or norm reflected in x-axis
  vec2 norm = vec2(-sin(theta),cos(theta));
  vec2 norm2 = !doubleup ? vec2(0.0,-1.0) : vec2(-sin(theta),-cos(theta));
  vec2 ci = vec2(0.0,1.0); // Complex i

  float radius = diskradius(p,r);

  // Adding a sub-pixel offset seems to reduce edge artefacts.
  vec2 z = (2.0*fragCoord + 0.35 - iResolution.xy)/iResolution.y;

  if (display == 1) {
    z = cdiv(z,vec2(1,1));
    z -= vec2(1,0);
    z *= 1.854; 
    z = cn(z, 0.5);
    z = cmul(z,vec2(0.70711,0.70711));
  } else if (display ==3) {
      z.y += 1.0;
  } else if (display == 4) {
    // rectangle -> half plane
    z *= 4.0;
    float k2 = 0.5*sin(0.2*iTime)+0.5;
    z.y += 1.0;
    z = sn(z,k2);
  } else if (display == 5) {
    z.y += 1.0;
    z *= 0.5*iResolution.y/iResolution.x;
    z = csin(PI*z); // edges and bottom are boundaries
  } else if (display == 6) {
    z.y += 1.0;
    z *= 0.5;
    z.x *= -1.0;
    z = cexp(PI*z); // top and bottom are boundaries
    z.x *= -1.0;
  } else if (display == 7) {
    z *= 0.5*iResolution.y/iResolution.x;
    z.x += 0.5;
    //z.x *= -1.0;
    z = cexp(PI*z.yx); // swap x,y; sides are boundaries
    z.x *= -1.0;
  } else if (display == 8) {
    z = csqrt(z);
    z.x -= 0.5;
    z = cmul(z,vec2(0,1));
  }
  if (display > 2) {
    // Map upper half-plane to the disk.
    z = cdiv(ci-z,ci+z);
  }

  z *= radius; // (Inverse of) scale to unit disk
  z = z.yx; // Flip coords to make image symmetric about y-axis
    
  if(iMouse.x > 0.0) {
    vec2 mouse = (2.0*iMouse.xy-iResolution.xy)/iResolution.y;
      mouse = mouse.yx;
    if (display == 3 || display == 4 || 
        display == 5 || display == 7) {
      mouse.x *= -1.0;
      mouse = mouse.yx;
    }
    float r = atan(mouse.y,mouse.x);
    float s = radius*length(mouse);

    z = mat2(cos(r),-sin(r),sin(r),cos(r))*z;
    z = translate(z,radius,s);
    z.x *= -1.0;
  }
  
  float psi = iTime*0.1      + Const.x*5.0;
  float rho = iTime*0.123    + Const.y*5.0;
  z = mat2(cos(rho),-sin(rho),sin(rho),cos(rho))*z;
    if (keypress(CHAR_G)) {
        z = translate(z,radius,offset); // Put 4-vertex in centre
    }
  if (dot(z,z) > radius*radius) {
    // Or invert to inside the disk
    if (mask) return;
  } else {
    // Only apply rrotation inside the disk
    psi += rrepeat*atanh(length(z)/radius);
  }
  {
    int flips = 0;
      bool found = false;
    for (int i = 0; i < NN; i++) {
      // Fundamental region is OAB
      // OA is on x-axis, OB is at angle theta
      // AB is circle for hyperbolic case.
      // norm is normal to OB, norm2 is other radial
      // reflection - either x-axis or reflection of OA.
      int k = tryreflect(z,norm) + tryreflect(z,norm2) + tryinvert(z,p,r2);
        if (k == 0) {
            found = true;
            break;
        }
      if (fundamental) return;
      flips += k;
    }
    if (!found) return;
    if (chiral && imod(flips,2) != 0) z.y = -z.y;
  }
  float fade = 1.25;

  // If mouse pressed, show region boundary
  if (keypress(CHAR_B) &&
      (abs(dot(z,norm)) < 0.03 || 
       abs(dot(z,norm2)) < 0.03 ||
       length(p-z)-r < 0.03)) {
    fade = 0.5;
  }
  // Now convert position (in fundamental region) to texture coord.
  z = mat2(cos(psi), -sin(psi), sin(psi), cos(psi)) * z;
  
  // scale texture access
  z *= 0.5;
  // and add a variable offset here?
  z += vec2(0.5,0.5);

  //vec4 texColor = texture(iChannel0, z);
  
  vec3 col = cos( vec3(z.x*1.5,(z.x+z.y)*0.5,z.y*1.5) ) *  sin( vec3(z.y*1.5,(z.x-z.y)*0.5,z.x*1.5) );
  col *= sin( T2 * vec3(7,9,13)*0.1 );
  vec4 texColor = vec4(col,1.0);
  
  fragColor = vec4(fade*texColor.xyz,1.0);
}

