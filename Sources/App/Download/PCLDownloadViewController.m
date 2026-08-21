#import "PCLDownloadViewController.h"
#import "PCLVanillaDownloadViewController.h"
#import "PCLModBrowseViewController.h"
#import "PCLModpackBrowseViewController.h"

static UIColor *PCLColor(NSUInteger rgb) {
    return [UIColor colorWithRed:((rgb >> 16) & 255) / 255.0
                           green:((rgb >> 8) & 255) / 255.0
                            blue:(rgb & 255) / 255.0
                           alpha:1.0];
}

@interface PCLDownloadViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *tabScrollView;
@property (nonatomic, strong) UIStackView *tabStackView;
@property (nonatomic, strong) UIView *contentContainer;
@property (nonatomic, strong) NSArray<NSString *> *tabTitles;
@property (nonatomic, assign) NSInteger selectedTab;
@property (nonatomic, strong) NSMutableArray<UIButton *> *tabButtons;

// Child view controllers
@property (nonatomic, strong) PCLVanillaDownloadViewController *vanillaVC;
@property (nonatomic, strong) PCLModBrowseViewController *modVC;
@property (nonatomic, strong) PCLModpackBrowseViewController *modpackVC;

@end

@implementation PCLDownloadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = PCLColor(0xF5F7FA);
    
    // 下载分类: 原版、模组、整合包、光影、资源包、数据包 (PCL CE风格)
    self.tabTitles = @[
        @"Minecraft", @"模组", @"整合包", @"光影",
        @"资源包", @"数据包"
    ];
    self.tabButtons = [NSMutableArray array];
    self.selectedTab = 0;
    
    [self setupUI];
    [self setupChildViewControllers];
    [self switchToTab:0];
}

- (void)setupUI {
    // 顶部滚动标签栏
    self.tabScrollView = [[UIScrollView alloc] init];
    self.tabScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tabScrollView.showsHorizontalScrollIndicator = NO;
    self.tabScrollView.backgroundColor = [UIColor whiteColor];
    self.tabScrollView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.tabScrollView.layer.shadowOpacity = 0.05;
    self.tabScrollView.layer.shadowRadius = 4;
    self.tabScrollView.layer.shadowOffset = CGSizeMake(0, 2);
    [self.view addSubview:self.tabScrollView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.tabScrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.tabScrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tabScrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tabScrollView.heightAnchor constraintEqualToConstant:50]
    ]];
    
    // 标签按钮容器
    self.tabStackView = [[UIStackView alloc] init];
    self.tabStackView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tabStackView.axis = UILayoutConstraintAxisHorizontal;
    self.tabStackView.spacing = 0;
    self.tabStackView.alignment = UIStackViewAlignmentCenter;
    self.tabStackView.distribution = UIStackViewDistributionFill;
    [self.tabScrollView addSubview:self.tabStackView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.tabStackView.topAnchor constraintEqualToAnchor:self.tabScrollView.topAnchor],
        [self.tabStackView.leadingAnchor constraintEqualToAnchor:self.tabScrollView.leadingAnchor constant:8],
        [self.tabStackView.trailingAnchor constraintEqualToAnchor:self.tabScrollView.trailingAnchor constant:-8],
        [self.tabStackView.bottomAnchor constraintEqualToAnchor:self.tabScrollView.bottomAnchor],
        [self.tabStackView.heightAnchor constraintEqualToAnchor:self.tabScrollView.heightAnchor]
    ]];
    
    // 创建标签按钮
    for (NSInteger i = 0; i < self.tabTitles.count; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.translatesAutoresizingMaskIntoConstraints = NO;
        [btn setTitle:self.tabTitles[i] forState:UIControlStateNormal];
        [btn setTitleColor:PCLColor(0x8C8C8C) forState:UIControlStateNormal];
        [btn setTitleColor:PCLColor(0x1370F3) forState:UIControlStateSelected];
        [btn setTitleColor:PCLColor(0x1370F3) forState:UIControlStateSelected | UIControlStateHighlighted];
        btn.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
        btn.tag = i;
        [btn addTarget:self action:@selector(tabTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.tabStackView addArrangedSubview:btn];
        [self.tabButtons addObject:btn];
        
        // 内边距
        btn.contentEdgeInsets = UIEdgeInsetsMake(0, 16, 0, 16);
        [btn.heightAnchor constraintEqualToConstant:50].active = YES;
    }
    
    // 选中指示器
    UIView *indicator = [[UIView alloc] init];
    indicator.translatesAutoresizingMaskIntoConstraints = NO;
    indicator.backgroundColor = PCLColor(0x1370F3);
    indicator.tag = 100;
    indicator.layer.cornerRadius = 2;
    [self.tabScrollView addSubview:indicator];
    
    [NSLayoutConstraint activateConstraints:@[
        [indicator.bottomAnchor constraintEqualToAnchor:self.tabScrollView.bottomAnchor],
        [indicator.heightAnchor constraintEqualToConstant:3],
        [indicator.widthAnchor constraintEqualToConstant:40]
    ]];
    
    // 内容容器
    self.contentContainer = [[UIView alloc] init];
    self.contentContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentContainer.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.contentContainer];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.contentContainer.topAnchor constraintEqualToAnchor:self.tabScrollView.bottomAnchor],
        [self.contentContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.contentContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.contentContainer.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
}

