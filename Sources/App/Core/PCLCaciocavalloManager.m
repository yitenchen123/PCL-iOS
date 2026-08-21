#import "PCLCaciocavalloManager.h"
#import "PCLDownloadManager.h"
#import "PCLLogger.h"

@implementation PCLCaciocavalloLibrary
@end

@implementation PCLCaciocavalloManager

+ (instancetype)sharedManager {
    static PCLCaciocavalloManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PCLCaciocavalloManager alloc] init];
    });
    return instance;
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

- (NSString *)caciocavalloDirectory {
    NSString *path = [[self documentsDirectory] stringByAppendingPathComponent:@"PCL Games/caciocavallo"];
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:path]) {
        [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return path;
}

- (PCLCaciocavalloVersion)caciocavalloVersionForJavaVersion:(NSInteger)javaVersion {
    if (javaVersion >= 17) {
        return PCLCaciocavalloVersion17;
    }
    return PCLCaciocavalloVersion8;
}

- (NSArray<PCLCaciocavalloLibrary *> *)requiredCaciocavalloForJavaVersion:(NSInteger)javaVersion {
    NSMutableArray *libs = [NSMutableArray array];
    
    PCLCaciocavalloVersion cavalloVersion = [self caciocavalloVersionForJavaVersion:javaVersion];
    
    if (cavalloVersion == PCLCaciocavalloVersion8) {
        PCLCaciocavalloLibrary *rt = [[PCLCaciocavalloLibrary alloc] init];
        rt.artifact = @"caciocavallo-rt";
        rt.version = @"1.10";
        rt.javaVersion = PCLCaciocavalloVersion8;
        rt.classifier = @"";
        [libs addObject:rt];
        
        PCLCaciocavalloLibrary *jdk8 = [[PCLCaciocavalloLibrary alloc] init];
        jdk8.artifact = @"caciocavallo-rt-amd64";
        jdk8.version = @"1.10";
        jdk8.javaVersion = PCLCaciocavalloVersion8;
        jdk8.classifier = @"";
        [libs addObject:jdk8];
    } else {
        PCLCaciocavalloLibrary *rt17 = [[PCLCaciocavalloLibrary alloc] init];
        rt17.artifact = @"caciocavallo17-rt";
        rt17.version = @"1.10";
        rt17.javaVersion = PCLCaciocavalloVersion17;
        rt17.classifier = @"";
        [libs addObject:rt17];
        
        PCLCaciocavalloLibrary *jdk17 = [[PCLCaciocavalloLibrary alloc] init];
        jdk17.artifact = @"caciocavallo17";
        jdk17.version = @"1.10";
        jdk17.javaVersion = PCLCaciocavalloVersion17;
        jdk17.classifier = @"";
        [libs addObject:jdk17];
    }
    
    return libs;
}

- (NSString *)downloadURLForCaciocavallo:(PCLCaciocavalloVersion)version {
    NSArray *libs = [self requiredCaciocavalloForJavaVersion:version == PCLCaciocavalloVersion8 ? 8 : 17];
    if (libs.count == 0) return nil;
    
    PCLCaciocavalloLibrary *lib = libs[0];
    
    if (version == PCLCaciocavalloVersion8) {
        return [NSString stringWithFormat:@"https://github.com/RobbitFPV/Caciocavallo/releases/download/%@/%@-%@.jar", lib.version, lib.artifact, lib.version];
    } else {
        return [NSString stringWithFormat:@"https://github.com/RobbitFPV/Caciocavallo17/releases/download/%@/%@-%@.jar", lib.version, lib.artifact, lib.version];
    }
}

- (NSString *)localPathForCaciocavallo:(PCLCaciocavalloVersion)version {
    NSArray *libs = [self requiredCaciocavalloForJavaVersion:version == PCLCaciocavalloVersion8 ? 8 : 17];
    if (libs.count == 0) return nil;
    
    PCLCaciocavalloLibrary *lib = libs[0];
    NSString *filename = [NSString stringWithFormat:@"%@-%@.jar", lib.artifact, lib.version];
    return [[self caciocavalloDirectory] stringByAppendingPathComponent:filename];
}

- (BOOL)isCaciocavalloDownloaded:(PCLCaciocavalloVersion)version {
    NSString *path = [self localPathForCaciocavallo:version];
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

- (NSString *)caciocavalloClasspath:(PCLCaciocavalloVersion)version {
    NSMutableString *classpath = [NSMutableString string];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSArray *libs = [self requiredCaciocavalloForJavaVersion:version == PCLCaciocavalloVersion8 ? 8 : 17];
    
    for (PCLCaciocavalloLibrary *lib in libs) {
        NSString *filename = [NSString stringWithFormat:@"%@-%@.jar", lib.artifact, lib.version];
        NSString *path = [[self caciocavalloDirectory] stringByAppendingPathComponent:filename];
        
        if ([fm fileExistsAtPath:path]) {
            if (classpath.length > 0) {
                [classpath appendString:@":"];
            }
            [classpath appendString:path];
        }
    }
    
    return [NSString stringWithString:classpath];
}

- (void)downloadCaciocavallo:(PCLCaciocavalloVersion)version
                    progress:(void (^)(double))progress
                  completion:(void (^)(BOOL, NSError *))completion {
    
    if ([self isCaciocavalloDownloaded:version]) {
        NSString *versionStr = (version == PCLCaciocavalloVersion8) ? @"Java 8" : @"Java 17+";
        [[PCLLogger sharedLogger] info:[NSString stringWithFormat:@"Caciocavallo for %@ already downloaded, skipping", versionStr]];
        if (completion) completion(YES, nil);
        return;
    }
    
    NSString *versionStr = (version == PCLCaciocavalloVersion8) ? @"Java 8" : @"Java 17+";
    [[PCLLogger sharedLogger] info:[NSString stringWithFormat:@"Starting Caciocavallo download for %@", versionStr]];
    
    NSArray *libs = [self requiredCaciocavalloForJavaVersion:version == PCLCaciocavalloVersion8 ? 8 : 17];
    NSUInteger totalLibs = libs.count;
    __block NSUInteger completedLibs = 0;
    __block BOOL overallSuccess = YES;
    __block NSError *lastError = nil;
    
    dispatch_group_t downloadGroup = dispatch_group_create();
    dispatch_queue_t downloadQueue = dispatch_queue_create("com.pcl.caciocavallo.download", DISPATCH_QUEUE_SERIAL);
    
    for (PCLCaciocavalloLibrary *lib in libs) {
        dispatch_group_enter(downloadGroup);
        dispatch_async(downloadQueue, ^{
            NSString *filename = [NSString stringWithFormat:@"%@-%@.jar", lib.artifact, lib.version];
            NSString *localPath = [[self caciocavalloDirectory] stringByAppendingPathComponent:filename];
            
            NSString *downloadURL;
            if (version == PCLCaciocavalloVersion8) {
                downloadURL = [NSString stringWithFormat:@"https://github.com/RobbitFPV/Caciocavallo/releases/download/%@/%@", lib.version, filename];
            } else {
                downloadURL = [NSString stringWithFormat:@"https://github.com/RobbitFPV/Caciocavallo17/releases/download/%@/%@", lib.version, filename];
            }
            
            NSFileManager *fm = [NSFileManager defaultManager];
            if ([fm fileExistsAtPath:localPath]) {
                completedLibs++;
                dispatch_group_leave(downloadGroup);
                return;
            }
            
            dispatch_semaphore_t sema = dispatch_semaphore_create(0);
            
            PCLDownloadTask *task = [[PCLDownloadTask alloc] init];
            task.url = downloadURL;
            task.targetPath = localPath;
            task.displayName = filename;
            task.resourceType = PCLResourceTypeLibrary;
            
            [[PCLDownloadManager sharedManager] addTask:task];
            [[PCLDownloadManager sharedManager] startDownload:task];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                BOOL success = (task.state == PCLDownloadStateCompleted);
                
                NSFileManager *fm2 = [NSFileManager defaultManager];
                if (success && [fm2 fileExistsAtPath:localPath]) {
                    completedLibs++;
                    [[PCLLogger sharedLogger] info:[NSString stringWithFormat:@"Caciocavallo library %@ downloaded", filename]];
                } else if (!success) {
                    overallSuccess = NO;
                    lastError = task.error ?: [NSError errorWithDomain:@"PCLCaciocavalloManager" code:-1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Failed to download %@", filename]}];
                    [[PCLLogger sharedLogger] error:[NSString stringWithFormat:@"Failed to download Caciocavallo library %@: %@", filename, lastError.localizedDescription]];
                }
                
                double currentProgress = (double)completedLibs / (double)totalLibs;
                if (progress) {
                    progress(currentProgress);
                }
                
                dispatch_semaphore_signal(sema);
            });
            
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
            dispatch_group_leave(downloadGroup);
        });
    }
    
    dispatch_group_notify(downloadGroup, dispatch_get_main_queue(), ^{
        if (overallSuccess) {
            [[PCLLogger sharedLogger] info:[NSString stringWithFormat:@"Caciocavallo for %@ download complete", versionStr]];
        } else {
            [[PCLLogger sharedLogger] error:[NSString stringWithFormat:@"Caciocavallo for %@ download failed", versionStr]];
        }
        if (completion) completion(overallSuccess, lastError);
    });
}

@end
