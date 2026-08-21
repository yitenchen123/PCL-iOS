#import "PCLSettingsRightView.h"
#import "PCLCEPageAnimator.h"
#import "PCLJavaManager.h"
#import <QuartzCore/QuartzCore.h>

static UIColor *PCLColor(NSUInteger rgb) {
    return [UIColor colorWithRed:((rgb >> 16) & 255) / 255.0
                           green:((rgb >> 8) & 255) / 255.0
                            blue:(rgb & 255) / 255.0
                           alpha:1.0];
}

@interface PCLSettingsRightView () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIStackView *cardStackView;
@property (nonatomic) PCLSettingsTab currentTab;
@property (nonatomic, strong) UITableView *javaTableView;
@property (nonatomic, strong) NSArray<PCLJavaRuntime *> *javaList;
@property (nonatomic, strong) UISegmentedControl *themeSegment;
@property (nonatomic, strong) UISlider *memorySlider;
@property (nonatomic, strong) UILabel *memoryLabel;
@property (nonatomic, strong) UISwitch *fullscreenSwitch;
@property (nonatomic, strong) UISwitch *autoLoginSwitch;
@property (nonatomic, strong) UILabel *aboutTitleLabel;
@property (nonatomic, strong) UILabel *aboutDescLabel;
@end

@implementation PCLSettingsRightView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _currentTab = PCLSettingsTabLaunch;
        [self setupView];
    }
    return self;
}

- (void)setupView {
    self.backgroundColor = [UIColor clearColor];
    
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.alwaysBounceVertical = YES;
    [self addSubview:self.scrollView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
    ]];
    
    self.cardStackView = [[UIStackView alloc] init];
    self.cardStackView.translatesAutoresizingMaskIntoConstraints = NO;
    self.cardStackView.axis = UILayoutConstraintAxisVertical;
    self.cardStackView.spacing = 16;
    self.cardStackView.alignment = UIStackViewAlignmentFill;
    self.cardStackView.distribution = UIStackViewDistributionFill;
    [self.scrollView addSubview:self.cardStackView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.cardStackView.topAnchor constraintEqualToAnchor:self.scrollView.topAnchor constant:16],
        [self.cardStackView.leadingAnchor constraintEqualToAnchor:self.scrollView.leadingAnchor constant:16],
        [self.cardStackView.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor constant:-16],
        [self.cardStackView.bottomAnchor constraintEqualToAnchor:self.scrollView.bottomAnchor constant:-16],
        [self.cardStackView.widthAnchor constraintEqualToAnchor:self.scrollView.widthAnchor constant:-32]
    ]];
}

