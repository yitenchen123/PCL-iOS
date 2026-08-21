# depends/

此目录包含PCL-iOS运行时所需的预打包库和资源。

## 目录结构

```
depends/
├── java-8-openjdk/      # Azul Zulu JRE 8 for iOS arm64
├── java-17-openjdk/     # Azul Zulu JRE 17 for iOS arm64
├── java-21-openjdk/     # Azul Zulu JRE 21 for iOS arm64
├── java-25-openjdk/     # Azul Zulu JRE 25 for iOS arm64
├── libs/                # LWJGL3 JARs + 其他库
│   ├── lwjgl.jar
│   ├── lwjgl-opengl.jar
│   ├── lwjgl-openal.jar
│   ├── lwjgl-glfw.jar
│   ├── lwjgl-stb.jar
│   ├── lwjgl-nanovg.jar
│   ├── lwjgl-jemalloc.jar
│   ├── lwjgl-tinyfd.jar
│   ├── lwjgl-vulkan.jar
│   ├── lwjgl-callback-descriptor.jar
│   ├── lwjgl-input.jar
│   ├── lwjgl-system.jar
│   ├── lwjgl-util.jar
│   ├── gson-2.13.1.jar
│   ├── jsr305.jar
│   └── arc_dns_injector.jar
├── libs_caciocavallo/   # Java 8 AWT桥接
│   ├── cacio-shared-1.10-SNAPSHOT.jar
│   ├── cacio-androidnw-1.10-SNAPSHOT.jar
│   └── ResConfHack.jar
├── libs_caciocavallo17/  # Java 17+ AWT桥接
│   ├── cacio-shared-1.10-SNAPSHOT.jar
│   ├── cacio-androidnw-1.10-SNAPSHOT.jar
│   └── ResConfHack.jar
└── Frameworks/          # iOS原生dylib
    ├── libgl4es_114.dylib      # GL4ES渲染器
    ├── libtinygl4angle.dylib   # MetalANGLE渲染器
    ├── libmobileglues.dylib    # MobileGlues渲染器
    ├── libOSMesa.8.dylib       # OSMesa软件渲染
    ├── libltw.dylib            # LTW渲染器
    ├── libglfw.dylib           # GLFW窗口/输入
    ├── libSDL3.dylib           # SDL3游戏控制器
    ├── libopenal.dylib         # OpenAL音频
    ├── libMoltenVK.dylib       # Vulkan支持
    ├── libawt_headless.dylib   # AWT无头模式
    ├── libawt_xawt.dylib       # AWT X11桥接
    └── libspirv-cross.dylib    # SPIRV交叉编译
```

## 如何获取

参考 [Amethyst-iOS-MyRemastered](https://github.com/herbrine8403/Amethyst-iOS-MyRemastered) 的Makefile:

1. **JRE**: 下载Azul Zulu JDK for iOS arm64 (通过Makefile的`jre`目标)
2. **LWJGL**: PojavLauncherTeam定制版LWJGL3
3. **dylib**: 通过CMake交叉编译iOS arm64
4. **caciocavallo**: 从源码编译Java 8/17兼容版本
