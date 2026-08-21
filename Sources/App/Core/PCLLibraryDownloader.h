#import <Foundation/Foundation.h>

typedef void(^PCLLibraryDownloadProgressBlock)(double progress, NSString *statusMessage);
typedef void(^PCLLibraryDownloadCompletionBlock)(BOOL success, NSError *error);

@interface PCLLibraryDownloader : NSObject

+ (void)downloadLibraries:(NSArray<NSDictionary *> *)libraries
                versionId:(NSString *)versionId
                 progress:(PCLLibraryDownloadProgressBlock)progress
               completion:(PCLLibraryDownloadCompletionBlock)completion;

@end
