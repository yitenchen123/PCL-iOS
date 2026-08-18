#import "PCLLaunchViewController.h"

@interface PCLLaunchViewController ()

@property (nonatomic, strong) UIView *leftPane;
@property (nonatomic, strong) UIScrollView *rightPane;

@end

@implementation PCLLaunchViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor =
        [UIColor colorWithRed:251.0/255.0
                        green:251.0/255.0
                         blue:251.0/255.0
                        alpha:1.0];

    [self setupLayout];
}

- (void)setupLayout {
    self.leftPane = [[UIView alloc] init];
    self.leftPane.translatesAutoresizingMaskIntoConstraints = NO;

    self.rightPane = [[UIScrollView alloc] init];
    self.rightPane.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addSubview:self.leftPane];
    [self.view addSubview:self.rightPane];

    [NSLayoutConstraint activateConstraints:@[
        [self.leftPane.topAnchor
            constraintEqualToAnchor:self.view.topAnchor],

        [self.leftPane.bottomAnchor
            constraintEqualToAnchor:self.view.bottomAnchor],

        [self.leftPane.leadingAnchor
            constraintEqualToAnchor:self.view.leadingAnchor],

        [self.leftPane.widthAnchor
            constraintEqualToConstant:300.0],

        [self.rightPane.topAnchor
            constraintEqualToAnchor:self.view.topAnchor],

        [self.rightPane.bottomAnchor
            constraintEqualToAnchor:self.view.bottomAnchor],

        [self.rightPane.leadingAnchor
            constraintEqualToAnchor:self.leftPane.trailingAnchor],

        [self.rightPane.trailingAnchor
            constraintEqualToAnchor:self.view.trailingAnchor]
    ]];

        [self.rightPane.topAnchor
            constraintEqualToAnchor:self.view.topAnchor],

        [self.rightPane.bottomAnchor
            constraintEqualToAnchor:self.view.bottomAnchor],

        [self.rightPane.leadingAnchor
            constraintEqualToAnchor:self.leftPane.trailingAnchor],

        [self.rightPane.trailingAnchor
            constraintEqualToAnchor:self.view.trailingAnchor]
    ]];

- (UIButton *)pclButtonWithTitle:(NSString *)title {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];

    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.layer.cornerRadius = 3.0;
    button.layer.borderWidth = 1.0;

    return button;
}

- (void)styleButton:(UIButton *)button
              title:(NSString *)title
          highlight:(BOOL)highlight {

    UIColor *color =
        highlight
        ? [UIColor colorWithRed:11.0/255.0
                          green:91.0/255.0
                           blue:203.0/255.0
                          alpha:1.0]

        : [UIColor colorWithRed:52.0/255.0
                          green:61.0/255.0
                           blue:74.0/255.0
                          alpha:1.0];

    button.layer.borderColor = color.CGColor;

    button.backgroundColor =
        [UIColor colorWithWhite:1.0
                          alpha:0x55 / 255.0];

    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:color forState:UIControlStateNormal];

    button.titleLabel.font =
        [UIFont systemFontOfSize:13.0];
}

    button.backgroundColor =
        [UIColor colorWithWhite:1.0
                          alpha:0x55 / 255.0];

    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:color forState:UIControlStateNormal];

    button.titleLabel.font =
        [UIFont systemFontOfSize:13.0];
}

    [NSLayoutConstraint activateConstraints:@[
        [launch.leadingAnchor
            constraintEqualToAnchor:self.leftPane.leadingAnchor
                           constant:20.0],

        [launch.trailingAnchor
            constraintEqualToAnchor:self.leftPane.trailingAnchor
                           constant:-20.0],

        [launch.heightAnchor
            constraintEqualToConstant:54.0]
    ]];

    UILabel *version = [[UILabel alloc] init];
    version.translatesAutoresizingMaskIntoConstraints = NO;

    version.text = @"正在加载 Minecraft 实例";
    version.textAlignment = NSTextAlignmentCenter;
    version.font = [UIFont systemFontOfSize:11.0];

    version.textColor =
        [UIColor colorWithRed:140.0/255.0
                        green:140.0/255.0
                         blue:140.0/255.0
                        alpha:1.0];

    [launch addSubview:version];

    [NSLayoutConstraint activateConstraints:@[
        [version.leadingAnchor
            constraintEqualToAnchor:launch.leadingAnchor
                           constant:15.0],

        [version.trailingAnchor
            constraintEqualToAnchor:launch.trailingAnchor
                           constant:-15.0],

        [version.bottomAnchor
            constraintEqualToAnchor:launch.bottomAnchor
                           constant:-6.0]
    ]];

    UIButton *instance =
        [self pclButtonWithTitle:@"选择实例"];

    [self styleButton:instance
                title:@"选择实例"
            highlight:NO];

    instance.enabled = NO;

    [self.leftPane addSubview:instance];

    UIButton *more =
        [self pclButtonWithTitle:@"实例设置"];

    [self styleButton:more
                title:@"实例设置"
            highlight:NO];

    more.hidden = YES;

    [self.leftPane addSubview:more];

    [NSLayoutConstraint activateConstraints:@[
        [instance.leadingAnchor
            constraintEqualToAnchor:self.leftPane.leadingAnchor
                           constant:20.0],

        [instance.trailingAnchor
            constraintEqualToAnchor:self.leftPane.trailingAnchor
                           constant:-20.0],

        [instance.bottomAnchor
            constraintEqualToAnchor:self.leftPane.bottomAnchor
                           constant:-20.0],

        [instance.heightAnchor
            constraintEqualToConstant:35.0]
    ]];

    [launch.bottomAnchor
        constraintEqualToAnchor:instance.topAnchor
                       constant:-10.0].active = YES;
}

- (void)setupRightPane {
    UIView *content = [[UIView alloc] init];
    content.translatesAutoresizingMaskIntoConstraints = NO;

    [self.rightPane addSubview:content];

    UILayoutGuide *guide =
        self.rightPane.contentLayoutGuide;

    UILayoutGuide *frameGuide =
        self.rightPane.frameLayoutGuide;

    [NSLayoutConstraint activateConstraints:@[
        [content.topAnchor
            constraintEqualToAnchor:guide.topAnchor
                           constant:25.0],

        [content.leadingAnchor
            constraintEqualToAnchor:guide.leadingAnchor
                           constant:25.0],

        [content.trailingAnchor
            constraintEqualToAnchor:guide.trailingAnchor
                           constant:-25.0],

        [content.bottomAnchor
            constraintEqualToAnchor:guide.bottomAnchor
                           constant:-10.0]
    ]];

    [content.widthAnchor
        constraintEqualToAnchor:frameGuide.widthAnchor
                       constant:-50.0].active = YES;

    [content.heightAnchor
        constraintGreaterThanOrEqualToAnchor:frameGuide.heightAnchor
                                     constant:-35.0].active = YES;
}

@end
