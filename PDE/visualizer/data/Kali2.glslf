
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

const float deg=3.0;

vec2 cinv( vec2 z)  { float d = dot(z,z); return vec2( z.x, -z.y ) / d; }
vec2 cmul( vec2 a, vec2 b )  { return vec2( a.x*b.x - a.y*b.y, a.x*b.y + a.y*b.x ); } // from iq

vec2 cdiv( vec2 a, vec2 b )  { float d = dot(b,b); return vec2( dot(a,b), a.y*b.x - a.x*b.y ) / d; }
vec2 cpow( vec2 z, float n ) { 
    float r = length( z ); 
    float a = atan( z.y, z.x );
    return pow( r, n )*vec2( cos(a*n), sin(a*n) ); 
}

// Fractals:

vec2 Kali2( vec2 z, vec2 c ){
    // https://www.shadertoy.com/view/lsBGWK
    z=(cinv(z))+c;
    z.x=abs(z.x);
    return z;
}


vec2 BurningShip( vec2 z, vec2 c ){
    // https://www.shadertoy.com/view/ltccRN
    z = abs(z);
    z=cmul(z,z)+c;
    return z;
}


vec2 NewtonNova( vec2 z, vec2 c ){
    // https://www.shadertoy.com/view/ttccRH
    return z - cdiv(cpow(z, deg) - vec2(1., 0.), cmul(vec2(deg, 0), cpow(z, deg-1.0))) + c;
}

vec2 rotate( vec2 z, float angle){
    vec2 cs = vec2(cos(angle),sin(angle));   // unitary complex number encode rotation 
	return cmul(z, cs);                      // multiplication of z by unitary complex number rotate it in complex plane
}

// This generate color of pixel from calculated mean distance
vec3 colorFunc( float f, float g ){
    //float ci = 1.0 - log2(.5*log2(mean/1.0));
    f = 1.0 + log(f)/15.0;
    g = 1.0 + log(f)/10.0;
    float freq = ColorShift.y;
    float t    = ColorShift.x;   //  ANIMATION 3] time dependnet phase shift of color
    //float freq = 6.0;
    //float t  = iTime * 0.5 + Const.x*100. - Const.y*100.;   //  ANIMATION 3] time dependnet phase shift of color
    return vec3(
        sin( f*f*freq + 0.0 + t),   // Red   - each color channel have different animation speed
        sin( f*g*freq + 1.0 + t),   // Green
        sin( g*g*freq + 2.0 + t)    // Blue
    );
    //return cos( vec3(ci)*6.0 + vec3(0.0,0.4,0.7) )*0.5 + 0.5;
}

//#define WHERE

//void main( void ) {
void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    //vec2 p = ( gl_FragCoord.xy / iResolution.xy );
    //vec3 d = vec3( 1.0/iResolution.xy, 0.0  );
    vec2 p = 1.2*(-iResolution.xy+2.0*fragCoord.xy)/iResolution.y;
    //vec2 p = ((fragCoord.xy / iResolution.xy) - 0.5)*4.0;
    //fragColor = vec4(sin(p),0.0,1.0);
    
    vec2 C = (vec2(0.5,0.5) + Const)*vec2(2.,-2.);
    //vec2 C = Const*vec2(2.,-2.);
    vec2 c=C;


    p = rotate( p, CamRot.x+1.57079632679 )*CamRot.y;
    vec2 z = p;
    float f = 4.;
    float g = 4.;
    //c = (-iResolution.xy+2.0*iMouse.xy)/iResolution.y;


    float xmin = 10.0;
    float ymin = 10.0;
    float val  = 10.0;
    for( int i=0; i<20; i++ ) 
    {
        
        z=(cinv(z))+c;
        z.x=abs(z.x);
        
        z=Kali2(z,c);
        //z=BurningShip(z,c);
        //z=NewtonNova( z,c );
        

        //f = min( f, dot(z-c,z-c));
        //g = min( g, dot(z+c,z+c));
        f = min( f, dot(z-p,z-p));
        g = min( g, dot(z  ,z   ));
        //g = min( g, dot(z-c,z-c));
        
        vec2 d = z-p;
        //val += 1./(1.+dot(p-z,p-z)*1000.0);
        //val  = min( val ,  dot(d,d)   );
        //xmin = min( xmin, d.x*d.x );
        //ymin = min( ymin, d.y*d.y );
    }

    float s = sin( ColorShift.x *10.0 )*10.*ColorShift.y;
    f = 1.0+log(f)/(15.0 - s );
    g = 1.0+log(g)/(15.0 + s );
    vec3 col = 1.-g*abs(vec3(g,f*g,f*f));
    //vec3 col = colorFunc( f, g );
    //vec3 col = abs( colorFunc( f, g ) );
    
    
    
    #ifdef WHERE
    vec2 d = p-C;
    if(dot(d,d)<0.001){
        col=vec3(1.,0.,0.);
    };
    #endif
    
    //vec3 col=vec3(xmin,val,ymin);

    //col = mix(col, vec3(1.),PrintValue((p-vec2(0.3,1.))/.07, c.x,5.,3.));
    //col = mix(col, vec3(1.),PrintValue((p-vec2(0.9,1.))/.07, c.y,5.,3.));

    //gl_FragColor = vec4(col,1.0);
    fragColor = vec4(col,1.0);
    
    
    //fragColor = vec4(sin(p),0.0,1.0);
    
    
}

