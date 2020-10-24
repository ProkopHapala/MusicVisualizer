add_library( Noise    OBJECT Noise.cpp    )
add_library( Mesh     OBJECT Mesh.cpp  )

file(GLOB math_HEADERS_ *.h )
add_custom_target(math_headers SOURCES ${math_HEADERS_} )
