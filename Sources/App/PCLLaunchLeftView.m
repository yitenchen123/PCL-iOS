#import "PCLLaunchLeftView.h"
#import "PCLCEPageAnimator.h"

static UIColor *PCLColor(NSUInteger rgb) {
    return [UIColor colorWithRed:((rgb >> 16) & 255) / 255.0
                           green:((rgb >> 8) & 255) / 255.0
                            blue:(rgb & 255) / 255.0
                           alpha:1.0];
}

@interface PCLCEButton : UIButton
@end

@implementation PCLCEButton

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    self.layer.cornerRadius = 3.0;
    self.layer.borderWidth = 1.0;

    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];

    [UIView animateWithDuration:0.08 animations:^{
        self.transform = CGAffineTransformMakeScale(0.955, 0.955);
        self.backgroundColor = PCLColor(0xE0EAFD);
    }];
}

- (void)restore {
    [UIView animateWithDuration:0.30 animations:^{
        self.transform = CGAffineTransformIdentity;
        self.backgroundColor =
            [UIColor colorWithWhite:1 alpha:0x55 / 255.0];
    }];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    [self restore];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    [self restore];
}

@end

@interface PCLSkinHeadView : UIView
@end

@implementation PCLSkinHeadView

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    self.backgroundColor = UIColor.clearColor;
    self.layer.shadowColor = PCLColor(0x0B5BCB).CGColor;
    self.layer.shadowOpacity = 0.20;
    self.layer.shadowRadius = 10.0;

    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef c = UIGraphicsGetCurrentContext();

    CGFloat size = MIN(rect.size.width, rect.size.height);
    CGFloat pixel = size / 8.0;

    UIColor *skin = PCLColor(0xB78363);
    UIColor *light = PCLColor(0xD9A17E);
    UIColor *hair = PCLColor(0x3A281C);
    UIColor *eye = PCLColor(0x4A78A8);

    [skin setFill];
    CGContextFillRect(c, CGRectMake(0, 0, size, size));

    [hair setFill];
    CGContextFillRect(c, CGRectMake(0, 0, size, pixel * 2));
    CGContextFillRect(c, CGRectMake(0, 0, pixel, pixel * 4));
    CGContextFillRect(c, CGRectMake(size - pixel, 0, pixel, pixel * 4));

    [light setFill];
    CGContextFillRect(c,
        CGRectMake(pixel * 2, pixel * 3,
                   pixel, pixel));

    CGContextFillRect(c,
        CGRectMake(pixel * 5, pixel * 3,
                   pixel, pixel));

    [eye setFill];

    CGContextFillRect(c,
        CGRectMake(pixel * 2, pixel * 3,
                   pixel, pixel * 0.45));

    CGContextFillRect(c,
        CGRectMake(pixel * 5, pixel * 3,
                   pixel, pixel * 0.45));

    [hair setFill];
    CGContextFillRect(c,
        CGRectMake(pixel * 3, pixel * 6,
                   pixel * 2, pixel * 0.55));
}

@end

@interface PCLLaunchLeftView ()

@property (nonatomic, strong) UIView *panLogin;

@property (nonatomic, strong) PCLCEButton *launchButton;
@property (nonatomic, strong) UILabel *versionLabel;

@property (nonatomic, strong) PCLCEButton *instanceButton;
@property (nonatomic, strong) PCLCEButton *moreButton;

@property (nonatomic, strong) UIView *profileSelectView;
@property (nonatomic, strong) UIView *profileSkinView;

@property (nonatomic, strong) UIView *hintView;
@property (nonatomic, strong) UILabel *hintLabel;

@property (nonatomic, strong) PCLSkinHeadView *skinView;
@property (nonatomic, strong) UILabel *usernameLabel;
@property (nonatomic, strong) UILabel *typeLabel;

@property (nonatomic, strong) UIView *profileButtonsCard;
@property (nonatomic, strong) UIButton *skinButton;
@property (nonatomic, strong) UIButton *editButton;
@property (nonatomic, strong) UIButton *switchButton;

@property (nonatomic, strong) UIButton *newProfileButton;

