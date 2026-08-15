#import "PCLAppDelegate.h"
#import "PCLRootViewController.h"
@implementation PCLAppDelegate - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions { self.window =
    [[UIWindow alloc]
        initWithFrame:[UIScreen mainScreen].bounds]; PCLRootViewController *root = [[PCLRootViewController alloc] init]; self.window.rootViewController = root;
    [self.window makeKeyAndVisible]; UIView *splash =
        [[UIView alloc] initWithFrame:self.window.bounds]; splash.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight; if
    (@available(iOS 13.0, *)) {
        splash.backgroundColor = self.window.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark ? UIColor.blackColor
            : UIColor.whiteColor;
    } else {
        splash.backgroundColor = UIColor.whiteColor;
    }
    UIImage *icon = [UIImage imageNamed:@"SplashLogo"]; UIImageView *logo = [[UIImageView alloc] initWithImage:icon]; logo.contentMode =
    UIViewContentModeScaleAspectFit; logo.translatesAutoresizingMaskIntoConstraints = NO; [splash addSubview:logo]; [self.window addSubview:splash];
    [NSLayoutConstraint activateConstraints:@[
        [logo.centerXAnchor constraintEqualToAnchor:splash.centerXAnchor], [logo.centerYAnchor constraintEqualToAnchor:splash.centerYAnchor], [logo.widthAnchor
        constraintEqualToConstant:180.0], [logo.heightAnchor constraintEqualToConstant:180.0]
    ]]; dispatch_after( dispatch_time( DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC) ), dispatch_get_main_queue(), ^{ [UIView animateWithDuration:0.45
                         animations:^{
            splash.alpha = 0.0;
        } completion:^(BOOL finished) {
            [splash removeFromSuperview];
        }];
    });
    return YES;
}
@end
