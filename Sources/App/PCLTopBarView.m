#import "PCLTopBarView.h"

@interface PCLTopBarView ()

@property (nonatomic, strong) UIStackView *buttonStack;
@property (nonatomic, strong) NSArray<UIButton *> *buttons;
@property (nonatomic, strong) UILabel *pclLabel;
@property (nonatomic, strong) UILabel *iosBadge;

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
    self.buttonStack.spacing = 16.0;

    self.buttonStack.translatesAutoresizingMaskIntoConstraints = NO;

    [self addSubview:self.buttonStack];
    for (NSInteger i = 0; i < titles.count; i++) {

        UIButton *button =
            [UIButton buttonWithType:UIButtonTypeSystem];

        [button setTitle:titles[i]
                forState:UIControlStateNormal];

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

        [self.iosBadge.bottomAnchor
            constraintEqualToAnchor:self.pclLabel.bottomAnchor],

        [self.iosBadge.widthAnchor
            constraintEqualToConstant:28.0],

        [self.iosBadge.heightAnchor
            constraintEqualToConstant:20.0],

        [self.buttonStack.centerYAnchor
            constraintEqualToAnchor:self.centerYAnchor],

        [self.buttonStack.centerXAnchor
            constraintEqualToAnchor:self.centerXAnchor]
    ]];

    self.selectedPage = PCLPageTypeLaunch;
    [self updateButtonAppearance];
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
}
- (void)updateButtonAppearance {
    for (NSInteger i = 0; i < self.buttons.count; i++) {
        UIButton *button = self.buttons[i];

        if (i == self.selectedPage) {
            [button setTitleColor:[self pclThemeColor]
                         forState:UIControlStateNormal];

            button.backgroundColor = UIColor.whiteColor;
            button.titleLabel.font =
                [UIFont systemFontOfSize:15.0
                                  weight:UIFontWeightSemibold];
        } else {
            [button setTitleColor:
                [UIColor colorWithWhite:1.0 alpha:0.85]
                         forState:UIControlStateNormal];

            button.backgroundColor = UIColor.clearColor;
            button.titleLabel.font =
                [UIFont systemFontOfSize:15.0
                                  weight:UIFontWeightMedium];
        }
    }
}

@end
