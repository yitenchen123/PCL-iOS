#import <Foundation/Foundation.h>

/**
 * ZIP文件解压器
 * 使用iOS内置的Compression框架，不需要外部依赖
 */
@interface PCLZipExtractor : NSObject

/// 解压整个zip文件到目标目录
+ (BOOL)extractZipAtPath:(NSString *)zipPath
                 toPath:(NSString *)destinationPath
                  error:(NSError **)error;

/// 解压并报告进度
+ (BOOL)extractZipAtPath:(NSString *)zipPath
                 toPath:(NSString *)destinationPath
               progress:(void (^)(NSString *currentFile, NSInteger current, NSInteger total))progressBlock
                  error:(NSError **)error;

@end
