#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, PCLSettingsTab) {
    PCLSettingsTabLaunch = 0,
    PCLSettingsTabJava,
    PCLSettingsTabGameManage,
    PCLSettingsTabGameLink,
    PCLSettingsTabUI,
    PCLSettingsTabLanguage,
    PCLSettingsTabMisc,
    PCLSettingsTabAbout,
    PCLSettingsTabUpdate,
    PCLSettingsTabFeedback,
    PCLSettingsTabLog
};

@interface PCLSettingsViewController : UIViewController

@property (nonatomic, assign) CGFloat leftPanelWidth;
@property (nonatomic) PCLSettingsTab currentTab;

- (void)switchToTab:(PCLSettingsTab)tab;
- (void)dismissTransientUI;
- (void)prepareCEEnterAnimation;
- (void)playCEEnterAnimation;
- (void)playCEExitWithCompletion:(dispatch_block_t)completion;
- (void)reloadState;

@end
