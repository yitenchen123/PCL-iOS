#import "PCLJavaRuntime.h"
#include <sys/stat.h>

static NSString *const kJREExtractedFlag = @"PCL(JavaRuntimesExtracted-v2)";

@interface PCLJavaRuntime ()
@property (nonatomic, strong) NSString *cachedRuntimesDir;
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
        // JRE解压到 Documents/Java 目录（持久化，不会被系统清理）
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docsDir = paths.firstObject;
        _cachedRuntimesDir = [docsDir stringByAppendingPathComponent:@"Java"];
    }
    return self;
}

- (NSString *)javaRuntimesDir {
    return self.cachedRuntimesDir;
}

- (void)ensureJREExtracted {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *zipPath = [[NSBundle mainBundle] pathForResource:@"java_runtimes" ofType:@"zip"];
    
    if (!zipPath) {
        NSLog(@"[PCLJavaRuntime] 未找到JRE压缩包，跳过解压");
        return;
    }
    
    // 检查是否需要解压（首次启动或解压失败）
    BOOL needsExtract = ![defaults boolForKey:kJREExtractedFlag];
    if (!needsExtract) {
        // 验证解压后的文件是否存在
        for (NSNumber *ver in @[@8, @17, @21, @25]) {
            NSString *releasePath = [self.javaRuntimesDir stringByAppendingPathComponent:
                [NSString stringWithFormat:@"java-%ld-openjdk/release", (long)ver.integerValue]];
            if (![[NSFileManager defaultManager] fileExistsAtPath:releasePath]) {
                needsExtract = YES;
                break;
            }
        }
    }
    
    if (!needsExtract) {
        NSLog(@"[PCLJavaRuntime] JRE已解压，跳过");
        return;
    }
    
    NSLog(@"[PCLJavaRuntime] 开始解压JRE...");
    
    // 清理旧目录
    [[NSFileManager defaultManager] removeItemAtPath:self.javaRuntimesDir error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:self.javaRuntimesDir
                             withIntermediateDirectories:YES
                                              attributes:nil
                                                   error:nil];
    
    // 使用unzip命令解压（TrollStore越狱环境中可用）
    NSString *cmd = [NSString stringWithFormat:@"/usr/bin/unzip -q -o '%@' -d '%@'", zipPath, self.javaRuntimesDir];
    int ret = system(cmd.UTF8String);
    
    if (ret != 0) {
        NSLog(@"[PCLJavaRuntime] system(unzip)失败(ret=%d)，尝试busybox unzip...", ret);
        // 尝试busybox
        cmd = [NSString stringWithFormat:@"/var/jb/usr/bin/unzip -q -o '%@' -d '%@'", zipPath, self.javaRuntimesDir];
        ret = system(cmd.UTF8String);
    }
    
    if (ret != 0) {
        NSLog(@"[PCLJavaRuntime] 所有unzip尝试失败，尝试procursus路径...");
        // 尝试dopamine/procursus路径
        NSArray *unzipPaths = @[
            @"/private/preboot/*/procursus/usr/bin/unzip",
            @"/usr/local/bin/unzip",
            @"/usr/bin/unzip",
            @"/bin/unzip"
        ];
        for (NSString *unzipPath in unzipPaths) {
            // 处理通配符
            if ([unzipPath containsString:@"*"]) {
                NSArray *matches = [self globExpand:unzipPath];
                if (matches.count > 0) {
                    unzipPath = matches.firstObject;
                } else {
                    continue;
                }
            }
            if ([[NSFileManager defaultManager] fileExistsAtPath:unzipPath]) {
                cmd = [NSString stringWithFormat:@"%@ -q -o '%@' -d '%@'", unzipPath, zipPath, self.javaRuntimesDir];
                ret = system(cmd.UTF8String);
                if (ret == 0) break;
            }
        }
    }
    
    // 检查解压是否成功
    BOOL success = NO;
    for (NSNumber *ver in @[@8, @17, @21, @25]) {
        NSString *releasePath = [self.javaRuntimesDir stringByAppendingPathComponent:
            [NSString stringWithFormat:@"java-%ld-openjdk/release", (long)ver.integerValue]];
        if ([[NSFileManager defaultManager] fileExistsAtPath:releasePath]) {
            success = YES;
            break;
        }
    }
    
    if (success) {
        [defaults setBool:YES forKey:kJREExtractedFlag];
        [defaults synchronize];
        NSLog(@"[PCLJavaRuntime] JRE解压完成");
    } else {
        NSLog(@"[PCLJavaRuntime] JRE解压失败！");
    }
}

- (NSArray<NSString *> *)globExpand:(NSString *)pattern {
    // 简单的glob展开
    NSMutableArray *results = [NSMutableArray array];
    NSString *dir = [pattern stringByDeletingLastPathComponent];
    NSString *filename = [pattern lastPathComponent];
    
    // 处理**通配符
    NSArray *dirComponents = [dir pathComponents];
    NSString *basePath = @"/";
    NSInteger wildcardIndex = -1;
    for (NSInteger i = 0; i < dirComponents.count; i++) {
        NSString *component = dirComponents[i];
        if ([component containsString:@"*"]) {
            wildcardIndex = i;
            break;
        }
        basePath = [basePath stringByAppendingPathComponent:component];
    }
    
    if (wildcardIndex == -1) {
        return @[pattern];
    }
    
    // 扫描目录
    NSError *error;
    NSArray *entries = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:basePath error:&error];
    for (NSString *entry in entries) {
        NSString *candidate = [basePath stringByAppendingPathComponent:entry];
        // 构建剩余路径
        NSString *remaining = @"";
        for (NSInteger i = wildcardIndex + 1; i < dirComponents.count; i++) {
            remaining = [remaining stringByAppendingPathComponent:dirComponents[i]];
        }
        if (remaining.length > 0) {
            candidate = [candidate stringByAppendingPathComponent:remaining];
        }
        if ([[NSFileManager defaultManager] fileExistsAtPath:candidate]) {
            [results addObject:candidate];
        }
    }
    
    return results;
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
    // 先检查自定义解压目录
    NSString *home = [self javaHomeForVersion:version];
    if (home) {
        NSString *javaPath = [home stringByAppendingPathComponent:@"bin/java"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:javaPath]) {
            return javaPath;
        }
    }
    
    // 回退到旧路径（兼容）
    NSString *resourcePath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"java-%ld-openjdk", (long)version] ofType:nil];
    if (resourcePath) {
        NSString *javaPath = [resourcePath stringByAppendingPathComponent:@"bin/java"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:javaPath]) return javaPath;
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