- (UIView *)createCardWithTitle:(NSString *)title {
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [UIColor whiteColor];
    card.layer.cornerRadius = 10;
    card.layer.shadowColor = [UIColor blackColor].CGColor;
    card.layer.shadowOpacity = 0.06;
    card.layer.shadowRadius = 8;
    card.layer.shadowOffset = CGSizeMake(0, 2);
    card.translatesAutoresizingMaskIntoConstraints = NO;
    
    if (title.length > 0) {
        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.text = title;
        titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
        titleLabel.textColor = PCLColor(0x343D4A);
        titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [card addSubview:titleLabel];
        
        [NSLayoutConstraint activateConstraints:@[
            [titleLabel.topAnchor constraintEqualToAnchor:card.topAnchor constant:16],
            [titleLabel.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
            [titleLabel.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16]
        ]];
    }
    
    return card;
}

- (void)switchToTab:(PCLSettingsTab)tab {
    self.currentTab = tab;
    
    [self.cardStackView.arrangedSubviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    switch (tab) {
        case PCLSettingsTabLaunch: [self buildLaunchSettings]; break;
        case PCLSettingsTabJava: [self buildJavaSettings]; break;
        case PCLSettingsTabGameManage: [self buildGameManageSettings]; break;
        case PCLSettingsTabUI: [self buildUISettings]; break;
        case PCLSettingsTabAbout: [self buildAboutPage]; break;
        default: [self buildPlaceholder:tab]; break;
    }
}

- (void)buildLaunchSettings {
    UIView *memCard = [self createCardWithTitle:@"内存设置"];
    
    UILabel *memTitle = [[UILabel alloc] init];
    memTitle.text = @"最大内存分配";
    memTitle.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    memTitle.textColor = PCLColor(0x343D4A);
    memTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [memCard addSubview:memTitle];
    
    self.memorySlider = [[UISlider alloc] init];
    self.memorySlider.translatesAutoresizingMaskIntoConstraints = NO;
    self.memorySlider.minimumValue = 512;
    self.memorySlider.maximumValue = 8192;
    self.memorySlider.value = 2048;
    self.memorySlider.tintColor = PCLColor(0x1370F3);
    [self.memorySlider addTarget:self action:@selector(memoryChanged:) forControlEvents:UIControlEventValueChanged];
    [memCard addSubview:self.memorySlider];
    
    self.memoryLabel = [[UILabel alloc] init];
    self.memoryLabel.text = @"2048 MB";
    self.memoryLabel.font = [UIFont systemFontOfSize:13];
    self.memoryLabel.textColor = PCLColor(0x8C8C8C);
    self.memoryLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [memCard addSubview:self.memoryLabel];
    
    [NSLayoutConstraint activateConstraints:@[
        [memTitle.topAnchor constraintEqualToAnchor:memCard.topAnchor constant:52],
        [memTitle.leadingAnchor constraintEqualToAnchor:memCard.leadingAnchor constant:16],
        [self.memorySlider.topAnchor constraintEqualToAnchor:memTitle.bottomAnchor constant:8],
        [self.memorySlider.leadingAnchor constraintEqualToAnchor:memCard.leadingAnchor constant:16],
        [self.memorySlider.trailingAnchor constraintEqualToAnchor:memCard.trailingAnchor constant:-80],
        [self.memoryLabel.centerYAnchor constraintEqualToAnchor:self.memorySlider.centerYAnchor],
        [self.memoryLabel.leadingAnchor constraintEqualToAnchor:self.memorySlider.trailingAnchor constant:8],
        [self.memoryLabel.trailingAnchor constraintEqualToAnchor:memCard.trailingAnchor constant:-16],
        [memCard.bottomAnchor constraintEqualToAnchor:self.memorySlider.bottomAnchor constant:16]
    ]];
    
    [self.cardStackView addArrangedSubview:memCard];
    
    UIView *argsCard = [self createCardWithTitle:@"启动参数"];
    
    UILabel *jvmArgsLabel = [[UILabel alloc] init];
    jvmArgsLabel.text = @"JVM 参数";
    jvmArgsLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    jvmArgsLabel.textColor = PCLColor(0x343D4A);
    jvmArgsLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [argsCard addSubview:jvmArgsLabel];
    
    UITextField *jvmArgsField = [[UITextField alloc] init];
    jvmArgsField.translatesAutoresizingMaskIntoConstraints = NO;
    jvmArgsField.font = [UIFont systemFontOfSize:13];
    jvmArgsField.textColor = PCLColor(0x404040);
    jvmArgsField.placeholder = @"-XX:+UseG1GC -XX:+UnlockExperimentalVMOptions";
    jvmArgsField.borderStyle = UITextBorderStyleRoundedRect;
    [argsCard addSubview:jvmArgsField];
    
    [NSLayoutConstraint activateConstraints:@[
        [jvmArgsLabel.topAnchor constraintEqualToAnchor:argsCard.topAnchor constant:52],
        [jvmArgsLabel.leadingAnchor constraintEqualToAnchor:argsCard.leadingAnchor constant:16],
        [jvmArgsField.topAnchor constraintEqualToAnchor:jvmArgsLabel.bottomAnchor constant:8],
        [jvmArgsField.leadingAnchor constraintEqualToAnchor:argsCard.leadingAnchor constant:16],
        [jvmArgsField.trailingAnchor constraintEqualToAnchor:argsCard.trailingAnchor constant:-16],
        [jvmArgsField.heightAnchor constraintEqualToConstant:36],
        [argsCard.bottomAnchor constraintEqualToAnchor:jvmArgsField.bottomAnchor constant:16]
    ]];
    
    [self.cardStackView addArrangedSubview:argsCard];
}

- (void)buildJavaSettings {
    UIView *javaCard = [self createCardWithTitle:@"Java 运行时"];
    
    self.javaList = [[PCLJavaManager sharedManager] availableJavaVersions];
    
    self.javaTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.javaTableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.javaTableView.delegate = self;
    self.javaTableView.dataSource = self;
    self.javaTableView.backgroundColor = [UIColor clearColor];
    self.javaTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.javaTableView.scrollEnabled = NO;
    self.javaTableView.rowHeight = 64;
    self.javaTableView.allowsSelection = NO;
    [javaCard addSubview:self.javaTableView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.javaTableView.topAnchor constraintEqualToAnchor:javaCard.topAnchor constant:52],
        [self.javaTableView.leadingAnchor constraintEqualToAnchor:javaCard.leadingAnchor],
        [self.javaTableView.trailingAnchor constraintEqualToAnchor:javaCard.trailingAnchor],
        [self.javaTableView.bottomAnchor constraintEqualToAnchor:javaCard.bottomAnchor constant:-8],
        [self.javaTableView.heightAnchor constraintEqualToConstant:self.javaList.count * 64]
    ]];
    
    [self.cardStackView addArrangedSubview:javaCard];
}

