# depends/

预打包库和资源 - 参考 [Amethyst-iOS-MyRemastered](https://github.com/herbrine8403/Amethyst-iOS-MyRemastered) 构建

## Java JRE 下载链接

从 Amethyst Makefile 获取的实际下载地址：

```
# Azul Zulu JRE for iOS arm64 (由 AngelAuraMC 项目预编译)
Java 8:  https://assets.angelauramc.dev/openjdk/ios-arm64/jre8-ios-aarch64.zip
Java 17: https://assets.angelauramc.dev/openjdk/ios-arm64/jre17-ios-aarch64.zip
Java 21: https://assets.angelauramc.dev/openjdk/ios-arm64/jre21-ios-aarch64.zip
Java 25: https://assets.angelauramc.dev/openjdk/ios-arm64/jre25-ios-aarch64.zip
```

下载后解压到对应目录：
```
depends/java-8-openjdk/
depends/java-17-openjdk/
depends/java-21-openjdk/
depends/java-25-openjdk/
```

## 目录结构

```
depends/
├── java-8-openjdk/      # JRE 8 (MC 1.16及以下)
├── java-17-openjdk/     # JRE 17 (MC 1.17-1.20.x)
├── java-21-openjdk/     # JRE 21 (MC 1.21+)
├── java-25-openjdk/     # JRE 25 (未来版本)
├── libs/                # LWJGL3 JARs (PojavLauncherTeam定制版)
│   ├── lwjgl.jar
│   ├── lwjgl-opengl.jar
│   ├── lwjgl-openal.jar
│   ├── lwjgl-glfw.jar       # GLFW窗口/输入
│   ├── lwjgl-stb.jar
│   ├── lwjgl-nanovg.jar
│   ├── lwjgl-jemalloc.jar
│   ├── lwjgl-tinyfd.jar
│   ├── lwjgl-vulkan.jar     # Vulkan支持
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
└── Frameworks/          # iOS原生dylib (CMake交叉编译)
    ├── libgl4es_114.dylib      # GL4ES渲染器 (OpenGL ES)
    ├── libtinygl4angle.dylib   # MetalANGLE渲染器 (Metal)
    ├── libmobileglues.dylib    # MobileGlues渲染器 (Vulkan→Metal)
    ├── libOSMesa.8.dylib       # OSMesa软件渲染
    ├── libltw.dylib            # LTW渲染器
    ├── libglfw.dylib           # GLFW窗口创建/输入
    ├── libopenal.dylib         # OpenAL音频
    ├── libMoltenVK.dylib       # Vulkan→Metal转译
    ├── libawt_headless.dylib   # AWT无头模式
    ├── libawt_xawt.dylib       # AWT X11桥接
    └── libspirv-cross.dylib    # SPIRV交叉编译
```

## LWJGL库列表 (PojavLauncherTeam定制版)

```
lwjgl.jar                  - 核心库
lwjgl-opengl.jar           - OpenGL绑定
lwjgl-openal.jar           - OpenAL音频
lwjgl-glfw.jar             - GLFW窗口/输入管理
lwjgl-stb.jar              - STB图像/字体
lwjgl-nanovg.jar           - NanoVG矢量图形
lwjgl-jemalloc.jar         - jemalloc内存分配器
lwjgl-tinyfd.jar           - 文件对话框
lwjgl-vulkan.jar           - Vulkan绑定
lwjgl-callback-descriptor.jar - 回调描述符
lwjgl-input.jar            - 输入处理
lwjgl-system.jar           - 系统工具
lwjgl-util.jar             - 工具类
```

## 渲染器与dylib对应关系

| 渲染器 | dylib | 后端 |
|--------|-------|------|
| GL4ES | libgl4es_114.dylib | OpenGL ES 3.0 |
| ANGLE | libtinygl4angle.dylib | Metal |
| MobileGlues | libmobileglues.dylib | Vulkan→Metal (MoltenVK) |
| Zink | libOSMesa.8.dylib + libMoltenVK.dylib | Vulkan→Metal |
| Vulkan | libMoltenVK.dylib | Vulkan→Metal |
| LTW | libltw.dylib | Metal |

## CurseForge API Key

CurseForge API Key 运行时设置（参考 Amethyst CurseForgeAPIKeyViewController）：
- 用户可在启动器设置中自定义 API Key
- 默认 Key 通过 CMake 注入（config.h），Makefile 传递：
  ```
  make CONFIG_CURSEFORGE_API_KEY="$2a$10$..."
  ```
- 存储在NSUserDefaults，Key: `PCLCurseForgeAPIKey`

## 构建流程 (参考Amethyst Makefile)

```bash
# 1. 下载JRE
make jre

# 2. 编译native dylib (CMake交叉编译)
make native

# 3. 编译Java代码
make java

# 4. 编译资源
make assets

# 5. 打包app
make payload

# 6. 打包IPA
make package
```
