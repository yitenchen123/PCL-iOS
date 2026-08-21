#import "PCLJavaManager.h"
#import "PCLDownloadManager.h"

@interface PCLJavaManager ()

@property (nonatomic, assign) BOOL isDownloading;
@property (nonatomic, assign) NSInteger downloadingVersion;
@property (nonatomic, strong) NSString *currentJavaHome;
@property (nonatomic, assign) NSInteger currentJavaVersion;

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

- (instancetype)init {
    self = [super init];
    if (self) {
        _isDownloading = NO;
        _downloadingVersion = 0;
        // Find existing Java home
        [self scanExistingJava];
    }
    return self;
}

- (void)scanExistingJava {
    // Check for bundled JREs first, then downloaded ones
    NSArray *versions = @[@8, @7, @11, @16, @17, @21];
    for (NSNumber *ver in versions) {
        NSString *home = [self javaHomeForVersion:ver.integerValue];
        if (home) {
            _currentJavaVersion = ver.integerValue;
            _currentJavaHome = home;
            break;
        }
    }
}

#pragma mark - Java Path Helpers

- (NSString *)javaHomeDirectory:(NSInteger)version {
    NSString *docsDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    return [docsDir stringByAppendingPathComponent:[NSString stringWithFormat:@"java/jre-%ld", (long)version]];
}

- (NSString *)javaHomeForVersion:(NSInteger)version {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *targetHome = [self javaHomeDirectory:version];
    
    // Check if java executable exists
    NSString *javaExec = [targetHome stringByAppendingPathComponent:@"bin/java"];
    if ([fm fileExistsAtPath:javaExec]) {
        return targetHome;
    }
    
    // Search subdirectories (PojavLauncher/Amethyst style: JRE may be nested)
    NSError *error = nil;
    NSArray *contents = [fm contentsOfDirectoryAtPath:targetHome error:&error];
    if (contents.count == 1) {
        NSString *subDir = [targetHome stringByAppendingPathComponent:contents[0]];
        BOOL isDirectory = NO;
        if ([fm fileExistsAtPath:subDir isDirectory:&isDirectory] && isDirectory) {
            javaExec = [subDir stringByAppendingPathComponent:@"bin/java"];
            if ([fm fileExistsAtPath:javaExec]) {
                return subDir;
            }
        }
    }
    
    return nil;
}

- (NSString *)javaExecutableForVersion:(NSInteger)version {
    NSString *javaHome = [self javaHomeForVersion:version];
    if (!javaHome) return nil;
    
    NSString *javaExec = [javaHome stringByAppendingPathComponent:@"bin/java"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:javaExec]) {
        return javaExec;
    }
    
    return nil;
}

- (NSInteger)javaVersionFromMC:(NSString *)mcVersion {
    return [self recommendedJavaVersionForMC:mcVersion];
}

- (NSInteger)recommendedJavaVersionForMC:(NSString *)mcVersion {
    if (!mcVersion || mcVersion.length == 0) return 8;
    
    // Parse major.minor.patch version
    NSArray *parts = [mcVersion componentsSeparatedByString:@"."];
    if (parts.count < 2) return 8;
    
    NSInteger major = [parts[0] integerValue];
    NSInteger minor = 0;
    NSInteger patch = 0;
    
    if (parts.count >= 2) minor = [parts[1] integerValue];
    if (parts.count >= 3) {
        // Handle versions like "1.20.4" where patch may contain non-numeric chars
        NSString *patchStr = parts[2];
        NSScanner *scanner = [NSScanner scannerWithString:patchStr];
        [scanner scanInteger:&patch];
    }
    
    if (major == 1) {
        // MC < 1.6: Java 7
        if (minor <= 5) return 7;
        // MC 1.6 ~ 1.16: Java 8 (1.13+ technically supports Java 11)
        if (minor <= 16) return 8;
        // MC 1.17 ~ 1.17.1: Java 16
        if (minor == 17) {
            if (patch <= 1) return 16;
            return 17;
        }
        // MC 1.18 ~ 1.20.4: Java 17
        if (minor == 20 && patch <= 4) return 17;
        if (minor <= 20) return 17;
        // MC 1.20.5+: Java 21
        return 21;
    }
    
    // Fallback
    return 17;
}

