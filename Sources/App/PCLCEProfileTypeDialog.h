#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, PCLProfileAuthType) {
    PCLProfileAuthMicrosoft,
    PCLProfileAuthOffline,
    PCLProfileAuthThirdParty
};

@interface PCLCEProfileTypeDialog : UIView
@property(nonatomic,copy) void (^onSelect)(PCLProfileAuthType type);
@property(nonatomic,copy) void (^onCancel)(void);
- (void)presentInView:(UIView *)view;
@end