- (void)buildGameManageSettings {
    UIView *generalCard = [self createCardWithTitle:@"通用"];
    
    UILabel *autoLoginLabel = [[UILabel alloc] init];
    autoLoginLabel.text = @"自动登录";
    autoLoginLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    autoLoginLabel.textColor = PCLColor(0x343D4A);
    autoLoginLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [generalCard addSubview:autoLoginLabel];
    
    self.autoLoginSwitch = [[UISwitch alloc] init];
    self.autoLoginSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    self.autoLoginSwitch.onTintColor = PCLColor(0x1370F3);
    [generalCard addSubview:self.autoLoginSwitch];
    
    [NSLayoutConstraint activateConstraints:@[
        [autoLoginLabel.topAnchor constraintEqualToAnchor:generalCard.topAnchor constant:52],
        [autoLoginLabel.leadingAnchor constraintEqualToAnchor:generalCard.leadingAnchor constant:16],
        [self.autoLoginSwitch.centerYAnchor constraintEqualToAnchor:autoLoginLabel.centerYAnchor],
        [self.autoLoginSwitch.trailingAnchor constraintEqualToAnchor:generalCard.trailingAnchor constant:-16],
        [generalCard.bottomAnchor constraintEqualToAnchor:autoLoginLabel.bottomAnchor constant:16]
    ]];
    
    [self.cardStackView addArrangedSubview:generalCard];
}

- (void)buildUISettings {
    UIView *themeCard = [self createCardWithTitle:@"主题"];
    
    UILabel *modeLabel = [[UILabel alloc] init];
    modeLabel.text = @"主题模式";
    modeLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    modeLabel.textColor = PCLColor(0x343D4A);
    modeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [themeCard addSubview:modeLabel];
    
    self.themeSegment = [[UISegmentedControl alloc] initWithItems:@[@"跟随系统", @"浅色", @"深色"]];
    self.themeSegment.selectedSegmentIndex = 0;
    self.themeSegment.translatesAutoresizingMaskIntoConstraints = NO;
    self.themeSegment.backgroundColor = PCLColor(0xF5F5F5);
    [themeCard addSubview:self.themeSegment];
    
    [NSLayoutConstraint activateConstraints:@[
        [modeLabel.topAnchor constraintEqualToAnchor:themeCard.topAnchor constant:52],
        [modeLabel.leadingAnchor constraintEqualToAnchor:themeCard.leadingAnchor constant:16],
        [self.themeSegment.topAnchor constraintEqualToAnchor:modeLabel.bottomAnchor constant:8],
        [self.themeSegment.leadingAnchor constraintEqualToAnchor:themeCard.leadingAnchor constant:16],
        [self.themeSegment.trailingAnchor constraintEqualToAnchor:themeCard.trailingAnchor constant:-16],
        [self.themeSegment.heightAnchor constraintEqualToConstant:36],
        [themeCard.bottomAnchor constraintEqualToAnchor:self.themeSegment.bottomAnchor constant:16]
    ]];
    
    [self.cardStackView addArrangedSubview:themeCard];
}

