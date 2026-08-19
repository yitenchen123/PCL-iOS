#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

static char PCLPressInstalledKey;

@interface UIButton (PCLInteraction)
@end

@implementation UIButton (PCLInteraction)

+ (void)load {
    static dispatch_once_t once;
    dispatch_once(&once,^{
        Class c=UIButton.class;

        Method old=class_getInstanceMethod(
            c,@selector(didMoveToWindow));

        class_addMethod(c,@selector(didMoveToWindow),
            method_getImplementation(old),
            method_getTypeEncoding(old));

        Method a=class_getInstanceMethod(
            c,@selector(didMoveToWindow));

        Method b=class_getInstanceMethod(
            c,@selector(pcl_didMoveToWindow));

        method_exchangeImplementations(a,b);
    });
}

- (void)pcl_didMoveToWindow {
    [self pcl_didMoveToWindow];

    if (!self.window) return;
    if ([NSStringFromClass(self.class)
        isEqualToString:@"PCLCEButton"]) return;

    if ([NSStringFromClass(self.class)
        isEqualToString:@"PCLCEButton"])
        return;

    if (objc_getAssociatedObject(
        self,&PCLPressInstalledKey)) return;

    objc_setAssociatedObject(
        self,&PCLPressInstalledKey,@YES,
        OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    [self addTarget:self
        action:@selector(pcl_pressDown)
        forControlEvents:
            UIControlEventTouchDown |
            UIControlEventTouchDragEnter];

    [self addTarget:self
        action:@selector(pcl_pressUp)
        forControlEvents:
            UIControlEventTouchUpInside |
            UIControlEventTouchUpOutside |
            UIControlEventTouchCancel |
            UIControlEventTouchDragExit];
}

- (void)pcl_scale:(CGFloat)scale
         duration:(NSTimeInterval)duration {

    [UIView animateWithDuration:duration
        delay:0
        options:
            UIViewAnimationOptionBeginFromCurrentState |
            UIViewAnimationOptionAllowUserInteraction |
            UIViewAnimationOptionCurveEaseOut
        animations:^{
            self.layer.transform =
                CATransform3DMakeScale(scale,scale,1.0);
        }
        completion:nil];
}

- (void)pcl_pressDown {
    [self pcl_scale:0.955 duration:0.09];
}

- (void)pcl_pressUp {
    [self pcl_scale:1.0 duration:0.18];
}

@end
