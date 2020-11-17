
// There Should be different classes of Software Renderes which react to music (which are not using GLSL shader)

interface MusicRenderer{
  void update();
  void draw  ();
}


// Tree Building Params

//int tree_nmin=1;
//int tree_nmax=3;
int tree_nmin=1;
int tree_nmax=1;
float tree_fL_min = 0.2;
float tree_fL_max = 0.4;

  
// ========== Renderer Spectrum

class Renderer_Spectrum implements MusicRenderer{
  
  void update(){
    fft.forward(song.mix);
    soundPower = downSampleSpectrum( fft, freqs );
    conv( freqs_smooth, freqs, freqMixRate );
    //linearFit(freqs_smooth, 2,15, ydy );
    linearFit2(freqs_smooth, 2,28, ydy );
  }
  
  void draw(){
    strokeWeight(1);
    //drawSpectrum( fft, height*0.9, 3.0, 0.7 );
    float scx = 12.0;
    float scy = 0.3;
    float y0  = height*0.9;
    stroke( 0, 150, 255);
    drawFreqs( freqs, y0, scy, scx );
    stroke( 0, 0, 255);
    drawFreqs( freqs_smooth, y0, scy, scx );
    stroke( 255, 0, 255);
    //line( 3*scx, y0-ydy[0]*scy, 12*scx, y0-(ydy[0]+((12-3)*ydy[1]))*scy );
    stroke( 0, 0.0, 0.5);
    line  ( 2*scx, y0-ydy[0]*scy, 28*scx, y0-ydy[1]*scy );
    stroke( 0, 0, 0);
    line  ( 0, y0, 32*scx, y0 );
  }
  
}

// ========== Renderer Particle Kinematic Rotation Tree 2D 

class Renderer_RotTree implements MusicRenderer{
  
  ArrayList<Kin2D> ps;
  
  //void update( float dt, float time, float [] freqs ){
  void update( ){
    for( Kin2D p : ps ){ p.move(); }
    for( Kin2D p : ps ){ p.update( ); }
  }
  
  void draw(){
    for( Kin2D p : ps ){ p.draw(); }
  }
  
  void makeTree( Kin2D par, int level, float L ){
    if(level<=0)return;
    int n = (int)random( tree_nmin, tree_nmax+1 );
    L *= random( tree_fL_min, tree_fL_max );
    //Particle par = ps.get(iparent);
    for(int i=0;i<n;i++){
      float omega = random(0.8,1.2) / L;
      Kin2D p = new Kin2D( par, L, omega );
      p.w = L;
      ps.add(p);
      //println( p.x +" "+ p.y  );
      makeTree( p, level-1,  L );
    }
  }
  Renderer_RotTree( int level, float L ){
    ps = new ArrayList<Kin2D>();
    Kin2D p = new Kin2D(); 
    p.x=width/2; p.y=height/2;
    ps.add( p );
    makeTree( p, level, L );
  }
  
}


// ========== Renderer Particle Dynamics 3D 

class Renderer_BondedBodyTree implements MusicRenderer{
  boolean bRecoil = false;
  float Bfield=0;
  float KFrict=0;
  
  //Particle [] particles;
  //Bond     [] bonds;
  ArrayList<Particle> particles;
  ArrayList<Bond>     bonds;

  //int[]      parents;    // anchor points of particles
  
  void makeTree( int iparent, int level, float L ){
    if(level<=0)return;
    int n = (int)random( tree_nmin, tree_nmax+1 );
    //println( "makeTree n "+n );
    L *= random( tree_fL_min, tree_fL_max );
    float vsc = 0.1*L;
    Particle par = particles.get(iparent);
    for(int i=0;i<n;i++){
      Particle p = new Particle();
      //p.opos=new PVector();
      float x = random(-1,1);
      float y = random(-1,1);
      float z = random(-1,1);
      float r2 = x*x + y*y + z*z;
      float sc =L/sqrt(r2);
      p.x = par.x + x*sc;
      p.y = par.y + y*sc;
      p.z = par.z + z*sc*0;
      //println( "@"+level+" #"+particles.size() );
      p.vx = random(-vsc,vsc);
      p.vy = random(-vsc,vsc);
      p.vz = random(-vsc,vsc)*0;
      p.circularOrbit(par);
      p.vx+=par.vx;
      p.vy+=par.vy;
      p.vz+=par.vz;
      particles.add(p);
      int ip = particles.size()-1;
      Bond b = new Bond(iparent,ip,particles, 1.0);
      bonds.add(b);
      makeTree( ip, level-1, L );
    }
  }
  Renderer_BondedBodyTree( int level, float L ){
    particles = new ArrayList<Particle>();
    bonds     = new ArrayList<Bond>();
    Particle p = new Particle(); p.x=width/2; p.y=height/2;
    particles.add( p );
    makeTree( 0, level, L );
  }
  
