
// There Should be different classes of Software Renderes which react to music (which are not using GLSL shader)

interface MusicRenderer{
  void start ();
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
  
  void start(){};
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
  void start(){};
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
  void start(){};
  
}


// ============== Particle Fission

class Renderer_ParticleFission implements MusicRenderer{
  int perFrame = 20;
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
  void start(){
     //background(1.);
     //fill( 1.0, 0.3 );
     fill( 1.0, 0.5 );
     //fill( 1.0, 1.0 );
    rect(0,0,width,height);
    start(2,width/2,height/2,150.0); 
  };

  //void update( float dt, float time, float [] freqs ){ 
  void update(){ 
   if(beater.bJustBeat){
     start();
   } 
   bParticleDraw = true;
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
       stroke( 0, p.m*5.0 );
       strokeWeight( 1+p.m*8.0 );
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

// ============== Spectral Chain

class Renderer_SpectralChains implements MusicRenderer{
  int nx,ny;
  Particle [][] ps;
  float  K    = 300.0;
  float  Lx   = 20.0;
  float  Ly   = 20.0;
  float  kick = 2500.0;
  float x0 = 100;
  float y0 = 100;
  float G =  100.0;
  
  Renderer_SpectralChains( int nx_, int ny_ ){
    nx=nx_; ny=ny_;
    ps = new Particle[nx][ny];
    for(int i=0; i<nx; i++){
      //ps[i] = 
      for(int j=0; j<ny; j++){
        ps[i][j] = new Particle();
      }
    }
  }
  
  void start(){
    fill( 1.0, 1.0 );rect(0,0,width,height);
    Lx = (width-2*x0)/nx;
    Ly = (height-2*y0)/ny;
    kick = 150*Lx;
    for(int i=0; i<nx; i++){
      for(int j=0; j<ny; j++){
        Particle p = ps[i][j];
        p.m=1.0;
        p.q=0.0;
        p.x=x0+i*Lx; 
        p.y=y0+j*Ly;
        println( "p["+i+","+j+"] "+p.x+" "+p.y );
        p.vx=0;
        p.vy=0;
      }
    }
  }

  //void update( float dt, float time, float [] freqs ){ 
  void update(){ 
    float dN = 0.8/nx;
    friction = 0.0;
    //dt = 0.0000000001;
    bParticleDraw = false;
    //fill( 1.0, 1.0 );rect(0,0,width,height);
    fill( 1.0, 0.05 );rect(0,0,width,height);
    for(int i=0; i<nx; i++){ Particle [] pis = ps[i]; for(int j=0; j<ny; j++){ pis[j].clearForce(); } }
    for(int i=0; i<nx; i++){
      Particle [] pis = ps[i];
      for(int j=0; j<ny; j++){
        Particle p = pis[j];
        if(j>0){
          Particle op = pis[j-1];
          p.fy += G*p.m;
          float dx = p.x-op.x;
          float dy = p.y-op.y;
          float dz = p.z-op.z;
          float r2 = dx*dx + dy*dy + dz*dz;
          float cV = dx*p.vx + dy*p.vy + dz*p.vz;
          float cF = dx*p.fx + dy*p.fy + dz*p.fz;
          float ir2 = 1/r2;
          float ir  = sqrt(ir2); // ToDo - we can do some Taylor approx to get rid of sqrt()
          float sr = (Ly*ir-1);
          p.x  += dx*sr;
          p.y  += dy*sr;
          p.z  += dz*sr;
          //cV *=-ir/sqrt(p.vx*p.vx + p.vy*p.vy + p.vz*p.vz);
          //float sV = sqrt(1-cV*cV);
          float aV = atan( p.vx/p.vy );
          //p.vx  += dx*cV;
          //p.vy  += dy*cV;
          //p.vz  += dz*cV;
          cF *=-ir2;
          p.fx  += dx*cF;
          p.fy  += dy*cF;
          p.fz  += dz*cF;
          
          p.update(dt);
          
          float sv = 10.0;
          float sf = 10.0;
          stroke(i*dN,1,0.3+abs(aV)*10.0,0.5);
          strokeWeight(3); 
          //point(p.x,p.y,p.z);
          line(p.x,p.y,p.z, op.x,op.y,op.z);
          /*
          stroke(0.7,1,1,1);
          line(p.x,p.y,p.z, p.x+p.vx*sv,p.y+p.vy*sv,p.z+p.vz*sv);
          stroke(0.0,1,1,1);
          line(p.x,p.y,p.z, p.x+p.fx*sf,p.y+p.fy*sf,p.z+p.fz*sf);
          */
        }else{
          float xi0 = x0 + i*Lx;
          p.vx = 0.999;
          p.vy = 0.999;
          p.fx += -K*(p.x-xi0) + sqrt(freqs[i])*kick;
          p.fy += -K*(p.y-y0);
          p.update(dt);
        }
        //strokeWeight(3); point(p.x,p.y);
        //println( "p["+i+","+j+"] "+p.x+" "+p.y );
        
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
  void start(){};

}

// ========== Renderer Flow Field
interface FlowField{ 
  float eval(float x,float y, float[] out); 
  void update();
};

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
    void start(){};
  
}

class Renderer_FlowField implements MusicRenderer{
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
    float width_ = width*0.7;
    for(int i=0; i<nc; i++){
      //float speed = 10;
      float speed = freqs[i];
      //curWs[i] = 10.0/(0.1+freqs_smooth[i]);
      //curWs[i] = 2.0 + freqs_smooth[i]*0.1;
      curWs[i] = 2.0 + sqrt(freqs[i])*2.0;
      //curWs[i] = 2.0;
      float x = curXs[i];
      float y = curYs[i];
      x += random(-1.,1.)*speed;
      y += random(-1.,1.)*speed;
      if(x<0     )x+=width_;
      if(x>width_)x-=width_;
      if(y<0     )y+=height;
      if(y>height)y-=height;
      curXs[i]=x;
      curYs[i]=y;
    }
  }

  void update(){
    ffc.update();
    updateCursors();
    if(frameCount%30==0){ fill(0,0,1,0.02); rect(0,0,width,height); }
    strokeWeight(1); stroke(0.,0.05); 
    for(int itr=0; itr<perFrame; itr++){
    for(int i=0; i<np; i++){
      float x=xs[i];
      float y=ys[i];
      //if( (x>width)||(x<0)||(y>height)||(y<0) ){ x=5;y=random(5,height-5); }     
      
      int   icur = (int)((i*2654435769L)%nc);
      float vol = freqs[icur];
      if( (0.3+vol*0.05)*restartProb >random(1.)){ 
      //if( (0.3+5.5/vol)*restartProb >random(1.)){ 
        //x=random(5,width-5);y=random(5,height-5);
        //int icur = (int)((i*2654435769L)%nc);
        float curWidth = curWs[icur];
        //float curWidth = vol*10.2;
        x=curXs[icur]+random(-curWidth,curWidth);y=curYs[icur]+random(-curWidth,curWidth);
      } 
      ffield.eval(x,y,fxy);
      float x_ = x + fxy[0]*dt;
      float y_ = y + fxy[1]*dt;
      if(bDraw){
        stroke( 0, 0.05 + vol*0.001 );
        line(x,y,x_,y_); 
      }
      xs[i]=x_;
      ys[i]=y_;
    }
    }
    if( bDEBUG_DRAW ) draw();
  }
  
  void draw(){
    strokeWeight(1);
    noFill();
    stroke(0,1,1,1);
    for(int i=0; i<nc; i++){
      ellipse( curXs[i], curYs[i], curWs[i], curWs[i] );
    }
  };
  void start(){};
  
}
