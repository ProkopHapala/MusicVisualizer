 
/*
  ToDo
========
 * Choose renderers by text script lines
 * setup parameters by text script lines ( pehraps using string hasmap for each parameter from which the program tries to read, if it founds )
 * Beats speed up run of simulations in renderes and shaders (music volume=velocity of simulation) 
 * renderes drawing to input texture of the shader
 * Renderers
   * Fractal L-system Tree moved by music
   * Particle scattering and fission like in CERN accelerator (  "Cloud Chamber particle detetor" )
 * Shaders to implement
   * Waves from object
     * Reaction diffusion Turing-Paterns 
     * Schroedinger wave mechanis
   * Fluid Dynamics 
   * Kaleidoscope
   * Complex number fractal (Julia Sets)

 * Fractal Colloring By Orbitraps - image-based orbitraps
   * https://iquilezles.org/www/articles/ftrapsbitmap/ftrapsbitmap.htm
   * https://iquilezles.org/www/articles/ftrapsgeometric/ftrapsgeometric.htm
   * Procedural Orbitraps
     * https://www.iquilezles.org/www/articles/ftrapsprocedural/ftrapsprocedural.htm
   * Smooth Iteration Count
     * https://www.shadertoy.com/view/MltXz2
     * https://www.iquilezles.org/www/articles/mset_smooth/mset_smooth.htm
   * Distance to Fractal 
     * https://www.iquilezles.org/www/articles/distancefractals/distancefractals.htm
     * https://www.shadertoy.com/view/lsX3W4
     * https://www.shadertoy.com/view/Mss3R8
   * Pop-Corn Images
     * https://www.shadertoy.com/view/Mdl3RH
     * https://www.shadertoy.com/view/Wss3zB
     * https://www.shadertoy.com/view/wlsfRn
     * https://www.iquilezles.org/www/articles/popcorns/popcorns.htm
     
  Inspiration 
 =============
 * Inigo Quilez
   * Domain Wraping -  https://iquilezles.org/www/articles/warp/warp.htm

*/


// ================= Libraries

import java.nio.ByteBuffer;

import ddf.minim.*;
import ddf.minim.analysis.*;

import com.jogamp.opengl.GL2;
import com.thomasdiewald.pixelflow.java.DwPixelFlow;
import com.thomasdiewald.pixelflow.java.dwgl.DwGLTexture;
import com.thomasdiewald.pixelflow.java.imageprocessing.DwShadertoy;

import com.hamoid.*;
VideoExport videoExport;

// ================= Global Variables

Minim minim;
AudioPlayer song;
FFT fft;

final int nfreq = 32;
float [] freqs        = new float[nfreq];
float [] freqs_smooth = new float[nfreq];
float [] ydy          = new float[2];
float soundPower;


DwPixelFlow context;
RenderStack stack;

PlayList     playlist;
BeatDetector beater;

VizualizerList visList;
RulingClass    suzerain;

MusicRenderer            render; 

Renderer_BondedBodyTree  renderBBT; 
Renderer_RotTree         renderRT;
Renderer_ParticleFission renderFission;
Renderer_Spectrum        renderSpectrum;
Renderer_FlowField       renderFlow;
Renderer_SpectralChains  renderChains;

FlowField_centers ffc;

float freqMixRate = 0.02;

float dt          = 0.025;
float time        = 0;
//float dt          = 1.0;
float KCoul       = 0.5;
//float dt        = 0.025;
float friction    = 0.04;
float fissionProb = 0.08;
float dieProb     = 0.000005;
float qSpread = 0.7;
float qConv   = 0.5;
float mMargin = 0.3;

boolean bParticleDraw = true;
boolean bDraw       = true;
boolean bHUD        = true;
boolean bDEBUG_DRAW = false; 

boolean hold_skip = false;


PGraphics pg_debug;


float global_Cx = 0;
float global_Cy = 0;
//float global_cx0 = -0.80;
//float global_cy0 = -0.2;

boolean bRecord = false;
//boolean bRecord = true;

// ================= INITIALIZE PROGRAM

void settings() {
  //fullScreen(P2D);
  size(800, 800, P2D);
  smooth(0);    // WARRNING : !!!! Make sure smooth(0) is required for proper function of pixelFlow library and RenderStack
  //smooth(8);  // This Breaks 
}