@end

@implementation PCLLaunchLeftView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;

    self.backgroundColor = PCLColor(0xFBFBFB);

    [self buildMainUI];
    [self buildProfileSelectUI];
    [self buildProfileSkinUI];

    [self reloadState];

    return self;
}

- (PCLCEButton *)pclButton:(NSString *)title
                 highlight:(BOOL)highlight {

    PCLCEButton *button = [[PCLCEButton alloc] init];

    UIColor *color =
        PCLColor(highlight ? 0x0B5BCB : 0x343D4A);

    button.layer.borderColor = color.CGColor;
    button.backgroundColor =
        [UIColor colorWithWhite:1 alpha:0x55 / 255.0];

    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:color forState:UIControlStateNormal];

    button.titleLabel.font =
        [UIFont systemFontOfSize:13.0];

    return button;
}

- (void)buildMainUI {
    self.panLogin = [[UIView alloc] init];
    [self addSubview:self.panLogin];

    self.launchButton =
        [self pclButton:@"启动" highlight:YES];

    [self.launchButton addTarget:self
                          action:@selector(launchPressed)
                forControlEvents:UIControlEventTouchUpInside];

    [self addSubview:self.launchButton];

    self.versionLabel = [[UILabel alloc] init];
    self.versionLabel.textAlignment = NSTextAlignmentCenter;
    self.versionLabel.font = [UIFont systemFontOfSize:11.0];
    self.versionLabel.textColor = PCLColor(0x8C8C8C);

    [self.launchButton addSubview:self.versionLabel];

    self.instanceButton =
        [self pclButton:@"选择实例" highlight:NO];

    [self.instanceButton addTarget:self
                            action:@selector(instancePressed)
                  forControlEvents:UIControlEventTouchUpInside];

    [self addSubview:self.instanceButton];

    self.moreButton =
        [self pclButton:@"实例设置" highlight:NO];

    [self.moreButton addTarget:self
                        action:@selector(morePressed)
              forControlEvents:UIControlEventTouchUpInside];

    [self addSubview:self.moreButton];
}

- (void)buildProfileSelectUI {
    self.profileSelectView = [[UIView alloc] init];
    [self.panLogin addSubview:self.profileSelectView];

    self.hintView = [[UIView alloc] init];
    self.hintView.backgroundColor =
        [PCLColor(0xEAF2FE) colorWithAlphaComponent:0.72];

    self.hintView.layer.cornerRadius = 2.0;
    [self.profileSelectView addSubview:self.hintView];

    UIView *bar = [[UIView alloc] init];
    bar.tag = 9201;
    bar.backgroundColor =
        [PCLColor(0x1370F3) colorWithAlphaComponent:0.60
        ];

    [self.hintView addSubview:bar];

    self.hintLabel = [[UILabel alloc] init];
    self.hintLabel.numberOfLines = 0;
    self.hintLabel.font =
        [UIFont systemFontOfSize:13.0];
    self.hintLabel.textColor =
        PCLColor(0x343D4A);

    self.hintLabel.text =
        @"请创建或选择一个档案以登录 Minecraft。";

    [self.hintView addSubview:self.hintLabel];
    UIView *newCard = [[UIView alloc] init];
    newCard.tag = 9202;

    newCard.backgroundColor =
        [UIColor colorWithRed:251.0/255.0
                        green:251.0/255.0
                         blue:251.0/255.0
                        alpha:210.0/255.0];
    newCard.layer.cornerRadius = 5.0;
    newCard.layer.shadowColor =
        UIColor.blackColor.CGColor;

    newCard.layer.shadowOpacity = 0.07;
    newCard.layer.shadowRadius = 3.0;

    [self.profileSelectView addSubview:newCard];
    self.newProfileButton =
        [UIButton buttonWithType:UIButtonTypeCustom];

    UIImageSymbolConfiguration *config =
        [UIImageSymbolConfiguration
            configurationWithPointSize:14.0
                                weight:UIImageSymbolWeightRegular];

    UIImage *icon =
        [[UIImage systemImageNamed:@"person.badge.plus"]
            imageByApplyingSymbolConfiguration:config];
    [self.newProfileButton
        setImage:icon
        forState:UIControlStateNormal];

    self.newProfileButton.tintColor =
        PCLColor(0x343D4A);

    [self.newProfileButton
        addTarget:self
           action:@selector(newProfilePressed)
 forControlEvents:UIControlEventTouchUpInside];

    [newCard addSubview:self.newProfileButton];
}

