

import ddf.minim.*;
import ddf.minim.analysis.*;
 
Minim minim;
AudioPlayer song;
FFT fft;

final int nfreq = 32;
float [] freqs = new float[nfreq];
float [] ydy   = new float[2];



RenderStack stack;

void setup() {
  
  minim = new Minim(this);
  song = minim.loadFile("/media/prokop/LENOVO/hudba/Hallucinogen-G/LSD.mp3");
  fft = new FFT(song.bufferSize(), song.sampleRate());
  
  
  int nx=400,ny=400;
  size(400, 400, P3D);   
  colorMode(HSB, 100);
  
  
  size(400, 400, P3D);    
  stack = new RenderStack( nx, ny );
  stack.addScriptLine( "Julia 0 = " );
  stack.addScriptLine( "KIFS -1 = 0");
  //stack.addScriptLine( "Julia -1 = " );
  //stack.addScriptLine( "multi_texture -1 = 0 1");
  stack.prepare();
  
  PShader sh = stack.shaders.get("Julia"); 
  shader( sh );
  sh.set("Const", 0.3, 0.43 );
  
  fillTex_and( stack.images.get(0) , 0 );
  //fillTex_and( stack.images.get(1) , 120 );
  //fillTex_sin( stack.images.get(0) , 0.035, 0.02 );
  //fillTex_sin( stack.images.get(1) , 0.045, 0.09 );  
  song.play(0);
    
}

void draw() {

  resetShader();
  
  fft.forward(song.mix);
  stroke( ((frameCount)&0xff), 255, 255);
  //drawSpectrum( fft, height*0.9, 3.0, 0.7 );
  downSampleSpectrum( fft, freqs );
  float scx = 12.0;
  float scy = 0.3;
  float y0  = height*0.9;
  drawFreqs( freqs, y0, scy, scx );
  linearFit(freqs, 2,15, ydy );
  stroke( 255, 0, 255);
  //line( 3*scx, y0-ydy[0]*scy, 12*scx, y0-(ydy[0]+((12-3)*ydy[1]))*scy );
  line( 2*scx, y0-ydy[0]*scy, 15*scx, y0-ydy[1]*scy );
  fill(0,0,0,5);
  rect(0,0,width,height);
   
  PShader sh = stack.shaders.get("Julia"); 
  shader( sh );
  sh.set("Const", 0.2-ydy[0]*0.005, 0.2-ydy[1]*0.005 );
  
  stack.time = frameCount* 0.01;
  textureWrap(REPEAT);
  stack.render();
  
 
}