void setup() {
  
  pg_debug = createGraphics(width, height);
  pg_debug.beginDraw();
  pg_debug.fill(1,1,1);
  //pg_debug.ellipse(300, 300, 400, 400);
  pg_debug.endDraw();
  
  colorMode(HSB, 1.0);  
  ellipseMode(CENTER);
  rectMode(CORNERS);
  context = new DwPixelFlow(this);
  context.print();
  context.printGL();
    
  minim = new Minim(this);
  playlist = new PlayList();

/*
  //playlist.addDirRecur( "D:\\hudba\\Basil Poledouris", 10 );
  playlist.addDirRecur( "/media/prokop/LENOVO/hudba/Prodigy - The Eat Of The Land-G", 10);
  playlist.addDirRecur( "/media/prokop/LENOVO/hudba/Luca Turilli"    , 10 );
  playlist.addDirRecur( "/media/prokop/LENOVO/hudba/Classic/-G"      , 10 );
  playlist.addDirRecur( "/media/prokop/LENOVO/hudba/Classic_forever" , 10 );
  playlist.addDirRecur( "/media/prokop/LENOVO/hudba/EuropaUniversalis-ST" , 10 );
  playlist.addDirRecur( "/media/prokop/LENOVO/hudba/HeartsOfIron-ST" , 10 );
  playlist.addDirRecur( "/media/prokop/LENOVO/hudba/Heroes of Might Magic 3 - ST" , 10 );
  playlist.addDirRecur( "/media/prokop/LENOVO/hudba/Hallucinogen-G"  , 10 );
  playlist.addDirRecur( "/media/prokop/LENOVO/hudba/Basil Poledouris", 10 );
  */
  
  //playlist.addDirRecur( "/media/prokop/LENOVO/hudba/Ramstein", 10 );
  //playlist.addDirRecur( "/media/prokop/LENOVO/hudba/xXx-G-ST", 10 );
  
  //playlist.addDirRecur( "/media/prokop/LENOVO/hudba/Classic/-G"      , 10 );
  //playlist.addDirRecur( "/media/prokop/LENOVO/hudba/Classic_forever" , 10 );
  
  //playlist.list.add( "/home/prokop/git/MusicVisualizer/resources/Prodigy_Tu_Cafe.mp3" );
  //playlist.list.add( "/media/prokop/LENOVO/hudba/Prodigy - The Eat Of The Land-G/Mindfields.mp3" );
  playlist.list.add( "/home/prokop/git/MusicVisualizer/resources/BoxCat_Games_10_Epic_Song.mp3" );
  //playlist.list.add( "/home/prokop/git/MusicVisualizer/resources/Psychedelic-LanaB-BlackOctopus.mp3" );
  
  beater = new BeatDetector();
  beater.k1        = 0.3;
  beater.k2        = 0.03;
  beater.triggerUp = 2.5;
  
  renderSpectrum = new Renderer_Spectrum();
  
  visList = new VizualizerList();
  visList.bShuffle = false;
  
  Rulez_JuliaLike jl;    
  /*
  jl = new Rulez_JuliaLike("","TripToSamarkand"                  );  visList.rules.add(jl);
  
  jl = new Rulez_JuliaLike("","Kali2"      );  visList.rules.add(jl);
  jl = new Rulez_JuliaLike("","GrinningFractal"      );  visList.rules.add(jl);
  jl = new Rulez_JuliaLike("","MandelbrotPatternDecoration"      );  visList.rules.add(jl);
  jl = new Rulez_JuliaLike("","Apolonian"      );  visList.rules.add(jl);
  jl = new Rulez_JuliaLike("","FractalPulse"      );  visList.rules.add(jl);
  jl = new Rulez_JuliaLike("","MandalaStarPattern"      );  visList.rules.add(jl);
  jl = new Rulez_JuliaLike("","InversiveKaleidoscope2"      );  visList.rules.add(jl);
  jl = new Rulez_JuliaLike("","MultiplicationTablesMandalas"      );  visList.rules.add(jl);
  
  //jl = new Rulez_JuliaLike("","AngelicMandelbrot"      );  visList.rules.add(jl);
  
  jl = new Rulez_JuliaLike("","Julia"                  );  visList.rules.add(jl);
  jl = new Rulez_JuliaLike("","Julia_distance1"        );  visList.rules.add(jl);
  jl = new Rulez_JuliaLike("","RotationalFractal"      );  visList.rules.add(jl);
  jl = new Rulez_JuliaLike("","FractalLinesOfSymmetry" );  visList.rules.add(jl);
  jl = new Rulez_JuliaLike("","Kaleidoscope3"          );  visList.rules.add(jl);
  jl = new Rulez_JuliaLike("","HyperbolicSquare"         );  visList.rules.add(jl);
  jl = new Rulez_JuliaLike("","HyperbolicPoincareWeave"  );  visList.rules.add(jl);
  jl = new Rulez_JuliaLike("","HyperbolicTruchetTiles"   );  visList.rules.add(jl);
  jl = new Rulez_JuliaLike("","Dodecahedralis7" );  visList.rules.add(jl);
  */
  
  // =========== Prezentable
  jl = new Rulez_JuliaLike("","Dodecahedralis7" );  visList.rules.add(jl);
  //jl = new Rulez_JuliaLike("","GrinningFractal"   );  visList.rules.add(jl);
  //jl = new Rulez_JuliaLike("","Kali2"             );  visList.rules.add(jl);
  //jl = new Rulez_JuliaLike("","TripToSamarkand"   );  visList.rules.add(jl);
  //jl = new Rulez_JuliaLike("","MandelbrotPatternDecoration"      );  visList.rules.add(jl);
  //jl = new Rulez_JuliaLike("","FractalPulse"      );  visList.rules.add(jl);
  //jl = new Rulez_JuliaLike("","InversiveKaleidoscope2"      );  visList.rules.add(jl);
  //jl = new Rulez_JuliaLike("","FractalLinesOfSymmetry" );  visList.rules.add(jl);
  //jl = new Rulez_JuliaLike("","Kaleidoscope3"          );  visList.rules.add(jl);
//jl = new Rulez_JuliaLike("","RotationalFractal"      );  visList.rules.add(jl);
//jl = new Rulez_JuliaLike("","Apolonian"      );  visList.rules.add(jl);
  
  
  
  
  
  
  
  //jl = new Rulez_JuliaLike("","HyperbolicSquare"         );  visList.rules.add(jl);
  //jl = new Rulez_JuliaLike("","Kaleidoscope3"          );  visList.rules.add(jl);
  
  //renderBBT = new Renderer_BondedBodyTree( 2, 300.0 ); render = renderBBT;
  //renderRT  = new Renderer_RotTree       ( 2, 200.0 ); render = renderRT;
  renderFission = new Renderer_ParticleFission(1024);
  
  ffc        = new FlowField_centers(freqs.length);
  renderFlow = new Renderer_FlowField(64,32);
  renderFlow.initCursors();
  renderFlow.ffield = ffc;
  for(int i=0; i<ffc.np; i++){  ffc.set( i, random(100,width-100), random(100,height-100), -random(1000.0), random(-200.0,200.0), random(-100.0,100.0) );  };
  //ffc.set( 0,  400,400, -1000.0, 0.0, 0.0 );
  //ffc.set( 1,  600,600, 0.0, 0.0, 100.0 );
  
  renderChains = new Renderer_SpectralChains( freqs.length, 16 );

  /*
  Rulez_JustRenderer jr; 
  jr = new Rulez_JustRenderer( "FlowField",       renderFlow    );   visList.rules.add(jr);
  jr = new Rulez_JustRenderer( "ParticleFission", renderFission );   visList.rules.add(jr);
  jr = new Rulez_JustRenderer( "spectralChains" , renderChains  );   visList.rules.add(jr);
  */
  
 
  stack = new RenderStack( width, height, context );
  
  // --- Script 1 : ExpansiveReactionDiffusion
  //stack.addImage("noise", "random" );  
  //stack.addShader( "A", "ExpansiveReactionDiffusion_BufA" );
  //stack.addShader( "B", "ExpansiveReactionDiffusion_BufB" );
  //stack.addShader( "C", "ExpansiveReactionDiffusion_BufC" );
  //stack.addShader( "D", "ExpansiveReactionDiffusion_BufD" );
  //stack.addShader( "main", "ExpansiveReactionDiffusion_main" );
  //stack.addScriptLine( "A : A C D noise" );
  //stack.addScriptLine( "B : A" );
  //stack.addScriptLine( "C : B" );
  //stack.addScriptLine( "D : A" );
  //stack.addScriptLine( "main : A C noise" );
  
  /*
  //stack.addShader    ( "main", "Julia" );
  //stack.addShader      ( "main", "Julia_distance1" );
  //stack.addShader    ( "main", "Julia_distance3" );
  //stack.addShader    ( "main", "RationalFractal" );
  //stack.addShader    ( "main", "PersianCarpet" );
  stack.addShader    ( "main", "FractalLinesOfSymmetry" );
  //stack.addShader    ( "main", "Kaleidoscope3" );
  stack.addScriptLine  ( "main :" );
  stack.prepare();
  */
 
  //song.play(0);
  playlist.nextSong();
  visList.next();
  
  if( bRecord ){
    videoExport = new VideoExport(this, "/home/prokop/myVideo.mp4");
    videoExport.setFrameRate(30);  
    videoExport.startMovie();
  }
  
  initControls();
    
}


