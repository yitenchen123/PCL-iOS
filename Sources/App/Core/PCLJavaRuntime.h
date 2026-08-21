#import <Foundation/Foundation.h>

/**
 * 预装JRE运行时管理器
 * JRE在构建时打包为zip，首次启动时解压到Documents/Java目录
 * 参考PojavLauncher/Amethyst的预装JRE方案
 */
@interface PCLJavaRuntime : NSObject

+ (instancetype)sharedRuntime;

/// JRE解压目标目录
@property (nonatomic, readonly) NSString *javaRuntimesDir;

/// 初始化并确保JRE已解压（应用启动时调用）
- (void)ensureJREExtracted;

/// 获取Java Home路径
- (NSString *)javaHomeForVersion:(NSInteger)version;

/// 获取Java可执行文件路径
- (NSString *)javaExecutableForVersion:(NSInteger)version;

/// 根据MC版本获取推荐Java版本
- (NSInteger)recommendedJavaVersionForMC:(NSString *)mcVersion;

/// 检查JRE是否已安装
- (BOOL)isJavaAvailable:(NSInteger)version;

@end
