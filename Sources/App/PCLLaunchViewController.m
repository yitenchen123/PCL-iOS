#import "PCLLaunchViewController.h"

static UIColor *PCLColor(NSUInteger rgb) {
    return [UIColor colorWithRed:((rgb >> 16) & 255) / 255.0
                           green:((rgb >> 8) & 255) / 255.0
                            blue:(rgb & 255) / 255.0
                           alpha:1.0];
}

@interface PCLLaunchViewController ()

@property (nonatomic, strong) UIView *leftPane;
@property (nonatomic, strong) UIScrollView *rightPane;
@property (nonatomic, strong) UIView *accountHost;

@property (nonatomic, strong) UIButton *launchButton;
@property (nonatomic, strong) UIButton *instanceButton;
@property (nonatomic, strong) UIButton *moreButton;
@property (nonatomic, strong) UILabel *versionLabel;

@property (nonatomic, strong) UIView *profilePanel;
@property (nonatomic, strong) UIImageView *profileIcon;
@property (nonatomic, strong) UILabel *profileNameLabel;
@property (nonatomic, strong) UILabel *profileTypeLabel;
@property (nonatomic, strong) UIButton *profileButton;

@property (nonatomic, strong) UIView *homeCard;
@property (nonatomic, strong) UILabel *homeTitle;
@property (nonatomic, strong) UILabel *homeBody;

@property (nonatomic, copy) NSArray<NSString *> *instances;
@property (nonatomic, copy) NSString *selectedInstance;
@property (nonatomic, copy) NSString *profileName;

@end

@implementation PCLLaunchViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = PCLColor(0xFBFBFB);

    [self buildUI];
    [self reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadData];
}

- (UIButton *)button:(NSString *)title
           highlight:(BOOL)highlight {

    UIButton *button =
        [UIButton buttonWithType:UIButtonTypeCustom];

    button.layer.cornerRadius = 3.0;
    button.layer.borderWidth = 1.0;
    button.titleLabel.font = [UIFont systemFontOfSize:13.0];

    [button setTitle:title forState:UIControlStateNormal];

    UIColor *color =
        PCLColor(highlight ? 0x0B5BCB : 0x343D4A);

    button.layer.borderColor = color.CGColor;

    [button setTitleColor:color
                 forState:UIControlStateNormal];

    button.backgroundColor =
        [UIColor colorWithWhite:1.0
                          alpha:0x55 / 255.0];

    [button addTarget:self
               action:@selector(buttonDown:)
     forControlEvents:UIControlEventTouchDown];

    [button addTarget:self
               action:@selector(buttonUp:)
     forControlEvents:UIControlEventTouchUpInside |
                      UIControlEventTouchUpOutside |
                      UIControlEventTouchCancel];

    return button;
}

- (void)buildUI {
    self.leftPane = [[UIView alloc] init];
    self.rightPane = [[UIScrollView alloc] init];
    self.accountHost = [[UIView alloc] init];

    self.rightPane.showsHorizontalScrollIndicator = NO;
    self.rightPane.alwaysBounceVertical = YES;

    [self.view addSubview:self.leftPane];
    [self.view addSubview:self.rightPane];
    [self.leftPane addSubview:self.accountHost];

    self.launchButton =
        [self button:@"启动" highlight:YES];

    self.instanceButton =
        [self button:@"选择实例" highlight:NO];

    self.moreButton =
        [self button:@"实例设置" highlight:NO];

    [self.launchButton addTarget:self
                          action:@selector(launchPressed)
                forControlEvents:UIControlEventTouchUpInside];

    [self.instanceButton addTarget:self
                            action:@selector(instancePressed)
                  forControlEvents:UIControlEventTouchUpInside];

    [self.moreButton addTarget:self
                        action:@selector(morePressed)
              forControlEvents:UIControlEventTouchUpInside];

    [self.leftPane addSubview:self.launchButton];
    [self.leftPane addSubview:self.instanceButton];
    [self.leftPane addSubview:self.moreButton];

    self.versionLabel = [[UILabel alloc] init];
    self.versionLabel.textAlignment = NSTextAlignmentCenter;
    self.versionLabel.textColor = PCLColor(0x8C8C8C);
    self.versionLabel.lineBreakMode =
        NSLineBreakByTruncatingTail;

    [self.launchButton addSubview:self.versionLabel];

    [self buildProfileUI];
    [self buildHomeUI];
}

