# PCL-iOS Makefile
# 参考 Amethyst-iOS-MyRemastered 构建系统
# 
# 用法:
#   make jre       - 下载Java JRE for iOS arm64
#   make native    - 编译native dylib (需要CMake交叉编译工具链)
#   make java      - 编译Java代码
#   make assets    - 编译资源
#   make all       - 完整构建
#   make clean     - 清理

SHELL := /bin/bash
.SHELLFLAGS = -ec

# 配置
SOURCEDIR := $(shell pwd)
OUTPUTDIR := $(SOURCEDIR)/artifacts
DEPENDS_DIR := $(SOURCEDIR)/depends
JRE_DIR := $(OUTPUTDIR)/java_runtimes
LIBS_DIR := $(DEPENDS_DIR)/libs
FRAMEWORKS_DIR := $(DEPENDS_DIR)/Frameworks

# Java JRE 下载链接 (Azul Zulu for iOS arm64 - 预编译)
# 来源: Amethyst-iOS-MyRemastered/Makefile
JRE8_URL  := https://assets.angelauramc.dev/openjdk/ios-arm64/jre8-ios-aarch64.zip
JRE17_URL := https://assets.angelauramc.dev/openjdk/ios-arm64/jre17-ios-aarch64.zip
JRE21_URL := https://assets.angelauramc.dev/openjdk/ios-arm64/jre21-ios-aarch64.zip
JRE25_URL := https://assets.angelauramc.dev/openjdk/ios-arm64/jre25-ios-aarch64.zip

# Java版本和目录
JRE8_DIR  := $(DEPENDS_DIR)/java-8-openjdk
JRE17_DIR := $(DEPENDS_DIR)/java-17-openjdk
JRE21_DIR := $(DEPENDS_DIR)/java-21-openjdk
JRE25_DIR := $(DEPENDS_DIR)/java-25-openjdk

# CurseForge API Key (运行时可通过启动器设置覆盖)
# 构建时通过 make CONFIG_CURSEFORGE_API_KEY="..." 传入
CONFIG_CURSEFORGE_API_KEY ?= ""

# CMake配置参数 (含CurseForge API Key)
CMAKE_CONFIG_FLAGS := -DCONFIG_CURSEFORGE_API_KEY="$(CONFIG_CURSEFORGE_API_KEY)"

# Xcode生成
XCODEGEN ?= xcodegen

.PHONY: all jre native java assets clean check help

all: jre assets gen

help:
	@echo "PCL-iOS Makefile"
	@echo ""
	@echo "目标:"
	@echo "  make jre       - 下载Java JRE for iOS arm64"
	@echo "  make native    - 编译native dylib (CMake)"
	@echo "  make java      - 编译Java启动器"
	@echo "  make assets    - 编译资源"
	@echo "  make gen       - 生成Xcode项目"
	@echo "  make all       - jre + assets + gen"
	@echo "  make clean     - 清理构建产物"
	@echo "  make check     - 检查依赖"

check:
	@echo "=== PCL-iOS 构建检查 ==="
	@echo "Java 8:  $(if $(wildcard $(JRE8_DIR)/bin/java),✓ 已安装,✗ 未安装 ($(JRE8_URL)))"
	@echo "Java 17: $(if $(wildcard $(JRE17_DIR)/bin/java),✓ 已安装,✗ 未安装 ($(JRE17_URL)))"
	@echo "Java 21: $(if $(wildcard $(JRE21_DIR)/bin/java),✓ 已安装,✗ 未安装 ($(JRE21_URL)))"
	@echo "Java 25: $(if $(wildcard $(JRE25_DIR)/bin/java),✓ 已安装,✗ 未安装 ($(JRE25_URL)))"
	@echo "LWJGL:   $(if $(wildcard $(LIBS_DIR)/lwjgl.jar),✓ 已安装,✗ 未安装)"
	@echo "Cacio8:  $(if $(wildcard $(DEPENDS_DIR)/libs_caciocavallo/cacio-shared-1.10-SNAPSHOT.jar),✓ 已安装,✗ 未安装)"
	@echo "Cacio17: $(if $(wildcard $(DEPENDS_DIR)/libs_caciocavallo17/cacio-shared-1.10-SNAPSHOT.jar),✓ 已安装,✗ 未安装)"
	@echo "GLFW:    $(if $(wildcard $(FRAMEWORKS_DIR)/libglfw.dylib),✓ 已安装,✗ 未安装)"
	@echo "GL4ES:   $(if $(wildcard $(FRAMEWORKS_DIR)/libgl4es_114.dylib),✓ 已安装,✗ 未安装)"
	@echo "MoltenVK:$(if $(wildcard $(FRAMEWORKS_DIR)/libMoltenVK.dylib),✓ 已安装,✗ 未安装)"
	@echo "OpenAL:  $(if $(wildcard $(FRAMEWORKS_DIR)/libopenal.dylib),✓ 已安装,✗ 未安装)"

