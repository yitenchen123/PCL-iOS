#import "PCLDownloadViewController.h"
#import "PCLDownloadLeftView.h"
#import "PCLDownloadRightView.h"
#import "PCLCEPageAnimator.h"

@interface PCLDownloadViewController ()

@property (nonatomic, strong) PCLDownloadLeftView *leftView;
@property (nonatomic, strong) PCLDownloadRightView *rightView;
@property (nonatomic, strong) CAGradientLayer *backgroundGradient;
@property (nonatomic, strong) UIView *leftShadowView;
@property (nonatomic, strong) CAGradientLayer *leftShadowGradient;
@property (nonatomic) PCLDownloadTab currentTab;

@end

@implementation PCLDownloadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithRed:251.0/255.0 green:251.0/255.0 blue:251.0/255.0 alpha:1.0];
    self.currentTab = PCLDownloadTabMinecraft;
    
    [self buildCEBackground];
    [self buildUI];
}

- (void)buildCEBackground {
    self.backgroundGradient = [CAGradientLayer layer];
    self.backgroundGradient.colors = @[
        (id)[UIColor colorWithRed:.68 green:.80 blue:.98 alpha:1].CGColor,
        (id)[UIColor colorWithRed:.92 green:.96 blue:1 alpha:1].CGColor,
        (id)[UIColor colorWithRed:.76 green:.84 blue:.99 alpha:1].CGColor
    ];
    self.backgroundGradient.locations = @[@0, @.4, @1];
    self.backgroundGradient.startPoint = CGPointMake(.9, 0);
    self.backgroundGradient.endPoint = CGPointMake(.1, 1);
    [self.view.layer insertSublayer:self.backgroundGradient atIndex:0];
}

- (void)buildUI {
    self.leftView = [[PCLDownloadLeftView alloc] init];
    self.rightView = [[PCLDownloadRightView alloc] init];
    
    [self.view addSubview:self.leftView];
    [self.view addSubview:self.rightView];
    
    self.leftShadowView = [[UIView alloc] init];
    self.leftShadowView.userInteractionEnabled = NO;
    self.leftShadowGradient = [CAGradientLayer layer];
    self.leftShadowGradient.colors = @[
        (id)[UIColor colorWithWhite:0 alpha:.04].CGColor,
        (id)[UIColor colorWithWhite:0 alpha:0].CGColor
    ];
    self.leftShadowGradient.startPoint = CGPointMake(0, .5);
    self.leftShadowGradient.endPoint = CGPointMake(1, .5);
    [self.leftShadowView.layer addSublayer:self.leftShadowGradient];
    [self.view addSubview:self.leftShadowView];
    
    __weak typeof(self) weakSelf = self;
    
    self.leftView.onSelectTab = ^(PCLDownloadTab tab) {
        [weakSelf selectTab:tab];
    };
    
    self.rightView.onCreateProfile = ^{
        if (weakSelf.onCreateProfile) weakSelf.onCreateProfile();
    };
    
    self.rightView.onLaunch = ^{
        if (weakSelf.onLaunch) weakSelf.onLaunch();
    };
    
    self.rightView.onSelectInstance = ^{
        if (weakSelf.onSelectInstance) weakSelf.onSelectInstance();
    };
    
    self.rightView.onInstanceSettings = ^{
        if (weakSelf.onInstanceSettings) weakSelf.onInstanceSettings();
    };
    
    self.rightView.onSkinOptions = ^{
        if (weakSelf.onSkinOptions) weakSelf.onSkinOptions();
    };
    
    self.rightView.onEditProfile = ^{
        if (weakSelf.onEditProfile) weakSelf.onEditProfile();
    };
    
    self.rightView.onCloseHint = ^{
        if (weakSelf.onCloseHint) weakSelf.onCloseHint();
    };
    
    self.rightView.onOpenDownload = ^{
        if (weakSelf.onOpenDownload) weakSelf.onOpenDownload();
    };
}

- (void)selectTab:(PCLDownloadTab)tab {
    self.currentTab = tab;
    [self.rightView switchToTab:tab];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat w = CGRectGetWidth(self.view.bounds);
    CGFloat h = CGRectGetHeight(self.view.bounds);
    CGFloat scale = MIN(w / 850.0, h / 417.2);
    CGFloat leftW = self.leftPanelWidth > 0 ? MIN(self.leftPanelWidth, w) : 300.0 * scale;
    scale = MIN(scale, leftW / 300.0);
    CGFloat y = 0.0;
    self.backgroundGradient.frame = self.view.bounds;
    self.leftView.frame = CGRectMake(0, y, leftW, h);
    self.leftView.designScale = scale;
    self.rightView.designScale = scale;
    self.rightView.frame = CGRectMake(leftW, y, MAX(0, w - leftW), h);
    self.leftShadowView.frame = CGRectMake(leftW, y, 4 * scale, h);
    self.leftShadowGradient.frame = self.leftShadowView.bounds;
}

- (void)dismissTransientUI {
    [self.leftView dismissTransientUI];
    [self.rightView dismissTransientUI];
}

- (void)prepareCEEnterAnimation {
    [self.leftView prepareCEEnterAnimation];
    [self.rightView prepareCEEnterAnimation];
    self.view.userInteractionEnabled = NO;
}

- (void)playCEEnterAnimation {
    [self.leftView playCEEnterAnimation];
    [self.rightView playCEEnterAnimation];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.400 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.view.userInteractionEnabled = YES;
    });
}

- (void)playCEExitWithCompletion:(dispatch_block_t)completion {
    [self dismissTransientUI];
    self.view.userInteractionEnabled = NO;
    [self.leftView playCEExitAnimation];
    [self.rightView playCEExitAnimation];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.110 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (completion) completion();
    });
}

- (void)reloadState {
    [self.leftView reloadState];
    [self.rightView reloadState];
}

@end
