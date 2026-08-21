# PCL-iOS Makefile
# 参考 Amethyst-iOS-MyRemastered 构建系统
# 
# 用法:
#   make all       - 完整构建
#   make jre       - 下载Java JRE for iOS arm64
#   make native    - 编译native dylib (CMake交叉编译)
#   make dylibs    - 下载预编译dylib (来自Amethyst)
#   make lwjgl     - 下载LWJGL JARs (来自Amethyst)
#   make gen       - 生成Xcode项目
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

# Amethyst源码路径
AMETHYST_BASE := https://raw.githubusercontent.com/herbrine8403/Amethyst-iOS-MyRemastered/main

# Xcode生成
XCODEGEN ?= xcodegen

# CMake配置参数
CONFIG_CURSEFORGE_API_KEY ?= ""
CMAKE_CONFIG_FLAGS := -DCONFIG_CURSEFORGE_API_KEY="$(CONFIG_CURSEFORGE_API_KEY)"

.PHONY: all jre native dylibs lwjgl assets gen clean check help

all: jre gen

help:
	@echo "PCL-iOS Makefile"
	@echo ""
	@echo "目标:"
	@echo "  make all       - jre + gen"
	@echo "  make jre       - 下载Java JRE for iOS arm64"
	@echo "  make native    - 编译native dylib (CMake)"
	@echo "  make dylibs    - 下载预编译dylib (来自Amethyst)"
	@echo "  make lwjgl     - 下载LWJGL JARs (来自Amethyst)"
	@echo "  make gen       - 生成Xcode项目"
	@echo "  make clean     - 清理构建产物"
	@echo "  make check     - 检查依赖"

check:
	@echo "=== PCL-iOS 构建检查 ==="
	@echo "Java 8:  $(if $(wildcard $(JRE8_DIR)/release),✓ 已安装,✗ 未安装 ($(JRE8_URL)))"
	@echo "Java 17: $(if $(wildcard $(JRE17_DIR)/release),✓ 已安装,✗ 未安装 ($(JRE17_URL)))"
	@echo "Java 21: $(if $(wildcard $(JRE21_DIR)/release),✓ 已安装,✗ 未安装 ($(JRE21_URL)))"
	@echo "Java 25: $(if $(wildcard $(JRE25_DIR)/release),✓ 已安装,✗ 未安装 ($(JRE25_URL)))"
	@echo "LWJGL:   $(if $(wildcard $(LIBS_DIR)/lwjgl.jar),✓ 已安装,✗ 未安装)"
	@echo "Cacio8:  $(if $(wildcard $(DEPENDS_DIR)/libs_caciocavallo/cacio-shared-1.10-SNAPSHOT.jar),✓ 已安装,✗ 未安装)"
	@echo "Cacio17: $(if $(wildcard $(DEPENDS_DIR)/libs_caciocavallo17/cacio-shared-1.18-SNAPSHOT.jar),✓ 已安装,✗ 未安装)"
	@echo "GL4ES:   $(if $(wildcard $(FRAMEWORKS_DIR)/libgl4es_114.dylib),✓ 已安装,✗ 未安装)"
	@echo "MoltenVK:$(if $(wildcard $(FRAMEWORKS_DIR)/libMoltenVK.dylib),✓ 已安装,✗ 未安装)"

# ============================================================================
# Java JRE下载 (参考Amethyst METHOD_JAVA_UNPACK)
# 来源: Amethyst-iOS-MyRemastered/Makefile
# ============================================================================
METHOD_JAVA_UNPACK = \
	cd $(DEPENDS_DIR); \
	if [ ! -f "java-$(1)-openjdk/release" ] && [ ! -f "$(ls jre$(1)-*.tar.xz 2>/dev/null)" ]; then \
		wget '$(2)' -q --show-progress -O jre$(1)-ios-aarch64.zip; \
		unzip -q jre$(1)-ios-aarch64.zip && rm jre$(1)-ios-aarch64.zip; \
		mkdir -p java-$(1)-openjdk; \
		tar xvf jre$(1)-*.tar.xz -C java-$(1)-openjdk; \
		rm -f jre$(1)-*.tar.xz; \
	fi

