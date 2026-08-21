#import <Foundation/Foundation.h>

@interface PCLLWJGLManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, readonly) NSArray<NSString *> *lwjglJars;
@property (nonatomic, readonly) NSArray<NSString *> *caciocavalloJars;
@property (nonatomic, readonly) NSArray<NSString *> *otherJars;

- (NSString *)lwjglClasspath;
- (NSString *)caciocavalloClasspathForJavaVersion:(NSInteger)javaVersion;
- (NSString *)allLibrariesClasspath;
- (BOOL)isAvailable;

@end
