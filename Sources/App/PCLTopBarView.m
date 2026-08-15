#import "PCLTopBarView.h"
@interface PCLTopBarView () @property (nonatomic, strong) UIStackView *buttonStack; @property (nonatomic, strong) NSArray<UIButton *> *buttons; @end
@implementation PCLTopBarView
- (UIColor *)pclThemeColor {
    return [UIColor colorWithRed:19.0/255.0 green:112.0/255.0 blue:243.0/255.0 alpha:1.0];
}
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame]; if (self) { [self setupView];
    }
    return self;
}
- (void)setupView { self.backgroundColor = [self pclThemeColor];
    NSArray<NSString *> *titles = @[ @"启动", @"下载", @"联机", @"设置" ];
    NSMutableArray<UIButton *> *buttons = [NSMutableArray array];
    self.buttonStack = [[UIStackView alloc] init]; self.buttonStack.axis =
    UILayoutConstraintAxisHorizontal; self.buttonStack.alignment = UIStackViewAlignmentCenter; self.buttonStack.spacing = 8.0;
    self.buttonStack.translatesAutoresizingMaskIntoConstraints = NO; [self addSubview:self.buttonStack]; for (NSInteger i = 0; i < titles.count; i++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem]; [button setTitle:titles[i] forState:UIControlStateNormal]; button.tag = i;
        button.layer.cornerRadius = 13.5;
        button.clipsToBounds = YES;
        button.contentEdgeInsets = UIEdgeInsetsMake(5.0, 14.0, 5.0, 14.0);
        [UIFont systemFontOfSize:17 weight:UIFontWeightMedium]; [button addTarget:self action:@selector(pageButtonPressed:)
         forControlEvents:UIControlEventTouchUpInside];
        [self.buttonStack addArrangedSubview:button]; [buttons addObject:button];
    }
    self.buttons = buttons;  [NSLayoutConstraint activateConstraints:@[
        [self.buttonStack.centerXAnchor constraintEqualToAnchor:self.centerXAnchor], [self.buttonStack.centerYAnchor constraintEqualToAnchor:self.centerXAnchor]];
        self.selectedPage = PCLPageTypeLaunch; [self updateButtonAppearance];
}
- (void)pageButtonPressed:(UIButton *)sender { PCLPageType page = (PCLPageType)sender.tag; [self selectPage:page animated:YES]; if ([self.delegate
    respondsToSelector:
         @selector(topBarView:didSelectPage:)]) { [self.delegate topBarView:self didSelectPage:page];
    }
}
- (void)selectPage:(PCLPageType)page animated:(BOOL)animated { if (page < 0 || page >= self.buttons.count) { return;
    }
    _selectedPage = page; [self updateButtonAppearance]; UIButton *button = self.buttons[page];
}
- (void)updateButtonAppearance { for (NSInteger i = 0; i < self.buttons.count; i++) { UIButton *button = self.buttons[i]; if (i == self.selectedPage) { [button
                       setTitleColor:[self pclThemeColor]
                           forState:UIControlStateNormal];
                          button.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
                          button.backgroundColor = UIColor.whiteColor;
        } else {
            [button setTitleColor:[self pclThemeColor] forState:UIControlStateNormal]; button.titleLabel.font = [UIFont systemFontOfSize:15
                                  weight:UIFontWeightRegular];
            button.backgroundColor = UIColor.clearColor;
        }
    }
}
@end