// ================= DRAW EACH FRAME

void draw() {
  song = playlist.song;
  fft  = playlist.fft; 
  playlist.update();
  int rewindStep = 1000;
  if(hold_skip){ song.skip( rewindStep ); }
  renderSpectrum.update();
     
  /*
  //blendMode(REPLACE);
  //smooth(0); // WARRNING : !!!! Make sure smooth(0) is in  settings(); function !!!!!
  //setupJulia_1();
  setupJulia_2();
  stack.time = frameCount * 0.01;
  stack.render(); ///  BIG RENDER HERE
  */
 
  visList.draw();
 
  //renderSpectrum.draw();

  resetShader(); blendMode(BLEND);
  
  //beater.bDraw=true;
  beater.update(soundPower);
  
  //renderFlow.update();
  //ffc.update();
  //renderFission.update();
  
  if(bDEBUG_DRAW){
    beater.bDraw=true;
    renderSpectrum.draw();
    drawSpectrumPix( pg_debug, fft, frameCount%width, 200, 1.0 );
    image(pg_debug,0,0);
  }else{ beater.bDraw=false; }
  
  if(bHUD){
    
    float szC = 10.0;
    float scC = 400.0;
    stroke (1.);
    fill   (0.);
    float px = width/2  + global_Cx*scC;
    float py = height/2 + global_Cy*scC;
    circle( px, py, szC  );
    
    RulingClass jl = visList.current();
    
    if(sliders!=null) for(int i=0; i<sliders.length; i++){ Control s = sliders[i]; if(s!=null)s.draw(); }
    
    if(mousePressed){
      if      (mouseButton == RIGHT){
        jl.mouseSet( (mouseX-(width/2))/scC, (mouseY-(height/2))/scC );
      }else if (mouseButton == LEFT){
        if( !mouseControl( mouseX,mouseY ) ){
          line( mouseX,mouseY, px,py );
          jl.mousePull( (mouseX-(width/2))/scC, (mouseY-(height/2))/scC );
        }
      }
    }
    applyControls();
    
    float done = song.position()/(float)song.length();  stroke(1,1,1,1); rect(0,height-10,width*done,height);
    //stroke(0,1,1,1);
    noStroke();
    fill(0,1);
    rect( 50,0,800,30);
    fill(1,1);
    //textSize(8);
    text( "Song:       "+playlist.getName(), 50, 15 );
    text( "Visualizer: "+visList .getName(), 50, 27 );
    //text( "Const: "+global_Cx+" "+global_Cy, 50, 40 );
  }
 
  if( bRecord ){
     videoExport.saveFrame();
  }
}

void mousePressed(){
  if(mouseY>(height-10)){   
    float f = (mouseX/(float)width); println( "cue to % "+ (100*f) );
    song.cue( (int)( song.length()*f ) );
  };
}

void keyPressed(){
    // ToDo - use cue() to set position in song by mouse     http://code.compartmental.net/minim/audioplayer_method_cue.html
    if (keyCode == RIGHT ){ hold_skip = true; } 
    if (keyCode == TAB   ){ bHUD = !bHUD; }
    if (keyCode == ENTER ){ visList.next();   } 
    if (key=='`'){ bDEBUG_DRAW=!bDEBUG_DRAW; } 
    //if (key == ' ' ){ song.cue(song.length()+1); playlist.nextSong(); } 
    //if (key == ' ' ){ song.skip(song.length()); playlist.nextSong(); } 
    if (key == ' ' ){ playlist.nextSong(); } 
    //if (key == ' ' ){  playlist.nextSong(); }
    
    if (keyCode == ESC) {
      if(bRecord)videoExport.endMovie();
      exit();
    }
}

void keyReleased(){
    if (keyCode == RIGHT ){ hold_skip = false;  } 
}
