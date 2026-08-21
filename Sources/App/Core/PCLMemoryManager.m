#import "PCLMemoryManager.h"
#import <mach/mach.h>
#import <sys/sysctl.h>

@implementation PCLMemoryManager

+ (instancetype)sharedManager {
    static PCLMemoryManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PCLMemoryManager alloc] init];
    });
    return instance;
}

- (long long)totalMemory {
    return [[NSProcessInfo processInfo] physicalMemory];
}

- (long long)usedMemory {
    struct mach_task_basic_info info;
    mach_msg_type_number_t size = MACH_TASK_BASIC_INFO_COUNT;
    kern_return_t kerr = task_info(mach_task_self(), MACH_TASK_BASIC_INFO, (task_info_t)&info, &size);
    if (kerr == KERN_SUCCESS) {
        return (long long)info.resident_size;
    }
    return 0;
}

- (long long)availableMemory {
    long long total = [self totalMemory];
    long long used = [self usedMemory];
    return total - used;
}

- (double)memoryUsagePercent {
    long long total = [self totalMemory];
    if (total == 0) return 0;
    return (double)[self usedMemory] / (double)total * 100.0;
}

- (long long)maxMemoryForDevice {
    long long total = [self totalMemory];
    if (total <= 2LL * 1024 * 1024 * 1024) return 1024;
    if (total <= 3LL * 1024 * 1024 * 1024) return 1536;
    if (total <= 4LL * 1024 * 1024 * 1024) return 2048;
    if (total <= 6LL * 1024 * 1024 * 1024) return 3072;
    return 4096;
}

- (long long)recommendedMemoryLimit {
    return [self maxMemoryForDevice];
}

- (long long)minimumMemoryLimit {
    return 512;
}

- (BOOL)isLowMemory {
    return [self memoryUsagePercent] > 85.0;
}

- (void)requestMemoryWarning {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    });
}

- (NSDictionary *)memoryInfo {
    return @{
        @"totalMemory": @([self totalMemory]),
        @"usedMemory": @([self usedMemory]),
        @"availableMemory": @([self availableMemory]),
        @"usagePercent": @([self memoryUsagePercent]),
        @"recommendedLimit": @([self recommendedMemoryLimit]),
        @"minimumLimit": @([self minimumMemoryLimit]),
        @"isLowMemory": @([self isLowMemory])
    };
}

@end
