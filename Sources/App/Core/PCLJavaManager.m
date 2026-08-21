#import "PCLJavaManager.h"
#import "PCLDownloadManager.h"

static NSString *const kJavaDownloadKey = @"javaDownloadInProgress";

@interface PCLJavaManager ()

@property (nonatomic, assign) BOOL isDownloading;
@property (nonatomic, assign) NSInteger downloadingVersion;

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
    }
    return self;
}

#pragma mark - Java Path Helpers

- (NSString *)javaHomeForVersion:(NSInteger)version {
    NSString *docsDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *javaHome = [docsDir stringByAppendingPathComponent:[NSString stringWithFormat:@"java/jdk-%ld", (long)version]];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // Check if Java exists and has the java executable
    NSString *javaExec = [javaHome stringByAppendingPathComponent:@"bin/java"];
    if ([fm fileExistsAtPath:javaExec]) {
        return javaHome;
    }
    
    // Check for iOS bundled JRE (PojavLauncher-style)
    NSString *bundledPath = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:[NSString stringWithFormat:@"jre%ld", (long)version]];
    if ([fm fileExistsAtPath:bundledPath]) {
        return bundledPath;
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
    if (!mcVersion) return 17;
    
    // Parse major.minor version
    NSArray *parts = [mcVersion componentsSeparatedByString:@"."];
    if (parts.count < 2) return 17;
    
    NSInteger major = [parts[0] integerValue];
    NSInteger minor = [parts[1] integerValue];
    
    if (major == 1) {
        if (minor <= 16) return 8;
        if (minor <= 17) return 16;
        if (minor <= 18) return 17;
        if (minor <= 20) {
            // 1.20.5+ requires Java 21
            if (minor == 20 && parts.count >= 3) {
                NSInteger patch = [parts[2] integerValue];
                if (patch >= 5) return 21;
            }
            return 17;
        }
        return 21;
    }
    
    return 17;
}

#pragma mark - Download

- (NSString *)downloadURLForJava:(NSInteger)version {
    // Use Adoptium (Eclipse Temurin) API for Java downloads
    NSString *baseURL = @"https://api.adoptium.net/v3/binary/latest";
    
    // Map to Adoptium version numbers
    NSInteger adoptiumVersion = version;
    if (version == 25) adoptiumVersion = 25;
    
    NSString *url = [NSString stringWithFormat:@"%@/%ld/gui/linux/x64/jre/hotspot/normal/eclipse",
                     baseURL, (long)adoptiumVersion];
    
    return url;
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
        if (completion) completion(NO, [NSError errorWithDomain:@"PCLJavaManager" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Download already in progress"}]);
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
    
    [[PCLDownloadManager sharedManager] downloadFile:url
                                              toPath:downloadPath
                                                sha1:nil
                                             success:^{
        self.isDownloading = NO;
        if (progress) progress(0.8);
        
        // Extract the downloaded archive
        BOOL extracted = [self extractJavaAtPath:downloadPath forVersion:version];
        
        // Clean up archive
        [[NSFileManager defaultManager] removeItemAtPath:downloadPath error:nil];
        
        if (extracted) {
            if (progress) progress(1.0);
            if (completion) completion(YES, nil);
        } else {
            if (completion) completion(NO, [NSError errorWithDomain:@"PCLJavaManager" code:-2 userInfo:@{NSLocalizedDescriptionKey: @"Failed to extract Java"}]);
        }
    } failure:^(NSError *error) {
        self.isDownloading = NO;
        [[NSFileManager defaultManager] removeItemAtPath:downloadPath error:nil];
        if (completion) completion(NO, error);
    }];
}

- (BOOL)extractJavaAtPath:(NSString *)path forVersion:(NSInteger)version {
    NSString *docsDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *targetDir = [docsDir stringByAppendingPathComponent:[NSString stringWithFormat:@"java/jdk-%ld", (long)version]];
    
    // Create target directory
    [[NSFileManager defaultManager] createDirectoryAtPath:targetDir withIntermediateDirectories:YES attributes:nil error:nil];
    
    // Use tar to extract
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/tar";
    task.arguments = @[@"-xzf", path, @"-C", targetDir, @"--strip-components=1"];
    
    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    task.standardError = pipe;
    
    [task launch];
    [task waitUntilExit];
    
    if (task.terminationStatus == 0) {
        // Verify java executable exists
        NSString *javaExec = [targetDir stringByAppendingPathComponent:@"bin/java"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:javaExec]) {
            return YES;
        }
    }
    
    return NO;
}

@end
