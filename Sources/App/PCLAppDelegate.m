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

    CGFloat w = CGRectGetWidth(splash.bounds);
    CGFloat h = CGRectGetHeight(splash.bounds);
    CGFloat shortSide = MIN(w, h);

    splash.backgroundColor =
        [UIColor colorWithRed:24.0/255.0
                        green:111.0/255.0
                         blue:232.0/255.0
                        alpha:1.0];

    CGFloat pixel = shortSide * 0.075;

    NSArray *topPattern = @[
        @[@0, @0, @0.22],
        @[@1, @0, @0.12],
        @[@2, @0, @0.08],
        @[@0, @1, @0.12],
        @[@1, @1, @0.18],
        @[@0, @2, @0.08],
        @[@1, @2, @0.12]
    ];

    for (NSArray *item in topPattern) {
        UIView *v = [[UIView alloc] init];

        v.backgroundColor =
            [UIColor colorWithWhite:1.0
                              alpha:[item[2] doubleValue]];

        v.frame = CGRectMake(
            [item[0] doubleValue] * pixel,
            [item[1] doubleValue] * pixel,
            pixel,
            pixel
        );

        [splash addSubview:v];
    }

    NSArray *bottomPattern = @[
        @[@0, @2, @0.06],
        @[@1, @1, @0.08],
        @[@1, @2, @0.12],
        @[@2, @0, @0.14],
        @[@2, @1, @0.18],
        @[@2, @2, @0.10],
        @[@3, @1, @0.08],
        @[@3, @2, @0.12]
    ];

    for (NSArray *item in bottomPattern) {
        UIView *v = [[UIView alloc] init];

        v.backgroundColor =
            [UIColor colorWithWhite:1.0
                              alpha:[item[2] doubleValue]];

        CGFloat x =
            w - pixel * 4.0 +
            [item[0] doubleValue] * pixel;

        CGFloat y =
            h - pixel * 3.0 +
            [item[1] doubleValue] * pixel;

        v.frame = CGRectMake(x, y, pixel, pixel);
        [splash addSubview:v];
    }

    NSArray *dots = @[
        @[@0.24, @0.26, @0.018],
        @[@0.80, @0.22, @0.016],
        @[@0.16, @0.68, @0.016],
        @[@0.74, @0.64, @0.017],
        @[@0.61, @0.80, @0.016]
    ];

    for (NSArray *dot in dots) {
        CGFloat size =
            shortSide * [dot[2] doubleValue];

        UIView *v = [[UIView alloc] init];

        v.backgroundColor =
            [UIColor colorWithWhite:1.0 alpha:0.20];

        v.frame = CGRectMake(
            w * [dot[0] doubleValue],
            h * [dot[1] doubleValue],
            size,
            size
        );

        [splash addSubview:v];
    }

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
