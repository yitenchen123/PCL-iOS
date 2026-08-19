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

- (BOOL)isTopBarButton:(UIButton *)button {
    for (UIView *v=button; v; v=v.superview) {
        if ([NSStringFromClass(v.class)
            isEqualToString:@"PCLTopBarView"])
            return YES;
    }
    return NO;
}

- (void)showHover:(UIButton *)button {
    self.button=button;

    UIView *v=[[UIView alloc] initWithFrame:button.bounds];
    v.userInteractionEnabled=NO;
    v.autoresizingMask=UIViewAutoresizingFlexibleWidth |
                       UIViewAutoresizingFlexibleHeight;
    CGFloat w=CGRectGetWidth(button.bounds);
    CGFloat h=CGRectGetHeight(button.bounds);

    BOOL iconOnly =
        button.currentTitle.length == 0 &&
        w <= 48.0 &&
        h <= 48.0;

    v.layer.cornerRadius = iconOnly
        ? MIN(w,h)/2.0
        : MAX(button.layer.cornerRadius,3.0);

    v.clipsToBounds=YES;

    UIColor *blue=[UIColor colorWithRed:19.0/255.0
        green:112.0/255.0 blue:243.0/255.0 alpha:1.0];

    BOOL topBar =
        [self isTopBarButton:button];


    if (topBar) {
        CGColorRef bg=button.backgroundColor.CGColor;
        CGFloat alpha=bg ? CGColorGetAlpha(bg) : 0.0;

        v.backgroundColor = alpha > 0.5
            ? [blue colorWithAlphaComponent:0.14]
            : [UIColor colorWithWhite:1 alpha:0.38];
    } else {
        v.backgroundColor =
            [blue colorWithAlphaComponent:
                iconOnly ? 0.12 : 0.10];
    }
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
