
import java.util.Map;

class RenderPass{
  PShader  sh;
  int     out;
  int []  ins;
  RenderPass(int nin){ ins=new int[nin]; }
};

class RenderStack{
  int nx,ny;
  int nimg;
  HashMap<String,PShader> shaders;
  ArrayList<RenderPass>   passes;
  ArrayList<PGraphics>    images;
  float time;
  float mx,my;

RenderStack( int nx_, int ny_ ){
  nx=nx_; ny=ny_;
  shaders = new HashMap<String,PShader>();
  images  = new ArrayList<PGraphics>(); 
  passes  = new ArrayList<RenderPass>();
};

void addScriptLine(String s){
  String[]   ws = splitTokens( s );
  RenderPass rc = new RenderPass( ws.length-3 );
  passes.add(rc);
  // --- load shader if new
  String name     = ws[0];
  PShader sh = shaders.get(name);
  if(sh==null){
    String ss = name+".glslf";
    println( ss );
    sh = loadShader(ss); 
    shaders.put( name, sh );
  }
  rc.sh=sh;
  // --- set input and output textures
  rc.out   = int(ws[1]);
  nimg     = max( nimg, rc.out );
  String sep  = ws[2];
  for(int i=3; i<ws.length; i++){
    int iin     = int(ws[i]);
    rc.ins[i-3] = iin;
    nimg        = max( nimg, iin );
  }
  nimg++;
  //images.ensureCapacity( nimg+1 );
  //println( "nimg "+ nimg + " " + images.size() );
}

void loadScrip( String fname){
  String[] lines = loadStrings(fname);
  for( String l : lines ){ addScriptLine(l); }
}

void prepare(){
  //println( "prepare " + images.size() );
  for(int i=0;i<nimg; i++){
    //println( "crate image  " + i );
    PGraphics pg = createGraphics(nx, ny, P2D);
    pg.textureWrap(REPEAT);
    images.add( pg );
  }
  for(PShader sh : shaders.values() ){
    shader(sh);
    sh.set("iResolution", (float)nx, (float)ny);
  }
  
}

void render( RenderPass rc ){
  PGraphics pg;
  println(  rc.out +" "+ rc.ins.length );
  if(rc.out<0){ pg = (PGraphics)g;       }
  else        { pg = images.get(rc.out); }
  pg.beginDraw();
  pg.shader( rc.sh );
  rc.sh.set( "iMouse", mx,my );
  rc.sh.set( "iTime" , time );
  for(int i=0;i<rc.ins.length;i++){
    String name = "iChannel"+int(i);
    print( ">>"+name+"<<");
    rc.sh.set( name, images.get( rc.ins[i] ) );
  }
  //println(  rc.out +" "+ rc.ins.length );
  pg.rect(0, 0, nx, ny);
  pg.endDraw();
}

void render(){
  for( RenderPass rc : passes ){ render( rc ); }
}

}
