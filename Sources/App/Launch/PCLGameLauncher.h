#import <Foundation/Foundation.h>
#import "PCLVersionManager.h"
#import "PCLJavaManager.h"

typedef NS_ENUM(NSInteger, PCLLaunchError) {
    PCLLaunchErrorNone = 0,
    PCLLaunchErrorVersionNotFound,
    PCLLaunchErrorJavaNotFound,
    PCLLaunchErrorJavaVersionMismatch,
    PCLLaunchErrorLibraryMissing,
    PCLLaunchErrorAssetMissing,
    PCLLaunchErrorProfileInvalid,
    PCLLaunchErrorNetworkFailure,
    PCLLaunchErrorCancelled,
    PCLLaunchErrorInternalFailure
};

typedef void(^PCLLogCallback)(NSString *line);
typedef void(^PCLLaunchCompletion)(BOOL success, NSError *error);

@interface PCLGameLauncher : NSObject

@property (nonatomic, copy) PCLLogCallback logCallback;

- (void)launchWithVersion:(NSString *)versionId
                  profile:(NSDictionary *)profile
               completion:(PCLLaunchCompletion)completion;

- (void)cancelLaunch;

@end