- (void)buildProfileUI {
    self.profilePanel = [[UIView alloc] init];

    self.profileIcon = [[UIImageView alloc]
        initWithImage:
            [UIImage systemImageNamed:@"person.crop.square"]];

    self.profileIcon.tintColor = PCLColor(0x1370F3);
    self.profileIcon.contentMode =
        UIViewContentModeScaleAspectFit;

    self.profileNameLabel = [[UILabel alloc] init];
    self.profileNameLabel.textAlignment =
        NSTextAlignmentCenter;
    self.profileNameLabel.textColor =
        PCLColor(0x343D4A);

    self.profileTypeLabel = [[UILabel alloc] init];
    self.profileTypeLabel.textAlignment =
        NSTextAlignmentCenter;
    self.profileTypeLabel.textColor =
        PCLColor(0xA6A6A6);

    self.profileButton =
        [self button:@"创建档案" highlight:YES];

    [self.profileButton addTarget:self
                           action:@selector(profilePressed)
                 forControlEvents:UIControlEventTouchUpInside];

    [self.accountHost addSubview:self.profilePanel];
    [self.profilePanel addSubview:self.profileIcon];
    [self.profilePanel addSubview:self.profileNameLabel];
    [self.profilePanel addSubview:self.profileTypeLabel];
    [self.profilePanel addSubview:self.profileButton];
}

- (void)buildHomeUI {
    self.homeCard = [[UIView alloc] init];

    self.homeCard.backgroundColor =
        [UIColor colorWithRed:251.0/255.0
                        green:251.0/255.0
                         blue:251.0/255.0
                        alpha:210.0/255.0];

    self.homeCard.layer.cornerRadius = 5.0;
    self.homeCard.layer.shadowColor =
        UIColor.blackColor.CGColor;
    self.homeCard.layer.shadowOpacity = 0.07;
    self.homeCard.layer.shadowRadius = 3.0;

    self.homeTitle = [[UILabel alloc] init];
    self.homeTitle.text = @"你知道吗";
    self.homeTitle.textColor = PCLColor(0x343D4A);

    self.homeTitle.font =
        [UIFont systemFontOfSize:13.0
                          weight:UIFontWeightBold];

    self.homeBody = [[UILabel alloc] init];
    self.homeBody.textColor = PCLColor(0x343D4A);
    self.homeBody.numberOfLines = 0;

    NSArray *hints = @[
        @"PCL [iOS] 会自动记住上一次选择的实例。",
        @"选择实例后，启动按钮下方会显示当前 Minecraft 实例。",
        @"档案与 Minecraft 实例是相互独立保存的。"
    ];

    self.homeBody.text =
        hints[arc4random_uniform((uint32_t)hints.count)];

    [self.rightPane addSubview:self.homeCard];
    [self.homeCard addSubview:self.homeTitle];
    [self.homeCard addSubview:self.homeBody];
}

- (NSArray<NSString *> *)versionRoots {
    NSString *docs =
        NSSearchPathForDirectoriesInDomains(
            NSDocumentDirectory,
            NSUserDomainMask,
            YES).firstObject;

    NSString *library =
        NSSearchPathForDirectoriesInDomains(
            NSLibraryDirectory,
            NSUserDomainMask,
            YES).firstObject;

    return @[
        [docs stringByAppendingPathComponent:
            @".minecraft/versions"],

        [docs stringByAppendingPathComponent:
            @"minecraft/versions"],

        [library stringByAppendingPathComponent:
            @"Application Support/minecraft/versions"],

        [library stringByAppendingPathComponent:
            @"minecraft/versions"]
    ];
}