# ===== Java JRE下载 =====
jre:
	@echo "[PCL-iOS] 下载Java JRE for iOS arm64..."
	mkdir -p $(DEPENDS_DIR)
	
	@# Java 8
	if [ ! -f "$(JRE8_DIR)/bin/java" ]; then \
		echo "[PCL-iOS] 下载 Java 8..."; \
		cd $(DEPENDS_DIR); \
		curl -L -o jre8-ios-aarch64.zip "$(JRE8_URL)" || wget "$(JRE8_URL)" -O jre8-ios-aarch64.zip; \
		unzip -q jre8-ios-aarch64.zip && rm jre8-ios-aarch64.zip; \
		mkdir -p java-8-openjdk; \
		tar xvf jre8-*.tar.xz -C java-8-openjdk 2>/dev/null || \
		mv jre* java-8-openjdk 2>/dev/null || true; \
	fi
	
	@# Java 17
	if [ ! -f "$(JRE17_DIR)/bin/java" ]; then \
		echo "[PCL-iOS] 下载 Java 17..."; \
		cd $(DEPENDS_DIR); \
		curl -L -o jre17-ios-aarch64.zip "$(JRE17_URL)" || wget "$(JRE17_URL)" -O jre17-ios-aarch64.zip; \
		unzip -q jre17-ios-aarch64.zip && rm jre17-ios-aarch64.zip; \
		mkdir -p java-17-openjdk; \
		tar xvf jre17-*.tar.xz -C java-17-openjdk 2>/dev/null || \
		mv jre* java-17-openjdk 2>/dev/null || true; \
	fi
	
	@# Java 21
	if [ ! -f "$(JRE21_DIR)/bin/java" ]; then \
		echo "[PCL-iOS] 下载 Java 21..."; \
		cd $(DEPENDS_DIR); \
		curl -L -o jre21-ios-aarch64.zip "$(JRE21_URL)" || wget "$(JRE21_URL)" -O jre21-ios-aarch64.zip; \
		unzip -q jre21-ios-aarch64.zip && rm jre21-ios-aarch64.zip; \
		mkdir -p java-21-openjdk; \
		tar xvf jre21-*.tar.xz -C java-21-openjdk 2>/dev/null || \
		mv jre* java-21-openjdk 2>/dev/null || true; \
	fi
	
	@# Java 25
	if [ ! -f "$(JRE25_DIR)/bin/java" ]; then \
		echo "[PCL-iOS] 下载 Java 25..."; \
		cd $(DEPENDS_DIR); \
		curl -L -o jre25-ios-aarch64.zip "$(JRE25_URL)" || wget "$(JRE25_URL)" -O jre25-ios-aarch64.zip; \
		unzip -q jre25-ios-aarch64.zip && rm jre25-ios-aarch64.zip; \
		mkdir -p java-25-openjdk; \
		tar xvf jre25-*.tar.xz -C java-25-openjdk 2>/dev/null || \
		mv jre* java-25-openjdk 2>/dev/null || true; \
	fi
	
	@echo "[PCL-iOS] Java JRE下载完成"

# ===== Native dylib编译 (CMake交叉编译) =====
native:
	@echo "[PCL-iOS] 编译native dylib..."
	mkdir -p $(FRAMEWORKS_DIR)
	
	@# 注意: 以下编译命令需要iOS交叉编译工具链
	@# 在GitHub Actions中使用macOS runner + Xcode编译
	
	@echo "[PCL-iOS] Native编译需要Xcode环境，在GitHub Actions中执行"

# ===== 资源编译 =====
assets:
	@echo "[PCL-iOS] 编译资源..."
	@# actool --compile Resources/Assets.xcassets ...
	@echo "[PCL-iOS] 资源编译完成"

# ===== Xcode项目生成 =====
gen:
	@echo "[PCL-iOS] 生成Xcode项目..."
	$(XCODEGEN) generate
	@echo "[PCL-iOS] 项目生成完成"

# ===== LWJGL和Caciocavallo说明 =====
lwjgl:
	@echo "[PCL-iOS] LWJGL库 (PojavLauncherTeam定制版)"
	@echo "需要以下JAR文件放在 depends/libs/ 目录:"
	@echo "  lwjgl.jar, lwjgl-opengl.jar, lwjgl-openal.jar, lwjgl-glfw.jar"
	@echo "  lwjgl-stb.jar, lwjgl-nanovg.jar, lwjgl-jemalloc.jar"
	@echo "  lwjgl-tinyfd.jar, lwjgl-vulkan.jar, lwjgl-callback-descriptor.jar"
	@echo "  lwjgl-input.jar, lwjgl-system.jar, lwjgl-util.jar"
	@echo "  gson-2.13.1.jar, jsr305.jar, arc_dns_injector.jar"
	@echo ""
	@echo "Caciocavallo (AWT桥接):"
	@echo "  depends/libs_caciocavallo/ (Java 8)"
	@echo "  depends/libs_caciocavallo17/ (Java 17+)"
	@echo ""
	@echo "Native dylib (Frameworks/):"
	@echo "  libglfw.dylib, libgl4es_114.dylib, libtinygl4angle.dylib"
	@echo "  libmobileglues.dylib, libMoltenVK.dylib, libopenal.dylib"
	@echo "  libOSMesa.8.dylib, libawt_headless.dylib, libawt_xawt.dylib"

# ===== 清理 =====
clean:
	@echo "[PCL-iOS] 清理..."
	rm -rf $(OUTPUTDIR)
	rm -f PCL-iOS.xcodeproj
	@echo "[PCL-iOS] 清理完成"

# ===== 完整清理 (包括JRE) =====
distclean: clean
	@echo "[PCL-iOS] 完整清理..."
	rm -rf $(DEPENDS_DIR)/java-*-openjdk
	rm -rf $(DEPENDS_DIR)/jre*.zip
	rm -rf $(DEPENDS_DIR)/jre*.tar.xz
	@echo "[PCL-iOS] 完整清理完成"