- (void)buildProfileSkinUI {
    self.profileSkinView = [[UIView alloc] init];
    [self.panLogin addSubview:self.profileSkinView];

    self.skinView = [[PCLSkinHeadView alloc] init];
    [self.profileSkinView addSubview:self.skinView];

    self.usernameLabel = [[UILabel alloc] init];
    self.usernameLabel.textAlignment =
        NSTextAlignmentCenter;

    self.usernameLabel.font =
        [UIFont systemFontOfSize:16.0];

    self.usernameLabel.textColor =
        PCLColor(0x343D4A);

    [self.profileSkinView
        addSubview:self.usernameLabel];

    self.typeLabel = [[UILabel alloc] init];

    self.typeLabel.textAlignment =
        NSTextAlignmentCenter;

    self.typeLabel.font =
        [UIFont systemFontOfSize:12.0];

    self.typeLabel.textColor =
        PCLColor(0xA6A6A6);

    [self.profileSkinView addSubview:self.typeLabel];

    self.profileButtonsCard =
        [[UIView alloc] init];

    self.profileButtonsCard.backgroundColor =
        [UIColor colorWithRed:251.0/255.0
                        green:251.0/255.0
                         blue:251.0/255.0
                        alpha:210.0/255.0];

    self.profileButtonsCard.layer.cornerRadius = 5.0;

    self.profileButtonsCard.layer.shadowColor =
        UIColor.blackColor.CGColor;

    self.profileButtonsCard.layer.shadowOpacity = 0.07;
    self.profileButtonsCard.layer.shadowRadius = 3.0;

    [self.profileSkinView
        addSubview:self.profileButtonsCard];

    self.skinButton =
        [UIButton buttonWithType:UIButtonTypeCustom];

    self.editButton =
        [UIButton buttonWithType:UIButtonTypeCustom];

    self.switchButton =
        [UIButton buttonWithType:UIButtonTypeCustom];

    UIImageSymbolConfiguration *config =
        [UIImageSymbolConfiguration
            configurationWithPointSize:13.0
                                weight:UIImageSymbolWeightRegular];

    [self.skinButton
        setImage:[[UIImage systemImageNamed:@"tshirt"]
            imageByApplyingSymbolConfiguration:config]
        forState:UIControlStateNormal];

    [self.editButton
        setImage:[[UIImage systemImageNamed:@"pencil"]
            imageByApplyingSymbolConfiguration:config]
        forState:UIControlStateNormal];

    [self.switchButton
        setImage:[[UIImage systemImageNamed:
            @"arrow.left.arrow.right"]
            imageByApplyingSymbolConfiguration:config]
        forState:UIControlStateNormal];

    NSArray *buttons = @[
        self.skinButton,
        self.editButton,
        self.switchButton
    ];

    for (UIButton *button in buttons) {
        button.tintColor = PCLColor(0x343D4A);
        [self.profileButtonsCard addSubview:button];
    }

    [self.skinButton
        addTarget:self
           action:@selector(skinPressed)
 forControlEvents:UIControlEventTouchUpInside];

    [self.editButton
        addTarget:self
           action:@selector(editPressed)
 forControlEvents:UIControlEventTouchUpInside];

    [self.switchButton
        addTarget:self
           action:@selector(switchPressed)
 forControlEvents:UIControlEventTouchUpInside];

    self.profileButtonsCard.alpha = 0.0;

    UITapGestureRecognizer *tap =
        [[UITapGestureRecognizer alloc]
            initWithTarget:self
                    action:@selector(profileTapped)];

    [self.profileSkinView addGestureRecognizer:tap];
}

