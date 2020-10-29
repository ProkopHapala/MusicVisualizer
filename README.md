# Music Visualizer

Modular and modern stand-alone music visualization engine. It is inspired by [WinAmp Advanced Visualization Studio (AVS)](https://en.wikipedia.org/wiki/Advanced_Visualization_Studio) but tries to use power of modern GPUs and fragment shaders from [ShaderToy.com](https://www.shadertoy.com/)

* Similarily to AVS this is rather engine to create user-made visualization by combination of independent modules
   * There are two types of modules
      1. CPU based vertex-renderes which define where OpenGL primitives (dots,lines,trinagnes) are rendered. 
         * This is used e.g. to render spectrum or particle systems etc.
      2. GPU/GLSL fragment shaders from ShaderToy which stack multiple render passes
         *  These can render per-pixel RayTraced objects (like 2D/3D fractal Julia Set etc.)
         *  It also provide texture deformation, kaleidoscope-effects etc.
         *  It can even implement partial-differential equation solver to simulate effects like Fluid, Fire, Turbulence, Waves, Diffusion-Reaction system
   * The input for these renderers and shaders are mostly power-spectrum of the sound-waveform which are obtained by means of fast fourier transform (FFT) from the .mp3 stream
   * The visualization should be created as simple scripts which determine how to combine (i.e. stack-on top of each other) various CPU Renderes and GPU shaders (which replace AVS visual editor)
   * Beside these high-level scripts Fine (low-level) control is provided by user defined GLSL framgnet/vertex shaders shaders and small  C/C++ sniplets which define behaviour of CPU renderers


## Dependencies

* SDL2
* SDL2-mixer
* GLEW
* OpenGL 4+

## Compilation

with cmake + g++ installed
```
mkdir Build
cd Build
cmake ..
make
```

## Screenshots

[![Watch the video](https://img.youtube.com/vi/quMz625TYCM/maxresdefault.jpg)](https://www.youtube.com/watch?v=dTpNaFz9zPQ&list=PLEwmvwH6XHeGbY14T-sUEgAvObu1LMy-m&index=3)

* https://www.youtube.com/watch?v=quMz625TYCM
* https://www.youtube.com/watch?v=dTpNaFz9zPQ&list=PLEwmvwH6XHeGbY14T-sUEgAvObu1LMy-m&index=3