- (void)setupChildViewControllers {
    // Minecraft 原版下载
    self.vanillaVC = [[PCLVanillaDownloadViewController alloc] init];
    [self addChildViewController:self.vanillaVC];
    [self.contentContainer addSubview:self.vanillaVC.view];
    self.vanillaVC.view.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.vanillaVC.view.topAnchor constraintEqualToAnchor:self.contentContainer.topAnchor],
        [self.vanillaVC.view.leadingAnchor constraintEqualToAnchor:self.contentContainer.leadingAnchor],
        [self.vanillaVC.view.trailingAnchor constraintEqualToAnchor:self.contentContainer.trailingAnchor],
        [self.vanillaVC.view.bottomAnchor constraintEqualToAnchor:self.contentContainer.bottomAnchor]
    ]];
    [self.vanillaVC didMoveToParentViewController:self];
    
    // 模组浏览
    self.modVC = [[PCLModBrowseViewController alloc] init];
    [self addChildViewController:self.modVC];
    [self.contentContainer addSubview:self.modVC.view];
    self.modVC.view.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.modVC.view.topAnchor constraintEqualToAnchor:self.contentContainer.topAnchor],
        [self.modVC.view.leadingAnchor constraintEqualToAnchor:self.contentContainer.leadingAnchor],
        [self.modVC.view.trailingAnchor constraintEqualToAnchor:self.contentContainer.trailingAnchor],
        [self.modVC.view.bottomAnchor constraintEqualToAnchor:self.contentContainer.bottomAnchor}
    ]];
    [self.modVC didMoveToParentViewController:self];
    self.modVC.view.hidden = YES;
    
    // 整合包浏览
    self.modpackVC = [[PCLModpackBrowseViewController alloc] init];
    [self addChildViewController:self.modpackVC];
    [self.contentContainer addSubview:self.modpackVC.view];
    self.modpackVC.view.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.modpackVC.view.topAnchor constraintEqualToAnchor:self.contentContainer.topAnchor],
        [self.modpackVC.view.leadingAnchor constraintEqualToAnchor:self.contentContainer.leadingAnchor],
        [self.modpackVC.view.trailingAnchor constraintEqualToAnchor:self.contentContainer.trailingAnchor],
        [self.modpackVC.view.bottomAnchor constraintEqualToAnchor:self.contentContainer.bottomAnchor}
    ]];
    [self.modpackVC didMoveToParentViewController:self];
    self.modpackVC.view.hidden = YES;
}

- (void)tabTapped:(UIButton *)sender {
    [self switchToTab:sender.tag];
}

