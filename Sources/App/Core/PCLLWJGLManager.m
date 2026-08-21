#import "PCLLWJGLManager.h"
#import "PCLDownloadManager.h"
#import "PCLLogger.h"

static NSString *const kMavenBaseURL = @"https://repo1.maven.org/maven2/org/lwjgl/";

@implementation PCLLWJGLLibrary
@end

@implementation PCLLWJGLManager

+ (instancetype)sharedManager {
    static PCLLWJGLManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PCLLWJGLManager alloc] init];
    });
    return instance;
}

+ (NSString *)versionStringFromEnum:(PCLLWJGLVersion)version {
    switch (version) {
        case PCLLWJGLVersion331: return @"3.3.1";
        case PCLLWJGLVersion332: return @"3.3.2";
        case PCLLWJGLVersion333: return @"3.3.3";
    }
    return @"3.3.1";
}

- (NSString *)documentsDirectory {
    return NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
}

- (NSString *)librariesDirectory {
    NSString *path = [[self documentsDirectory] stringByAppendingPathComponent:@"PCL Games/libraries"];
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:path]) {
        [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return path;
}

- (NSString *)lwjglDirectory {
    NSString *path = [[self documentsDirectory] stringByAppendingPathComponent:@"PCL Games/lwjgl"];
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:path]) {
        [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return path;
}

- (NSString *)lwjglDirectoryForVersion:(PCLLWJGLVersion)version {
    NSString *versionStr = [PCLLWJGLManager versionStringFromEnum:version];
    NSString *path = [[self lwjglDirectory] stringByAppendingPathComponent:versionStr];
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:path]) {
        [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return path;
}

- (NSString *)lwjglNativeDirectory:(PCLLWJGLVersion)version {
    NSString *path = [[self lwjglDirectoryForVersion:version] stringByAppendingPathComponent:@"native"];
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:path]) {
        [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return path;
}

- (NSArray<PCLLWJGLLibrary *> *)requiredLWJGLLibraries {
    return [self requiredLWJGLLibrariesForVersion:PCLLWJGLVersion331];
}

- (NSArray<PCLLWJGLLibrary *> *)requiredLWJGLLibrariesForVersion:(PCLLWJGLVersion)version {
    NSString *versionStr = [PCLLWJGLManager versionStringFromEnum:version];
    
    NSArray *baseArtifacts = @[
        @"lwjgl",
        @"lwjgl-opengl",
        @"lwjgl-openal",
        @"lwjgl-glfw",
        @"lwjgl-stb",
        @"lwjgl-nanovg",
        @"lwjgl-jemalloc",
        @"lwjgl-tinyfd",
        @"lwjgl-vulkan"
    ];
    
    NSArray *nativeArtifacts = @[
        @"lwjgl",
        @"lwjgl-opengl",
        @"lwjgl-openal",
        @"lwjgl-glfw",
        @"lwjgl-stb",
        @"lwjgl-nanovg",
        @"lwjgl-jemalloc",
        @"lwjgl-tinyfd"
    ];
    
    NSMutableArray *libs = [NSMutableArray array];
    
    for (NSString *artifact in baseArtifacts) {
        PCLLWJGLLibrary *lib = [[PCLLWJGLLibrary alloc] init];
        lib.artifact = artifact;
        lib.group = @"org.lwjgl";
        lib.version = versionStr;
        lib.isNative = NO;
        lib.classifier = @"";
        [libs addObject:lib];
    }
    
    for (NSString *artifact in nativeArtifacts) {
        PCLLWJGLLibrary *lib = [[PCLLWJGLLibrary alloc] init];
        lib.artifact = artifact;
        lib.group = @"org.lwjgl";
        lib.version = versionStr;
        lib.isNative = YES;
        lib.classifier = @"natives-ios";
        [libs addObject:lib];
    }
    
    return libs;
}

- (NSString *)downloadURLForLibrary:(PCLLWJGLLibrary *)lib {
    NSString *groupPath = [lib.group stringByReplacingOccurrencesOfString:@"." withString:@"/"];
    
    NSString *filename;
    if (lib.isNative && lib.classifier.length > 0) {
        filename = [NSString stringWithFormat:@"%@-%@-%@.jar", lib.artifact, lib.version, lib.classifier];
    } else {
        filename = [NSString stringWithFormat:@"%@-%@.jar", lib.artifact, lib.version];
    }
    
    return [NSString stringWithFormat:@"%@%@/%@/%@/%@", kMavenBaseURL, groupPath, lib.artifact, lib.version, filename];
}

- (NSString *)localPathForLibrary:(PCLLWJGLLibrary *)lib version:(PCLLWJGLVersion)version {
    NSString *lwjglDir = [self lwjglDirectoryForVersion:version];
    
    NSString *filename;
    if (lib.isNative && lib.classifier.length > 0) {
        filename = [NSString stringWithFormat:@"%@-%@-%@.jar", lib.artifact, lib.version, lib.classifier];
    } else {
        filename = [NSString stringWithFormat:@"%@-%@.jar", lib.artifact, lib.version];
    }
    
    if (lib.isNative) {
        return [[self lwjglNativeDirectory:version] stringByAppendingPathComponent:filename];
    }
    return [lwjglDir stringByAppendingPathComponent:filename];
}

- (BOOL)isLWJGLDownloaded:(PCLLWJGLVersion)version {
    NSArray *libs = [self requiredLWJGLLibrariesForVersion:version];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    for (PCLLWJGLLibrary *lib in libs) {
        NSString *path = [self localPathForLibrary:lib version:version];
        if (![fm fileExistsAtPath:path]) {
            return NO;
        }
    }
    
    return YES;
}

- (NSString *)lwjglClasspath:(PCLLWJGLVersion)version {
    NSArray *libs = [self requiredLWJGLLibrariesForVersion:version];
    NSMutableString *classpath = [NSMutableString string];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    for (PCLLWJGLLibrary *lib in libs) {
        if (lib.isNative) continue;
        
        NSString *path = [self localPathForLibrary:lib version:version];
        if ([fm fileExistsAtPath:path]) {
            [classpath appendString:path];
            [classpath appendString:@":"];
        }
    }
    
    if (classpath.length > 0 && [classpath hasSuffix:@":"]) {
        [classpath deleteCharactersInRange:NSMakeRange(classpath.length - 1, 1)];
    }
    
    return [NSString stringWithString:classpath];
}

- (void)downloadLWJGL:(PCLLWJGLVersion)version
             progress:(void (^)(double, NSString *))progress
           completion:(void (^)(BOOL, NSError *))completion {
    
    if ([self isLWJGLDownloaded:version]) {
        NSString *versionStr = [PCLLWJGLManager versionStringFromEnum:version];
        [[PCLLogger sharedLogger] info:[NSString stringWithFormat:@"LWJGL %@ already downloaded, skipping", versionStr]];
        if (completion) completion(YES, nil);
        return;
    }
    
    NSString *versionStr = [PCLLWJGLManager versionStringFromEnum:version];
    [[PCLLogger sharedLogger] info:[NSString stringWithFormat:@"Starting LWJGL %@ library download", versionStr]];
    
    NSArray *libs = [self requiredLWJGLLibrariesForVersion:version];
    NSUInteger totalLibs = libs.count;
    __block NSUInteger completedLibs = 0;
    __block BOOL overallSuccess = YES;
    __block NSError *lastError = nil;
    
    dispatch_group_t downloadGroup = dispatch_group_create();
    dispatch_queue_t downloadQueue = dispatch_queue_create("com.pcl.lwjgl.download", DISPATCH_QUEUE_SERIAL);
    
    for (PCLLWJGLLibrary *lib in libs) {
        dispatch_group_enter(downloadGroup);
        
        NSString *localPath = [self localPathForLibrary:lib version:version];
        NSString *downloadURL = [self downloadURLForLibrary:lib];
        
        NSFileManager *fm = [NSFileManager defaultManager];
        NSString *dir = [localPath stringByDeletingLastPathComponent];
        [fm createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
        
        if ([fm fileExistsAtPath:localPath]) {
            completedLibs++;
            dispatch_group_leave(downloadGroup);
            continue;
        }
        
        dispatch_async(downloadQueue, ^{
            dispatch_semaphore_t sema = dispatch_semaphore_create(0);
            
            PCLDownloadTask *task = [[PCLDownloadTask alloc] init];
            task.url = downloadURL;
            task.targetPath = localPath;
            task.displayName = [NSString stringWithFormat:@"%@-%@", lib.artifact, lib.version];
            task.resourceType = PCLResourceTypeLibrary;
            
            [[PCLDownloadManager sharedManager] addTask:task];
            [[PCLDownloadManager sharedManager] startDownload:task];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                BOOL success = (task.state == PCLDownloadStateCompleted);
                
                NSFileManager *fm2 = [NSFileManager defaultManager];
                if (success && [fm2 fileExistsAtPath:localPath]) {
                    completedLibs++;
                    [[PCLLogger sharedLogger] info:[NSString stringWithFormat:@"LWJGL lib %@-%@ downloaded", lib.artifact, lib.version]];
                } else if (!success) {
                    overallSuccess = NO;
                    lastError = task.error ?: [NSError errorWithDomain:@"PCLLWJGLManager" code:-1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Failed to download %@", lib.artifact]}];
                    [[PCLLogger sharedLogger] error:[NSString stringWithFormat:@"Failed to download LWJGL lib %@: %@", lib.artifact, lastError.localizedDescription]];
                }
                
                double currentProgress = (double)completedLibs / (double)totalLibs;
                if (progress) {
                    progress(currentProgress, lib.artifact);
                }
                
                dispatch_semaphore_signal(sema);
            });
            
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
            dispatch_group_leave(downloadGroup);
        });
    }
    
    dispatch_group_notify(downloadGroup, dispatch_get_main_queue(), ^{
        if (overallSuccess) {
            [[PCLLogger sharedLogger] info:[NSString stringWithFormat:@"LWJGL %@ all libraries downloaded successfully", versionStr]];
        } else {
            [[PCLLogger sharedLogger] error:[NSString stringWithFormat:@"LWJGL %@ download completed with errors", versionStr]];
        }
        if (completion) completion(overallSuccess, lastError);
    });
}

@end