jre:
	@echo "[PCL-iOS] 下载Java JRE for iOS arm64..."
	mkdir -p $(DEPENDS_DIR)
	$(call METHOD_JAVA_UNPACK,8,$(JRE8_URL))
	$(call METHOD_JAVA_UNPACK,17,$(JRE17_URL))
	$(call METHOD_JAVA_UNPACK,21,$(JRE21_URL))
	$(call METHOD_JAVA_UNPACK,25,$(JRE25_URL))
	@# 清理不必要的文件 (参考Amethyst)
	rm -rf $(DEPENDS_DIR)/java-{8,17,21,25}-openjdk/{ASSEMBLY_EXCEPTION,bin,include,jre,legal,LICENSE,man,THIRD_PARTY_README,lib/{ct.sym,jspawnhelper,libjsig.dylib,src.zip,tools.jar}} 2>/dev/null || true
	@# 复制JRE到输出目录 (参考Amethyst)
	$(call METHOD_DIRCHECK,$(JRE_DIR))
	cp -R $(JRE8_DIR) $(JRE_DIR)
	cp -R $(JRE17_DIR) $(JRE_DIR)
	cp -R $(JRE21_DIR) $(JRE_DIR)
	cp -R $(JRE25_DIR) $(JRE_DIR)
	@echo "[PCL-iOS] Java JRE下载完成"

