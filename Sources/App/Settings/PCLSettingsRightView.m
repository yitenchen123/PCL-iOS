#import "PCLSettingsRightView.h"
#import "PCLCEPageAnimator.h"
#import "PCLPathUtils.h"
#import <mach/mach.h>
#import <QuartzCore/QuartzCore.h>

static UIColor *PCLColor(NSUInteger rgb) {
    return [UIColor colorWithRed:((rgb >> 16) & 255) / 255.0
                           green:((rgb >> 8) & 255) / 255.0
                            blue:(rgb & 255) / 255.0
                           alpha:1.0];
}

static long long PCLTotalMemory() {
    return [[NSProcessInfo processInfo] physicalMemory];
}

@interface PCLSettingsRightView () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIStackView *cardStackView;
@property (nonatomic) PCLSettingsTab currentTab;

// Launch settings
@property (nonatomic, strong) UISlider *memorySlider;
@property (nonatomic, strong) UILabel *memoryLabel;
@property (nonatomic, strong) UISwitch *autoLoginSwitch;

// Java settings
@property (nonatomic, strong) UITableView *javaTableView;
@property (nonatomic, strong) NSArray<NSDictionary *> *javaList;
@property (nonatomic, strong) UISwitch *javaAutoSwitch;
@property (nonatomic) NSInteger selectedJavaIndex;

// UI settings
@property (nonatomic, strong) UISegmentedControl *themeSegment;
@property (nonatomic, strong) UISlider *opacitySlider;
@property (nonatomic, strong) UILabel *opacityLabel;

// About
@property (nonatomic, strong) UILabel *aboutTitleLabel;
@property (nonatomic, strong) UILabel *aboutDescLabel;

@end

@implementation PCLSettingsRightView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _currentTab = PCLSettingsTabLaunch;
        _selectedJavaIndex = 1;
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

#pragma mark - Card Builder

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

- (void)addSeparatorToCard:(UIView *)card belowView:(UIView *)view {
    UIView *sep = [[UIView alloc] init];
    sep.backgroundColor = PCLColor(0xE0E0E0);
    sep.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:sep];
    [NSLayoutConstraint activateConstraints:@[
        [sep.topAnchor constraintEqualToAnchor:view.bottomAnchor constant:8],
        [sep.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
        [sep.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],
        [sep.heightAnchor constraintEqualToConstant:1]
    ]];
}

#pragma mark - Tab Switcher

- (void)switchToTab:(PCLSettingsTab)tab {
    self.currentTab = tab;
    [self.cardStackView.arrangedSubviews makeObjectsPerformSelector:@selector(removeFromSuperview]];
    
    switch (tab) {
        case PCLSettingsTabLaunch: [self buildLaunchSettings]; break;
        case PCLSettingsTabJava: [self buildJavaSettings]; break;
        case PCLSettingsTabGameManage: [self buildGameManageSettings]; break;
        case PCLSettingsTabUI: [self buildUISettings]; break;
        case PCLSettingsTabAbout: [self buildAboutPage]; break;
        default: [self buildPlaceholder:tab]; break;
    }
}

#pragma mark - Launch Settings (PCL-CE风格)

