#import "PCLLaunchLeftView.h"
#import "PCLCEPageAnimator.h"
#import <QuartzCore/QuartzCore.h>

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


- (void)pclAnimateScale:(CGFloat)target
               duration:(NSTimeInterval)duration {
    CALayer *shown=(CALayer *)self.layer.presentationLayer;

    CGFloat current=
        shown ? shown.transform.m11 : self.layer.transform.m11;

    if (current<=0.0) current=1.0;

    [self.layer removeAnimationForKey:@"pcl.press.scale"];

    CABasicAnimation *a=
        [CABasicAnimation animationWithKeyPath:@"transform.scale"];

    a.fromValue=@(current);
    a.toValue=@(target);
    a.duration=duration;

    a.timingFunction=
        [CAMediaTimingFunction functionWithName:
            kCAMediaTimingFunctionEaseOut];


    [CATransaction begin];
    [CATransaction setDisableActions:YES];

    self.layer.transform=
        CATransform3DMakeScale(target,target,1.0);

    [CATransaction commit];
    [self.layer addAnimation:a forKey:@"pcl.press.scale"];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];

    [self pclAnimateScale:0.955 duration:0.09];
    self.backgroundColor=PCLColor(0xE0EAFD);
}

- (void)restore {
    [self pclAnimateScale:1.0 duration:0.18];

    [UIView animateWithDuration:0.16 animations:^{
        self.backgroundColor=
            [UIColor colorWithWhite:1 alpha:0x55/255.0];
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
    self.layer.shadowOffset = CGSizeZero;

    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef c = UIGraphicsGetCurrentContext();

    CGFloat canvasSize = MIN(rect.size.width, rect.size.height);
    CGFloat size = canvasSize * 48.0 / 64.0;
    CGFloat origin = (canvasSize - size) / 2.0;

    CGContextSaveGState(c);
    CGContextTranslateCTM(c, origin, origin);

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

    CGContextRestoreGState(c);

    CGFloat foreSize = canvasSize * 56.0 / 64.0;
    CGFloat x = (canvasSize - foreSize) / 2.0;
    CGFloat px = foreSize / 8.0;

    [[hair colorWithAlphaComponent:0.42] setFill];
    CGContextFillRect(c, CGRectMake(x,x,foreSize,px*1.35));
    CGContextFillRect(c, CGRectMake(x,x,px,px*3.0));
    CGContextFillRect(c, CGRectMake(x+foreSize-px,x,px,px*3.0));
}

@end

@interface PCLLaunchLeftView ()

@property (nonatomic, strong) UIView *panLogin;

@property (nonatomic, strong) PCLCEButton *launchButton;
@property (nonatomic, strong) UIView *launchContentView;
@property (nonatomic, strong) UILabel *launchTitleLabel;
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

@property (nonatomic, strong) UIButton *createProfileButton;

@end

@implementation PCLLaunchLeftView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;

    self.backgroundColor = [UIColor colorWithWhite:0.995 alpha:0.824];

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
        [self pclButton:@"" highlight:YES];

    [self.launchButton addTarget:self
                          action:@selector(launchPressed)
                forControlEvents:UIControlEventTouchUpInside];

    [self addSubview:self.launchButton];

    self.launchContentView = [[UIView alloc] init];
    self.launchContentView.userInteractionEnabled = NO;
    [self.launchButton addSubview:self.launchContentView];

    self.launchTitleLabel = [[UILabel alloc] init];
    self.launchTitleLabel.textAlignment = NSTextAlignmentCenter;
    [self.launchContentView addSubview:self.launchTitleLabel];

    self.versionLabel = [[UILabel alloc] init];
    self.versionLabel.textAlignment = NSTextAlignmentCenter;
    self.versionLabel.font = [UIFont systemFontOfSize:11.0];
    self.versionLabel.textColor = PCLColor(0x8C8C8C);

    [self.launchContentView addSubview:self.versionLabel];

    self.instanceButton =
        [self pclButton:@"实例选择" highlight:NO];

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
        @"选择一个档案以启动游戏";

    [self.hintView addSubview:self.hintLabel];
    UIView *newCard = [[UIView alloc] init];
    newCard.tag = 9202;

    newCard.backgroundColor = [UIColor colorWithWhite:0.995 alpha:0.824];
    newCard.layer.cornerRadius = 5.0;
    newCard.layer.shadowColor =
        UIColor.blackColor.CGColor;

    newCard.layer.shadowOpacity = 0.07;
    newCard.layer.shadowRadius = 3.0;
    newCard.layer.shadowOffset = CGSizeZero;

    [self.profileSelectView addSubview:newCard];
    self.createProfileButton =
        [UIButton buttonWithType:UIButtonTypeCustom];

    UIImageSymbolConfiguration *config =
        [UIImageSymbolConfiguration
            configurationWithPointSize:14.0
                                weight:UIImageSymbolWeightRegular];

    UIImage *icon =
        [[UIImage systemImageNamed:@"person.badge.plus"]
            imageByApplyingSymbolConfiguration:config];
    [self.createProfileButton
        setImage:icon
        forState:UIControlStateNormal];

    self.createProfileButton.tintColor =
        PCLColor(0x343D4A);

    [self.createProfileButton
        addTarget:self
           action:@selector(newProfilePressed)
 forControlEvents:UIControlEventTouchUpInside];

    [newCard addSubview:self.createProfileButton];
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

    self.profileButtonsCard.backgroundColor = [UIColor colorWithWhite:0.995 alpha:0.824];

    self.profileButtonsCard.layer.cornerRadius = 5.0;

    self.profileButtonsCard.layer.shadowColor =
        UIColor.blackColor.CGColor;

    self.profileButtonsCard.layer.shadowOpacity = 0.07;
    self.profileButtonsCard.layer.shadowRadius = 3.0;
    self.profileButtonsCard.layer.shadowOffset = CGSizeZero;

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
        : @"未找到可用的游戏实例";

    self.launchTitleLabel.text =
        hasInstance ? @"启动游戏" : @"下载游戏";

    BOOL canLaunch =
        hasInstance ? hasProfile : YES;

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

    self.launchTitleLabel.textColor =
        launchColor;

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
        self.designScale > 0.0
        ? self.designScale
        : 1.0;

    for (PCLCEButton *b in @[self.launchButton,self.instanceButton,self.moreButton]) {
        b.layer.cornerRadius = 3.0 * scale;
        b.layer.borderWidth = 1.0 * scale;
    }

    self.skinView.layer.shadowRadius = 10.0 * scale;
    self.profileButtonsCard.layer.cornerRadius = 5.0 * scale;
    self.profileButtonsCard.layer.shadowRadius = 3.0 * scale;
    self.hintView.layer.cornerRadius = 2.0 * scale;

    CGFloat designWidth =
        300.0 * scale;


    CGFloat ox =
        (width - designWidth) / 2.0;

    CGFloat launchHeight = 54.0 * scale;
    CGFloat smallHeight = 35.0 * scale;

    CGFloat instanceY =
        height - 20.0 * scale - smallHeight;

    CGFloat launchY =
        instanceY - 10.0 * scale - launchHeight;

    CGFloat loginAreaHeight = launchY;
    CGFloat wantedLoginHeight =
        (self.profileSelectView.hidden ? 235.0 : 114.0) * scale;
    CGFloat loginHeight =
        MIN(loginAreaHeight,wantedLoginHeight);
    CGFloat loginY =
        MAX(0.0,(loginAreaHeight-loginHeight)/2.0);

    self.panLogin.frame =
        CGRectMake(ox + 20.0 * scale,
                   loginY,
                   260.0 * scale,
                   loginHeight);

    self.launchButton.frame =
        CGRectMake(ox + 20.0 * scale,
                   launchY,
                   260.0 * scale,
                   launchHeight);

    self.launchContentView.frame =
        self.launchButton.bounds;

    self.launchTitleLabel.font =
        [UIFont systemFontOfSize:13.0 * scale];

    CGFloat launchWidth =
        CGRectGetWidth(self.launchContentView.bounds);

    self.launchTitleLabel.frame =
        CGRectMake(0,
                   7.0 * scale,
                   launchWidth,
                   20.0 * scale);

    self.versionLabel.font =
        [UIFont systemFontOfSize:10.0 * scale];

    self.versionLabel.frame =
        CGRectMake(0,
                   30.0 * scale,
                   launchWidth,
                   14.0 * scale);

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
                   34.0 * scale);

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
                   9.0 * scale,
                   loginWidth
                       - 27.0 * scale,
                   16.0 * scale);

    UIView *newCard =
        [self.profileSelectView
            viewWithTag:9202];

    newCard.layer.cornerRadius = 5.0 * scale;
    newCard.layer.shadowRadius = 3.0 * scale;

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

    self.createProfileButton.frame =
        CGRectMake(10.0 * scale,
                   3.0 * scale,
                   24.0 * scale,
                   24.0 * scale);

    UIImageSymbolConfiguration *newIcon =
        [UIImageSymbolConfiguration configurationWithPointSize:14.0*scale
                                                        weight:UIImageSymbolWeightRegular];

    [self.createProfileButton
        setImage:[[UIImage systemImageNamed:@"person.badge.plus"]
        imageByApplyingSymbolConfiguration:newIcon]
        forState:UIControlStateNormal];

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

    UIImageSymbolConfiguration *icons =
        [UIImageSymbolConfiguration configurationWithPointSize:13.0*scale
                                                        weight:UIImageSymbolWeightRegular];

    [self.skinButton setImage:[[UIImage systemImageNamed:@"tshirt"]
        imageByApplyingSymbolConfiguration:icons] forState:UIControlStateNormal];

    [self.editButton setImage:[[UIImage systemImageNamed:@"pencil"]
        imageByApplyingSymbolConfiguration:icons] forState:UIControlStateNormal];

    [self.switchButton setImage:[[UIImage systemImageNamed:@"arrow.left.arrow.right"]
        imageByApplyingSymbolConfiguration:icons] forState:UIControlStateNormal];
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
