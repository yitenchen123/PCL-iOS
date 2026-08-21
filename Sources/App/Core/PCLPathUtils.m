#import "PCLPathUtils.h"
#import "PCLJavaRuntime.h"

@implementation PCLPathUtils

+ (NSString *)resourcePath:(NSString *)name {
    return [[NSBundle mainBundle] pathForResource:name ofType:nil];
}

+ (NSString *)resourcePath:(NSString *)name ofType:(NSString *)ext {
    return [[NSBundle mainBundle] pathForResource:name ofType:ext];
}

+ (NSString *)dependsDir {
    return [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"depends"];
}

+ (NSString *)gameDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = paths.firstObject;
    NSString *gameDir = [docsDir stringByAppendingPathComponent:@".minecraft"];
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:gameDir]) {
        [fm createDirectoryAtPath:gameDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return gameDir;
}

+ (NSString *)versionsDirectory {
    return [[self gameDirectory] stringByAppendingPathComponent:@"versions"];
}

+ (NSString *)instancesDirectory {
    return [[self gameDirectory] stringByAppendingPathComponent:@"instances"];
}

+ (NSString *)javaHomeForVersion:(NSInteger)version {
    // 优先从解压目录查找
    NSString *path = [[PCLJavaRuntime.sharedRuntime.javaRuntimesDir] stringByAppendingPathComponent:[NSString stringWithFormat:@"java-%ld-openjdk", (long)version]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:[path stringByAppendingPathComponent:@"release"]]) return path;
    
    // 回退到bundle资源路径（旧方式）
    path = [[self dependsDir] stringByAppendingPathComponent:[NSString stringWithFormat:@"java-%ld-openjdk", (long)version]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:[path stringByAppendingPathComponent:@"bin/java"]]) return path;
    return nil;
}

+ (NSString *)javaExecutableForVersion:(NSInteger)version {
    // 优先使用PCLJavaRuntime
    NSString *result = [PCLJavaRuntime.sharedRuntime javaExecutableForVersion:version];
    if (result) return result;
    
    // 回退到bundle资源路径
    NSString *home = [self javaHomeForVersion:version];
    if (home) return [home stringByAppendingPathComponent:@"bin/java"];
    return nil;
}

+ (NSInteger)recommendedJavaVersionForMC:(NSString *)mcVersion {
    return [PCLJavaRuntime.sharedRuntime recommendedJavaVersionForMC:mcVersion];
}

+ (NSString *)lwjglJarPath:(NSString *)jarName {
    // Amethyst 布局: libs/lwjgl/
    NSString *path = [[[self dependsDir] stringByAppendingPathComponent:@"libs/lwjgl"] stringByAppendingPathComponent:jarName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) return path;
    // 兼容旧布局
    path = [[[self dependsDir] stringByAppendingPathComponent:@"libs"] stringByAppendingPathComponent:jarName];
    return [[NSFileManager defaultManager] fileExistsAtPath:path] ? path : nil;
}

+ (NSArray<NSString *> *)allLwjglJars {
    // Amethyst 布局: libs/lwjgl/ + libs/others/
    NSString *lwjglDir = [[self dependsDir] stringByAppendingPathComponent:@"libs/lwjgl"];
    NSString *othersDir = [[self dependsDir] stringByAppendingPathComponent:@"libs/others"];
    NSArray *lwjglJars = @[
        @"lwjgl.jar", @"lwjgl-opengl.jar", @"lwjgl-openal.jar", @"lwjgl-glfw.jar",
        @"lwjgl-stb.jar", @"lwjgl-nanovg.jar", @"lwjgl-vulkan.jar",
        @"lwjgl-callback-descriptor.jar", @"lwjgl-input.jar",
        @"lwjgl-system.jar", @"lwjgl-util.jar"
    ];
    NSArray *otherJars = @[@"gson-2.13.1.jar", @"jsr305.jar", @"arc_dns_injector.jar"];
    NSMutableArray *result = [NSMutableArray array];
    for (NSString *name in lwjglJars) {
        NSString *path = [lwjglDir stringByAppendingPathComponent:name];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) [result addObject:path];
    }
    for (NSString *name in otherJars) {
        NSString *path = [othersDir stringByAppendingPathComponent:name];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) [result addObject:path];
    }
    return result;
}

+ (NSString *)caciocavalloJarDir:(NSInteger)javaVersion {
    // Amethyst 布局: libs/caciocavallo/ (Java 8) 或 libs/caciocavallo17/ (Java 17+)
    NSString *folder = javaVersion >= 17 ? @"libs/caciocavallo17" : @"libs/caciocavallo";
    NSString *path = [[self dependsDir] stringByAppendingPathComponent:folder];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) return path;
    // 兼容旧布局
    folder = javaVersion >= 17 ? @"libs_caciocavallo17" : @"libs_caciocavallo";
    path = [[self dependsDir] stringByAppendingPathComponent:folder];
    return [[NSFileManager defaultManager] fileExistsAtPath:path] ? path : nil;
}

+ (NSString *)frameworkPath:(NSString *)dylibName {
    NSString *path = [[NSBundle mainBundle] pathForResource:[dylibName stringByDeletingPathExtension] ofType:@"dylib"];
    return path;
}

+ (NSString *)rendererDylib:(NSString *)name {
    NSDictionary *map = @{
        @"gl4es": @"libgl4es_114.dylib",
        @"angle": @"libtinygl4angle.dylib",
        @"mobileglues": @"libmobileglues.dylib",
        @"osmesa": @"libOSMesa.8.dylib",
        @"ltw": @"libltw.dylib"
    };
    NSString *dylib = map[name] ?: @"libgl4es_114.dylib";
    return [self frameworkPath:dylib];
}

@end
