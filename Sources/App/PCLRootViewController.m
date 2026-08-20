#import "PCLRootViewController.h"
#import "PCLTopBarView.h"
#import "PCLLaunchViewController.h"

@interface PCLRootViewController () <PCLTopBarViewDelegate>

@property (nonatomic, strong) PCLTopBarView *topBar;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *pageLabel;
@property (nonatomic, strong) PCLLaunchViewController *launchVC;

@end

@implementation PCLRootViewController
- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor =
        [UIColor systemBackgroundColor];

    [self setupTopBar];
    [self setupContentView];

    self.topBar.alpha = 0.0;
    self.contentView.alpha = 0.0;

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

    self.launchVC =
        [[PCLLaunchViewController alloc] init];

    __weak typeof(self) weakSelf = self;
    self.launchVC.onOpenDownload = ^{
        [weakSelf.topBar
            selectPage:PCLPageTypeDownload
              animated:YES];

        [weakSelf.launchVC
            playExitFadeWithCompletion:^{
                [weakSelf showPage:
                    PCLPageTypeDownload];
            }];
    };

    [self addChildViewController:self.launchVC];
    self.launchVC.view.translatesAutoresizingMaskIntoConstraints = NO;

    [self.contentView addSubview:self.launchVC.view];
    [self.launchVC didMoveToParentViewController:self];

    [NSLayoutConstraint activateConstraints:@[
        [self.launchVC.view.topAnchor
            constraintEqualToAnchor:self.contentView.topAnchor],
        [self.launchVC.view.leadingAnchor
            constraintEqualToAnchor:self.contentView.leadingAnchor],
        [self.launchVC.view.trailingAnchor
            constraintEqualToAnchor:self.contentView.trailingAnchor],
        [self.launchVC.view.bottomAnchor
            constraintEqualToAnchor:self.contentView.bottomAnchor]
    ]];

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
    BOOL enteringLaunch=
        page==PCLPageTypeLaunch &&
        self.launchVC.view.hidden;

    [self.launchVC dismissTransientUI];

    switch (page) {
        case PCLPageTypeLaunch:
            self.launchVC.view.hidden=NO;
            self.pageLabel.hidden=YES;

            if (enteringLaunch)
                [self.launchVC playCEEnterAnimation];

            break;

        case PCLPageTypeDownload:
            self.launchVC.view.hidden = YES;
            self.pageLabel.hidden = NO;
            self.pageLabel.text = @"下载";
            break;
        case PCLPageTypeSettings:
            self.launchVC.view.hidden = YES;
            self.pageLabel.hidden = NO;
            self.pageLabel.text = @"设置";
            break;

        case PCLPageTypeTools:
            self.launchVC.view.hidden = YES;
            self.pageLabel.hidden = NO;
            self.pageLabel.text = @"工具";
            break;
    }
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.topBar layoutIfNeeded];
    self.launchVC.leftPanelWidth = [self.topBar launchButtonCenterX];
    [self.launchVC.view setNeedsLayout];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)playEntranceAnimation {
    [UIView animateWithDuration:0.30
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