- (NSString *)javaDisplayName:(NSInteger)version {
    switch (version) {
        case 7: return @"Java 7";
        case 8: return @"Java 8";
        case 11: return @"Java 11";
        case 16: return @"Java 16";
        case 17: return @"Java 17";
        case 21: return @"Java 21";
        case 25: return @"Java 25";
        default: return [NSString stringWithFormat:@"Java %ld", (long)version];
    }
}

#pragma mark - Download

- (NSString *)downloadURLForJava:(NSInteger)version {
    // Use Azul Zulu JRE builds - compatible with iOS/ARM64
    // These are community-trusted builds used by PojavLauncher ecosystem
    
    NSString *baseUrl = @"https://cdn.azul.com/zulu/bin";
    NSString *fileName;
    
    switch (version) {
        case 7:
            fileName = @"zulu7.56.0.11-ca-jre7.0.352-macosx_aarch64.tar.gz";
            break;
        case 8:
            fileName = @"zulu8.78.0.19-ca-jre8.0.412-macosx_aarch64.tar.gz";
            break;
        case 11:
            fileName = @"zulu11.70.15-ca-jre11.0.23-macosx_aarch64.tar.gz";
            break;
        case 16:
            fileName = @"zulu16.32.15-ca-jre16.0.2-macosx_aarch64.tar.gz";
            break;
        case 17:
            fileName = @"zulu17.50.19-ca-jre17.0.11-macosx_aarch64.tar.gz";
            break;
        case 21:
            fileName = @"zulu21.34.19-ca-jre21.0.3-macosx_aarch64.tar.gz";
            break;
        default:
            fileName = @"zulu8.78.0.19-ca-jre8.0.412-macosx_aarch64.tar.gz";
            break;
    }
    
    return [NSString stringWithFormat:@"%@/%@", baseUrl, fileName];
}

- (NSString *)alternativeDownloadURLForJava:(NSInteger)version {
    // Alternative source via PojavLauncher CDN / community mirrors
    switch (version) {
        case 7:
            return @"https://jenkins.pojavlauncherteam.com/job/JRE-7/job/Zulu-JRE-7/lastSuccessfulBuild/artifact/zulu7.56.0.11-ca-jre7.0.352-linux_aarch64.tar.gz";
        case 8:
            return @"https://github.com/Huazhi3000/JRE/releases/download/v8.0.412/jre8u412-arm64.tar.gz";
        case 17:
            return @"https://github.com/Huazhi3000/JRE/releases/download/v17.0.11/jre17-arm64.tar.gz";
        default:
            return [self downloadURLForJava:version];
    }
}

- (BOOL)isJavaAvailable:(NSInteger)version {
    return [self javaHomeForVersion:version] != nil;
}

