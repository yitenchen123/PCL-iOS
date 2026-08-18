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

    CGFloat pixel = shortSide * 0.062;

    NSArray *topPattern = @[
        @[@0, @0, @0.10],
        @[@1, @0, @0.18],
        @[@2, @0, @0.10],
        @[@0, @1, @0.18],
        @[@1, @1, @0.10],
        @[@2, @1, @0.06],
        @[@0, @2, @0.08],
        @[@1, @2, @0.16]
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
        @[@0, @2, @0.05],
        @[@1, @1, @0.07],
        @[@1, @2, @0.12],
        @[@2, @0, @0.10],
        @[@2, @1, @0.16],
        @[@2, @2, @0.09],
        @[@3, @0, @0.05],
        @[@3, @1, @0.10],
        @[@3, @2, @0.15]
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


    CGFloat unit = shortSide * 0.052;
    CGFloat logoW = unit * 10.2;
    CGFloat logoH = unit * 3.4;

    UIView *logoView = [[UIView alloc] initWithFrame:
        CGRectMake((w - logoW) / 2.0,
                   (h - logoH) / 2.0,
                   logoW,
                   logoH)];

    [splash addSubview:logoView];


    void (^block)(CGFloat,CGFloat,CGFloat,CGFloat) =
    ^(CGFloat x, CGFloat y, CGFloat bw, CGFloat bh) {
        UIView *v = [[UIView alloc] initWithFrame:
            CGRectMake(x * unit, y * unit,
                       bw * unit, bh * unit)];
        v.backgroundColor = UIColor.whiteColor;
        [logoView addSubview:v];
    };


    block(0.00, 0.00, 0.42, 2.10);
    block(0.00, 0.00, 1.65, 0.42);
    block(1.23, 0.00, 0.42, 1.25);
    block(0.65, 0.83, 1.00, 0.42);


    block(2.15, 0.00, 0.42, 2.10);
    block(2.15, 0.00, 1.85, 0.42);
    block(2.15, 1.68, 1.85, 0.42);


    block(4.45, 0.00, 0.42, 2.10);
    block(4.45, 1.68, 1.70, 0.42);


    block(1.05, -0.34, 0.20, 0.20);
    block(1.32, -0.22, 0.15, 0.15);
    block(0.82, -0.14, 0.12, 0.12);


    UILabel *ios = [[UILabel alloc] initWithFrame:
        CGRectMake(6.65 * unit,
                   0.63 * unit,
                   2.05 * unit,
                   0.90 * unit)];

    ios.text = @"iOS";
    ios.textAlignment = NSTextAlignmentCenter;
    ios.backgroundColor = UIColor.whiteColor;

    ios.textColor =
        [UIColor colorWithRed:24.0/255.0
                        green:111.0/255.0
                         blue:232.0/255.0
                        alpha:1.0];

    ios.font =
        [UIFont systemFontOfSize:unit * 0.62
                          weight:UIFontWeightSemibold];


    ios.layer.cornerRadius = unit * 0.15;
    ios.clipsToBounds = YES;
    [logoView addSubview:ios];


    UILabel *subtitle = [[UILabel alloc] initWithFrame:
        CGRectMake(0,
                   2.55 * unit,
                   logoW,
                   0.65 * unit)];

    subtitle.text = @"P C L - i O S";
    subtitle.textAlignment = NSTextAlignmentCenter;
    subtitle.textColor = UIColor.whiteColor;


    subtitle.font =
        [UIFont monospacedSystemFontOfSize:unit * 0.36
                                    weight:UIFontWeightRegular];

    [logoView addSubview:subtitle];

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