- (void)reloadState {
    NSUserDefaults *defaults =
        NSUserDefaults.standardUserDefaults;

    NSString *username =
        [defaults stringForKey:@"PCLProfileUsername"];

    NSString *instance =
        [defaults stringForKey:@"PCLSelectedInstance"];

    BOOL hasProfile =
        username.length > 0;

    BOOL hasInstance =
        instance.length > 0;

    self.profileSelectView.hidden =
        hasProfile;

    self.profileSkinView.hidden =
        !hasProfile;

    self.usernameLabel.text =
        hasProfile
        ? username
        : @"";

    self.typeLabel.text =
        hasProfile
        ? @"离线登录"
        : @"";

    self.versionLabel.text =
        hasInstance
        ? instance
        : @"未选择实例";

    BOOL canLaunch =
        hasProfile && hasInstance;

    self.launchButton.enabled =
        canLaunch;

    self.instanceButton.enabled = YES;

    self.moreButton.hidden =
        !hasInstance;

    UIColor *launchColor =
        canLaunch
        ? PCLColor(0x0B5BCB)
        : PCLColor(0xA6A6A6);

    self.launchButton.layer.borderColor =
        launchColor.CGColor;

    [self.launchButton
        setTitleColor:launchColor
             forState:UIControlStateNormal];

    [self setNeedsLayout];
}

- (void)launchPressed {
    if (self.onLaunch)
        self.onLaunch();
}

- (void)instancePressed {
    if (self.onSelectInstance)
        self.onSelectInstance();
}

- (void)morePressed {
    if (self.onInstanceSettings)
        self.onInstanceSettings();
}

- (void)newProfilePressed {
    if (self.onCreateProfile)
        self.onCreateProfile();
}

- (void)switchPressed {
    if (self.onSwitchProfile)
        self.onSwitchProfile();
}

- (void)skinPressed {
    if (self.onSkinOptions)
        self.onSkinOptions();
}

- (void)editPressed {
    if (self.onEditProfile)
        self.onEditProfile();
}

