#import "PCLNativeLibManager.h"
#import "PCLDownloadManager.h"
#import "PCLLogger.h"

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

- (NSString *)documentsDirectory {
    return NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
}

- (NSString *)nativeLibDirectory {
    NSString *path = [[self documentsDirectory] stringByAppendingPathComponent:@"PCL Games/native"];
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:path]) {
        [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return path;
}

- (NSString *)rendererLibDirectory {
    NSString *path = [[self nativeLibDirectory] stringByAppendingPathComponent:@"renderer"];
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:path]) {
        [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return path;
}

- (NSString *)audioLibDirectory {
    NSString *path = [[self nativeLibDirectory] stringByAppendingPathComponent:@"audio"];
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:path]) {
        [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return path;
}

- (NSString *)inputLibDirectory {
    NSString *path = [[self nativeLibDirectory] stringByAppendingPathComponent:@"input"];
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:path]) {
        [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return path;
}

- (NSArray<PCLNativeLib *> *)requiredNativeLibs {
    NSMutableArray *libs = [NSMutableArray array];
    
    // Renderer dylibs
    PCLNativeLib *gl4es = [[PCLNativeLib alloc] init];
    gl4es.name = @"gl4es_114";
    gl4es.filename = @"libgl4es_114.dylib";
    gl4es.type = PCLNativeLibTypeRenderer;
    gl4es.isRequired = YES;
    [libs addObject:gl4es];
    
    PCLNativeLib *tinygl4angle = [[PCLNativeLib alloc] init];
    tinygl4angle.name = @"tinygl4angle";
    tinygl4angle.filename = @"libtinygl4angle.dylib";
    tinygl4angle.type = PCLNativeLibTypeRenderer;
    tinygl4angle.isRequired = YES;
    [libs addObject:tinygl4angle];
    
    PCLNativeLib *mobileglues = [[PCLNativeLib alloc] init];
    mobileglues.name = @"mobileglues";
    mobileglues.filename = @"libmobileglues.dylib";
    mobileglues.type = PCLNativeLibTypeRenderer;
    mobileglues.isRequired = YES;
    [libs addObject:mobileglues];
    
    // Audio dylibs
    PCLNativeLib *openal = [[PCLNativeLib alloc] init];
    openal.name = @"openal";
    openal.filename = @"libopenal.dylib";
    openal.type = PCLNativeLibTypeAudio;
    openal.isRequired = YES;
    [libs addObject:openal];
    
    // Input dylibs
    PCLNativeLib *glfw = [[PCLNativeLib alloc] init];
    glfw.name = @"glfw";
    glfw.filename = @"libglfw.dylib";
    glfw.type = PCLNativeLibTypeInput;
    glfw.isRequired = YES;
    [libs addObject:glfw];
    
    return libs;
}

- (NSArray<PCLNativeLib *> *)requiredNativeLibsForType:(PCLNativeLibType)type {
    NSArray *allLibs = [self requiredNativeLibs];
    NSMutableArray *filtered = [NSMutableArray array];
    for (PCLNativeLib *lib in allLibs) {
        if (lib.type == type) {
            [filtered addObject:lib];
        }
    }
    return filtered;
}

- (NSArray<NSString *> *)rendererDylibs {
    NSArray *libs = [self requiredNativeLibsForType:PCLNativeLibTypeRenderer];
    NSMutableArray *paths = [NSMutableArray array];
    for (PCLNativeLib *lib in libs) {
        NSString *path = [self nativeLibPath:lib.name];
        if (path) {
            [paths addObject:path];
        }
    }
    return paths;
}

- (NSArray<NSString *> *)audioDylibs {
    NSArray *libs = [self requiredNativeLibsForType:PCLNativeLibTypeAudio];
    NSMutableArray *paths = [NSMutableArray array];
    for (PCLNativeLib *lib in libs) {
        NSString *path = [self nativeLibPath:lib.name];
        if (path) {
            [paths addObject:path];
        }
    }
    return paths;
}

- (NSArray<NSString *> *)inputDylibs {
    NSArray *libs = [self requiredNativeLibsForType:PCLNativeLibTypeInput];
    NSMutableArray *paths = [NSMutableArray array];
    for (PCLNativeLib *lib in libs) {
        NSString *path = [self nativeLibPath:lib.name];
        if (path) {
            [paths addObject:path];
        }
    }
    return paths;
}

- (NSArray<NSString *> *)allRequiredDylibPaths {
    NSArray *libs = [self requiredNativeLibs];
    NSMutableArray *paths = [NSMutableArray array];
    for (PCLNativeLib *lib in libs) {
        NSString *path = [self nativeLibPath:lib.name];
        if (path) {
            [paths addObject:path];
        }
    }
    return paths;
}

- (NSString *)directoryForLibType:(PCLNativeLibType)type {
    switch (type) {
        case PCLNativeLibTypeRenderer: return [self rendererLibDirectory];
        case PCLNativeLibTypeAudio:    return [self audioLibDirectory];
        case PCLNativeLibTypeInput:    return [self inputLibDirectory];
    }
    return [self nativeLibDirectory];
}

- (NSString *)nativeLibPath:(NSString *)libName {
    NSArray *libs = [self requiredNativeLibs];
    for (PCLNativeLib *lib in libs) {
        if ([lib.name isEqualToString:libName]) {
            NSString *dir = [self directoryForLibType:lib.type];
            return [dir stringByAppendingPathComponent:lib.filename];
        }
    }
    return nil;
}

- (BOOL)isNativeLibAvailable:(NSString *)libName {
    NSString *path = [self nativeLibPath:libName];
    if (!path) return NO;
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

- (void)downloadNativeLibs:(void (^)(double, NSString *))progress
                completion:(void (^)(BOOL, NSError *))completion {
    
    NSArray *libs = [self requiredNativeLibs];
    NSUInteger totalLibs = libs.count;
    __block NSUInteger completedLibs = 0;
    __block BOOL overallSuccess = YES;
    __block NSError *lastError = nil;
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    BOOL allDownloaded = YES;
    for (PCLNativeLib *lib in libs) {
        NSString *dir = [self directoryForLibType:lib.type];
        NSString *localPath = [dir stringByAppendingPathComponent:lib.filename];
        if (![fm fileExistsAtPath:localPath]) {
            allDownloaded = NO;
            break;
        }
    }
    
    if (allDownloaded) {
        [[PCLLogger sharedLogger] info:@"All native libraries already downloaded, skipping"];
        if (completion) completion(YES, nil);
        return;
    }
    
    [[PCLLogger sharedLogger] info:[NSString stringWithFormat:@"Starting native library download (%lu libraries)", (unsigned long)totalLibs]];
    
    dispatch_group_t downloadGroup = dispatch_group_create();
    dispatch_queue_t downloadQueue = dispatch_queue_create("com.pcl.nativelib.download", DISPATCH_QUEUE_SERIAL);
    
    for (PCLNativeLib *lib in libs) {
        dispatch_group_enter(downloadGroup);
        dispatch_async(downloadQueue, ^{
            NSString *dir = [self directoryForLibType:lib.type];
            NSString *localPath = [dir stringByAppendingPathComponent:lib.filename];
            
            [fm createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
            
            if ([fm fileExistsAtPath:localPath]) {
                completedLibs++;
                dispatch_group_leave(downloadGroup);
                return;
            }
            
            NSString *downloadURL = [self downloadURLForNativeLib:lib];
            if (!downloadURL) {
                overallSuccess = NO;
                lastError = [NSError errorWithDomain:@"PCLNativeLibManager" code:-3 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"No download URL for %@", lib.filename]}];
                [[PCLLogger sharedLogger] error:lastError.localizedDescription];
                dispatch_group_leave(downloadGroup);
                return;
            }
            
            dispatch_semaphore_t sema = dispatch_semaphore_create(0);
            
            PCLDownloadTask *task = [[PCLDownloadTask alloc] init];
            task.url = downloadURL;
            task.targetPath = localPath;
            task.displayName = lib.filename;
            task.resourceType = PCLResourceTypeLibrary;
            
            [[PCLDownloadManager sharedManager] addTask:task];
            [[PCLDownloadManager sharedManager] startDownload:task];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                BOOL success = (task.state == PCLDownloadStateCompleted);
                
                NSFileManager *fm2 = [NSFileManager defaultManager];
                if (success && [fm2 fileExistsAtPath:localPath]) {
                    completedLibs++;
                    
                    // Set executable permissions for dylib
                    [self setExecutablePermissions:localPath];
                    
                    [[PCLLogger sharedLogger] info:[NSString stringWithFormat:@"Native library %@ downloaded", lib.filename]];
                } else if (!success) {
                    overallSuccess = NO;
                    lastError = task.error ?: [NSError errorWithDomain:@"PCLNativeLibManager" code:-1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Failed to download %@", lib.filename]}];
                    [[PCLLogger sharedLogger] error:[NSString stringWithFormat:@"Failed to download native library %@: %@", lib.filename, lastError.localizedDescription]];
                }
                
                double currentProgress = (double)completedLibs / (double)totalLibs;
                if (progress) {
                    progress(currentProgress, lib.filename);
                }
                
                dispatch_semaphore_signal(sema);
            });
            
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
            dispatch_group_leave(downloadGroup);
        });
    }
    
    dispatch_group_notify(downloadGroup, dispatch_get_main_queue(), ^{
        if (overallSuccess) {
            [[PCLLogger sharedLogger] info:@"All native libraries downloaded successfully"];
        } else {
            [[PCLLogger sharedLogger] error:@"Native library download completed with errors"];
        }
        if (completion) completion(overallSuccess, lastError);
    });
}

#pragma mark - Private

- (NSString *)downloadURLForNativeLib:(PCLNativeLib *)lib {
    NSString *baseURL = @"https://github.com/RobbitFPV/PCL-iOS-Natives/releases/download/v1.0";
    return [NSString stringWithFormat:@"%@/%@", baseURL, lib.filename];
}

- (void)setExecutablePermissions:(NSString *)path {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    NSDictionary *attrs = @{NSFilePosixPermissions: @0755};
    [fm setAttributes:attrs ofItemAtPath:path error:&error];
    if (error) {
        [[PCLLogger sharedLogger] warning:[NSString stringWithFormat:@"Failed to set permissions on %@: %@", path, error.localizedDescription]];
    }
}

@end
