

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


float AmpC = 1.0;
float Amp0 = 0.0;
float ampZ = 0.0;
float phZ  = 0.0; 

/*
float minx  =+1e+8;
float miny  =+1e+8;
float maxx  =-1e+8; 
float maxy  =-1e+8;
float x2sum =0.;
float y2sum =0.;
float xsum  =0.;
float ysum  =0.;
*/


const vec2 sw=vec2(-1.,1.);

vec2 mulComplex( vec2 a, vec2 b ){
	return vec2(
    	a.x*b.x - a.y*b.y, 
    	a.x*b.y + a.x*b.y
    );
}


float targetFunc(vec2 p){
    //float f = max( 1.-dot(p,p), 0. ); return f*f;
    return 1./(1.+ dot(p,p) );
}



vec3 fractal(vec2 p, vec2 C ) {
	vec2  p0= p;
    float ca = cos(phZ)*ampZ;
    float sa = sin(phZ)*ampZ;
    //p += C*sin(iTime)*0.2;
    //p += vec2( cos(iTime)*0.2, sin(iTime)*0.2 );
    
    //float phase = iTime + Const.x
    //p0 *= vec2( 1.+cos(iTime)*0.5, 1.+sin(iTime)*0.5 );
    p0 *= vec2( 1.+cos(iTime+Const.x*-50.)*0.8, 1.+sin(iTime+Const.y*-50.)*0.8 );
    
	vec3 result = vec3(0.0,0.0,0.0);
    
    float w1 = 1.0 + 0.7* sin(iTime*0.1);
    float w2 = 1.0 + 0.7* cos(iTime*0.1156);
    float w3 = 1.0 + 0.7*-sin(iTime*0.1498);
   
    vec2 off1=vec2(0.0, 0.0);
    vec2 off2=vec2(0.0,-0.3);
    vec2 off3=vec2(0.0, 0.3);
    
	for (int i = 0; i < iters; i++) {
		//p = vec2(p.x * p.x - p.y * p.y,          2.0* p.x * p.y                );
        //float cx = C.x*cAmp + p.x*ca - p.y*sa + p0.x*p0Amp;
        //float cy = C.y*cAmp + p.x*sa + p.x*ca + p0.y*p0Amp; 
		
        //vec2 c = C*AmpC + p0*Amp0 + p*ca + p*sw*sa; 
        //p = mulComplex( p, p ) + c;
        //p = mulComplex( p, p ) + C*1.1;
        //p = mulComplex( p, p ) + p0*1.5;
        //p = mulComplex( p, p );
        p = mulComplex( p, p ) + p0;
        //p = mulComplex( p, p ) + p0*1.8;
        //p = mulComplex( p, p ) + p0*vec2(5.,1.5);
        //p = mulComplex( p, p ) + p0.yx*sw*1.8;
        
        /*
        x2sum = p.x*p.x;
        y2sum = p.y*p.y;
        xsum  = p.x;
        ysum  = p.y;
        minx = min(minx,p.x);
        miny = min(miny,p.y);
        maxx = max(maxx,p.x);
        maxy = max(maxy,p.y);
		*/
        
        //result += targetFunc(p);
        
        vec3 prj = vec3(
        	targetFunc((p+off1)*w1),
            targetFunc((p+off2)*w2),
            targetFunc((p+off3)*w3)
        );
        result = max(result,prj);
        /*
        result = vec3(
            max( result.x, targetFunc(p*w1) ),
            max( result.y, targetFunc(p*w2) ),
            max( result.z, targetFunc(p*w3) )
        );
		*/
        
	}
	
	return result;	
}


void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 p = ((fragCoord.xy / iResolution.xy) - 0.5)*4.0;
    fragColor = vec4(sin(p),0.0,1.0);
    
    /*
    p.y -= 1.0;
    //p.x *= iResolution.x/iResolution.y;
    //vec2 mouse = vec2(iMouse.x/iResolution.x,iMouse.y/iResolution.y);
    vec2 C =  vec2(0.098386255, 0.6387662);
    //int i = fractal(-p.yx, C );
    vec3 c = fractal(p.yx, C );
    
    //float c = 1.2*sqrt(float(i)/float(iters));
    //float c = sqrt( x2sum + y2sum )*0.1;
    //float c = sqrt(xsum*xsum + ysum*ysum) *1.1;
    //float c = abs(minx+maxx);
    //float c = log( abs(minx-maxx) / abs(miny-maxy) );
    
    
    fragColor = vec4( pow(c,vec3(0.8)),1.0);
    */
}