- (void)buildAboutPage {
    UIView *aboutCard = [self createCardWithTitle:@"关于 PCL-iOS"];
    
    self.aboutTitleLabel = [[UILabel alloc] init];
    self.aboutTitleLabel.text = @"PCL-iOS v0.1 (build 1)";
    self.aboutTitleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    self.aboutTitleLabel.textColor = PCLColor(0x343D4A);
    self.aboutTitleLabel.textAlignment = NSTextAlignmentCenter;
    self.aboutTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [aboutCard addSubview:self.aboutTitleLabel];
    
    self.aboutDescLabel = [[UILabel alloc] init];
    self.aboutDescLabel.text = @"PCL-iOS 是一个开源的 Minecraft Java Edition iOS 启动器\n基于 PCL2 Community Edition UI 设计\n\n开发者: yitenchen123, Robit-space\n许可证: GPL-2.0";
    self.aboutDescLabel.font = [UIFont systemFontOfSize:13];
    self.aboutDescLabel.textColor = PCLColor(0x8C8C8C);
    self.aboutDescLabel.textAlignment = NSTextAlignmentCenter;
    self.aboutDescLabel.numberOfLines = 0;
    self.aboutDescLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [aboutCard addSubview:self.aboutDescLabel];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.aboutTitleLabel.topAnchor constraintEqualToAnchor:aboutCard.topAnchor constant:52],
        [self.aboutTitleLabel.centerXAnchor constraintEqualToAnchor:aboutCard.centerXAnchor],
        [self.aboutDescLabel.topAnchor constraintEqualToAnchor:self.aboutTitleLabel.bottomAnchor constant:16],
        [self.aboutDescLabel.leadingAnchor constraintEqualToAnchor:aboutCard.leadingAnchor constant:16],
        [self.aboutDescLabel.trailingAnchor constraintEqualToAnchor:aboutCard.trailingAnchor constant:-16],
        [aboutCard.bottomAnchor constraintEqualToAnchor:self.aboutDescLabel.bottomAnchor constant:16]
    ]];
    
    [self.cardStackView addArrangedSubview:aboutCard];
}

- (void)buildPlaceholder:(PCLSettingsTab)tab {
    UIView *card = [self createCardWithTitle:@""];
    
    UILabel *placeholder = [[UILabel alloc] init];
    NSArray *names = @[@"", @"", @"", @"", @"", @"", @"", @"", @"", @"", @"日志"];
    placeholder.text = names[(NSInteger)tab];
    placeholder.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    placeholder.textColor = PCLColor(0x8C8C8C);
    placeholder.textAlignment = NSTextAlignmentCenter;
    placeholder.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:placeholder];
    
    [NSLayoutConstraint activateConstraints:@[
        [placeholder.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        [placeholder.centerYAnchor constraintEqualToAnchor:card.centerYAnchor],
        [card.heightAnchor constraintEqualToConstant:80]
    ]];
    
    [self.cardStackView addArrangedSubview:card];
}

#pragma mark - Actions

- (void)memoryChanged:(UISlider *)slider {
    NSInteger value = (NSInteger)(slider.value / 256) * 256;
    self.memoryLabel.text = [NSString stringWithFormat:@"%ld MB", (long)value];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.javaList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"JavaCell"];
    cell.backgroundColor = [UIColor clearColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    PCLJavaRuntime *java = self.javaList[indexPath.row];
    cell.textLabel.text = java.name;
    cell.textLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    cell.textLabel.textColor = PCLColor(0x343D4A);
    
    if (java.isDownloaded) {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"已安装 - %@", java.path];
        cell.detailTextLabel.textColor = PCLColor(0x27AE60);
    } else {
        cell.detailTextLabel.text = @"点击下载安装";
        cell.detailTextLabel.textColor = PCLColor(0x8C8C8C);
    }
    cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
    
    return cell;
}

#pragma mark - Animation

- (void)dismissTransientUI {}
- (void)prepareCEEnterAnimation {
    self.cardStackView.alpha = 0;
}
- (void)playCEEnterAnimation {
    [PCLCEPageAnimator showRightItems:self.cardStackView.arrangedSubviews scrollView:self.scrollView];
}
- (void)playCEExitAnimation {
    [PCLCEPageAnimator hideRightItems:self.cardStackView.arrangedSubviews scrollView:self.scrollView];
}
- (void)reloadState {}

@end
