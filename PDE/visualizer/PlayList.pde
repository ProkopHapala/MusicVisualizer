
import java.io.FileFilter;

final FileFilter fileFilder_dir = new FileFilter() { boolean accept(File f) {return f.isDirectory();              } };
final FileFilter fileFilder_mp3 = new FileFilter() { boolean accept(File f) {return f.getName().endsWith(".mp3"); } };

class PlayList{

  boolean bShuffle = true;
  int songIndex    = 0;
  ArrayList<String> list;
  AudioPlayer song;
  FFT         fft;

PlayList(){
  list = new ArrayList<String>();
} 

String getName(){ return list.get(songIndex); };
 
void addDirRecur( String path, int level ){
  File folder  = dataFile(path);
  File[] files = folder.listFiles(fileFilder_mp3);
  File[] dirs  = folder.listFiles(fileFilder_dir);
  for(int i=0; i<files.length; i++){
      String name=files[i].getPath();
      // println( "["+i+"] "+name);
      list.add(name);
  }
  if(level<=0) return;
  for(int i=0; i<dirs.length; i++){ addDirRecur( dirs[i].getPath(), level-1 ); }
}

void nextSong(){
  int n = list.size();
  // see https://forum.processing.org/two/discussion/16413/minim-pause-does-not-work
  if(song!=null){
    song.pause();
    song.close();
  }
  //for (final ddf.minim.AudioSource s : songs)  s.close();
  if(bShuffle){
    songIndex = (int)random(n);
  }else{
    songIndex=(songIndex+1)%n;
  }
  String name = list.get(songIndex);
  println( "nextSong() :  "+name);
  song = minim.loadFile(name);
  fft  = new FFT(song.bufferSize(), song.sampleRate());
  song.play(0);
};

void update(){
  if(song!=null){ if(!song.isPlaying()){
    println( "finished :  ",  list.get(songIndex) );
    nextSong(); 
  };
  }else{ nextSong(); }
}

};