- (void)buildLaunchSettings {
    UIView *memCard = [self createCardWithTitle:@"启动设置"];
    
    UILabel *memTitle = [[UILabel alloc] init];
    memTitle.text = @"最大内存分配";
    memTitle.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    memTitle.textColor = PCLColor(0x343D4A);
    memTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [memCard addSubview:memTitle];
    
    long long totalMemMB = PCLTotalMemory() / (1024 * 1024);
    long long maxMem = totalMemMB > 4096 ? 4096 : totalMemMB / 2;
    
    self.memorySlider = [[UISlider alloc] init];
    self.memorySlider.translatesAutoresizingMaskIntoConstraints = NO;
    self.memorySlider.minimumValue = 512;
    self.memorySlider.maximumValue = (float)maxMem;
    self.memorySlider.value = MIN(2048, maxMem);
    self.memorySlider.tintColor = PCLColor(0x1370F3);
    [self.memorySlider addTarget:self action:@selector(memoryChanged:) forControlEvents:UIControlEventValueChanged];
    [memCard addSubview:self.memorySlider];
    
    self.memoryLabel = [[UILabel alloc] init];
    self.memoryLabel.text = [NSString stringWithFormat:@"%.0f MB", self.memorySlider.value];
    self.memoryLabel.font = [UIFont systemFontOfSize:13];
    self.memoryLabel.textColor = PCLColor(0x8C8C8C);
    self.memoryLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [memCard addSubview:self.memoryLabel];
    
    UILabel *memHint = [[UILabel alloc] init];
    memHint.text = [NSString stringWithFormat:@"设备总内存: %lld MB", totalMemMB];
    memHint.font = [UIFont systemFontOfSize:11];
    memHint.textColor = PCLColor(0xB0B0B0);
    memHint.translatesAutoresizingMaskIntoConstraints = NO;
    [memCard addSubview:memHint];
    
    [NSLayoutConstraint activateConstraints:@[
        [memTitle.topAnchor constraintEqualToAnchor:memCard.topAnchor constant:52],
        [memTitle.leadingAnchor constraintEqualToAnchor:memCard.leadingAnchor constant:16],
        [self.memorySlider.topAnchor constraintEqualToAnchor:memTitle.bottomAnchor constant:8],
        [self.memorySlider.leadingAnchor constraintEqualToAnchor:memCard.leadingAnchor constant:16],
        [self.memorySlider.trailingAnchor constraintEqualToAnchor:memCard.trailingAnchor constant:-80],
        [self.memoryLabel.centerYAnchor constraintEqualToAnchor:self.memorySlider.centerYAnchor],
        [self.memoryLabel.leadingAnchor constraintEqualToAnchor:self.memorySlider.trailingAnchor constant:8],
        [self.memoryLabel.trailingAnchor constraintEqualToAnchor:memCard.trailingAnchor constant:-16],
        [memHint.topAnchor constraintEqualToAnchor:self.memorySlider.bottomAnchor constant:4],
        [memHint.leadingAnchor constraintEqualToAnchor:memCard.leadingAnchor constant:16],
        [memCard.bottomAnchor constraintEqualToAnchor:memHint.bottomAnchor constant:16]
    ]];
    
    [self.cardStackView addArrangedSubview:memCard];
    
    // JVM参数
    UIView *argsCard = [self createCardWithTitle:@"Java 虚拟机参数"];
    
    UITextView *jvmArgsView = [[UITextView alloc] init];
    jvmArgsView.translatesAutoresizingMaskIntoConstraints = NO;
    jvmArgsView.font = [UIFont systemFontOfSize:12];
    jvmArgsView.textColor = PCLColor(0x404040);
    jvmArgsView.backgroundColor = PCLColor(0xF8F8F8);
    jvmArgsView.layer.cornerRadius = 6;
    jvmArgsView.layer.borderWidth = 1;
    jvmArgsView.layer.borderColor = PCLColor(0xE0E0E0).CGColor;
    jvmArgsView.text = @"-XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:+UseContainerSupport -XX:MaxGCPauseMillis=50";
    jvmArgsView.editable = YES;
    [argsCard addSubview:jvmArgsView];
    
    [NSLayoutConstraint activateConstraints:@[
        [jvmArgsView.topAnchor constraintEqualToAnchor:argsCard.topAnchor constant:52],
        [jvmArgsView.leadingAnchor constraintEqualToAnchor:argsCard.leadingAnchor constant:16],
        [jvmArgsView.trailingAnchor constraintEqualToAnchor:argsCard.trailingAnchor constant:-16],
        [jvmArgsView.heightAnchor constraintEqualToConstant:80],
        [argsCard.bottomAnchor constraintEqualToAnchor:jvmArgsView.bottomAnchor constant:16]
    ]];
    
    [self.cardStackView addArrangedSubview:argsCard];
}

#pragma mark - Java Settings (PCL-CE风格: Java管理页面)

