#import "PCLJavaManager.h"
#import "PCLDownloadManager.h"

@implementation PCLJavaRuntime
@end

@implementation PCLJavaManager

+ (instancetype)sharedManager {
    static PCLJavaManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PCLJavaManager alloc] init];
    });
    return instance;
}

- (NSString *)documentsDirectory {
    return NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
}

- (NSString *)javaDirectory {
    NSString *path = [[self documentsDirectory] stringByAppendingPathComponent:@"PCL Games/java"];
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:path]) {
        [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return path;
}

- (NSInteger)recommendedJavaVersionForMC:(NSString *)mcVersion {
    if (!mcVersion) return 17;
    
    NSArray *components = [mcVersion componentsSeparatedByString:@"."];
    if (components.count < 2) return 17;
    
    NSInteger major = [components[0] integerValue];
    NSInteger minor = [components[1] integerValue];
    
    if (major >= 1 && minor >= 17) return 21;
    if (major >= 1 && minor >= 16) return 17;
    return 8;
}

- (NSArray<PCLJavaRuntime *> *)availableJavaVersions {
    NSMutableArray *javacases = [NSMutableArray array];
    
    NSInteger versions[] = {8, 11, 17, 21};
    for (int i = 0; i < 4; i++) {
        PCLJavaRuntime *rt = [[PCLJavaRuntime alloc] init];
        rt.version = [NSString stringWithFormat:@"%ld", (long)versions[i]];
        rt.name = [NSString stringWithFormat:@"Java %ld", (long)versions[i]];
        rt.path = [[self javaDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"java-%ld", (long)versions[i]]];
        rt.isDownloaded = [[NSFileManager defaultManager] fileExistsAtPath:[rt.path stringByAppendingPathComponent:@"bin/java"]];
        rt.totalSize = 50 * 1024 * 1024;
        rt.downloadURL = [NSString stringWithFormat:@"https://api.azul.com/zulu/download/community/v1.0/binaries/latest/?java_version=%ld&os=ios&arch=arm64&archive_type=zip&bundle_type=jre", (long)versions[i]];
        [javacases addObject:rt];
    }
    
    return javacases;
}

- (NSArray<PCLJavaRuntime *> *)installedJavaVersions {
    NSMutableArray *installed = [NSMutableArray array];
    for (PCLJavaRuntime *rt in [self availableJavaVersions]) {
        if (rt.isDownloaded) {
            [installed addObject:rt];
        }
    }
    return installed;
}

- (PCLJavaRuntime *)javaRuntimeForVersion:(NSString *)mcVersion {
    NSInteger requiredJava = [self recommendedJavaVersionForMC:mcVersion];
    
    NSArray *installed = [self installedJavaVersions];
    for (PCLJavaRuntime *rt in installed) {
        if ([rt.version integerValue] == requiredJava) {
            return rt;
        }
    }
    
    for (PCLJavaRuntime *rt in [self availableJavaVersions]) {
        if ([rt.version integerValue] == requiredJava) {
            return rt;
        }
    }
    
    return nil;
}

- (void)downloadJava:(PCLJavaRuntime *)javaRuntime
            progress:(void (^)(double))progress
          completion:(void (^)(BOOL, NSError *))completion {
    if (javaRuntime.isDownloaded) {
        if (completion) completion(YES, nil);
        return;
    }
    
    NSString *zipPath = [[self javaDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"java-%@.zip", javaRuntime.version]];
    NSString *destPath = javaRuntime.path;
    
    PCLDownloadTask *task = [[PCLDownloadTask alloc] init];
    task.url = javaRuntime.downloadURL;
    task.targetPath = zipPath;
    task.displayName = [NSString stringWithFormat:@"Java %@", javaRuntime.version];
    task.resourceType = PCLResourceTypeLibrary;
    
    [[PCLDownloadManager sharedManager] addTask:task];
    [[PCLDownloadManager sharedManager] startDownload:task];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        BOOL success = [[NSFileManager defaultManager] fileExistsAtPath:zipPath];
        if (success) {
            NSFileManager *fm = [NSFileManager defaultManager];
            [fm createDirectoryAtPath:destPath withIntermediateDirectories:YES attributes:nil error:nil];
            javaRuntime.isDownloaded = YES;
        }
        if (completion) completion(success, success ? nil : [NSError errorWithDomain:@"PCLJava" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Download failed"}]);
    });
}

- (NSString *)findJavaPathForMCVersion:(NSString *)mcVersion {
    PCLJavaRuntime *rt = [self javaRuntimeForVersion:mcVersion];
    if (rt && rt.isDownloaded) {
        NSString *javaBin = [rt.path stringByAppendingPathComponent:@"bin/java"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:javaBin]) {
            return javaBin;
        }
    }
    return nil;
}

@end
