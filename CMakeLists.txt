cmake_minimum_required ( VERSION 2.8 )
project ( MusicVisualizer )

# ==== FLAGS

set(default_build_type Release)

SET( CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -std=c++17" )
# https://stackoverflow.com/questions/7724569/debug-vs-release-in-cmake
message ( "CMAKE_BUILD_TYPE   ${CMAKE_BUILD_TYPE}  " )
SET( IGNORE_WARRNING_FLAGS "-Wno-maybe-uninitialized -Wno-char-subscripts -Wno-write-strings -Wno-format -Wno-parentheses -Wno-unused-but-set-variable  -Wno-narrowing -Wno-unused-result  -Wno-sign-compare -Wno-strict-aliasing -Wno-unused-variable -Wno-unused-value -Wno-comment -Wno-misleading-indentation " )
SET( WARRNING_TO_ERROR "-Werror=return-type")

#SET( AXULIARY_COMPILE_FLAGS "-O2 -fPIC -march=native " )
SET( AXULIARY_COMPILE_FLAGS "-g -Og -fPIC -fno-strict-aliasing ")
SET( CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS} ${AXULIARY_COMPILE_FLAGS} ${IGNORE_WARRNING_FLAGS} ${WARRNING_TO_ERROR}" )
message ( "CMAKE_CXX_FLAGS " ${CMAKE_CXX_FLAGS} )

# ==== DIRS

SET( MY_SRC_DIR    "${CMAKE_SOURCE_DIR}" )
SET( MY_BIN_SHARE  "${MY_SRC_DIR}/Build"       )

SET( COMMON_SRCS      "${MY_SRC_DIR}/common"     )
SET( COMMON_RESOURCES "${MY_SRC_DIR}/resources"       )
SET( COMMON_SHADERS   "${MY_SRC_DIR}/resources/shaders" )

include_directories(
        ${COMMON_SRCS}
        ${COMMON_SRCS}/math
        ${COMMON_SRCS}/utils
        ${COMMON_SRCS}/SDL2OGL3
)

set( CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_SOURCE_DIR}/cmake_utils )

file (GLOB_RECURSE _COMMON_SRCS_     ${COMMON_SRCS}/*.h     ${COMMON_SRCS}/*.cpp     ${COMMON_SRCS}/*.c     )
file (GLOB_RECURSE _COMMON_SHADERS_  ${COMMON_SHADERS}/*.glslv  ${COMMON_SHADERS}/*.glslf    )

# ==== BUILD TARGETS

find_package( OpenGL REQUIRED )
find_package( GLU    REQUIRED )
find_package( SDL2   REQUIRED )

add_subdirectory( ${MY_SRC_DIR}/common   ${MY_BIN_SHARE}/common    )
add_subdirectory( ${MY_SRC_DIR}/MusicVisualizer         )
