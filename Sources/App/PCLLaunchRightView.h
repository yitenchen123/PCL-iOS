#import <UIKit/UIKit.h>

@interface PCLLaunchRightView : UIView

@property (nonatomic, copy) void (^onCloseHint)(void);

@property (nonatomic) CGFloat designScale;

- (void)setHintHidden:(BOOL)hidden;
- (void)playCEEnterAnimation;
- (void)playCEExitAnimation;
- (void)setDebugLog:(NSString *)text visible:(BOOL)visible;

@end
