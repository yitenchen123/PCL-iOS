#import "PCLJavaRuntime.h"
#import "PCLZipExtractor.h"

static NSString *const kJREInstalledFlag = @"PCL(JavaRuntimesInstalled-v1)";

@interface PCLJavaRuntime ()
@property (nonatomic, strong) NSString *cachedRuntimesDir;
@property (nonatomic, assign) BOOL isBusy;
@property (nonatomic, strong) NSURLSessionDownloadTask *currentTask;
@end

@implementation PCLJavaRuntime

+ (instancetype)sharedRuntime {
    static PCLJavaRuntime *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PCLJavaRuntime alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // JRE解压到 Library/Caches/Java 目录
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *cachesDir = paths.firstObject;
        _cachedRuntimesDir = [cachesDir stringByAppendingPathComponent:@"Java"];
    }
    return self;
}

- (NSString *)javaRuntimesDir {
    return self.cachedRuntimesDir;
}

- (NSArray<NSString *> *)jreDownloadURLs {
    static NSArray *urls = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        urls = @[
            // Amethyst官方CDN（最可靠）
            @"https://github.com/AngelAuraMC/Amethyst-iOS/releases/latest/download/java_runtimes.zip",
            // 备用：直接下载各个JRE
            @"https://assets.angelauramc.dev/openjdk/ios-arm64/jre8-ios-aarch64.zip",
        ];
    });
    return urls;
}

- (void)ensureJREInstalled {
    // 检查JRE是否已安装
    if ([self checkJREInstalled]) {
        NSLog(@"[PCLJavaRuntime] JRE已安装");
        return;
    }
    
    // 检查bundle中是否有预打包的JRE zip
    NSString *bundleZip = [[NSBundle mainBundle] pathForResource:@"java_runtimes" ofType:@"zip"];
    if (bundleZip) {
        NSLog(@"[PCLJavaRuntime] 从bundle解压JRE");
        [self extractJREFromZip:bundleZip];
        return;
    }
    
    // 需要下载JRE
    NSLog(@"[PCLJavaRuntime] JRE未安装，需要下载");
}

- (BOOL)checkJREInstalled {
    NSFileManager *fm = [NSFileManager defaultManager];
    // 检查至少Java 8是否存在
    NSString *releasePath = [self.javaRuntimesDir stringByAppendingPathComponent:@"java-8-openjdk/release"];
    return [fm fileExistsAtPath:releasePath];
}

- (void)extractJREFromZip:(NSString *)zipPath {
    if (self.isBusy) return;
    self.isBusy = YES;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"[PCLJavaRuntime] 开始解压JRE...");
        
        // 清理旧目录
        [[NSFileManager defaultManager] removeItemAtPath:self.javaRuntimesDir error:nil];
        [[NSFileManager defaultManager] createDirectoryAtPath:self.javaRuntimesDir
                                 withIntermediateDirectories:YES
                                                  attributes:nil
                                                       error:nil];
        
        NSError *error = nil;
        BOOL success = [PCLZipExtractor extractZipAtPath:zipPath
                                                toPath:self.javaRuntimesDir
                                              progress:^(NSString *file, NSInteger cur, NSInteger total) {
            if (cur % 200 == 0 || cur == total) {
                NSLog(@"[PCLJavaRuntime] 解压进度: %ld/%ld", (long)cur, (long)total);
            }
        } error:&error];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.isBusy = NO;
            if (success) {
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kJREInstalledFlag];
                [[NSUserDefaults standardUserDefaults] synchronize];
                NSLog(@"[PCLJavaRuntime] JRE解压完成");
            } else {
                NSLog(@"[PCLJavaRuntime] JRE解压失败: %@", error.localizedDescription);
            }
        });
    });
}

- (void)downloadJREWithProgress:(void (^)(double, NSString *))progressBlock
                     completion:(void (^)(BOOL, NSError *))completion {
    if (self.isBusy) {
        if (completion) completion(NO, [NSError errorWithDomain:@"PCLJavaRuntime" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"已有任务在运行"}]);
        return;
    }
    
    self.isBusy = YES;
    
    // 使用第一个可用的URL
    NSString *urlString = [self.jreDownloadURLs firstObject];
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSLog(@"[PCLJavaRuntime] 开始下载JRE: %@", urlString);
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.timeoutIntervalForRequest = 300;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    __weak typeof(self) weakSelf = self;
    self.currentTask = [session downloadTaskWithURL:url completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        self.isBusy = NO;
        
        if (error) {
            NSLog(@"[PCLJavaRuntime] 下载失败: %@", error.localizedDescription);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(NO, error);
            });
            return;
        }
        
        // 移动文件到临时位置
        NSString *tempZip = [NSTemporaryDirectory() stringByAppendingPathComponent:@"jre_download.zip"];
        [[NSFileManager defaultManager] removeItemAtPath:tempZip error:nil];
        [[NSFileManager defaultManager] moveItemAtPath:location.path toPath:tempZip error:nil];
        
        // 解压
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSError *extractError = nil;
            BOOL success = [PCLZipExtractor extractZipAtPath:tempZip
                                                    toPath:self.javaRuntimesDir
                                                  progress:^(NSString *file, NSInteger cur, NSInteger total) {
                double progress = total > 0 ? (double)cur / total : 0;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (progressBlock) progressBlock(progress, [NSString stringWithFormat:@"解压中... %ld/%ld", (long)cur, (long)total]);
                });
            } error:&extractError];
            
            // 清理临时文件
            [[NSFileManager defaultManager] removeItemAtPath:tempZip error:nil];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kJREInstalledFlag];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    NSLog(@"[PCLJavaRuntime] JRE安装完成");
                    if (completion) completion(YES, nil);
                } else {
                    NSLog(@"[PCLJavaRuntime] JRE解压失败: %@", extractError.localizedDescription);
                    if (completion) completion(NO, extractError);
                }
            });
        });
    }];
    
    [self.currentTask resume];
}

- (NSString *)javaHomeForVersion:(NSInteger)version {
    NSString *path = [self.javaRuntimesDir stringByAppendingPathComponent:
        [NSString stringWithFormat:@"java-%ld-openjdk", (long)version]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:[path stringByAppendingPathComponent:@"release"]]) {
        return path;
    }
    return nil;
}

- (NSString *)javaExecutableForVersion:(NSInteger)version {
    NSString *home = [self javaHomeForVersion:version];
    if (home) {
        NSString *javaPath = [home stringByAppendingPathComponent:@"bin/java"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:javaPath]) {
            return javaPath;
        }
    }
    return nil;
}

- (BOOL)isJavaAvailable:(NSInteger)version {
    return [self javaExecutableForVersion:version] != nil;
}

- (NSInteger)recommendedJavaVersionForMC:(NSString *)mcVersion {
    if (!mcVersion) return 17;
    NSArray *parts = [mcVersion componentsSeparatedByString:@"."];
    if (parts.count < 2) return 17;
    NSInteger minor = [parts[1] integerValue];
    if (minor >= 17) return 21;
    if (minor >= 16) return 17;
    return 8;
}

@end
