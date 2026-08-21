#import "PCLJavaManager.h"
#import "PCLDownloadManager.h"

@interface PCLJavaManager ()

@property (nonatomic, readwrite, assign) BOOL isDownloading;
@property (nonatomic, readwrite, assign) NSInteger downloadingVersion;
@property (nonatomic, readwrite, strong) NSString *currentJavaHome;
@property (nonatomic, readwrite, assign) NSInteger currentJavaVersion;

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
        _currentJavaHome = nil;
        _currentJavaVersion = 0;
        [self scanExistingJava];
    }
    return self;
}

- (void)scanExistingJava {
    // Check for bundled/pre-installed JREs
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
    
    // Check resource bundle for pre-bundled JRE
    NSString *bundleJRE = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:[NSString stringWithFormat:@"jre%ld", (long)version]];
    javaExec = [bundleJRE stringByAppendingPathComponent:@"bin/java"];
    if ([fm fileExistsAtPath:javaExec]) {
        return bundleJRE;
    }
    
    // Search subdirectories
    NSError *error = nil;
    NSArray *contents = [fm contentsOfDirectoryAtPath:targetHome error:&error];
    if (contents.count > 0) {
        for (NSString *item in contents) {
            BOOL isDir = NO;
            NSString *subDir = [targetHome stringByAppendingPathComponent:item];
            if ([fm fileExistsAtPath:subDir isDirectory:&isDir] && isDir) {
                javaExec = [subDir stringByAppendingPathComponent:@"bin/java"];
                if ([fm fileExistsAtPath:javaExec]) {
                    return subDir;
                }
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
    
    NSArray *parts = [mcVersion componentsSeparatedByString:@"."];
    if (parts.count < 2) return 8;
    
    NSInteger major = [parts[0] integerValue];
    NSInteger minor = 0;
    NSInteger patch = 0;
    
    if (parts.count >= 2) minor = [parts[1] integerValue];
    if (parts.count >= 3) {
        NSString *patchStr = parts[2];
        NSScanner *scanner = [NSScanner scannerWithString:patchStr];
        [scanner scanInteger:&patch];
    }
    
    if (major == 1) {
        if (minor <= 5) return 7;
        if (minor <= 16) return 8;
        if (minor == 17) {
            if (patch <= 1) return 16;
            return 17;
        }
        if (minor == 20 && patch <= 4) return 17;
        if (minor <= 20) return 17;
        return 21;
    }
    
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
    // Use Azul Zulu JRE builds via CDN
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
        NSError *err = [NSError errorWithDomain:@"PCLJavaManager" code:-1
                                       userInfo:@{NSLocalizedDescriptionKey: @"下载正在进行中"}];
        if (completion) completion(NO, err);
        return;
    }
    
    self.isDownloading = YES;
    self.downloadingVersion = version;
    
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
        
        // Note: On iOS, NSTask/system() are unavailable. 
        // The archive should be extracted using a bundled extraction library.
        // For now, we check if extraction was done by build-time script
        BOOL extracted = [self verifyJavaInstallation:targetDir];
        
        // Clean up archive
        [[NSFileManager defaultManager] removeItemAtPath:downloadPath error:nil];
        
        self.isDownloading = NO;
        
        if (extracted) {
            [self scanExistingJava];
            if (progress) progress(1.0);
            if (completion) completion(YES, nil);
        } else {
            self.downloadingVersion = 0;
            NSError *err = [NSError errorWithDomain:@"PCLJavaManager" code:-2
                                           userInfo:@{NSLocalizedDescriptionKey: @"解压 Java 失败，请确保 JRE 已预置在应用资源中"}];
            if (completion) completion(NO, err);
        }
    } failure:^(NSError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        
        self.isDownloading = NO;
        self.downloadingVersion = 0;
        [[NSFileManager defaultManager] removeItemAtPath:downloadPath error:nil];
        if (completion) completion(NO, error);
    }];
}

- (BOOL)verifyJavaInstallation:(NSString *)javaHome {
    NSString *javaExec = [javaHome stringByAppendingPathComponent:@"bin/java"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:javaExec]) {
        return YES;
    }
    
    // Check nested directories
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
