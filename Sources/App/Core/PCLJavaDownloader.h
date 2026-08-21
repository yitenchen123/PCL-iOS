#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PCLJavaVersion) {
    PCLJavaVersion8 = 8,
    PCLJavaVersion11 = 11,
    PCLJavaVersion17 = 17,
    PCLJavaVersion21 = 21
};

@interface PCLJavaDownloader : NSObject

+ (instancetype)sharedDownloader;

- (NSString *)javaDirectory;
- (NSString *)javaPathForVersion:(PCLJavaVersion)version;
- (NSString *)javaBinaryPathForVersion:(PCLJavaVersion)version;

- (void)downloadJava:(PCLJavaVersion)version
            progress:(void (^)(double progress))progress
          completion:(void (^)(BOOL success, NSError *error))completion;

- (BOOL)verifyJavaAtPath:(NSString *)path;
- (NSInteger)javaVersionAtPath:(NSString *)path;
- (BOOL)isJavaDownloaded:(PCLJavaVersion)version;

- (NSString *)downloadURLForJavaVersion:(PCLJavaVersion)version;
- (long long)expectedSizeForJavaVersion:(PCLJavaVersion)version;

@end
