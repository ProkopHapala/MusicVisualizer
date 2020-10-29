
void fillTex_and( PGraphics pg, int c ){
  pg.loadPixels();
  int nx =pg.width;
  for(int iy=0;iy<pg.height; iy++){
    int icy=iy^c;
    for(int ix=0;ix<nx; ix++){
      int i = iy*nx + ix;  
      pg.pixels[i] = color(ix^icy, 0, 0);
    };
  }
  pg.updatePixels();
}

void fillTex_sin( PGraphics pg, float fx, float fy ){
  pg.loadPixels();
  int nx =pg.width;
  for(int iy=0;iy<pg.height; iy++){
    for(int ix=0;ix<nx; ix++){
      int i = iy*nx + ix;  
      float wave = sin(ix*fx)*sin(iy*fy)*0.5 + 0.5;
      pg.pixels[i] = color( wave*255 );
    };
  }
  pg.updatePixels();
}

void downSampleSpectrum( FFT fft, float [] freqs ){
  float step = (freqs.length-1)/(float)fft.specSize();
  for(int i=0; i<freqs.length; i++){ freqs[i]=0; }
  for(int i=0; i<fft.specSize(); i++){
    float  x  = i*step;
    int   ix  = (int)x;
    float dx  = x-ix;
    float val =  fft.getBand(i)   * step *(i+1);
    freqs[ix  ] += val*(1-dx);
    freqs[ix+1] += val*dx;
  }
}

void drawSpectrum( FFT fft, float y0, float scy, float scx ){
  float oy = fft.getBand(0);
  for(int i = 1; i < fft.specSize(); i++){
    float y = fft.getBand(i)*i;
    line( (i-1)*scx, y0-oy*scy, i*scx, y0-y*scy );
    oy=y;
  }
}

void drawFreqs( float [] freqs, float y0, float scy, float scx ){
  float oy = fft.getBand(0);
  for(int i = 1; i < freqs.length; i++){
    float y = freqs[i];
    line( (i-1)*scx, y0-oy*scy, i*scx, y0-y*scy );
    oy=y;
  }
}


void linearFit(float [] freqs, int i0, int imax, float [] ydy ){
  float y0 = 0;
  float dy = 0;
  int n = imax-i0;
  float w = 1./n;
  for(int i=i0;i<imax;i++){
    float y =  freqs[i];
    y0 += y;
    dy += y*(i-i0);
  }
  dy -= 0.5*(i0+imax)*y0;
  dy*=w;
  y0*=w;
  //ydy[0]=y0;
  ydy[0]=y0-dy*0.5;
  ydy[1]=y0+dy*0.5;
}
