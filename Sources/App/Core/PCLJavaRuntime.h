#import <Foundation/Foundation.h>

/**
 * JRE运行时管理器
 * 负责JRE的下载、解压和路径查询
 * 
 * JRE下载源优先级：
 * 1. GitHub Releases（如果开发者提供了发布）
 * 2. Amethyst官方CDN (assets.angelauramc.dev)
 * 3. 用户提供的本地zip文件
 */
@interface PCLJavaRuntime : NSObject

+ (instancetype)sharedRuntime;

/// JRE解压目标目录
@property (nonatomic, readonly) NSString *javaRuntimesDir;

/// 是否正在下载/解压
@property (nonatomic, readonly, getter=isBusy) BOOL busy;

/// 初始化并确保JRE已安装
- (void)ensureJREInstalled;

/// 获取Java Home路径
- (NSString *)javaHomeForVersion:(NSInteger)version;

/// 获取Java可执行文件路径
- (NSString *)javaExecutableForVersion:(NSInteger)version;

/// 根据MC版本获取推荐Java版本
- (NSInteger)recommendedJavaVersionForMC:(NSString *)mcVersion;

/// 检查JRE是否已安装
- (BOOL)isJavaAvailable:(NSInteger)version;

/// 开始下载JRE（带进度回调）
- (void)downloadJREWithProgress:(void (^)(double progress, NSString *status))progressBlock
                     completion:(void (^)(BOOL success, NSError *error))completion;

/// JRE下载源URL列表
+ (NSArray<NSString *> *)jreDownloadURLs;

@end
