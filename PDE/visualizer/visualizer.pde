
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


*/


// ================= Libraries

import java.nio.ByteBuffer;

import ddf.minim.*;
import ddf.minim.analysis.*;

import com.jogamp.opengl.GL2;
import com.thomasdiewald.pixelflow.java.DwPixelFlow;
import com.thomasdiewald.pixelflow.java.dwgl.DwGLTexture;
import com.thomasdiewald.pixelflow.java.imageprocessing.DwShadertoy;

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

Renderer_BondedBodyTree  renderBBT; 
Renderer_RotTree         renderRT;
MusicRenderer            render; 
Renderer_ParticleFission renderFission;
Renderer_Spectrum        renderSpectrum;

float dt          = 0.025;
//float dt          = 1.0;
float KCoul       = 1.0;
//float dt        = 0.025;
float friction    = 0.02;
float fissionProb = 0.05;
float dieProb     = 0.00001;
float qSpread = 0.7;
float qConv   = 0.5;
float mMargin = 0.3;

boolean bDraw = true;

boolean hold_skip = false;


// ================= INITIALIZE PROGRAM

void settings() {
  size(800, 800, P2D);
  smooth(0);
}

void setup() {
  colorMode(HSB, 1.0);  
  ellipseMode(CENTER);
  
  //minim = new Minim(this);
  //song = minim.loadFile("/home/prokop/git/MusicVisualizer/resources/BoxCat_Games_10_Epic_Song.mp3");
  //song = minim.loadFile("/media/prokop/LENOVO/hudba/Hallucinogen-G/LSD.mp3");
  //fft = new FFT(song.bufferSize(), song.sampleRate());
  
  minim = new Minim(this);
  playlist = new PlayList();
  playlist.list.add( "/home/prokop/git/MusicVisualizer/resources/BoxCat_Games_10_Epic_Song.mp3" );
  //playlist.addDirRecur( "D:\\hudba\\Basil Poledouris", 10 );
  //playlist.addDirRecur( "/media/prokop/LENOVO/hudba/Basil Poledouris", 10 );
  
  beater = new BeatDetector();
  beater.k1        = 0.3;
  beater.k2        = 0.03;
  beater.triggerUp = 2.5;
  
  renderSpectrum = new Renderer_Spectrum();
  
  //renderBBT = new Renderer_BondedBodyTree( 2, 300.0 ); render = renderBBT;
  //renderRT  = new Renderer_RotTree       ( 2, 200.0 ); render = renderRT;
  renderFission = new Renderer_ParticleFission(1024);
  
  context = new DwPixelFlow(this);
  context.print();
  context.printGL();
    
  stack = new RenderStack( width, height, context );
  stack.addImage("noise", "random" );  
  stack.addShader( "A", "ExpansiveReactionDiffusion_BufA" );
  stack.addShader( "B", "ExpansiveReactionDiffusion_BufB" );
  stack.addShader( "C", "ExpansiveReactionDiffusion_BufC" );
  stack.addShader( "D", "ExpansiveReactionDiffusion_BufD" );
  stack.addShader( "main", "ExpansiveReactionDiffusion_main" );
  stack.addScriptLine( "A : A C D noise" );
  stack.addScriptLine( "B : A" );
  stack.addScriptLine( "C : B" );
  stack.addScriptLine( "D : A" );
  stack.addScriptLine( "main : A C noise" );
  //stack.addScriptLine( "main :" );
  
  stack.prepare();
 
  //song.play(0);
  playlist.nextSong();
  
}


// ================= DRAW EACH FRAME

void draw() {
  song = playlist.song;
  fft  = playlist.fft; 
  
  //blendMode(REPLACE);    
  //stack.time = frameCount* 0.01;
  //stack.render(); ///  BIG RENDER HERE
  
  resetShader();
  
  fill(0,0,1,0.01); rect(0,0,width,height);
  
  renderSpectrum.update();
  //renderSpectrum.draw();
  
  renderFission.update();
  beater.update(soundPower);
  
  
}
