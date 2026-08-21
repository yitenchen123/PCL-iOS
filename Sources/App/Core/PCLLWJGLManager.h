#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PCLLWJGLVersion) {
    PCLLWJGLVersion331 = 331,
    PCLLWJGLVersion332 = 332,
    PCLLWJGLVersion333 = 333
};

@interface PCLLWJGLLibrary : NSObject
@property (nonatomic, copy) NSString *artifact;
@property (nonatomic, copy) NSString *group;
@property (nonatomic, copy) NSString *version;
@property (nonatomic, assign) BOOL isNative;
@property (nonatomic, copy) NSString *classifier;
@end

@interface PCLLWJGLManager : NSObject

+ (instancetype)sharedManager;

- (NSString *)lwjglDirectory;
- (NSString *)lwjglDirectoryForVersion:(PCLLWJGLVersion)version;
- (NSString *)librariesDirectory;

- (NSArray<PCLLWJGLLibrary *> *)requiredLWJGLLibraries;
- (NSArray<PCLLWJGLLibrary *> *)requiredLWJGLLibrariesForVersion:(PCLLWJGLVersion)version;

- (void)downloadLWJGL:(PCLLWJGLVersion)version
             progress:(void (^)(double progress, NSString *currentLib))progress
           completion:(void (^)(BOOL success, NSError *error))completion;

- (BOOL)isLWJGLDownloaded:(PCLLWJGLVersion)version;
- (NSString *)lwjglClasspath:(PCLLWJGLVersion)version;
- (NSString *)lwjglNativeDirectory:(PCLLWJGLVersion)version;

- (NSString *)downloadURLForLibrary:(PCLLWJGLLibrary *)lib;
- (NSString *)localPathForLibrary:(PCLLWJGLLibrary *)lib version:(PCLLWJGLVersion)version;

+ (NSString *)versionStringFromEnum:(PCLLWJGLVersion)version;

@end