- (void)switchToTab:(NSInteger)tab {
    self.selectedTab = tab;
    
    // 更新按钮状态
    for (UIButton *btn in self.tabButtons) {
        btn.selected = (btn.tag == tab);
        btn.titleLabel.font = (btn.tag == tab) ? 
            [UIFont systemFontOfSize:15 weight:UIFontWeightBold] :
            [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    }
    
    // 切换子视图控制器显示
    self.vanillaVC.view.hidden = (tab != 0);
    self.modVC.view.hidden = (tab != 1);
    self.modpackVC.view.hidden = (tab != 2);
    
    // 其他标签显示占位
    if (tab > 2) {
        self.vanillaVC.view.hidden = YES;
        self.modVC.view.hidden = YES;
        self.modpackVC.view.hidden = YES;
        [self showPlaceholderForTab:tab];
    }
    
    // 更新指示器位置
    [self updateIndicatorPosition];
}

- (void)updateIndicatorPosition {
    UIButton *selectedBtn = self.tabButtons[self.selectedTab];
    UIView *indicator = [self.tabScrollView viewWithTag:100];
    
    [UIView animateWithDuration:0.25 animations:^{
        // 将指示器移动到选中按钮下方
        CGRect btnFrame = [self.tabScrollView convertRect:selectedBtn.frame fromView:self.tabStackView];
        indicator.center = CGPointMake(CGRectGetMidX(btnFrame), self.tabScrollView.bounds.size.height - 1.5);
        
        // 滚动标签栏使选中项可见
        CGFloat targetX = selectedBtn.center.x - self.tabScrollView.bounds.size.width / 2;
        targetX = MAX(0, MIN(targetX, self.tabScrollView.contentSize.width - self.tabScrollView.bounds.size.width));
        [self.tabScrollView setContentOffset:CGPointMake(targetX, 0) animated:YES];
    }];
}

- (void)showPlaceholderForTab:(NSInteger)tab {
    static NSInteger placeholderTag = 999;
    UIView *existing = [self.contentContainer viewWithTag:placeholderTag];
    [existing removeFromSuperview];
    
    UIView *placeholder = [[UIView alloc] init];
    placeholder.translatesAutoresizingMaskIntoConstraints = NO;
    placeholder.tag = placeholderTag;
    placeholder.backgroundColor = [UIColor clearColor];
    [self.contentContainer addSubview:placeholder];
    
    [NSLayoutConstraint activateConstraints:@[
        [placeholder.topAnchor constraintEqualToAnchor:self.contentContainer.topAnchor],
        [placeholder.leadingAnchor constraintEqualToAnchor:self.contentContainer.leadingAnchor],
        [placeholder.trailingAnchor constraintEqualToAnchor:self.contentContainer.trailingAnchor],
        [placeholder.bottomAnchor constraintEqualToAnchor:self.contentContainer.bottomAnchor]
    ]];
    
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = self.tabTitles[tab];
    label.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    label.textColor = PCLColor(0x343D4A);
    label.textAlignment = NSTextAlignmentCenter;
    [placeholder addSubview:label];
    
    UILabel *subLabel = [[UILabel alloc] init];
    subLabel.translatesAutoresizingMaskIntoConstraints = NO;
    subLabel.text = @"功能开发中...";
    subLabel.font = [UIFont systemFontOfSize:14];
    subLabel.textColor = PCLColor(0x8C8C8C);
    subLabel.textAlignment = NSTextAlignmentCenter;
    [placeholder addSubview:subLabel];
    
    [NSLayoutConstraint activateConstraints:@[
        [label.centerXAnchor constraintEqualToAnchor:placeholder.centerXAnchor],
        [label.centerYAnchor constraintEqualToAnchor:placeholder.centerYAnchor constant:-20],
        [subLabel.centerXAnchor constraintEqualToAnchor:placeholder.centerXAnchor],
        [subLabel.topAnchor constraintEqualToAnchor:label.bottomAnchor constant:8]
    ]];
}

- (void)dismissTransientUI {
    // 清理临时UI
}

@end