- (void)buildJavaSettings {
    UIView *javaCard = [self createCardWithTitle:@"Java 选择"];
    
    UILabel *autoLabel = [[UILabel alloc] init];
    autoLabel.text = @"自动选择 Java";
    autoLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    autoLabel.textColor = PCLColor(0x343D4A);
    autoLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [javaCard addSubview:autoLabel];
    
    self.javaAutoSwitch = [[UISwitch alloc] init];
    self.javaAutoSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    self.javaAutoSwitch.onTintColor = PCLColor(0x1370F3);
    self.javaAutoSwitch.on = YES;
    [self.javaAutoSwitch addTarget:self action:@selector(javaAutoChanged:) forControlEvents:UIControlEventValueChanged];
    [javaCard addSubview:self.javaAutoSwitch];
    
    [NSLayoutConstraint activateConstraints:@[
        [autoLabel.topAnchor constraintEqualToAnchor:javaCard.topAnchor constant:52],
        [autoLabel.leadingAnchor constraintEqualToAnchor:javaCard.leadingAnchor constant:16],
        [self.javaAutoSwitch.centerYAnchor constraintEqualToAnchor:autoLabel.centerYAnchor],
        [self.javaAutoSwitch.trailingAnchor constraintEqualToAnchor:javaCard.trailingAnchor constant:-16],
        [javaCard.bottomAnchor constraintEqualToAnchor:autoLabel.bottomAnchor constant:16]
    ]];
    
    [self.cardStackView addArrangedSubview:javaCard];
    
    // Java 列表 (PCL-CE风格: 列表+Radio选择)
    UIView *listCard = [self createCardWithTitle:@"可用的 Java 环境"];
    
    [self refreshJavaList];
    
    self.javaTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.javaTableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.javaTableView.delegate = self;
    self.javaTableView.dataSource = self;
    self.javaTableView.backgroundColor = [UIColor clearColor];
    self.javaTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.javaTableView.scrollEnabled = NO;
    self.javaTableView.rowHeight = 64;
    self.javaTableView.allowsSelection = NO;
    [listCard addSubview:self.javaTableView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.javaTableView.topAnchor constraintEqualToAnchor:listCard.topAnchor constant:52],
        [self.javaTableView.leadingAnchor constraintEqualToAnchor:listCard.leadingAnchor],
        [self.javaTableView.trailingAnchor constraintEqualToAnchor:listCard.trailingAnchor],
        [self.javaTableView.bottomAnchor constraintEqualToAnchor:listCard.bottomAnchor constant:-8],
        [self.javaTableView.heightAnchor constraintEqualToConstant:self.javaList.count * 64]
    ]];
    
    [self.cardStackView addArrangedSubview:listCard];
}

- (void)refreshJavaList {
    NSArray *versions = @[@8, @17, @21, @25];
    NSMutableArray *list = [NSMutableArray array];
    for (NSNumber *ver in versions) {
        NSString *home = [PCLPathUtils javaHomeForVersion:ver.integerValue];
        BOOL available = home != nil;
        [list addObject:@{
            @"version": ver,
            @"home": home ?: @"未安装",
            @"available": @(available)
        }];
    }
    self.javaList = list;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.javaList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"JavaCell"];
    cell.backgroundColor = [UIColor clearColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    NSDictionary *java = self.javaList[indexPath.row];
    BOOL available = [java[@"available"] boolValue];
    NSInteger version = [java[@"version"] integerValue];
    
    cell.textLabel.text = [NSString stringWithFormat:@"Java %ld", (long)version];
    cell.textLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    cell.textLabel.textColor = available ? PCLColor(0x343D4A) : PCLColor(0xB0B0B0);
    
    cell.detailTextLabel.text = available ? java[@"home"] : @"未找到 - 请构建时包含JRE";
    cell.detailTextLabel.font = [UIFont systemFontOfSize:11];
    cell.detailTextLabel.textColor = available ? PCLColor(0x27AE60) : PCLColor(0xE74C3C);
    cell.detailTextLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    
    // Radio button (PCL-CE风格)
    UIButton *radio = [UIButton buttonWithType:UIButtonTypeCustom];
    radio.frame = CGRectMake(0, 0, 22, 22);
    radio.userInteractionEnabled = NO;
    radio.layer.cornerRadius = 11;
    radio.layer.borderWidth = 2;
    radio.layer.borderColor = PCLColor(0x1370F3).CGColor;
    
    BOOL isSelected = (indexPath.row == self.selectedJavaIndex);
    if (isSelected) {
        radio.backgroundColor = PCLColor(0x1370F3);
        UIView *dot = [[UIView alloc] initWithFrame:CGRectMake(7, 7, 8, 8)];
        dot.backgroundColor = [UIColor whiteColor];
        dot.layer.cornerRadius = 4;
        [radio addSubview:dot];
    } else {
        radio.backgroundColor = [UIColor clearColor];
    }
    
    cell.accessoryView = radio;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedJavaIndex = indexPath.row;
    [tableView reloadData];
}

#pragma mark - Game Manage Settings

- (void)buildGameManageSettings {
    UIView *card = [self createCardWithTitle:@"通用"];
    
    UILabel *autoLoginLabel = [[UILabel alloc] init];
    autoLoginLabel.text = @"启动后自动启动游戏";
    autoLoginLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    autoLoginLabel.textColor = PCLColor(0x343D4A);
    autoLoginLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:autoLoginLabel];
    
    self.autoLoginSwitch = [[UISwitch alloc] init];
    self.autoLoginSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    self.autoLoginSwitch.onTintColor = PCLColor(0x1370F3);
    [card addSubview:self.autoLoginSwitch];
    
    [NSLayoutConstraint activateConstraints:@[
        [autoLoginLabel.topAnchor constraintEqualToAnchor:card.topAnchor constant:52],
        [autoLoginLabel.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
        [self.autoLoginSwitch.centerYAnchor constraintEqualToAnchor:autoLoginLabel.centerYAnchor],
        [self.autoLoginSwitch.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],
        [card.bottomAnchor constraintEqualToAnchor:autoLoginLabel.bottomAnchor constant:16]
    ]];
    
    [self.cardStackView addArrangedSubview:card];
}

