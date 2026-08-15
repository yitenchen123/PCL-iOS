#import "PCLAppDelegate.h"
#import "PCLRootViewController.h"
@implementation PCLAppDelegate - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions { self.window = 
    [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds]; PCLRootViewController *rootViewController =
        [[PCLRootViewController alloc] init]; self.window.rootViewController = rootViewController; [self.window makeKeyAndVisible]; return YES;
}
@end
