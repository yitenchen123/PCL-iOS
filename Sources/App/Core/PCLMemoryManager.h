#import <Foundation/Foundation.h>

@interface PCLMemoryManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, readonly) long long totalMemory;
@property (nonatomic, readonly) long long availableMemory;
@property (nonatomic, readonly) long long usedMemory;
@property (nonatomic, readonly) double memoryUsagePercent;
@property (nonatomic, readonly) long long recommendedMemoryLimit;
@property (nonatomic, readonly) long long minimumMemoryLimit;

- (long long)maxMemoryForDevice;
- (BOOL)isLowMemory;
- (void)requestMemoryWarning;
- (NSDictionary *)memoryInfo;

@end