- (void)reloadData {
    NSUserDefaults *defaults =
        NSUserDefaults.standardUserDefaults;

    self.profileName =
        [defaults stringForKey:@"PCLProfileUsername"];

    NSFileManager *fm =
        NSFileManager.defaultManager;

    NSMutableOrderedSet *found =
        [NSMutableOrderedSet orderedSet];

    for (NSString *root in [self versionRoots]) {
        NSArray *names =
            [fm contentsOfDirectoryAtPath:root
                                    error:nil];

        for (NSString *name in names) {
            NSString *dir =
                [root stringByAppendingPathComponent:name];

            NSString *json =
                [dir stringByAppendingPathComponent:
                    [name stringByAppendingString:@".json"]];

            if ([fm fileExistsAtPath:json])
                [found addObject:name];
        }
    }

    self.instances =
        [[found array]
            sortedArrayUsingSelector:
                @selector(localizedCaseInsensitiveCompare:)];

    NSString *saved =
        [defaults stringForKey:@"PCLSelectedInstance"];

    self.selectedInstance =
        [self.instances containsObject:saved]
        ? saved
        : self.instances.firstObject;

    if (self.selectedInstance.length) {
        [defaults setObject:self.selectedInstance
                     forKey:@"PCLSelectedInstance"];
    } else {
        [defaults removeObjectForKey:@"PCLSelectedInstance"];
    }

    [self refreshState];
    [self.view setNeedsLayout];
}

- (void)refreshState {
    BOOL hasProfile =
        self.profileName.length > 0;

    BOOL hasInstance =
        self.selectedInstance.length > 0;

    self.profileNameLabel.text =
        hasProfile
        ? self.profileName
        : @"尚未选择档案";

    self.profileTypeLabel.text =
        hasProfile
        ? @"离线登录"
        : @"创建档案后即可启动";

    [self.profileButton
        setTitle:(hasProfile ? @"切换档案"
                             : @"创建档案")
        forState:UIControlStateNormal];

    self.versionLabel.text =
        hasInstance
        ? self.selectedInstance
        : @"未找到可用的 Minecraft 实例";

    self.launchButton.enabled =
        hasProfile && hasInstance;

    self.instanceButton.enabled = YES;
    self.moreButton.hidden = !hasInstance;

    UIColor *launchColor =
        self.launchButton.enabled
        ? PCLColor(0x0B5BCB)
        : PCLColor(0xA6A6A6);

    self.launchButton.layer.borderColor =
        launchColor.CGColor;

    [self.launchButton
        setTitleColor:launchColor
             forState:UIControlStateNormal];
}

- (void)profilePressed {
    if (self.profileName.length) {
        [NSUserDefaults.standardUserDefaults
            removeObjectForKey:@"PCLProfileUsername"];

        [self reloadData];
        return;
    }

    UIAlertController *alert =
        [UIAlertController
            alertControllerWithTitle:@"创建离线档案"
                             message:@"输入玩家名"
                      preferredStyle:UIAlertControllerStyleAlert];

    [alert addTextFieldWithConfigurationHandler:
        ^(UITextField *field) {
            field.placeholder = @"玩家名";
            field.autocapitalizationType =
                UITextAutocapitalizationTypeNone;
        }];

    [alert addAction:
        [UIAlertAction actionWithTitle:@"取消"
                                 style:UIAlertActionStyleCancel
                               handler:nil]];

    __weak typeof(self) weakSelf = self;

    [alert addAction:
        [UIAlertAction actionWithTitle:@"创建"
                                 style:UIAlertActionStyleDefault
                               handler:^(__unused UIAlertAction *action) {

        NSString *name =
            [alert.textFields.firstObject.text
                stringByTrimmingCharactersInSet:
                    NSCharacterSet.whitespaceAndNewlineCharacterSet];

        if (!name.length || name.length > 16)
            return;

        [NSUserDefaults.standardUserDefaults
            setObject:name
               forKey:@"PCLProfileUsername"];

        [weakSelf reloadData];
    }]];

    [self presentViewController:alert
                       animated:YES
                     completion:nil];
}

