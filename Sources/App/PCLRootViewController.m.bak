#import "PCLRootViewController.h"
#import "PCLTopBarView.h"

@interface PCLRootViewController () <PCLTopBarViewDelegate>

@property (nonatomic, strong) PCLTopBarView *topBar;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *pageLabel;

@end

@implementation PCLRootViewController
- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor =
        [UIColor systemBackgroundColor];

    [self setupTopBar];
    [self setupContentView];

    self.topBar.alpha = 0.0;
    self.topBar.transform =
        CGAffineTransformMakeTranslation(0.0, -18.0);
    self.contentView.alpha = 0.0;
    self.contentView.transform =
        CGAffineTransformMakeTranslation(0.0, 24.0);

    [self showPage:PCLPageTypeLaunch];
}

- (void)setupTopBar {
    self.topBar = [[PCLTopBarView alloc] init];
    self.topBar.delegate = self;
    self.topBar.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addSubview:self.topBar];

    [NSLayoutConstraint activateConstraints:@[
        [self.topBar.topAnchor
            constraintEqualToAnchor:self.view.topAnchor],

        [self.topBar.leadingAnchor
            constraintEqualToAnchor:self.view.leadingAnchor],
        [self.topBar.trailingAnchor
            constraintEqualToAnchor:self.view.trailingAnchor],

        [self.topBar.heightAnchor
            constraintEqualToConstant:56.0]
    ]];
}

- (void)setupContentView {
    self.contentView = [[UIView alloc] init];
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addSubview:self.contentView];

    [NSLayoutConstraint activateConstraints:@[
        [self.contentView.topAnchor
            constraintEqualToAnchor:self.topBar.bottomAnchor],

        [self.contentView.leadingAnchor
            constraintEqualToAnchor:self.view.leadingAnchor],
        [self.contentView.trailingAnchor
            constraintEqualToAnchor:self.view.trailingAnchor],

        [self.contentView.bottomAnchor
            constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    self.pageLabel = [[UILabel alloc] init];
    self.pageLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.pageLabel.font =
        [UIFont systemFontOfSize:30.0
                          weight:UIFontWeightSemibold];

    self.pageLabel.textColor = [UIColor labelColor];

    [self.contentView addSubview:self.pageLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.pageLabel.centerXAnchor
            constraintEqualToAnchor:self.contentView.centerXAnchor],
        [self.pageLabel.centerYAnchor
            constraintEqualToAnchor:self.contentView.centerYAnchor]
    ]];
}

- (void)topBarView:(PCLTopBarView *)topBar
     didSelectPage:(PCLPageType)page {

    [self showPage:page];
}
- (void)showPage:(PCLPageType)page {
    switch (page) {
        case PCLPageTypeLaunch:
            self.pageLabel.text = @"启动";
            break;

        case PCLPageTypeDownload:
            self.pageLabel.text = @"下载";
            break;
        case PCLPageTypeSettings:
            self.pageLabel.text = @"设置";
            break;

        case PCLPageTypeTools:
            self.pageLabel.text = @"工具";
            break;
    }
}
- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)playEntranceAnimation {
    [UIView animateWithDuration:0.65
                          delay:0.0
         usingSpringWithDamping:0.86
          initialSpringVelocity:0.25
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{

        self.topBar.alpha = 1.0;
        self.topBar.transform =
            CGAffineTransformIdentity;

        self.contentView.alpha = 1.0;
        self.contentView.transform =
            CGAffineTransformIdentity;

    } completion:nil];
}

@end
