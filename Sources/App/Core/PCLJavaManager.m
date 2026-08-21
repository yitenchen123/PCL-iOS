#import "PCLJavaManager.h"

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

- (NSString *)jreDirectory {
    return [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"java_runtimes"];
}

- (NSArray<PCLJavaRuntime *> *)availableRuntimes {
    NSMutableArray *runtimes = [NSMutableArray array];
    NSInteger versions[] = {8, 17, 21, 25};
    NSFileManager *fm = [NSFileManager defaultManager];
    
    for (int i = 0; i < 4; i++) {
        PCLJavaRuntime *rt = [[PCLJavaRuntime alloc] init];
        rt.version = [NSString stringWithFormat:@"%ld", (long)versions[i]];
        rt.path = [[self jreDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"java-%ld-openjdk", (long)versions[i]]];
        rt.isAvailable = [fm fileExistsAtPath:[rt.path stringByAppendingPathComponent:@"bin/java"]];
        [runtimes addObject:rt];
    }
    return runtimes;
}

- (NSArray<PCLJavaRuntime *> *)installedRuntimes {
    NSMutableArray *installed = [NSMutableArray array];
    for (PCLJavaRuntime *rt in self.availableRuntimes) {
        if (rt.isAvailable) [installed addObject:rt];
    }
    return installed;
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

- (NSString *)javaHomeForVersion:(NSInteger)version {
    NSString *path = [[self jreDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"java-%ld-openjdk", (long)version]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) return path;
    return nil;
}

- (NSString *)javaPathForMCVersion:(NSString *)mcVersion {
    NSInteger ver = [self recommendedJavaVersionForMC:mcVersion];
    NSString *home = [self javaHomeForVersion:ver];
    if (home) return [home stringByAppendingPathComponent:@"bin/java"];
    for (PCLJavaRuntime *rt in self.installedRuntimes) {
        return [rt.path stringByAppendingPathComponent:@"bin/java"];
    }
    return nil;
}

@end
