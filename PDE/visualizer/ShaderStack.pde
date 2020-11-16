

/*

ToDo 
 * Input can be either image (DwGLTexture) or FrameBuffer  DwShadertoy

*/


import java.util.Map;

class RenderPass{
  //PShader  sh;
  DwShadertoy sh;
  int     out;
  //int []  ins;
  DwGLTexture [] ins;
  //RenderPass(int nin){ ins=new int[nin]; }
  RenderPass(int nin){ ins=new DwGLTexture[nin]; }
};

class RenderStack{
  DwPixelFlow  context;
  int nx,ny;
  int nimg;
  HashMap<String,DwShadertoy>  shaders;
  ArrayList<RenderPass>        passes;
  HashMap<String,DwGLTexture>  images;
  float time;
  float mx,my, omx, omy;

RenderStack( int nx_, int ny_ , DwPixelFlow context_){
  context=context_;
  nx=nx_; ny=ny_;
  shaders = new HashMap<String,DwShadertoy>();
  images  = new HashMap<String,DwGLTexture>(); 
  passes  = new ArrayList<RenderPass>();
};

void addImage( String name, String sInit ){
  DwGLTexture img = new DwGLTexture();
  images.put( name, img );
  
  if( sInit.equals("random") ){
    int wh = 256;
    byte[] bdata = new byte[wh * wh * 4];
    ByteBuffer bbuffer = ByteBuffer.wrap(bdata);
    for(int i = 0; i < bdata.length;){
      bdata[i++] = (byte) random(0, 255);
      bdata[i++] = (byte) random(0, 255);
      bdata[i++] = (byte) random(0, 255);
      bdata[i++] = (byte) 255;
    }
    img.resize(context, GL2.GL_RGBA8, wh, wh, GL2.GL_RGBA, GL2.GL_UNSIGNED_BYTE, GL2.GL_LINEAR, GL2.GL_MIRRORED_REPEAT, 4, 1, bbuffer);
   }

}

void addShader( String name, String fpath ){
    String ss = "data/"+fpath+".glslf";
    println( ss );
    DwShadertoy sh = new DwShadertoy(context, ss );
    shaders.put( name, sh );
}

void addScriptLine(String s){
  String[]   ws = splitTokens( s );
  int noff = 2;
  int nin = ws.length-noff;
  //println( "nin "+nin );
  RenderPass rc = new RenderPass( nin );
  passes.add(rc);
  String name     = ws[0].trim();
  DwShadertoy sh = shaders.get(name);
  //println("name >>"+name+"<<");
  if(name.equals("main")){ rc.out=-1; }
  for(int i=0; i<nin; i++){
    String w = ws[noff+i];
    DwShadertoy insh = shaders.get( w );
    if(insh==null){
      rc.ins[i] = images.get( w );
    }else{
      rc.ins[i] = insh.tex; 
    }
  }
  rc.sh=sh;
}

void loadScrip( String fname){
  String[] lines = loadStrings(fname);
  for( String l : lines ){ addScriptLine(l); }
}

void prepare(){
  for(DwShadertoy sh : shaders.values() ){
    //shader(sh);
    sh.set_iResolution( (float)nx, (float)ny, 1.0 );
  }
}

void render( RenderPass rc ){
  DwShadertoy sh = rc.sh;
  //sh.set_iMouse( mx,my, omx,omy );
  sh.set_iTime(  time );
  for(int i=0;i<rc.ins.length;i++){
    sh.set_iChannel( i, rc.ins[i] );
  }
  if(rc.out<0){ sh.apply(g);    }
  else        { sh.apply(nx, ny); }
}

void render(){
  for( RenderPass rc : passes ){ render( rc ); }
}

}