# ============================================================================
# 目录检查函数 (参考Amethyst METHOD_DIRCHECK)
# ============================================================================
METHOD_DIRCHECK = \
	if [ ! -d '$(1)' ]; then \
		mkdir -p $(1); \
	else \
		rm -rf $(1)/*; \
	fi

# ============================================================================
# Native dylib编译 (CMake交叉编译)
# ============================================================================
native:
	@echo "[PCL-iOS] 编译native dylib..."
	mkdir -p $(FRAMEWORKS_DIR)
	@echo "[PCL-iOS] Native编译需要Xcode环境，在GitHub Actions中执行"

# ============================================================================
# Dylibs下载 (来自Amethyst Natives/resources/Frameworks)
# ============================================================================
dylibs:
	@echo "[PCL-iOS] 下载预编译dylib (来自 Amethyst Natives/resources/Frameworks)..."
	mkdir -p $(FRAMEWORKS_DIR)
	@# 基础dylib
	for dylib in libMoltenVK.dylib libOSMesa.8.dylib libfreetype.dylib libgl4es_114.dylib libglapi.0.dylib libopenal.dylib libshaderc.dylib libspirv-cross-c-shared.0.dylib libvirgl_test_server.dylib liblwjgl.dylib liblwjgl_opengl.dylib liblwjgl_nanovg.dylib liblwjgl_stb.dylib liblwjgl_tinyfd.dylib liblwjgl_vma.dylib; do \
		echo "  下载 $$dylib..."; \
		curl -sL -o $(FRAMEWORKS_DIR)/$$dylib "$(AMETHYST_BASE)/Natives/resources/Frameworks/$$dylib" || wget -q -O $(FRAMEWORKS_DIR)/$$dylib "$(AMETHYST_BASE)/Natives/resources/Frameworks/$$dylib"; \
	done
	@# Frameworks
	mkdir -p $(FRAMEWORKS_DIR)/libEGL.framework $(FRAMEWORKS_DIR)/libGLESv2.framework $(FRAMEWORKS_DIR)/AltKit.framework $(FRAMEWORKS_DIR)/CAltKit.framework $(FRAMEWORKS_DIR)/UnzipKit.framework
	curl -sL -o $(FRAMEWORKS_DIR)/libEGL.framework/Info.plist "$(AMETHYST_BASE)/Natives/resources/Frameworks/libEGL.framework/Info.plist"
	curl -sL -o $(FRAMEWORKS_DIR)/libEGL.framework/libEGL "$(AMETHYST_BASE)/Natives/resources/Frameworks/libEGL.framework/libEGL"
	curl -sL -o $(FRAMEWORKS_DIR)/libGLESv2.framework/Info.plist "$(AMETHYST_BASE)/Natives/resources/Frameworks/libGLESv2.framework/Info.plist"
	curl -sL -o $(FRAMEWORKS_DIR)/libGLESv2.framework/libGLESv2 "$(AMETHYST_BASE)/Natives/resources/Frameworks/libGLESv2.framework/libGLESv2"
	curl -sL -o $(FRAMEWORKS_DIR)/AltKit.framework/Info.plist "$(AMETHYST_BASE)/Natives/resources/Frameworks/AltKit.framework/Info.plist"
	curl -sL -o $(FRAMEWORKS_DIR)/AltKit.framework/AltKit "$(AMETHYST_BASE)/Natives/resources/Frameworks/AltKit.framework/AltKit"
	curl -sL -o $(FRAMEWORKS_DIR)/CAltKit.framework/Info.plist "$(AMETHYST_BASE)/Natives/resources/Frameworks/CAltKit.framework/Info.plist"
	curl -sL -o $(FRAMEWORKS_DIR)/CAltKit.framework/CAltKit "$(AMETHYST_BASE)/Natives/resources/Frameworks/CAltKit.framework/CAltKit"
	curl -sL -o $(FRAMEWORKS_DIR)/UnzipKit.framework/Info.plist "$(AMETHYST_BASE)/Natives/resources/Frameworks/UnzipKit.framework/Info.plist"
	curl -sL -o $(FRAMEWORKS_DIR)/UnzipKit.framework/UnzipKit "$(AMETHYST_BASE)/Natives/resources/Frameworks/UnzipKit.framework/UnzipKit"
	@echo "[PCL-iOS] Dylibs下载完成"
	@# MoltenVK (使用yitenchen123预构建的1.4.3真机版)
	@echo "[PCL-iOS] 注意: libMoltenVK.dylib 应替换为 yitenchen123/MoltenVK 构建的 1.4.3 真机arm64 版本"
	@echo "  下载地址: https://github.com/yitenchen123/MoltenVK/actions/runs/31651139093"

# ============================================================================
# LWJGL下载 (来自Amethyst JavaApp/libs)
# ============================================================================
lwjgl:
	@echo "[PCL-iOS] 下载LWJGL JARs (来自 Amethyst JavaApp/libs)..."
	mkdir -p $(DEPENDS_DIR)/libs/lwjgl $(DEPENDS_DIR)/libs/others $(DEPENDS_DIR)/libs/caciocavallo $(DEPENDS_DIR)/libs/caciocavallo17
	@# LWJGL JARs
	for jar in lwjgl.jar lwjgl-opengl.jar lwjgl-openal.jar lwjgl-glfw.jar lwjgl-stb.jar lwjgl-nanovg.jar lwjgl-vulkan.jar lwjgl-callback-descriptor.jar lwjgl-input.jar lwjgl-system.jar lwjgl-util.jar; do \
		echo "  下载 $$jar..."; \
		curl -sL -o $(DEPENDS_DIR)/libs/lwjgl/$$jar "$(AMETHYST_BASE)/JavaApp/libs/lwjgl/$$jar" || wget -q -O $(DEPENDS_DIR)/libs/lwjgl/$$jar "$(AMETHYST_BASE)/JavaApp/libs/lwjgl/$$jar"; \
	done
	@# 其他依赖
	for jar in gson-2.13.1.jar jsr305.jar arc_dns_injector.jar; do \
		echo "  下载 $$jar..."; \
		curl -sL -o $(DEPENDS_DIR)/libs/others/$$jar "$(AMETHYST_BASE)/JavaApp/libs/others/$$jar" || wget -q -O $(DEPENDS_DIR)/libs/others/$$jar "$(AMETHYST_BASE)/JavaApp/libs/others/$$jar"; \
	done
	@# Caciocavallo (Java 8)
	for jar in ResConfHack.jar cacio-androidnw-1.10-SNAPSHOT.jar cacio-shared-1.10-SNAPSHOT.jar; do \
		echo "  下载 $$jar..."; \
		curl -sL -o $(DEPENDS_DIR)/libs/caciocavallo/$$jar "$(AMETHYST_BASE)/JavaApp/libs/caciocavallo/$$jar" || wget -q -O $(DEPENDS_DIR)/libs/caciocavallo/$$jar "$(AMETHYST_BASE)/JavaApp/libs/caciocavallo/$$jar"; \
	done
	@# Caciocavallo17 (Java 17+)
	for jar in cacio-shared-1.18-SNAPSHOT.jar cacio-tta-1.18-SNAPSHOT.jar; do \
		echo "  下载 $$jar..."; \
		curl -sL -o $(DEPENDS_DIR)/libs/caciocavallo17/$$jar "$(AMETHYST_BASE)/JavaApp/libs/caciocavallo17/$$jar" || wget -q -O $(DEPENDS_DIR)/libs/caciocavallo17/$$jar "$(AMETHYST_BASE)/JavaApp/libs/caciocavallo17/$$jar"; \
	done
	@echo "[PCL-iOS] LWJGL下载完成"

# ============================================================================
# 资源编译
# ============================================================================
assets:
	@echo "[PCL-iOS] 编译资源..."
	@echo "[PCL-iOS] 资源编译完成"

# ============================================================================
# Xcode项目生成
# ============================================================================
gen:
	@echo "[PCL-iOS] 生成Xcode项目..."
	$(XCODEGEN) generate
	@echo "[PCL-iOS] 项目生成完成"

# ============================================================================
# 清理
# ============================================================================
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