- (void)instancePressed {
    [self reloadData];

    if (!self.instances.count) {
        [self showAlert:@"选择实例"
                message:@"没有扫描到 Minecraft 实例。"];
        return;
    }

    UIAlertController *alert =
        [UIAlertController
            alertControllerWithTitle:@"选择实例"
                             message:nil
                      preferredStyle:UIAlertControllerStyleAlert];

    __weak typeof(self) weakSelf = self;

    for (NSString *name in self.instances) {
        NSString *title =
            [name isEqualToString:self.selectedInstance]
            ? [@"✓ " stringByAppendingString:name]
            : name;

        [alert addAction:
            [UIAlertAction actionWithTitle:title
                                     style:UIAlertActionStyleDefault
                                   handler:^(__unused UIAlertAction *action) {

            weakSelf.selectedInstance = name;

            [NSUserDefaults.standardUserDefaults
                setObject:name
                   forKey:@"PCLSelectedInstance"];

            [weakSelf refreshState];
        }]];
    }

    [alert addAction:
        [UIAlertAction actionWithTitle:@"取消"
                                 style:UIAlertActionStyleCancel
                               handler:nil]];

    [self presentViewController:alert
                       animated:YES
                     completion:nil];
}

- (void)morePressed {
    NSString *message =
        [NSString stringWithFormat:
            @"当前实例：%@",
            self.selectedInstance ?: @"无"];

    [self showAlert:@"实例设置"
            message:message];
}

- (void)launchPressed {
    if (!self.selectedInstance.length ||
        !self.profileName.length)
        return;

    NSString *message =
        [NSString stringWithFormat:
            @"实例：%@\n档案：%@\n\n启动 runtime 将在下一阶段接入。",
            self.selectedInstance,
            self.profileName];

    [self showAlert:@"启动"
            message:message];
}

- (void)showAlert:(NSString *)title
          message:(NSString *)message {

    UIAlertController *alert =
        [UIAlertController
            alertControllerWithTitle:title
                             message:message
                      preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:
        [UIAlertAction actionWithTitle:@"确定"
                                 style:UIAlertActionStyleDefault
                               handler:nil]];

    [self presentViewController:alert
                       animated:YES
                     completion:nil];
}

- (void)buttonDown:(UIButton *)button {
    [UIView animateWithDuration:0.08
                     animations:^{
        button.transform =
            CGAffineTransformMakeScale(0.955, 0.955);

        button.backgroundColor =
            PCLColor(0xE0EAFD);
    }];
}

