#import <Foundation/Foundation.h>

typedef void(^PCLAssetDownloadProgressBlock)(double progress, NSString *statusMessage);
typedef void(^PCLAssetDownloadCompletionBlock)(BOOL success, NSError *error);

@interface PCLAssetDownloader : NSObject

+ (void)downloadAssetsWithIndexId:(NSString *)indexId
                        assetsDir:(NSString *)assetsDir
                         progress:(PCLAssetDownloadProgressBlock)progress
                       completion:(PCLAssetDownloadCompletionBlock)completion;

+ (void)downloadAssetsWithIndexJson:(NSDictionary *)indexJson
                          assetsDir:(NSString *)assetsDir
                           progress:(PCLAssetDownloadProgressBlock)progress
                         completion:(PCLAssetDownloadCompletionBlock)completion;

@end
