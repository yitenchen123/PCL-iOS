#import <UIKit/UIKit.h>

@interface PCLLaunchLeftView : UIView

@property (nonatomic) CGFloat designScale;

@property (nonatomic, copy) void (^onLaunch)(void);
@property (nonatomic, copy) void (^onSelectInstance)(void);
@property (nonatomic, copy) void (^onInstanceSettings)(void);

@property (nonatomic, copy) void (^onCreateProfile)(void);
@property (nonatomic, copy) void (^onSwitchProfile)(void);
@property (nonatomic, copy) void (^onSkinOptions)(void);
@property (nonatomic, copy) void (^onEditProfile)(void);

- (void)reloadState;
- (void)playCEEnterAnimation;
- (void)playCEExitAnimation;

@end
