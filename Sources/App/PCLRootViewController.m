#import "PCLRootViewController.h"
#import "PCLTopBarView.h"
@interface PCLRootViewController () <PCLTopBarViewDelegate> @property (nonatomic, strong) PCLTopBarView *topBar; @property (nonatomic, strong) UIView 
*contentView; @property (nonatomic, strong) UILabel *pageLabel; @end @implementation PCLRootViewController - (void)viewDidLoad {
    [super viewDidLoad]; self.view.backgroundColor = [UIColor systemBackgroundColor]; [self setupTopBar]; [self setupContentView]; [self 
    showPage:PCLPageTypeLaunch];
}
- (void)setupTopBar { self.topBar = [[PCLTopBarView alloc] init]; self.topBar.delegate = self; self.topBar.translatesAutoresizingMaskIntoConstraints = NO; 
    [self.view addSubview:self.topBar]; [NSLayoutConstraint activateConstraints:@[
        [self.topBar.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor], [self.topBar.leadingAnchor 
            constraintEqualToAnchor:self.view.leadingAnchor],
        [self.topBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor], [self.topBar.heightAnchor constraintEqualToConstant:58.0] ]];
}
- (void)setupContentView { self.contentView = [[UIView alloc] init]; self.contentView.translatesAutoresizingMaskIntoConstraints = NO; [self.view 
    addSubview:self.contentView]; [NSLayoutConstraint activateConstraints:@[
        [self.contentView.topAnchor constraintEqualToAnchor:self.topBar.bottomAnchor], [self.contentView.leadingAnchor 
            constraintEqualToAnchor:self.view.leadingAnchor],
        [self.contentView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor], [self.contentView.bottomAnchor 
            constraintEqualToAnchor:self.view.bottomAnchor]
    ]]; self.pageLabel = [[UILabel alloc] init]; self.pageLabel.translatesAutoresizingMaskIntoConstraints = NO; self.pageLabel.font = [UIFont systemFontOfSize:30 
                          weight:UIFontWeightSemibold];
    self.pageLabel.textColor = [UIColor labelColor]; [self.contentView addSubview:self.pageLabel]; [NSLayoutConstraint activateConstraints:@[ 
        [self.pageLabel.centerXAnchor
            constraintEqualToAnchor:self.contentView.centerXAnchor], [self.pageLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor] ]];
}
- (void)topBarView:(PCLTopBarView *)topBar didSelectPage:(PCLPageType)page { [self showPage:page];
}
- (void)showPage:(PCLPageType)page { switch (page) { case PCLPageTypeLaunch: self.pageLabel.text = @"启动"; break; case PCLPageTypeDownload: self.pageLabel.text 
            = @"下载"; break;
        case PCLPageTypeMultiplayer: self.pageLabel.text = @"联机"; break; case PCLPageTypeSettings: self.pageLabel.text = @"设置"; break;
    }
}
@end
