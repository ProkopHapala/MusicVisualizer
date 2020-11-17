
interface RulingClass{
  void   start();
  void   draw();
  void   finish();
  String getName();
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
  float cxTimeAmp = 0.05;
  float cyTimeAmp = 0.1;
  float cx0 = -0.80;
  float cy0 = -0.2;
  float cxVol =  0.001;
  float cyVol = -0.005;
  
  Rulez_JuliaLike( String nickName_, String shaderName_ ){
    shaderName = shaderName_;
    nickName   = nickName_;
  }
  void setParams(){
    DwShadertoy sh = stack.shaders.get("main");
    time += (timeRate0 + pow(soundPower,timeRateVolPower)*timeRateVolume); 
    float cx = cx0 + sin(time*cxTimeFreq)*cxTimeAmp + ydy[0]*cxVol;
    float cy = cy0 + cos(time*cyTimeFreq)*cyTimeAmp + ydy[1]*cyVol;
    //println( nickName+" "+shaderName+" Cxy "+cx+" "+cy );
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
}


class Rulez_JustRenderer implements RulingClass{
  MusicRenderer            renderer;
  String name;
  Rulez_JustRenderer(String name_, MusicRenderer renderer_){
    renderer=renderer_;
    name = name_;
  }
  void start(){
    beater.bJustBeat  = true;
    renderer.update();
    fill(0,0,1,1); rect(0,0,width,height);
  }
  void draw  (){
    resetShader(); blendMode(BLEND);
    renderer.update();
  };
  void finish(){};
  String getName(){return name; };
}
