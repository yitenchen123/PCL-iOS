#import "PCLJavaDownloader.h"
#import "PCLDownloadManager.h"
#import "PCLLogger.h"

static NSString *const kAzulAPIBaseURL = @"https://api.azul.com/zulu/download/community/v1.0/binaries/latest/";

@implementation PCLJavaDownloader

+ (instancetype)sharedDownloader {
    static PCLJavaDownloader *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PCLJavaDownloader alloc] init];
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

- (NSString *)javaPathForVersion:(PCLJavaVersion)version {
    return [[self javaDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"java-%ld", (long)version]];
}

- (NSString *)javaBinaryPathForVersion:(PCLJavaVersion)version {
    return [[self javaPathForVersion:version] stringByAppendingPathComponent:@"bin/java"];
}

- (NSString *)downloadURLForJavaVersion:(PCLJavaVersion)version {
    return [NSString stringWithFormat:@"%@?java_version=%ld&os=ios&arch=arm64&archive_type=zip&bundle_type=jre", kAzulAPIBaseURL, (long)version];
}

- (long long)expectedSizeForJavaVersion:(PCLJavaVersion)version {
    switch (version) {
        case PCLJavaVersion8:  return 45 * 1024 * 1024;
        case PCLJavaVersion11: return 50 * 1024 * 1024;
        case PCLJavaVersion17: return 55 * 1024 * 1024;
        case PCLJavaVersion21: return 60 * 1024 * 1024;
    }
    return 50 * 1024 * 1024;
}

- (BOOL)isJavaDownloaded:(PCLJavaVersion)version {
    NSString *javaBin = [self javaBinaryPathForVersion:version];
    return [[NSFileManager defaultManager] fileExistsAtPath:javaBin];
}

- (void)downloadJava:(PCLJavaVersion)version
            progress:(void (^)(double))progress
          completion:(void (^)(BOOL, NSError *))completion {
    
    if ([self isJavaDownloaded:version]) {
        [[PCLLogger sharedLogger] info:[NSString stringWithFormat:@"Java %ld already downloaded, skipping", (long)version]];
        if (completion) completion(YES, nil);
        return;
    }
    
    NSString *versionStr = [NSString stringWithFormat:@"%ld", (long)version];
    NSString *zipPath = [[self javaDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"java-%@.zip", versionStr]];
    NSString *destPath = [self javaPathForVersion:version];
    NSString *downloadURL = [self downloadURLForJavaVersion:version];
    
    [[PCLLogger sharedLogger] info:[NSString stringWithFormat:@"Starting Java %ld download from Azul Zulu API", (long)version]];
    
    PCLDownloadTask *task = [[PCLDownloadTask alloc] init];
    task.url = downloadURL;
    task.targetPath = zipPath;
    task.displayName = [NSString stringWithFormat:@"Java %ld JRE", (long)version];
    task.resourceType = PCLResourceTypeLibrary;
    task.totalBytes = [self expectedSizeForJavaVersion:version];
    
    [[PCLDownloadManager sharedManager] addTask:task];
    [[PCLDownloadManager sharedManager] startDownload:task];
    
    dispatch_queue_t monitorQueue = dispatch_queue_create("com.pcl.java.download.monitor", DISPATCH_QUEUE_SERIAL);
    dispatch_async(monitorQueue, ^{
        BOOL success = NO;
        NSError *error = nil;
        
        while (task.state == PCLDownloadStateDownloading || task.state == PCLDownloadStatePending) {
            if (progress) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    progress(task.progress);
                });
            }
            [NSThread sleepForTimeInterval:0.5];
        }
        
        if (task.state == PCLDownloadStateCompleted) {
            NSFileManager *fm = [NSFileManager defaultManager];
            [fm createDirectoryAtPath:destPath withIntermediateDirectories:YES attributes:nil error:nil];
            
            success = [self unzipFileAtPath:zipPath toDestination:destPath];
            
            if (success) {
                success = [self verifyJavaAtPath:destPath];
            }
            
            if (!success) {
                error = [NSError errorWithDomain:@"PCLJavaDownloader" code:-2 userInfo:@{NSLocalizedDescriptionKey: @"Java installation verification failed"}];
                [fm removeItemAtPath:destPath error:nil];
            }
            
            [fm removeItemAtPath:zipPath error:nil];
        } else {
            error = task.error ?: [NSError errorWithDomain:@"PCLJavaDownloader" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Download failed"}];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                [[PCLLogger sharedLogger] info:[NSString stringWithFormat:@"Java %ld download and installation complete", (long)version]];
            } else {
                [[PCLLogger sharedLogger] error:[NSString stringWithFormat:@"Java %ld download failed: %@", (long)version, error.localizedDescription]];
            }
            if (completion) completion(success, error);
        });
    });
}

