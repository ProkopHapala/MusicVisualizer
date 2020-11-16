

class BeatDetector{
  float k1 = 0.3; // signal pre smoothing
  float k2 = 0.05; // singnal beat
  float oP,ooP;
  float beat;
  float triggerUp   = 2.5;
  float triggerDown = 1.2;
  boolean bBeat = false;
  boolean bJustBeat = false;
  boolean bDraw = false;
  
  void update(float P){
    
    float oP_ =oP;
    float ooP_=ooP;
   
    oP  = oP *(1-k1) +  P*k1; // smoother
    ooP = ooP*(1-k2) + oP*k2; // 
    beat = oP/ooP;
    if      (beat>triggerUp  ){ if(bBeat){bJustBeat=false;}else{bJustBeat=true;}; bBeat=true; }
    else if (beat<triggerDown){ bBeat=false; bJustBeat=false; }
  
    if(bDraw){
       int frame = frameCount%width;
       float sc = 0.0005;
       stroke(0);       line(frame,0,frame,P*sc);
       strokeWeight(2.0);
       stroke(1.0,1.0,1.0); line(frame-1, oP_*sc,frame,oP*sc);
       stroke(0.5,1.0,1.0); line(frame-1,ooP_*sc,frame,ooP*sc);
        if( bJustBeat ){
          //println(  "beat "+frame +" "+ooP );
          fill  (0.8,1.0,1.0);
          stroke(0.8,1.0,1.0);  
          ellipse( frame, ooP*sc, 10, 10 );
        }
     }
  }
};
