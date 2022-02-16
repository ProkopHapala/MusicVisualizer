
class Control{
  String label; 
  float x=0,y=0,w=100,h=10; // position and size on the screen
  float v, vmin,vmax;

Control( String label_, float x_, float y_, float vmin_, float vmax_){
    label=label_;
    x=x_; y=y_; vmin=vmin_; vmax=vmax_;
    v = (vmin+vmax)*0.5;
  }
  
  boolean set(float mX, float mY){
    if( (mX>x) && (mX<(x+w)) && (mY>y) && (mY<(y+h)) ){ 
      //v = vmin + (vmax-vmin)* (mouseY-y)/h;
      v = vmin + (vmax-vmin)* (mouseX-x)/w;
      //println("set "+v);
      return true;
    }
    return false;
  }
  
  void draw(){
    stroke(1);
    fill(0.5);
    //noFill();
    rect(x,y,x+w,y+h);
    fill(1);
    float f = (v-vmin)/(vmax-vmin);
    rect(x,y,x+w*f,y+h);
    fill(0);
    text(label, x, y+h );
  };
  
};


// ========= Controls
Control[] sliders;

void initControls(){
  sliders = new Control[3];
  for(int i=0; i<sliders.length; i++){ sliders[i] = new Control( "label_"+i, 10,30+i*10, -1.0, 1.0 ); }
  //float cVol      = 1.0;
  //float cTimeAmp  = 1.0;
  //float cTimeFreq = 1.0;
  sliders[0].label = "cVol";
  sliders[1].label = "cTimeAmp";
  sliders[2].label = "cTimeFreq";
}

void applyControls(){
  RulingClass jl = visList.current();
  if(jl.getType()==1){
    Rulez_JuliaLike jlr = (Rulez_JuliaLike)jl;
    jlr.cVol      = pow( 10, sliders[0].v );
    jlr.cTimeAmp  = pow( 10, sliders[1].v );
    jlr.cTimeFreq = pow( 10, sliders[2].v );
  }
}

boolean mouseControl( float mX, float mY ){
  Control last  = sliders[sliders.length-1];
  Control first = sliders[0               ];
  //println( first.x+"<"+last.x +" "+ first.y+"<"+last.y );
  boolean hit=false;
  if( (mX>first.x)&&(mX<(last.x+last.w)) && (mY>first.y)&&(mY<(last.y+last.h)) ){
    for(int i=0; i<sliders.length; i++){ hit |= sliders[i].set(mX, mY); }
  }
  return hit;
}
