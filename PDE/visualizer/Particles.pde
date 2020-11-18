
// ========== Kinematic Particle 2D

class Kin2D{
  Kin2D parent;
  float w;
  float x,y;
  float x_,y_;
  float ux,uy;
  
  Kin2D(){ parent = null; };
  Kin2D( Kin2D parent_, float L, float omega ){
      parent = parent_;
      float dx = random(-1,1);
      float dy = random(-1,1);
      ux = cos(omega);
      uy = sin(omega);
      println( omega+" : "+ux +" "+ uy);
      float r2 = dx*dx + dy*dy;
      float sc =L/sqrt(r2);
      x = parent.x + dx*sc;
      y = parent.y + dy*sc;
  }
  
  void update(){ // rotation by unitary complex number
    if(parent==null) return;
    float dx = x_-parent.x_;
    float dy = y_-parent.y_;
    x = parent.x_ + dx*ux - dy*uy;
    y = parent.y_ + dy*ux + dx*uy;
    println( "r " + sqrt(dx*dx+dy*dy) );
  }
  void move(){ x_=x; y_=y; }
  
  void draw(){ 
    stroke(0);
    //strokeWeight(3); point(x,y);
    strokeWeight( w * 0.1 );
    //println( x +" "+ y  );
    line( x,y, x_,y_ ); 
    strokeWeight( 1 );
    if(parent!=null){
      stroke(50,255,100,50);
      line( x,y, parent.x, parent.y );
    }

  }
  
}



// ========== Dynamic Particles 3D

// Bonded-Body-Tree Renderer
// System (Tree, Cluster) of bonded bodies. In simple case bodies are bonded with springs

class Particle{
  float m;
  float q;
  float x,y,z;
  float vx,vy,vz;
  float fx,fy,fz;  
  //PVector opos;      // To backup previous position 
  
  Particle(){};
  Particle(Particle p){
     x=p.x;   y=p.y;   z=p.z;
    vx=p.vx; vy=p.vy; vz=p.vz;
    q=p.q; m=p.m;
  }
  
  float speed2   (){ return vx*vx + vy*vy + vz*vz; }
  void clearForce(){ fx=0; fy=0; fz=0; }
    
  void magnetic( float Bx, float By, float Bz ){  // b*v
    // https://en.wikipedia.org/wiki/Lorentz_force
    // https://en.wikipedia.org/wiki/Cross_product
    fx = (vy*Bz - vz*By)*q;
    fy = (vz*Bx - vx*Bz)*q;
    fz = (vx*By - vy*Bx)*q;
  }
  
  /*
  void friction( float dt, float K ){
    float kf = max( 0, 1-(friction*dt/m) );
    vx *= kf;vy *= kf; vz *= kf;
    //fx -= vx*K; fy -= vy*K; fz -= vz*K; 
  }
  */
  
  void update(float dt){
    //if(opos!=null){ opos.x=x; opos.y=y; opos.z=z; }
    float vdt = dt/m;
    float kf = max( 0, 1-(friction*vdt) );
    vx *= kf;
    vy *= kf; 
    vz *= kf;
    vx+=fx*vdt;
    vy+=fy*vdt;
    vz+=fz*vdt;
    float x_=x+vx*dt;
    float y_=y+vy*dt;
    float z_=z+vz*dt;
    if(bParticleDraw){
      //stroke( 0, m*3.0 );
      //println( "p "+x+" "+y+" "+z+" p_ "+x_+" "+y_+" "+z_+" v "+vx+" "+vy+" "+vz );
      line(x,y,z, x_,y_,z_ );
    }
    x=x_;y=y_;z=z_;
  }
  
  Particle fission( float q_, float fm ){
    Particle p = new Particle(this);
    p.m*=fm; m*=(1.-fm);
    p.q=q_; q-=q_;  
    //println( "fission m: "+m+"|"+p.m+" q: "+q+"|"+p.q );
    return p;
  }
   
  void circularOrbit(Particle p){
    float dx = x-p.x;
    float dy = y-p.y;
    float dz = z-p.z;
    //float invr = 1/sqrt(dx*dx + dy*dy + dz*dz);
    float c = -( vx*dx + vy*dy + vz*dz )/(dx*dx + dy*dy + dz*dz);
    //c*=invr;
    //println( "c "+ c ); 
    vx+=dx*c;
    vy+=dy*c;
    vz+=dz*c;
    //fx=vx+dx*c;
    //fy=vy+dy*c;
    //fz=vz+dz*c;
  }
  
  void draw(){  point(x,y,z); };
  
    /*
  void update(float dt, float Bx, float By, float Bz ){
    
    float invmdt = dt/m;
    float kq = KCoul*q*invmdt;
    float kf = max( 0, 1-(friction*invmdt) );
    
    vx *= kf;
    vy *= kf;
    vz *= kf;
    
    vx += (By*vz - Bz*vy)*kq;
    vy += (Bz*vx - Bx*vz)*kq;
    vz += (Bx*vy - By*vx)*kq;
    
    float x_ = x + vx*dt;
    float y_ = y + vy*dt;
    float z_ = z + vz*dt;
    //println( x+" "+y+" "+z );
    
    //strokeWeight(m);
    //stroke( (q+1.)*0.5,1.,1.);
    
    stroke( 0, m*3.0 );
    
    line(x,y,z, x_,y_,z_ );
    x=x_;y=y_;z=z_;
    
  }
  */
  
  /*
  void draw(){ 
    if(opos!=null){
      //strokeWeight(3.0);
      //point(x,y,z);
      //println( x+" "+y+" "+z  );
      //strokeWeight(1);
      //float vsc = 100.0;
      //stroke(60,255,150); line( x,y,z,   x+vx*vsc,y+vy*vsc,z+vz*vsc );
      //stroke(120,255,150); line( x,y,z,   x+fx*vsc,y+fy*vsc,z+fz*vsc );
      line( opos.x,opos.y,opos.z, x,y,z );
    }else{
      point(x,y,z);
    }
  };
  */
  
};


// ========== Bonds between 3D particles

class Bond{
  int i,j;
  float k; // stiffness
  float l; // length
  //void force(Particle[] ps, boolean recoil){
  
  void force( ArrayList<Particle> ps, boolean recoil){
    //Particle a = ps[i];
    //Particle b = ps[i];
    Particle a = ps.get(i);
    Particle b = ps.get(j);
    float x = b.x-a.x;
    float y = b.y-a.y;
    float z = b.z-a.z;
    float r2 = x*x + y*y + z*z;
    float r = sqrt(r2);
    float fr = k*(l-r)/r;
    //float fr = k*(r-l)/l;
    float fx = fr*x;
    float fy = fr*y;
    float fz = fr*z;
    //println( "bond["+i+" "+j+"] "+"("+fx+" "+fy+" "+fz+")" );
    b.fx+=fx; b.fy+=fy; b.fz+=fz;
    if(recoil){ a.fx-=fx; a.fy-=fy; a.fz-=fz; }
  }
  
  void draw( ArrayList<Particle> ps ){ 
    Particle a = ps.get(i);
    Particle b = ps.get(j);
    line( a.x,a.y,a.z,   b.x,b.y,b.z ); 
  }
  
  Bond(int i_,int j_, ArrayList<Particle> ps, float k_){
    i=i_; j=j_; k=k_;
    Particle a = ps.get(i);
    Particle b = ps.get(j);
    float x = b.x-a.x;
    float y = b.y-a.y;
    float z = b.z-a.z;
    l = sqrt(x*x + y*y + z*z);
  }
  
};
