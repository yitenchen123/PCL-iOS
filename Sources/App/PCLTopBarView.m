#import "PCLTopBarView.h"

@interface PCLTopBarView ()

@property (nonatomic, strong) UIStackView *buttonStack;
@property (nonatomic, strong) NSArray<UIButton *> *buttons;
@property (nonatomic, strong) UILabel *pclLabel;
@property (nonatomic, strong) UILabel *iosBadge;
@property (nonatomic, strong) UIView *selectionPill;

@end

@implementation PCLTopBarView

- (UIColor *)pclThemeColor {
    return [UIColor colorWithRed:19.0/255.0
                           green:112.0/255.0
                            blue:243.0/255.0
                           alpha:1.0];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        [self setupView];
    }

    return self;
}
- (void)setupView {
    self.backgroundColor = [self pclThemeColor];

    self.pclLabel = [[UILabel alloc] init];
    self.pclLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.pclLabel.text = @"PCL";
    self.pclLabel.textColor = UIColor.whiteColor;
    self.pclLabel.font =
        [UIFont systemFontOfSize:26.0
                          weight:UIFontWeightBold];

    [self addSubview:self.pclLabel];

    self.iosBadge = [[UILabel alloc] init];
    self.iosBadge.translatesAutoresizingMaskIntoConstraints = NO;
    self.iosBadge.text = @"iOS";
    self.iosBadge.textAlignment = NSTextAlignmentCenter;
    self.iosBadge.textColor = [self pclThemeColor];
    self.iosBadge.backgroundColor = UIColor.whiteColor;
    self.iosBadge.font =
        [UIFont systemFontOfSize:11.0
                          weight:UIFontWeightBold];

    self.iosBadge.layer.cornerRadius = 5.0;
    self.iosBadge.clipsToBounds = YES;

    [self addSubview:self.iosBadge];
    NSArray<NSString *> *titles =
        @[@"启动", @"下载", @"联机", @"设置"];

    NSMutableArray<UIButton *> *buttons =
        [NSMutableArray array];

    self.buttonStack = [[UIStackView alloc] init];
    self.buttonStack.axis =
        UILayoutConstraintAxisHorizontal;
    self.buttonStack.alignment =
        UIStackViewAlignmentCenter;
    self.buttonStack.spacing = 36.0;
    self.buttonStack.translatesAutoresizingMaskIntoConstraints = NO;

    UIVisualEffect *pillEffect = nil;
    if (@available(iOS 26.0, *)) {
        UIGlassEffect *glass = [[UIGlassEffect alloc] init];
        glass.interactive = YES;
        pillEffect = glass;
}
    else {
        pillEffect = [UIBlurEffect
            effectWithStyle:UIBlurEffectStyleLight];
}
    UIVisualEffectView *glassView =
        [[UIVisualEffectView alloc] initWithEffect:pillEffect];
    self.selectionPill = glassView;
    self.selectionPill.layer.cornerRadius = 14.0;
    self.selectionPill.clipsToBounds = YES;
    self.selectionPill.userInteractionEnabled = NO;
    [self addSubview:self.selectionPill];
    [self addSubview:self.buttonStack];
    [self bringSubviewToFront:self.buttonStack];
    for (NSInteger i = 0; i < titles.count; i++) {

        UIButton *button =
            [UIButton buttonWithType:UIButtonTypeSystem];

        [button setTitle:titles[i]
                forState:UIControlStateNormal];
        button.titleLabel.font =
            [UIFont systemFontOfSize:17.0
                              weight:UIFontWeightSemibold];

        button.tag = i;
        button.layer.cornerRadius = 14.0;
        button.clipsToBounds = YES;

        button.contentEdgeInsets =
            UIEdgeInsetsMake(6.0, 13.0, 6.0, 13.0);

        [button addTarget:self
                   action:@selector(pageButtonPressed:)
         forControlEvents:UIControlEventTouchUpInside];

        [self.buttonStack addArrangedSubview:button];
        [buttons addObject:button];
    }

    self.buttons = buttons;
    [NSLayoutConstraint activateConstraints:@[
        [self.pclLabel.leadingAnchor
            constraintEqualToAnchor:self.leadingAnchor
                           constant:16.0],

        [self.pclLabel.centerYAnchor
            constraintEqualToAnchor:self.centerYAnchor],

        [self.iosBadge.leadingAnchor
            constraintEqualToAnchor:self.pclLabel.trailingAnchor
                           constant:6.0],

        [self.iosBadge.centerYAnchor
            constraintEqualToAnchor:self.pclLabel.centerYAnchor],

        [self.iosBadge.widthAnchor
            constraintEqualToConstant:28.0],

        [self.iosBadge.heightAnchor
            constraintEqualToConstant:20.0],

        [self.buttonStack.centerYAnchor
            constraintEqualToAnchor:self.centerYAnchor],

        [self.buttonStack.centerXAnchor
            constraintEqualToAnchor:self.centerXAnchor],

        [self.buttonStack.leadingAnchor
            constraintGreaterThanOrEqualToAnchor:self.iosBadge.trailingAnchor
                                        constant:24.0]



    ]];

    self.selectedPage = PCLPageTypeLaunch;
    [self updateButtonAppearance];

}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.buttons.count == 0) {
        return;
    }

    UIButton *button =
        self.buttons[self.selectedPage];

    CGRect frame =
        [self.buttonStack convertRect:button.frame
                               toView:self];
    self.selectionPill.frame =
        CGRectInset(frame, -4.0, 0.0);
}

- (void)pageButtonPressed:(UIButton *)sender {
    PCLPageType page = (PCLPageType)sender.tag;

    [self selectPage:page animated:YES];

    if ([self.delegate respondsToSelector:
         @selector(topBarView:didSelectPage:)]) {

        [self.delegate topBarView:self
                    didSelectPage:page];
    }
}

- (void)selectPage:(PCLPageType)page
          animated:(BOOL)animated {

    if (page < 0 || page >= self.buttons.count) {
        return;
    }

    _selectedPage = page;
    [self updateButtonAppearance];
    UIButton *button = self.buttons[page];
    CGRect targetFrame =
        [self.buttonStack convertRect:button.frame
                               toView:self];
    targetFrame =
        CGRectInset(targetFrame, -4.0, 0.0);

    void (^movePill)(void) = ^{
        self.selectionPill.frame = targetFrame;
    };

    if (animated) {
        [UIView animateWithDuration:0.42
                              delay:0.0
             usingSpringWithDamping:0.80
              initialSpringVelocity:0.25
                            options:UIViewAnimationOptionBeginFromCurrentState |
                                    UIViewAnimationOptionAllowUserInteraction
                        animations:movePill completion:nil];
}

    else {
        movePill();
    }
}

- (void)updateButtonAppearance {
    for (NSInteger i = 0; i < self.buttons.count; i++) {
        UIButton *button = self.buttons[i];

        if (i == self.selectedPage) {
            [button setTitleColor:UIColor.whiteColor
                         forState:UIControlStateNormal];

            button.backgroundColor = UIColor.clearColor;
            button.titleLabel.font =
                [UIFont systemFontOfSize:17.0
                                  weight:UIFontWeightSemibold];
        } else {
            [button setTitleColor:
                [UIColor colorWithWhite:1.0 alpha:0.85]
                         forState:UIControlStateNormal];

            button.backgroundColor = UIColor.clearColor;
            button.titleLabel.font =
                [UIFont systemFontOfSize:17.0
                                  weight:UIFontWeightSemibold];
        }
    }
}

@end