  void evalForces(){
    for( Particle p : particles ){ p.clearForce(); }
    /*
    for(int i=0;i<bonds.length; i++){ bonds[i].force(particles, bRecoil); }
    for(int i=0;i<particles.length; i++){
      Particle.p = 
      particles.git[i].magnetic( 0,0,Bfield ); 
      particles[i].friction( KFrict ); 
    }
    */
    for(Bond b : bonds  ){ b.force(particles, bRecoil); }
    /*
    for(Particle p : particles ){ 
      p.magnetic( 0,0,Bfield ); 
      p.friction( KFrict ); 
    }
    */
  };
  
  //void update( float dt, float time, float [] freqs ){
  void update( ){
    evalForces();
    for(Particle p : particles ){ p.update(dt); }
    int i=0;
    //for(Particle p : particles ){ println( "["+i+"]" +"("+p.x+" "+p.y+" "+p.z+")"+   "("+p.vx+" "+p.vy+" "+p.vz+")"+  "("+p.fx+" "+p.fy+" "+p.fz+")" ); i++; }
  }
  

  void draw(){
   strokeWeight(1); stroke(0,255,150,50); drawParticles();
   strokeWeight(1); stroke(50,150,150,15);   drawBonds();
  }
  
  void drawBonds(){
    for(Bond b     : bonds     ){ b.draw(particles); }
  }
  void drawParticles(){
    for(Particle p : particles ){ p.draw();          }
  }

  
}


// ============== Particle Fission

class Renderer_ParticleFission implements MusicRenderer{
  int perFrame = 100;
  int npMax;
  int np;
  Particle [] ps;
  
  Renderer_ParticleFission( int npMax_ ){
    npMax = npMax_;
    ps = new Particle[npMax];
  }
  
  void start(int n, float x0, float y0, float v){
    np=0;
    float dphi = PI*2/n;
    //float v = 150;
    for(int i=0; i<n; i++){
      Particle p = new Particle();
      p.m=1.0;
      p.q=0.0;
      p.x=x0; 
      p.y=y0;
      float phi = dphi*i;
      p.vx=cos(phi)*v;
      p.vy=sin(phi)*v;
      ps[i]=p; 
      np++;
    }
  }

  //void update( float dt, float time, float [] freqs ){ 
  void update(){ 
   if(beater.bJustBeat){
     //background(1.);
     //fill( 1.0, 0.3 );
     fill( 1.0, 0.5 );
     //fill( 1.0, 1.0 );
     rect(0,0,width,height);
     start(2,width/2,height/2,150.0);
   } 
   //smooth();
   strokeWeight(1);
   stroke(0,0,0,1);
   //println("n "+perFrame+" np "+np );
   for(int itr=0; itr<perFrame; itr++){
     for(int i=0; i<np; i++){
       Particle p = ps[i];
       if(random(1.)<dieProb){ ps[i]=null; continue; };
       if(p==null) continue;
       float v2 = p.speed2();
       if( (v2<1) || (v2>1000000) ){ ps[i]=null; continue;  }
       p.magnetic( 0.,0.,1. );
       p.update  ( dt );
       if( (np<npMax) && (random(1.)<(fissionProb*p.m)) ){
         ps[np] = p.fission( random(qSpread,-qSpread)-p.q*qConv, random(mMargin,1-mMargin) );
         np++;
       }
     }  
   }
  }
  
  void draw(){
   //strokeWeight(1); stroke(0,255,150,50); drawParticles();
   //strokeWeight(1); stroke(50,150,150,15);   drawBonds();
  }
  
}

// ============== Spectral Tree

class Renderer_SpectralTree implements MusicRenderer{

void branch( int level, float s, float ds, float x0, float y0, float ux, float uy ){

  float phi = sin( 3*s/ds + frameCount*0.001 )*1.1;
  //float phi = sin( 3*s/ds+frameCount*0.001 )*1.1;
  //phi += lrp( s, freqs_smooth )*0.001;
  
  float Af = freqs_smooth[level];
  phi*=(1+Af*0.003);
  
  float vx = cos(phi);
  float vy = sin(phi);
  
  float dx = vx*ux - vy*uy;
  float dy = vy*ux + vx*uy;
  
  float L = 400.0*ds;
  float x = x0 + dx*L;
  float y = y0 + dy*L;
  
  strokeWeight(ds*30.0);
  line(x0,y0, x,y);
  if(ds>0.01){
    branch( level+1, s - 0.25*ds, ds*0.7, x, y, dx, dy );
    branch( level+1, s + 0.25*ds, ds*0.7, x, y, dx, dy );
  }
}

  //void update( float dt, float time, float [] freqs ){
  void update( ){
    branch( 0, 0.5, 0.5, 400, 800, 0.0, -1.0  );
  }
  
