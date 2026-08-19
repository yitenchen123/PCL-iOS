#import "PCLGlobalButtonHover.h"
#import "PCLMouseSupport.h"

@interface PCLGlobalButtonHoverManager : NSObject
@property(nonatomic,weak) UIWindow *window;
@property(nonatomic,strong) UIHoverGestureRecognizer *hover;
@property(nonatomic,weak) UIButton *button;
@property(nonatomic,strong) UIView *overlay;
@end

@implementation PCLGlobalButtonHoverManager

- (instancetype)initWithWindow:(UIWindow *)window {
    self=[super init];
    if (!self) return nil;
    self.window=window;

    self.hover=[[UIHoverGestureRecognizer alloc]
        initWithTarget:self action:@selector(hoverChanged:)];

    self.hover.cancelsTouchesInView=NO;
    [window addGestureRecognizer:self.hover];

    [[NSNotificationCenter defaultCenter]
        addObserver:self selector:@selector(mouseChanged)
        name:PCLMouseAvailabilityDidChangeNotification object:nil];

    [self mouseChanged];
    return self;
}

- (void)mouseChanged {
    self.hover.enabled=PCLExternalMouseConnected();
    if (!self.hover.enabled) [self clearHover];
}

- (UIButton *)buttonAtPointer {
    CGPoint p=[self.hover locationInView:self.window];
    UIView *v=[self.window hitTest:p withEvent:nil];

    while (v && ![v isKindOfClass:UIButton.class])
        v=v.superview;

    UIButton *b=(UIButton *)v;
    if (!b.enabled || b.hidden || b.alpha<0.01) return nil;
    return b;
}

- (void)showHover:(UIButton *)button {
    self.button=button;

    UIView *v=[[UIView alloc] initWithFrame:button.bounds];
    v.userInteractionEnabled=NO;
    v.autoresizingMask=UIViewAutoresizingFlexibleWidth |
                       UIViewAutoresizingFlexibleHeight;
    v.layer.cornerRadius=button.layer.cornerRadius;

    UIColor *blue=[UIColor colorWithRed:19.0/255.0
        green:112.0/255.0 blue:243.0/255.0 alpha:1.0];

    BOOL topBar =
        [NSStringFromClass(button.superview.superview.class)
            containsString:@"StackView"];

    v.backgroundColor = topBar
        ? [UIColor colorWithWhite:1 alpha:0.18]
        : [blue colorWithAlphaComponent:0.10];
    v.alpha=0.0;

    [button insertSubview:v atIndex:0];
    self.overlay=v;

    [UIView animateWithDuration:0.10 animations:^{
        v.alpha=1.0;
    }];
}

- (void)clearHover {
    UIView *v=self.overlay;
    self.overlay=nil;
    self.button=nil;

    [UIView animateWithDuration:0.15 animations:^{
        v.alpha=0.0;
    } completion:^(BOOL done) {
        [v removeFromSuperview];
    }];
}

- (void)hoverChanged:(UIHoverGestureRecognizer *)hover {
    if (hover.state==UIGestureRecognizerStateEnded ||
        hover.state==UIGestureRecognizerStateCancelled) {
        [self clearHover];
        return;
    }

    UIButton *b=[self buttonAtPointer];
    if (b==self.button) return;

    [self clearHover];
    if (b) [self showHover:b];
}

@end

static PCLGlobalButtonHoverManager *PCLHoverManager;

void PCLInstallGlobalButtonHover(UIWindow *window) {
    PCLHoverManager=
        [[PCLGlobalButtonHoverManager alloc] initWithWindow:window];
}
