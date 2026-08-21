#import <Foundation/Foundation.h>

@interface PCLJavaRuntime : NSObject
@property (nonatomic, copy) NSString *version;
@property (nonatomic, copy) NSString *path;
@property (nonatomic, assign) BOOL isAvailable;
@end

@interface PCLJavaManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, readonly) NSArray<PCLJavaRuntime *> *availableRuntimes;
@property (nonatomic, readonly) NSArray<PCLJavaRuntime *> *installedRuntimes;

- (NSString *)javaPathForMCVersion:(NSString *)mcVersion;
- (NSInteger)recommendedJavaVersionForMC:(NSString *)mcVersion;
- (NSString *)javaHomeForVersion:(NSInteger)version;

@end
