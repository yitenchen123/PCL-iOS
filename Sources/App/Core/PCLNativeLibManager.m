#import "PCLNativeLibManager.h"

@implementation PCLNativeLib
@end

@implementation PCLNativeLibManager

+ (instancetype)sharedManager {
    static PCLNativeLibManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PCLNativeLibManager alloc] init];
    });
    return instance;
}

- (NSString *)frameworksDirectory {
    return [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"Frameworks"];
}

- (NSArray<PCLNativeLib *> *)allLibs {
    NSMutableArray *libs = [NSMutableArray array];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *dir = [self frameworksDirectory];
    
    struct { const char *name; PCLNativeLibType type; } libDefs[] = {
        {"libgl4es_114.dylib", PCLNativeLibTypeRenderer},
        {"libtinygl4angle.dylib", PCLNativeLibTypeRenderer},
        {"libmobileglues.dylib", PCLNativeLibTypeRenderer},
        {"libOSMesa.8.dylib", PCLNativeLibTypeRenderer},
        {"libopenal.dylib", PCLNativeLibTypeAudio},
        {"libglfw.dylib", PCLNativeLibTypeInput},
        {"libSDL3.dylib", PCLNativeLibTypeInput},
        {"libMoltenVK.dylib", PCLNativeLibTypeVulkan},
        {"libawt_headless.dylib", PCLNativeLibTypeSystem},
        {"libawt_xawt.dylib", PCLNativeLibTypeSystem},
        {"libspirv-cross.dylib", PCLNativeLibTypeVulkan},
        {"libltw.dylib", PCLNativeLibTypeRenderer},
        {NULL, 0}
    };
    
    for (int i = 0; libDefs[i].name != NULL; i++) {
        PCLNativeLib *lib = [[PCLNativeLib alloc] init];
        lib.name = [NSString stringWithUTF8String:libDefs[i].name];
        lib.path = [dir stringByAppendingPathComponent:lib.name];
        lib.type = libDefs[i].type;
        lib.isAvailable = [fm fileExistsAtPath:lib.path];
        [libs addObject:lib];
    }
    return libs;
}

- (NSArray<PCLNativeLib *> *)libsOfType:(PCLNativeLibType)type {
    NSMutableArray *result = [NSMutableArray array];
    for (PCLNativeLib *lib in self.allLibs) {
        if (lib.type == type) [result addObject:lib];
    }
    return result;
}

- (NSArray<PCLNativeLib *> *)rendererLibs { return [self libsOfType:PCLNativeLibTypeRenderer]; }
- (NSArray<PCLNativeLib *> *)audioLibs { return [self libsOfType:PCLNativeLibTypeAudio]; }
- (NSArray<PCLNativeLib *> *)inputLibs { return [self libsOfType:PCLNativeLibTypeInput]; }
- (NSArray<PCLNativeLib *> *)vulkanLibs { return [self libsOfType:PCLNativeLibTypeVulkan]; }

- (NSString *)pathForLib:(NSString *)name {
    NSString *path = [[self frameworksDirectory] stringByAppendingPathComponent:name];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) return path;
    return nil;
}

- (BOOL)isAvailable:(NSString *)name {
    return [self pathForLib:name] != nil;
}

- (NSString *)glfwPath { return [self pathForLib:@"libglfw.dylib"]; }
- (NSString *)sdl3Path { return [self pathForLib:@"libSDL3.dylib"]; }
- (NSString *)moltenVKPath { return [self pathForLib:@"libMoltenVK.dylib"]; }
- (NSString *)openALPath { return [self pathForLib:@"libopenal.dylib"]; }

- (NSString *)rendererPath:(NSString *)rendererName {
    NSDictionary *map = @{
        @"gl4es": @"libgl4es_114.dylib",
        @"angle": @"libtinygl4angle.dylib",
        @"mobileglues": @"libmobileglues.dylib",
        @"osmesa": @"libOSMesa.8.dylib",
        @"ltw": @"libltw.dylib"
    };
    NSString *libName = map[rendererName] ?: @"libgl4es_114.dylib";
    return [self pathForLib:libName];
}

@end
