#import "PCLTopBarView.h"

@interface PCLTopBarView ()
@property (nonatomic, strong) UIStackView *buttonStack;
@property (nonatomic, strong) NSArray<UIButton *> *buttons;
@property (nonatomic, strong) UILabel *pclLabel;
@property (nonatomic, strong) UILabel *iosBadge;
@property (nonatomic, strong) UIView *selectionContainer;
@property (nonatomic, strong) UIVisualEffectView *glassView;
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
    if (self) [self setupView];
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
        @[@"启动", @"下载", @"设置", @"工具"];

    NSArray<NSString *> *symbols =
        @[@"TopBarPlay", @"TopBarDownload",
          @"TopBarSettings", @"TopBarTools"];

    self.selectionContainer = [[UIView alloc] init];
    self.selectionContainer.userInteractionEnabled = NO;
    self.selectionContainer.layer.cornerRadius = 13.5;
    self.selectionContainer.clipsToBounds = YES;
    [self addSubview:self.selectionContainer];
    if (@available(iOS 26.0, *)) {
        UIGlassEffect *glass = [[UIGlassEffect alloc] init];
        glass.interactive = YES;
    self.glassView =
        [[UIVisualEffectView alloc] initWithEffect:glass];
    self.glassView.frame =
        self.selectionContainer.bounds;
    self.glassView.autoresizingMask =
        UIViewAutoresizingFlexibleWidth |
        UIViewAutoresizingFlexibleHeight;

    [self.selectionContainer addSubview:self.glassView];
}
else {
    self.selectionContainer.backgroundColor =
          UIColor.whiteColor;
}

    self.buttonStack = [[UIStackView alloc] init];
    self.buttonStack.axis = UILayoutConstraintAxisHorizontal;
    self.buttonStack.alignment = UIStackViewAlignmentCenter;
    self.buttonStack.spacing = 36.0; self.buttonStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.buttonStack];
    NSMutableArray<UIButton *> *buttons =
        [NSMutableArray array];

    for (NSInteger i = 0; i < titles.count; i++) {
        UIButton *button =
            [UIButton buttonWithType:UIButtonTypeSystem];
        button.tag = i;

        [button setTitle:titles[i]
                forState:UIControlStateNormal];

        button.titleLabel.font =
            [UIFont systemFontOfSize:17.0
                              weight:UIFontWeightSemibold];

        button.titleLabel.lineBreakMode =
            NSLineBreakByClipping;

        [button setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                forAxis:UILayoutConstraintAxisHorizontal];

        UIImage *image =
            [UIImage imageNamed:symbols[i]];

        [button setImage:image
                forState:UIControlStateNormal];

        button.imageView.contentMode =
            UIViewContentModeScaleAspectFit;

        [button.imageView.widthAnchor
            constraintEqualToConstant:16.0].active = YES;

        [button.imageView.heightAnchor
            constraintEqualToConstant:16.0].active = YES;

        button.tintColor = UIColor.whiteColor;
        button.semanticContentAttribute =
            UISemanticContentAttributeForceLeftToRight;

        button.layer.cornerRadius = 13.5;
        button.clipsToBounds = YES;

        button.contentEdgeInsets =
            UIEdgeInsetsMake(5.0, 12.0, 5.0, 12.0);

        button.imageEdgeInsets =
            UIEdgeInsetsMake(0.0, 0.0, 0.0, 4.0);

        button.titleEdgeInsets =
            UIEdgeInsetsMake(0.0, 4.0, 0.0, 0.0);

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

        [self.buttonStack.centerXAnchor
            constraintEqualToAnchor:self.centerXAnchor],
        [self.buttonStack.centerYAnchor
            constraintEqualToAnchor:self.centerYAnchor]
    ]];

    self.selectedPage = PCLPageTypeLaunch;
    [self updateButtonAppearanceAnimated:NO];
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
    if (page < 0 || page >= self.buttons.count) return;

    _selectedPage = page;

    UIButton *button =
        self.button[page];
    CGRect target =
        [button convertRect:button.bounds}
                     toView:self];

    target.size.height = 27.0;
    target.origin.y =
    CGRectGetMidY(button.frame) - 13.5;

    if (animated) {
        [UIView animateWithDuration:0.22
                              delay:0.0
             usingSpringWithDamping:0.82
              initialSpringVelocity:0.15
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{

        self.selectionContainer.frame = target;
    } completion:nil];
} else {
    self.selectionContainer.frame = target;
}
    [self updateButtonAppearanceAnimated:animated];

- (void)updateButtonAppearanceAnimated:(BOOL)animated {
     for (NSInteger i = 0; i < self.buttons.count; i++) {
        UIButton *button = self.buttons[i];
        BOOL selected = (i == self.selectedPage);

        [button setTitleColor:UIColor.whiteColor
                     forState:UIControlStateNormal];
        button.tintColor = UIColor.whiteColor;

        void (^changes)(void) = ^{
            button.transform = CGAffineTransformIdentity;
        };

        if (animated && selected) {
            [UIView animateWithDuration:0.22
                             animations:changes];
        } else {
            changes();
        }
    }
}
- (void)layoutSubviews {
    [super layoutSubviews];

    if (self.buttons.count == 0) return;

    UIButton *button =
        self.buttons[self.selectedPage];

    CGRect frame =
        [button convertRect:button.bounds
                     toView:self];
    frame.size.height = 27.0;
    frame.origin.y =
        CGRectGetMidY(button.frame) - 13.5;
    if (CGRectIsEmpty(self.selectionContainer.frame)) {
        self.selectionContainer.frame = frame;
    }
}
@end
