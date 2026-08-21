# PCL-iOS Native dylib Cross-Compilation
# Based on Amethyst-iOS-MyRemastered CMakeLists.txt
# Targets iOS arm64 (iPhone/iPad)

cmake_minimum_required(VERSION 3.21)
project(PCLiOS-Native C CXX ASM)

# iOS Platform Settings
set(CMAKE_SYSTEM_NAME iOS)
set(CMAKE_OSX_ARCHITECTURES arm64)
set(CMAKE_OSX_DEPLOYMENT_TARGET "14.0")
set(CMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH NO)

# Find toolchain
set(CMAKE_C_COMPILER clang)
set(CMAKE_CXX_COMPILER clang++)
set(CMAKE_ASM_COMPILER clang)

# Common flags for iOS
set(IOS_FLAGS "-miphoneos-version-min=14.0 -fembed-bitcode")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${IOS_FLAGS}")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${IOS_FLAGS}")
set(CMAKE_ASM_FLAGS "${CMAKE_ASM_FLAGS} ${IOS_FLAGS}")

# Output directory
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# Include generated config
configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/config.h.in
    ${CMAKE_BINARY_DIR}/include/config.h
)

# === AWT/Caciocavallo (from PojavLauncherTeam) ===
# These are stub libraries for Java AWT headless support

add_library(awt_headless
   Sources/Native/cacio/cacio-dim.c
)

add_library(awt_xawt
    Sources/Native/cacio/cacio.c
    Sources/Native/cacio/cacio_awt_pivot.c
)

# === GL4ES (OpenGL ES 1.1.4 wrapper) ===
# Source: https://github.com/PojavLauncherTeam/gl4es

add_library(gl4es_114
    Sources/Native/gl4es/src/gl/build_info.c
    Sources/Native/gl4es/src/gl/gl4es.c
    Sources/Native/gl4es/src/gl/matvec.c
)

target_include_directories(gl4es_114 PRIVATE
    Sources/Native/gl4es/include
    Sources/Native/gl4es/src/gl
)

target_compile_definitions(gl4es_114 PRIVATE
    GLES1=1
    NO_OMIT_FRAMEBUFFER
)

# === MetalANGLE wrapper ===
# Provides OpenGL ES via Metal

add_library(tinygl4angle
    Sources/Native/metalangle_wrapper.mm
)

target_link_libraries(tinygl4angle
    "-framework Metal"
    "-framework MetalKit"
    "-framework QuartzCore"
    "-framework UIKit"
    "-framework Foundation"
)

# === MobileGlues (GL/Vulkan wrapper) ===

add_library(mobileglues
    Sources/Native/mobileglues/bridge.c
    Sources/Native/mobileglues/config.c
)

target_include_directories(mobileglues PRIVATE
    Sources/Native/mobileglues/include
)

# === OSMesa (Software rendering) ===

add_library(OSMesa
    Sources/Native/osmesa/src/api.c
    Sources/Native/osmesa/src/render.c
)

target_include_directories(OSMesa PRIVATE
    Sources/Native/osmesa/include
)

# === LTW (LWJGL Toolkit Wrapper) ===

add_library(ltw
    Sources/Native/ltw/ltw.c
)

target_include_directories(ltw PRIVATE
    Sources/Native/ltw
)

# === GLFW (bundled for iOS) ===
# Source: https://github.com/glfw/glfw (iOS port)

find_package(glfw3 QUIET)
if (NOT glfw3_FOUND)
    add_subdirectory(Sources/Native/glfw)
endif()

# === MoltenVK (Vulkan-to-Metal) ===
# dylib placed in Frameworks, not built from source

# === CurseForge API Key ===
# Defined in config.h.in, set from Makefile

# === LWJGL Natives (not built, bundled as dylib) ===
# Sources:
# - lwjgl.dylib
# - lwjgl_opengl.dylib
# - lwjgl_stb.dylib
# - lwjgl_openal.dylib
# - lwjgl_tinyfd.dylib

# === Install rules ===
install(TARGETS
    awt_headless
    awt_xawt
    gl4es_114
    tinygl4angle
    mobileglues
    OSMesa
    ltw
    DESTINATION Frameworks
)

# === Summary ===
message(STATUS "")
message(STATUS "=== PCL-iOS Native Build Configuration ===")
message(STATUS "  System:           iOS arm64")
message(STATUS "  Deployment target: 14.0")
message(STATUS "  Build type:       ${CMAKE_BUILD_TYPE}")
message(STATUS "  Output:           ${CMAKE_BINARY_DIR}/lib")
message(STATUS "  CurseForge Key:   ${CONFIG_CURSEFORGE_API_KEY}")
message(STATUS "")