- (void)ensureJavaDownloaded:(NSInteger)version
                    progress:(PCLJavaDownloadProgress)progress
                  completion:(PCLJavaDownloadCompletion)completion {
    
    // Check if already available
    if ([self isJavaAvailable:version]) {
        if (progress) progress(1.0);
        if (completion) completion(YES, nil);
        return;
    }
    
    // Check if already downloading
    if (self.isDownloading) {
        if (completion) completion(NO, [NSError errorWithDomain:@"PCLJavaManager" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"下载正在进行中"}]);
        return;
    }
    
    self.isDownloading = YES;
    self.downloadingVersion = version;
    
    // Get download URL
    NSString *url = [self downloadURLForJava:version];
    NSString *docsDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *downloadPath = [docsDir stringByAppendingPathComponent:[NSString stringWithFormat:@"java/jre-%ld.tar.gz", (long)version]];
    
    // Ensure directory exists
    NSString *dir = [downloadPath stringByDeletingLastPathComponent];
    [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    
    if (progress) progress(0.0);
    
    __weak typeof(self) weakSelf = self;
    
    [[PCLDownloadManager sharedManager] downloadFile:url
                                              toPath:downloadPath
                                                sha1:nil
                                             success:^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        
        if (progress) progress(0.7);
        
        // Create target directory
        NSString *targetDir = [self javaHomeDirectory:version];
        [[NSFileManager defaultManager] createDirectoryAtPath:targetDir withIntermediateDirectories:YES attributes:nil error:nil];
        
        // Extract
        BOOL extracted = [self extractJavaAtPath:downloadPath targetDir:targetDir];
        
        // Clean up archive
        [[NSFileManager defaultManager] removeItemAtPath:downloadPath error:nil];
        
        self.isDownloading = NO;
        
        if (extracted) {
            [self scanExistingJava];
            if (progress) progress(1.0);
            if (completion) completion(YES, nil);
        } else {
            self.downloadingVersion = 0;
            if (completion) completion(NO, [NSError errorWithDomain:@"PCLJavaManager" code:-2 userInfo:@{NSLocalizedDescriptionKey: @"解压 Java 失败"}]);
        }
    } failure:^(NSError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        
        self.isDownloading = NO;
        self.downloadingVersion = 0;
        [[NSFileManager defaultManager] removeItemAtPath:downloadPath error:nil];
        
        // Try alternative URL
        NSString *altUrl = [weakSelf alternativeDownloadURLForJava:version];
        if (altUrl && ![altUrl isEqualToString:url]) {
            [[PCLDownloadManager sharedManager] downloadFile:altUrl
                                                      toPath:downloadPath
                                                        sha1:nil
                                                     success:^{
                __strong typeof(weakSelf) self = weakSelf;
                if (!self) return;
                
                if (progress) progress(0.7);
                NSString *targetDir = [self javaHomeDirectory:version];
                [[NSFileManager defaultManager] createDirectoryAtPath:targetDir withIntermediateDirectories:YES attributes:nil error:nil];
                BOOL extracted = [self extractJavaAtPath:downloadPath targetDir:targetDir];
                [[NSFileManager defaultManager] removeItemAtPath:downloadPath error:nil];
                
                self.isDownloading = NO;
                if (extracted) {
                    [self scanExistingJava];
                    if (progress) progress(1.0);
                    if (completion) completion(YES, nil);
                } else {
                    if (completion) completion(NO, [NSError errorWithDomain:@"PCLJavaManager" code:-3 userInfo:@{NSLocalizedDescriptionKey: "解压 Java 失败"}]);
                }
            } failure:^(NSError *altError) {
                __strong typeof(weakSelf) self = weakSelf;
                if (!self) return;
                self.isDownloading = NO;
                [[NSFileManager defaultManager] removeItemAtPath:downloadPath error:nil];
                if (completion) completion(NO, altError);
            }];
        } else {
            if (completion) completion(NO, error);
        }
    }];
}

- (BOOL)extractJavaAtPath:(NSString *)path targetDir:(NSString *)targetDir {
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // Use NSTask to extract tar.gz
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/tar";
    task.arguments = @[@"-xzf", path, @"-C", targetDir, @"--strip-components=1"];
    
    NSPipe *pipe = [NSPipe pipe];
    task.standardError = pipe;
    
    @try {
        [task launch];
        [task waitUntilExit];
    } @catch (NSException *exception) {
        // On iOS, NSTask may not be available - use libarchive or manual extraction
        NSLog(@"[PCLJavaManager] Extract exception: %@", exception);
        
        // Fallback: try shell command via posix_spawn
        return [self extractWithSystem:path targetDir:targetDir];
    }
    
    if (task.terminationStatus == 0) {
        // Verify
        return [self verifyJavaInstallation:targetDir];
    }
    
    return [self extractWithSystem:path targetDir:targetDir];
}

- (BOOL)extractWithSystem:(NSString *)path targetDir:(NSString *)targetDir {
    // Use system() as fallback
    NSString *cmd = [NSString stringWithFormat:@"tar -xzf '%@' -C '%@' --strip-components=1", path, targetDir];
    int result = system(cmd.UTF8String);
    return (result == 0) ? [self verifyJavaInstallation:targetDir] : NO;
}

- (BOOL)verifyJavaInstallation:(NSString *)javaHome {
    // Check for java executable
    NSString *javaExec = [javaHome stringByAppendingPathComponent:@"bin/java"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:javaExec]) {
        return YES;
    }
    
    // Sometimes the JRE is nested one level deeper
    NSError *error = nil;
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:javaHome error:&error];
    for (NSString *item in contents) {
        if ([item hasPrefix:@"zulu"] || [item hasPrefix:@"jre"] || [item hasPrefix:@"jdk"]) {
            NSString *nested = [javaHome stringByAppendingPathComponent:item];
            NSString *nestedJava = [nested stringByAppendingPathComponent:@"bin/java"];
            if ([[NSFileManager defaultManager] fileExistsAtPath:nestedJava]) {
                return YES;
            }
        }
    }
    
    return NO;
}

@end
