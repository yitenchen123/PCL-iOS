#import <UIKit/UIKit.h>

@interface PCLLoginPanelView : UIView
@property(nonatomic) CGFloat designScale;
@property(nonatomic,copy) void (^onClose)(void);

@property(nonatomic,copy) void (^onProfileCreated)(void);
- (void)showMicrosoft;
- (void)showOffline;
- (void)showThirdParty;
- (void)editOfflineProfile:(NSDictionary *)profile;
@end