- (void)buttonUp:(UIButton *)button {
    [UIView animateWithDuration:0.30
                     animations:^{
        button.transform =
            CGAffineTransformIdentity;

        button.backgroundColor =
            [UIColor colorWithWhite:1.0
                              alpha:0x55 / 255.0];
    }];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    CGFloat width =
        CGRectGetWidth(self.view.bounds);

    CGFloat height =
        CGRectGetHeight(self.view.bounds);

    CGFloat scale = width / 850.0;
    scale = MAX(0.78, MIN(scale, 1.45));

    CGFloat leftWidth = 300.0 * scale;

    CGFloat margin = 20.0 * scale;
    CGFloat bottom = 20.0 * scale;

    CGFloat smallHeight = 35.0 * scale;
    CGFloat launchHeight = 54.0 * scale;
    CGFloat gap = 10.0 * scale;

    self.leftPane.frame =
        CGRectMake(0, 0, leftWidth, height);

    self.rightPane.frame =
        CGRectMake(leftWidth,
                   0,
                   MAX(0, width - leftWidth),
                   height);

    CGFloat smallY =
        height - bottom - smallHeight;

    CGFloat launchY =
        smallY - gap - launchHeight;

    self.launchButton.frame =
        CGRectMake(margin,
                   launchY,
                   leftWidth - margin * 2.0,
                   launchHeight);

    self.launchButton.titleLabel.font =
        [UIFont systemFontOfSize:13.0 * scale];

    self.launchButton.titleEdgeInsets =
        UIEdgeInsetsMake(0, 0, 15.0 * scale, 0);

    self.versionLabel.font =
        [UIFont systemFontOfSize:11.0 * scale];

    self.versionLabel.frame =
        CGRectMake(15.0 * scale,
                   launchHeight - 23.0 * scale,
                   CGRectGetWidth(self.launchButton.bounds)
                       - 30.0 * scale,
                   13.0 * scale);

    self.instanceButton.titleLabel.font =
        [UIFont systemFontOfSize:13.0 * scale];

    self.moreButton.titleLabel.font =
        [UIFont systemFontOfSize:13.0 * scale];

    CGFloat moreWidth = 96.0 * scale;

    if (self.moreButton.hidden) {
        self.instanceButton.frame =
            CGRectMake(margin,
                       smallY,
                       leftWidth - margin * 2.0,
                       smallHeight);

    } else {
        self.moreButton.frame =
            CGRectMake(leftWidth - margin - moreWidth,
                       smallY,
                       moreWidth,
                       smallHeight);

        self.instanceButton.frame =
            CGRectMake(margin,
                       smallY,
                       CGRectGetMinX(self.moreButton.frame)
                           - margin - gap,
                       smallHeight);
    }

    self.accountHost.frame =
        CGRectMake(margin,
                   0,
                   leftWidth - margin * 2.0,
                   MAX(0, launchY));

    CGFloat panelWidth =
        CGRectGetWidth(self.accountHost.bounds);

    CGFloat panelHeight =
        190.0 * scale;

    self.profilePanel.frame =
        CGRectMake(0,
                   MAX(0,
                       (CGRectGetHeight(self.accountHost.bounds)
                        - panelHeight) / 2.0),
                   panelWidth,
                   panelHeight);

    CGFloat iconSize = 72.0 * scale;

    self.profileIcon.frame =
        CGRectMake((panelWidth - iconSize) / 2.0,
                   0,
                   iconSize,
                   iconSize);

    self.profileNameLabel.frame =
        CGRectMake(0,
                   84.0 * scale,
                   panelWidth,
                   22.0 * scale);

    self.profileTypeLabel.frame =
        CGRectMake(0,
                   110.0 * scale,
                   panelWidth,
                   18.0 * scale);

    self.profileButton.frame =
        CGRectMake((panelWidth - 110.0 * scale) / 2.0,
                   145.0 * scale,
                   110.0 * scale,
                   35.0 * scale);

    self.profileNameLabel.font =
        [UIFont systemFontOfSize:16.0 * scale];

    self.profileTypeLabel.font =
        [UIFont systemFontOfSize:12.0 * scale];

    self.profileButton.titleLabel.font =
        [UIFont systemFontOfSize:13.0 * scale];

    CGFloat rightWidth =
        CGRectGetWidth(self.rightPane.bounds);

    CGFloat cardMargin = 25.0 * scale;
    CGFloat cardHeight = 116.0 * scale;

    self.homeCard.frame =
        CGRectMake(cardMargin,
                   cardMargin,
                   MAX(0, rightWidth - cardMargin * 2.0),
                   cardHeight);

    self.homeTitle.frame =
        CGRectMake(15.0 * scale,
                   12.0 * scale,
                   CGRectGetWidth(self.homeCard.bounds)
                       - 30.0 * scale,
                   18.0 * scale);

    self.homeBody.frame =
        CGRectMake(25.0 * scale,
                   38.0 * scale,
                   CGRectGetWidth(self.homeCard.bounds)
                       - 48.0 * scale,
                   cardHeight - 53.0 * scale);

    self.homeTitle.font =
        [UIFont systemFontOfSize:13.0 * scale
                          weight:UIFontWeightBold];

    self.homeBody.font =
        [UIFont systemFontOfSize:13.0 * scale];

    self.rightPane.contentSize =
        CGSizeMake(rightWidth,
                   MAX(height,
                       CGRectGetMaxY(self.homeCard.frame)
                       + 10.0 * scale));
}

@end
