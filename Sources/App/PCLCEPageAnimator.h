#import <UIKit/UIKit.h>

@interface PCLCEPageAnimator : NSObject

+ (void)showSimpleLeftPage:(UIView *)view;
+ (void)hideSimpleLeftPage:(UIView *)view;

+ (void)showLeftItems:(NSArray<UIView *> *)items;
+ (void)hideLeftItems:(NSArray<UIView *> *)items;

+ (void)showRightItems:(NSArray<UIView *> *)items
            scrollView:(UIScrollView *)scrollView;

+ (void)hideRightItems:(NSArray<UIView *> *)items
            scrollView:(UIScrollView *)scrollView;

@end