#pragma mark - UI Settings

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
    
    // 启动器透明度
    UIView *opacityCard = [self createCardWithTitle:@"启动器透明度"];
    
    self.opacitySlider = [[UISlider alloc] init];
    self.opacitySlider.translatesAutoresizingMaskIntoConstraints = NO;
    self.opacitySlider.minimumValue = 0.3;
    self.opacitySlider.maximumValue = 1.0;
    self.opacitySlider.value = 1.0;
    self.opacitySlider.tintColor = PCLColor(0x1370F3);
    [opacityCard addSubview:self.opacitySlider];
    
    self.opacityLabel = [[UILabel alloc] init];
    self.opacityLabel.text = @"100%";
    self.opacityLabel.font = [UIFont systemFontOfSize:13];
    self.opacityLabel.textColor = PCLColor(0x8C8C8C);
    self.opacityLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [opacityCard addSubview:self.opacityLabel];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.opacitySlider.topAnchor constraintEqualToAnchor:opacityCard.topAnchor constant:52],
        [self.opacitySlider.leadingAnchor constraintEqualToAnchor:opacityCard.leadingAnchor constant:16],
        [self.opacitySlider.trailingAnchor constraintEqualToAnchor:opacityCard.trailingAnchor constant:-50],
        [self.opacityLabel.centerYAnchor constraintEqualToAnchor:self.opacitySlider.centerYAnchor],
        [self.opacityLabel.trailingAnchor constraintEqualToAnchor:opacityCard.trailingAnchor constant:-16],
        [opacityCard.bottomAnchor constraintEqualToAnchor:self.opacitySlider.bottomAnchor constant:16]
    ]];
    
    [self.cardStackView addArrangedSubview:opacityCard];
}

#pragma mark - About

- (void)buildAboutPage {
    UIView *aboutCard = [self createCardWithTitle:@"关于 PCL-iOS"];
    
    self.aboutTitleLabel = [[UILabel alloc] init];
    self.aboutTitleLabel.text = @"PCL-iOS v0.1";
    self.aboutTitleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    self.aboutTitleLabel.textColor = PCLColor(0x343D4A);
    self.aboutTitleLabel.textAlignment = NSTextAlignmentCenter;
    self.aboutTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [aboutCard addSubview:self.aboutTitleLabel];
    
    self.aboutDescLabel = [[UILabel alloc] init];
    self.aboutDescLabel.text = @"基于 PCL2 Community Edition 设计\nMinecraft Java Edition iOS 启动器\n\n开发者: yitenchen123";
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
    UILabel *label = [[UILabel alloc] init];
    NSArray *names = @[@"", @"", @"", @"", @"", @"", @"", @"", @"", @"", @"日志"];
    label.text = names[(NSInteger)tab];
    label.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    label.textColor = PCLColor(0x8C8C8C);
    label.textAlignment = NSTextAlignmentCenter;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:label];
    [NSLayoutConstraint activateConstraints:@[
        [label.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        [label.centerYAnchor constraintEqualToAnchor:card.centerYAnchor],
        [card.heightAnchor constraintEqualToConstant:80]
    ]];
    [self.cardStackView addArrangedSubview:card];
}

#pragma mark - Actions

- (void)memoryChanged:(UISlider *)slider {
    NSInteger value = (NSInteger)(slider.value / 256) * 256;
    self.memoryLabel.text = [NSString stringWithFormat:@"%ld MB", (long)value];
}

- (void)javaAutoChanged:(UISwitch *)sender {
    self.javaTableView.userInteractionEnabled = !sender.isOn;
    self.javaTableView.alpha = sender.isOn ? 0.4 : 1.0;
}

#pragma mark - Animation

- (void)dismissTransientUI {}
- (void)prepareCEEnterAnimation { self.cardStackView.alpha = 0; }
- (void)playCEEnterAnimation { [PCLCEPageAnimator showRightItems:self.cardStackView.arrangedSubviews scrollView:self.scrollView]; }
- (void)playCEExitAnimation { [PCLCEPageAnimator hideRightItems:self.cardStackView.arrangedSubviews scrollView:self.scrollView]; }
- (void)reloadState {}

@end
