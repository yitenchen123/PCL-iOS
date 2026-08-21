#import <Foundation/Foundation.h>
#import "PCLVersionManager.h"
#import "PCLRendererManager.h"

@interface PCLLaunchArguments : NSObject

+ (NSDictionary *)buildArgumentsForVersion:(PCLVersionInfo *)version
                                   profile:(NSDictionary *)profile
                                    config:(NSDictionary *)config;

+ (NSString *)replaceVariables:(NSString *)string
                    withValues:(NSDictionary *)values
                         error:(NSError **)error;

+ (BOOL)areModsLoadedForVersion:(NSString *)version;

@end
