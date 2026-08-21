#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PCLJavaVersion) {
    PCLJavaVersion7 = 7,
    PCLJavaVersion8 = 8,
    PCLJavaVersion11 = 11,
    PCLJavaVersion16 = 16,
    PCLJavaVersion17 = 17,
    PCLJavaVersion21 = 21,
    PCLJavaVersion25 = 25
};

typedef void(^PCLJavaDownloadProgress)(double progress, NSString *status);
typedef void(^PCLJavaDownloadCompletion)(BOOL success, NSError *error);

@interface PCLJavaManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, readonly) BOOL isDownloading;
@property (nonatomic, assign) PCLJavaVersion downloadingVersion;
@property (nonatomic, readonly) NSString *currentJavaHome;
@property (nonatomic, readonly) NSInteger currentJavaVersion;

- (NSString *)javaHomeForVersion:(NSInteger)version;
- (NSString *)javaExecutableForVersion:(NSInteger)version;
- (NSInteger)javaVersionFromMC:(NSString *)mcVersion;

- (void)ensureJavaDownloaded:(NSInteger)version
                    progress:(PCLJavaDownloadProgress)progress
                  completion:(PCLJavaDownloadCompletion)completion;

- (NSArray<NSString *> *)allDownloadURLsForJava:(NSInteger)version;
- (BOOL)isJavaAvailable:(NSInteger)version;
- (NSString *)javaDisplayName:(NSInteger)version;

+ (NSString *)defaultJavaURLForVersion:(NSInteger)version;

@end
