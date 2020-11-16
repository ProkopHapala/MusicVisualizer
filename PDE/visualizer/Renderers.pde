
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
    conv( freqs_smooth, freqs, 0.05 );
    linearFit(freqs_smooth, 2,15, ydy );
  }
  
  void draw(){
    strokeWeight(1);
    stroke( ((frameCount)&0xff), 255, 255);
    //drawSpectrum( fft, height*0.9, 3.0, 0.7 );
    float scx = 12.0;
    float scy = 0.3;
    float y0  = height*0.9;
    drawFreqs( freqs, y0, scy, scx );
    drawFreqs( freqs_smooth, y0, scy, scx );
    stroke( 255, 0, 255);
    //line( 3*scx, y0-ydy[0]*scy, 12*scx, y0-(ydy[0]+((12-3)*ydy[1]))*scy );
    line( 2*scx, y0-ydy[0]*scy, 15*scx, y0-ydy[1]*scy );
    fill(0,0,0,5);
    //rect(0,0,width,height);
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
     fill( 1.0, 0.3 );
     rect(0,0,width,height);
     start(2,width/2,height/2,150.0);
   } 
   //smooth();
   strokeWeight(1);
   stroke(0,0,0,1);
   println("n "+perFrame+" np "+np );
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