  void draw(){
   //strokeWeight(1); stroke(0,255,150,50); drawParticles();
   //strokeWeight(1); stroke(50,150,150,15);   drawBonds();
  }

}

// ========== Renderer Flow Field
interface FlowField{ float eval(float x,float y, float[] out); };

class FlowField_centers implements FlowField{
  int np;
  float [] xs;
  float [] ys;
  float [] dxs;
  float [] dys;
  float [] rots;
  float vx = 1.0;
  float vy = 0.0;
  
  FlowField_centers(int np_){
    np = np_;
    xs   = new float[np];
    ys   = new float[np];
    dxs  = new float[np];
    dys  = new float[np];
    rots = new float[np];
  }
  
  void set(int i, float x, float y, float dx, float dy, float rot){
    xs[i]=x; ys[i]=y; dxs[i]=dx; dys[i]=dy; rots[i]=rot;
  }
  
  float eval(float x,float y, float[] out){
    float fx=0;
    float fy=0;
    for(int i=0; i<np; i++){
      float dx = x - xs[i];
      float dy = y - ys[i];
      float invr2 = 1/(dx*dx + dy*dy);
      //float invr  = sqrt(invr2);
      //float invr3 = invr*invr2;
      float invr4 = invr2*invr2;
      float rot = rots[i]*invr2;
      // see https://en.wikipedia.org/wiki/Potential_flow#Power_laws_with_n_=_%E2%88%921:_doublet
      float Dx = dxs[i];
      float Dy = dys[i];
      float da = (dx*dx - dy*dy)*invr4;
      float db = (2*dx*dy)*invr4;
      //float a2 = a*a;  // Taylor Approx of sinus and cosinus
      //float sa = a * ( 1 - a2*( 0.16666666666  - 0.00833333333*a2 ) );
      //float ca =       1 - a2*( 0.50000000000 - 0.04166666666*a2 )   ;
      fx += (Dx*da - Dy*db) - dy*rot;
      fy += (Dy*da + Dx*db) + dx*rot;
    }
    fx+=vx; fy+=vy;
    out[0]=fx;out[1]=fy;
    return 0;
  }
  
  void update(){
     if(beater.bJustBeat){
       fill( 1.0, 1.0 );
       rect(0,0,width,height);
       for(int i=0; i<ffc.np; i++){ ffc.xs[i] = random(100,width-100); ffc.ys[i] = random(100,height-100);  };
     } 
  }
  
}

class Renderer_FlowField{
  int   np,nc;
  float [] xs;
  float [] ys;
  float [] fxy;
  FlowField ffield;
  float dt = 1.0;
  int perFrame = 200;
  float restartProb = 0.01;
  
  //float curX=width/2;
  //float curY=height/2;
  
  float [] curWs;
  float [] curXs;
  float [] curYs; 
  
  Renderer_FlowField(int np_, int nc_){
    np=np_; nc=nc_;
    xs = new float[np];
    ys = new float[np];
    curXs = new float[nc];
    curYs = new float[nc]; 
    curWs = new float[nc];
    fxy= new float[2];
  }

  void initCursors(){  
    for(int i=0; i<nc; i++){
      curXs[i] = random(100,width -100);
      curYs[i] = random(100,height-100);
      curWs[i] = 10.0;
    }
  }

  void updateCursors(){
    for(int i=0; i<nc; i++){
      //float speed = 10;
      float speed = freqs[i];
      //curWs[i] = 10.0/(0.1+freqs_smooth[i]);
      //curWs[i] = 2.0 + freqs_smooth[i]*0.1;
      curWs[i] = 2.0;
      float x = curXs[i];
      float y = curYs[i];
      x += random(-1.,1.)*speed;
      y += random(-1.,1.)*speed;
      if(x<0     )x+=width;
      if(x>width )x-=width;
      if(x<0     )x+=height;
      if(x>height)x-=height;
      curXs[i]=x;
      curYs[i]=y;
    }
  }

  void update(){
    
    updateCursors();
    
    for(int itr=0; itr<perFrame; itr++){
    for(int i=0; i<np; i++){
      float x=xs[i];
      float y=ys[i];
      //if( (x>width)||(x<0)||(y>height)||(y<0) ){ x=5;y=random(5,height-5); }     
      if(restartProb>random(1.)){ 
        //x=random(5,width-5);y=random(5,height-5);
        int icur = (int)((i*2654435769L)%nc);
        float curWidth = curWs[icur];
        x=curXs[icur]+random(-curWidth,curWidth);y=curYs[icur]+random(-curWidth,curWidth);
      } 
      ffield.eval(x,y,fxy);
      float x_ = x + fxy[0]*dt;
      float y_ = y + fxy[1]*dt;
      if(bDraw){ line(x,y,x_,y_); }
      xs[i]=x_;
      ys[i]=y_;
    }
    }
  }
  
}
