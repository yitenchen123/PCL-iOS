#import "PCLLWJGLManager.h"

@implementation PCLLWJGLManager

+ (instancetype)sharedManager {
    static PCLLWJGLManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PCLLWJGLManager alloc] init];
    });
    return instance;
}

- (NSString *)libsDirectory {
    NSString *path = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"libs"];
    return path;
}

- (NSString *)caciocavalloDir:(NSInteger)javaVersion {
    NSString *folder = javaVersion >= 17 ? @"caciocavallo17" : @"caciocavallo";
    return [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:[NSString stringWithFormat:@"libs_%@/", folder]];
}

- (NSArray<NSString *> *)lwjglJars {
    NSString *dir = [self libsDirectory];
    NSArray *names = @[
        @"lwjgl.jar", @"lwjgl-opengl.jar", @"lwjgl-openal.jar",
        @"lwjgl-glfw.jar", @"lwjgl-stb.jar", @"lwjgl-nanovg.jar",
        @"lwjgl-jemalloc.jar", @"lwjgl-tinyfd.jar", @"lwjgl-vulkan.jar",
        @"lwjgl-callback-descriptor.jar", @"lwjgl-input.jar",
        @"lwjgl-system.jar", @"lwjgl-util.jar"
    ];
    NSMutableArray *jars = [NSMutableArray array];
    for (NSString *name in names) {
        NSString *path = [dir stringByAppendingPathComponent:name];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            [jars addObject:path];
        }
    }
    return jars;
}

- (NSArray<NSString *> *)caciocavalloJars {
    NSString *dir = [self caciocavalloDir:17];
    NSArray *names = @[@"cacio-shared-1.10-SNAPSHOT.jar", @"cacio-androidnw-1.10-SNAPSHOT.jar", @"ResConfHack.jar"];
    NSMutableArray *jars = [NSMutableArray array];
    for (NSString *name in names) {
        NSString *path = [dir stringByAppendingPathComponent:name];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            [jars addObject:path];
        }
    }
    return jars;
}

- (NSArray<NSString *> *)otherJars {
    NSString *dir = [self libsDirectory];
    NSArray *names = @[@"gson-2.13.1.jar", @"jsr305.jar", @"arc_dns_injector.jar"];
    NSMutableArray *jars = [NSMutableArray array];
    for (NSString *name in names) {
        NSString *path = [dir stringByAppendingPathComponent:name];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            [jars addObject:path];
        }
    }
    return jars;
}

- (NSString *)lwjglClasspath {
    return [[self lwjglJars] componentsJoinedByString:@":"];
}

- (NSString *)caciocavalloClasspathForJavaVersion:(NSInteger)javaVersion {
    NSString *dir = [self caciocavalloDir:javaVersion];
    NSArray *names = @[@"cacio-shared-1.10-SNAPSHOT.jar", @"cacio-androidnw-1.10-SNAPSHOT.jar", @"ResConfHack.jar"];
    NSMutableArray *jars = [NSMutableArray array];
    for (NSString *name in names) {
        NSString *path = [dir stringByAppendingPathComponent:name];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            [jars addObject:path];
        }
    }
    return [jars componentsJoinedByString:@":"];
}

- (NSString *)allLibrariesClasspath {
    NSMutableArray *all = [NSMutableArray array];
    [all addObjectsFromArray:[self lwjglJars]];
    [all addObjectsFromArray:[self caciocavalloJars]];
    [all addObjectsFromArray:[self otherJars]];
    return [all componentsJoinedByString:@":"];
}

- (BOOL)isAvailable {
    return [self lwjglJars].count > 0;
}

@end