- (BOOL)verifyJavaAtPath:(NSString *)path {
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSString *javaBin = [path stringByAppendingPathComponent:@"bin/java"];
    if (![fm fileExistsAtPath:javaBin]) {
        [[PCLLogger sharedLogger] warning:[NSString stringWithFormat:@"Java binary not found at %@", javaBin]];
        return NO;
    }
    
    NSString *releaseFile = [path stringByAppendingPathComponent:@"release"];
    if (![fm fileExistsAtPath:releaseFile]) {
        [[PCLLogger sharedLogger] warning:[NSString stringWithFormat:@"Java release file not found at %@", releaseFile]];
        return NO;
    }
    
    NSError *error = nil;
    NSString *releaseContent = [NSString stringWithContentsOfFile:releaseFile encoding:NSUTF8StringEncoding error:&error];
    if (error || releaseContent.length == 0) {
        [[PCLLogger sharedLogger] warning:@"Could not read Java release file"];
        return NO;
    }
    
    if (![releaseContent containsString:@"JAVA_VERSION="]) {
        [[PCLLogger sharedLogger] warning:@"Java release file missing JAVA_VERSION"];
        return NO;
    }
    
    return YES;
}

- (NSInteger)javaVersionAtPath:(NSString *)path {
    NSString *releaseFile = [path stringByAppendingPathComponent:@"release"];
    NSError *error = nil;
    NSString *releaseContent = [NSString stringWithContentsOfFile:releaseFile encoding:NSUTF8StringEncoding error:&error];
    
    if (error || releaseContent.length == 0) {
        return 0;
    }
    
    NSArray *lines = [releaseContent componentsSeparatedByString:@"\n"];
    for (NSString *line in lines) {
        if ([line hasPrefix:@"JAVA_VERSION="]) {
            NSString *versionStr = [line stringByReplacingOccurrencesOfString:@"JAVA_VERSION=" withString:@""];
            versionStr = [versionStr stringByReplacingOccurrencesOfString:@"\"" withString:@""];
            
            NSArray *components = [versionStr componentsSeparatedByString:@"."];
            if (components.count > 0) {
                NSString *major = components[0];
                if ([major isEqualToString:@"1"] && components.count > 1) {
                    return [components[1] integerValue];
                }
                return [major integerValue];
            }
        }
    }
    
    return 0;
}

#pragma mark - Zip Extraction

- (BOOL)unzipFileAtPath:(NSString *)zipPath toDestination:(NSString *)destPath {
    NSFileManager *fm = [NSFileManager defaultManager];
    
    if (![fm fileExistsAtPath:zipPath]) {
        [[PCLLogger sharedLogger] error:[NSString stringWithFormat:@"Zip file not found: %@", zipPath]];
        return NO;
    }
    
    [fm createDirectoryAtPath:destPath withIntermediateDirectories:YES attributes:nil error:nil];
    
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/unzip";
    task.arguments = @[@"-o", zipPath, @"-d", destPath];
    
    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    task.standardError = pipe;
    
    @try {
        [task launch];
        [task waitUntilExit];
    } @catch (NSException *exception) {
        [[PCLLogger sharedLogger] error:[NSString stringWithFormat:@"Unzip failed: %@", exception.reason]];
        return [self unzipUsingPythonAtPath:zipPath toDestination:destPath];
    }
    
    if (task.terminationStatus != 0) {
        [[PCLLogger sharedLogger] warning:@"unzip command failed, trying alternative method"];
        return [self unzipUsingPythonAtPath:zipPath toDestination:destPath];
    }
    
    return YES;
}

- (BOOL)unzipUsingPythonAtPath:(NSString *)zipPath toDestination:(NSString *)destPath {
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSString *scriptPath = [destPath stringByAppendingPathComponent:@"__unzip_helper__.py"];
    NSString *scriptContent = [NSString stringWithFormat:
        @"import zipfile, os, sys\n"
        @"with zipfile.ZipFile('%@', 'r') as z:\n"
        @"    z.extractall('%@')\n", zipPath, destPath];
    
    [scriptContent writeToFile:scriptPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/python3";
    task.arguments = @[scriptPath];
    
    @try {
        [task launch];
        [task waitUntilExit];
    } @catch (NSException *exception) {
        [[PCLLogger sharedLogger] error:[NSString stringWithFormat:@"Python unzip failed: %@", exception.reason]];
        return NO;
    }
    
    [fm removeItemAtPath:scriptPath error:nil];
    return task.terminationStatus == 0;
}

@end
