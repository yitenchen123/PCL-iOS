#import <Foundation/Foundation.h>

@interface PCLJavaRuntime : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *version;
@property (nonatomic, copy) NSString *path;
@property (nonatomic, assign) BOOL isDownloaded;
@property (nonatomic, copy) NSString *downloadURL;
@property (nonatomic, assign) long long totalSize;
@end

@interface PCLJavaManager : NSObject

+ (instancetype)sharedManager;

- (NSString *)javaDirectory;
- (NSArray<PCLJavaRuntime *> *)availableJavaVersions;
- (NSArray<PCLJavaRuntime *> *)installedJavaVersions;
- (PCLJavaRuntime *)javaRuntimeForVersion:(NSString *)mcVersion;
- (void)downloadJava:(PCLJavaRuntime *)javaRuntime
            progress:(void (^)(double progress))progress
            completion:(void (^)(BOOL success, NSError *error))completion;
- (NSString *)findJavaPathForMCVersion:(NSString *)mcVersion;
- (NSInteger)recommendedJavaVersionForMC:(NSString *)mcVersion;

@end
