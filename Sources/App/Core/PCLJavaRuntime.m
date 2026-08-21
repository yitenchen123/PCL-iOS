#import "PCLJavaRuntime.h"
#import "PCLZipExtractor.h"

static NSString *const kJREExtractedFlag = @"PCL(JavaRuntimesExtracted-v3)";

@interface PCLJavaRuntime ()
@property (nonatomic, strong) NSString *cachedRuntimesDir;
@property (nonatomic, assign) BOOL isExtracting;
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
        // JRE解压到 Library/Caches/Java 目录（持久化存储）
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *cachesDir = paths.firstObject;
        _cachedRuntimesDir = [cachesDir stringByAppendingPathComponent:@"Java"];
    }
    return self;
}

- (NSString *)javaRuntimesDir {
    return self.cachedRuntimesDir;
}

- (void)ensureJREExtracted {
    if (self.isExtracting) return;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *zipPath = [[NSBundle mainBundle] pathForResource:@"java_runtimes" ofType:@"zip"];
    
    if (!zipPath) {
        NSLog(@"[PCLJavaRuntime] 未找到JRE压缩包");
        return;
    }
    
    // 检查是否需要解压
    BOOL needsExtract = ![defaults boolForKey:kJREExtractedFlag];
    if (!needsExtract) {
        // 验证关键文件是否存在
        NSString *releasePath = [self.javaRuntimesDir stringByAppendingPathComponent:@"java-8-openjdk/release"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:releasePath]) {
            NSLog(@"[PCLJavaRuntime] JRE已安装，跳过解压");
            return;
        }
        needsExtract = YES;
    }
    
    NSLog(@"[PCLJavaRuntime] 开始解压JRE到: %@", self.javaRuntimesDir);
    
    self.isExtracting = YES;
    
    // 清理旧目录
    [[NSFileManager defaultManager] removeItemAtPath:self.javaRuntimesDir error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:self.javaRuntimesDir
                             withIntermediateDirectories:YES
                                              attributes:nil
                                                   error:nil];
    
    // 使用内置ZIP解压器（不需要外部命令）
    NSError *error = nil;
    BOOL success = [PCLZipExtractor extractZipAtPath:zipPath
                                            toPath:self.javaRuntimesDir
                                          progress:^(NSString *file, NSInteger cur, NSInteger total) {
        if (cur % 100 == 0 || cur == total) {
            NSLog(@"[PCLJavaRuntime] 解压进度: %ld/%ld (%@)", (long)cur, (long)total, file);
        }
    } error:&error];
    
    self.isExtracting = NO;
    
    if (success) {
        [defaults setBool:YES forKey:kJREExtractedFlag];
        [defaults synchronize];
        NSLog(@"[PCLJavaRuntime] JRE解压完成");
    } else {
        NSLog(@"[PCLJavaRuntime] JRE解压失败: %@", error.localizedDescription);
    }
}

- (NSString *)javaHomeForVersion:(NSInteger)version {
    NSString *path = [self.javaRuntimesDir stringByAppendingPathComponent:
        [NSString stringWithFormat:@"java-%ld-openjdk", (long)version]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:[path stringByAppendingPathComponent:@"release"]]) {
        return path;
    }
    // 回退到bundle资源路径
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"java-%ld-openjdk", (long)version] ofType:nil];
    if (bundlePath && [[NSFileManager defaultManager] fileExistsAtPath:[path stringByAppendingPathComponent:@"bin/java"]]) {
        return bundlePath;
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
