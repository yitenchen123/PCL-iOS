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
    backgroundView.frame = splash.bounds;
    backgroundView.autoresizingMask =
        UIViewAutoresizingFlexibleWidth |
        UIViewAutoresizingFlexibleHeight;
    UIImageView *contentView =
        [[UIImageView alloc] initWithImage:image];
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    contentView.contentMode = UIViewContentModeScaleAspectFit;
    [splash addSubview:contentView];

    [NSLayoutConstraint activateConstraints:@[
        [contentView.centerXAnchor
            constraintEqualToAnchor:splash.centerXAnchor],
        [contentView.centerYAnchor
            constraintEqualToAnchor:splash.centerYAnchor],
        [contentView.widthAnchor
            constraintLessThanOrEqualToAnchor:splash.widthAnchor],
        [contentView.heightAnchor
            constraintLessThanOrEqualToAnchor:splash.heightAnchor]
    ]];

    CGFloat ratio =
        image.size.width / image.size.height;

    [contentView.widthAnchor
        constraintEqualToAnchor:contentView.heightAnchor
                     multiplier:ratio].active = YES;

    NSLayoutConstraint *height =
        [contentView.heightAnchor
            constraintEqualToAnchor:splash.heightAnchor
                         multiplier:0.88];
    height.priority = UILayoutPriorityDefaultHigh;
    height.active = YES;

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
