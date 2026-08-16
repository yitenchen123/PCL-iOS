#import "PCLAppDelegate.h"
#import "PCLRootViewController.h"

@implementation PCLAppDelegate

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc]
        initWithFrame:[UIScreen mainScreen].bounds];

    PCLRootViewController *root =
        [[PCLRootViewController alloc] init];

    self.window.rootViewController = root;
    [self.window makeKeyAndVisible];
    UIView *splash =
        [[UIView alloc] initWithFrame:self.window.bounds];

    splash.autoresizingMask =
        UIViewAutoresizingFlexibleWidth |
        UIViewAutoresizingFlexibleHeight;

    splash.backgroundColor =
        [UIColor colorWithRed:24.0/255.0
                        green:111.0/255.0
                         blue:232.0/255.0
                        alpha:1.0];

    UIImage *image =
        [UIImage imageNamed:@"SplashScreen"];

    UIImageView *backgroundView =
        [[UIImageView alloc] initWithImage:image];
    backgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    backgroundView.contentMode =
        UIViewContentModeScaleAspectFill;
    backgroundView.clipsToBounds = YES;

    [splash addSubview:backgroundView];

    [NSLayoutConstraint activateConstraints:@[
        [backgroundView.leadingAnchor
            constraintEqualToAnchor:splash.leadingAnchor],

        [backgroundView.trailingAnchor
            constraintEqualToAnchor:splash.trailingAnchor],

        [backgroundView.topAnchor
            constraintEqualToAnchor:splash.topAnchor],

        [backgroundView.bottomAnchor
            constraintEqualToAnchor:splash.bottomAnchor]
    ]];

    UIBlurEffect *blurEffect =
        [UIBlurEffect effectWithStyle:
            UIBlurEffectStyleSystemUltraThinMaterial];

    UIVisualEffectView *blurView =
        [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    blurView.translatesAutoresizingMaskIntoConstraints = NO;
    [splash addSubview:blurView];

    [NSLayoutConstraint activateConstraints:@[
        [blurView.leadingAnchor
            constraintEqualToAnchor:splash.leadingAnchor],

        [blurView.trailingAnchor
            constraintEqualToAnchor:splash.trailingAnchor],
        [blurView.topAnchor
            constraintEqualToAnchor:splash.topAnchor],

        [blurView.bottomAnchor
            constraintEqualToAnchor:splash.bottomAnchor]
    ]];

    UIImageView *mainImageView =
        [[UIImageView alloc] initWithImage:image];
    mainImageView.translatesAutoresizingMaskIntoConstraints = NO;
    mainImageView.contentMode =
        UIViewContentModeScaleAspectFit;

    [splash addSubview:mainImageView];

    [NSLayoutConstraint activateConstraints:@[
        [mainImageView.leadingAnchor
            constraintEqualToAnchor:splash.leadingAnchor],
        [mainImageView.trailingAnchor
            constraintEqualToAnchor:splash.trailingAnchor],

        [mainImageView.topAnchor
            constraintEqualToAnchor:splash.topAnchor],

        [mainImageView.bottomAnchor
            constraintEqualToAnchor:splash.bottomAnchor]
    ]];
    [self.window addSubview:splash];

    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            (int64_t)(3.0 * NSEC_PER_SEC)
        ),
        dispatch_get_main_queue(),
        ^{
        [UIView animateWithDuration:0.55
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{

            splash.transform =
                CGAffineTransformMakeScale(1.04, 1.04);

            splash.alpha = 0.0;
        } completion:^(BOOL finished) {

            [splash removeFromSuperview];

            [root playEntranceAnimation];
        }];
    });

    return YES;
}
@end
