




class Control{
  String label; 
  float x=0,y=0,w=100,h=10; // position and size on the screen
  float v, vmin,vmax;
  
  Control( String label_, float x_, float y_, float vmin_, float vmax_){
    label=label_;
    x=x_; y=y_; vmin=vmin_; vmax=vmax_;
    v = (vmin+vmax)*0.5;
  }
  
  void set(float mX, float mY){
    if( (mX>x) && (mX<(x+w)) && (mY>y) && (mY<(y+h)) ){ 
      //v = vmin + (vmax-vmin)* (mouseY-y)/h;
      v = vmin + (vmax-vmin)* (mouseX-x)/w;
    }
  }
  
  void draw(){
    
    stroke(1);
    noFill();
    rect(x,y,x+w,y+h);
    fill(1);
    float f = (v-vmin)/(vmin-vmax);
    rect(x,y,x+w*f,y+h);
    text(label, x, y );
  };
  
};

Control[] sliders = new Control[10];

interface RulingClass{
  void   start();
  void   draw();
  void   finish();
  String getName();
  void mousePull(float mX, float mY);
  void mouseSet(float mX, float mY);
}

class VizualizerList{
  int icur=0;
  boolean bShuffle = true;
  ArrayList<RulingClass> rules;
  VizualizerList(){
     rules = new ArrayList<RulingClass>();
  }
  void next(){
    rules.get(icur).finish();
    if(bShuffle){ icur=(int)random(rules.size()); }else{ icur=(icur+1)%rules.size(); }
    rules.get(icur).start();
  }
  RulingClass current(){ return rules.get(icur); };
  void draw(){ rules.get(icur).draw(); }
  String getName(){ return rules.get(icur).getName(); };
  
}

class Rulez_JuliaLike implements RulingClass{
  String shaderName;
  String nickName;
  RenderStack stack;
  
  // ToDo : We should make a method to read this params from string !!! (through HashMap/Dictionary)
  float timeRate0        = 0.0005*0.7;
  float timeRateVolume   = 0.0003*0.7;
  float timeRateVolPower = 0.3;
  float cxTimeFreq = 1.9597;
  float cyTimeFreq = 1.1648;
  float cxTimeAmp = 0.5;
  float cyTimeAmp = 1.0;
  float cx0 = -0.80;
  float cy0 = -0.2;
  float cxVol =  0.1;
  float cyVol = -0.5;
  
  float cVol      = 0.01;
  float cTimeAmp  = 0.1;
  float cTimeFreq = 1.0;
  
  Rulez_JuliaLike( String nickName_, String shaderName_ ){
    shaderName = shaderName_;
    nickName   = nickName_;
  }
  void setParams(){
    DwShadertoy sh = stack.shaders.get("main");
    time += (timeRate0 + pow(soundPower,timeRateVolPower)*timeRateVolume); 
    float cx = cx0 + sin(time*cxTimeFreq*cTimeFreq)*cxTimeAmp*cTimeAmp + ydy[0]*cxVol*cVol;
    float cy = cy0 + cos(time*cyTimeFreq*cTimeFreq)*cyTimeAmp*cTimeAmp + ydy[1]*cyVol*cVol;
    global_Cx = cx;
    global_Cy = cy;
    sh.shader.begin(); sh.shader.uniform2f("Const", cx, cy ); 
  };
  void start(){
    stack = new RenderStack( width, height, context );
    stack.addShader      ( "main", shaderName );
    stack.addScriptLine  ( "main :" );
    stack.prepare();
  }
  void draw  (){
    //println( "Rulez_JuliaLike.draw()  | "+nickName+shaderName );
    //setupJulia_2();
    setParams();
    stack.time = frameCount * 0.01;
    stack.render(); ///  BIG RENDER HERE
  };
  void finish(){};
  String getName(){return nickName+"("+shaderName+")"; };

  void mousePull(float mX, float mY){
    float fsc  = 0.1;
    float rmax = 0.1; 
    float fx = (mX-global_Cx);
    float fy = (mY-global_Cy);
    float r = rmax/sqrt(fx*fx + fy*fy);
    if(r<1){ fx*=r; fy*=r; }
    cx0 += fx*fsc;
    cy0 += fy*fsc;
  }
  
  void mouseSet(float mX, float mY){
    cx0 += mX-global_Cx;
    cy0 += mY-global_Cy;
  }
  
}


class Rulez_JustRenderer implements RulingClass{
  MusicRenderer            renderer;
  String name;
  Rulez_JustRenderer(String name_, MusicRenderer renderer_){
    renderer=renderer_;
    name = name_;
  }
  void start(){
    //beater.bJustBeat  = true;
    renderer.start();
    renderer.update();
    fill(0,0,1,1); rect(0,0,width,height);
  }
  void draw  (){
    resetShader(); blendMode(BLEND);
    renderer.update();
  };
  void finish(){};
  String getName(){return name; };
  void mousePull(float mX, float mY){};
  void mouseSet (float mX, float mY){};
}