- (void)profileTapped {
    CGFloat target =
        self.profileButtonsCard.alpha > 0.5
        ? 0.0
        : 1.0;

    [UIView animateWithDuration:0.18 animations:^{
        self.profileButtonsCard.alpha = target;
    }];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat width =
        CGRectGetWidth(self.bounds);

    CGFloat height =
        CGRectGetHeight(self.bounds);

    CGFloat scale =
        MIN(width / 300.0,
            height / 417.2);

    CGFloat designWidth =
        300.0 * scale;

    CGFloat designHeight =
        417.2 * scale;

    CGFloat ox =
        (width - designWidth) / 2.0;

    CGFloat oy =
        (height - designHeight) / 2.0;

    CGFloat loginHeight =
        298.2 * scale;

    CGFloat launchY =
        oy + 298.2 * scale;

    CGFloat launchHeight =
        54.0 * scale;

    CGFloat instanceY =
        oy + 362.2 * scale;

    CGFloat smallHeight =
        35.0 * scale;

    self.panLogin.frame =
        CGRectMake(ox + 20.0 * scale,
                   oy,
                   260.0 * scale,
                   loginHeight);

    self.launchButton.frame =
        CGRectMake(ox + 20.0 * scale,
                   launchY,
                   260.0 * scale,
                   launchHeight);

    self.launchButton.titleLabel.font =
        [UIFont systemFontOfSize:
            13.0 * scale];

    self.launchButton.titleEdgeInsets =
        UIEdgeInsetsMake(0,
                         0,
                         15.0 * scale,
                         0);

    self.versionLabel.font =
        [UIFont systemFontOfSize:
            11.0 * scale];

    self.versionLabel.frame =
        CGRectMake(15.0 * scale,
                   launchHeight - 25.0 * scale,
                   230.0 * scale,
                   15.0 * scale);

    self.instanceButton.titleLabel.font =
        [UIFont systemFontOfSize:
            13.0 * scale];

    self.moreButton.titleLabel.font =
        [UIFont systemFontOfSize:
            13.0 * scale];

    if (self.moreButton.hidden) {
        self.instanceButton.frame =
            CGRectMake(ox + 20.0 * scale,
                       instanceY,
                       260.0 * scale,
                       smallHeight);

    } else {
        CGFloat moreWidth =
            92.0 * scale;

        self.moreButton.frame =
            CGRectMake(ox + 300.0 * scale
                           - 20.0 * scale
                           - moreWidth,
                       instanceY,
                       moreWidth,
                       smallHeight);

        CGFloat instanceRight =
            CGRectGetMinX(self.moreButton.frame)
            - 10.0 * scale;

        self.instanceButton.frame =
            CGRectMake(ox + 20.0 * scale,
                       instanceY,
                       instanceRight
                           - (ox + 20.0 * scale),
                       smallHeight);
    }

    self.profileSelectView.frame =
        self.panLogin.bounds;

    CGFloat loginWidth =
        CGRectGetWidth(self.panLogin.bounds);

    self.hintView.frame =
        CGRectMake(0,
                   10.0 * scale,
                   loginWidth,
                   52.0 * scale);

    UIView *hintBar =
        [self.hintView viewWithTag:9201];

    hintBar.frame =
        CGRectMake(0,
                   0,
                   3.0 * scale,
                   CGRectGetHeight(
                       self.hintView.bounds));

    self.hintLabel.font =
        [UIFont systemFontOfSize:
            13.0 * scale];

    self.hintLabel.frame =
        CGRectMake(15.0 * scale,
                   7.0 * scale,
                   loginWidth
                       - 27.0 * scale,
                   38.0 * scale);

    UIView *newCard =
        [self.profileSelectView
            viewWithTag:9202];

    CGFloat cardWidth =
        44.0 * scale;

    CGFloat cardHeight =
        30.0 * scale;

    newCard.frame =
        CGRectMake((loginWidth - cardWidth) / 2.0,
                   CGRectGetHeight(
                       self.profileSelectView.bounds)
                       - 20.0 * scale
                       - cardHeight,
                   cardWidth,
                   cardHeight);

    self.newProfileButton.frame =
        CGRectMake(10.0 * scale,
                   3.0 * scale,
                   24.0 * scale,
                   24.0 * scale);

    self.profileSkinView.frame =
        self.panLogin.bounds;

    CGFloat profileWidth =
        CGRectGetWidth(
            self.profileSkinView.bounds);

    CGFloat skinSize =
        64.0 * scale;

    self.skinView.frame =
        CGRectMake((profileWidth - skinSize) / 2.0,
                   80.0 * scale,
                   skinSize,
                   skinSize);

    self.usernameLabel.font =
        [UIFont systemFontOfSize:
            16.0 * scale];

    self.usernameLabel.frame =
        CGRectMake(8.0 * scale,
                   154.0 * scale,
                   profileWidth
                       - 16.0 * scale,
                   21.0 * scale);

    self.typeLabel.font =
        [UIFont systemFontOfSize:
            12.0 * scale];

    self.typeLabel.frame =
        CGRectMake(8.0 * scale,
                   179.0 * scale,
                   profileWidth
                       - 16.0 * scale,
                   18.0 * scale);

    CGFloat buttonsWidth =
        109.0 * scale;

    CGFloat buttonsHeight =
        30.0 * scale;

    self.profileButtonsCard.frame =
        CGRectMake((profileWidth
                    - buttonsWidth) / 2.0,
                   205.0 * scale,
                   buttonsWidth,
                   buttonsHeight);

    self.skinButton.frame =
        CGRectMake(10.0 * scale,
                   3.0 * scale,
                   24.0 * scale,
                   24.0 * scale);

    self.editButton.frame =
        CGRectMake(43.0 * scale,
                   3.0 * scale,
                   24.0 * scale,
                   24.0 * scale);

    self.switchButton.frame =
        CGRectMake(76.0 * scale,
                   3.0 * scale,
                   24.0 * scale,
                   24.0 * scale);
}


- (void)playCEEnterAnimation {
    [PCLCEPageAnimator
        showSimpleLeftPage:self];
}

- (void)playCEExitAnimation {
    [PCLCEPageAnimator
        hideSimpleLeftPage:self];
}

@end
