#import <UIKit/UIKit.h>

@interface PCLLoginPanelView : UIView
@property(nonatomic) CGFloat designScale;
@property(nonatomic,copy) void (^onClose)(void);

@property(nonatomic,copy) void (^onOfflineCreate)(NSString *name);
- (void)showMicrosoft;
- (void)showOffline;
- (void)showThirdParty;
@end
