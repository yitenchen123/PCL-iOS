#import "PCLTopBarView.h"
@interface PCLTopBarView () @property (nonatomic, strong) UIStackView *buttonStack; @property (nonatomic, strong) UIView *selectionIndicator; @property 
(nonatomic, strong) NSArray<UIButton *> *buttons; @end @implementation PCLTopBarView - (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame]; if (self) { [self setupView];
    }
    return self;
}
- (void)setupView { self.backgroundColor = [UIColor systemBackgroundColor]; NSArray<NSString *> *titles = @[ @"启动", @"下载", @"联机", @"设置" ]; 
    NSMutableArray<UIButton *> *buttons = [NSMutableArray array]; self.buttonStack = [[UIStackView alloc] init]; self.buttonStack.axis = 
    UILayoutConstraintAxisHorizontal; self.buttonStack.alignment = UIStackViewAlignmentCenter; self.buttonStack.spacing = 28.0; 
    self.buttonStack.translatesAutoresizingMaskIntoConstraints = NO; [self addSubview:self.buttonStack]; for (NSInteger i = 0; i < titles.count; i++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem]; [button setTitle:titles[i] forState:UIControlStateNormal]; button.tag = i; 
        button.titleLabel.font =
            [UIFont systemFontOfSize:17 weight:UIFontWeightMedium]; [button addTarget:self action:@selector(pageButtonPressed:) 
         forControlEvents:UIControlEventTouchUpInside];
        [self.buttonStack addArrangedSubview:button]; [buttons addObject:button];
    }
    self.buttons = buttons; self.selectionIndicator = [[UIView alloc] init]; self.selectionIndicator.backgroundColor = [UIColor systemBlueColor]; 
    self.selectionIndicator.layer.cornerRadius = 1.5; self.selectionIndicator.translatesAutoresizingMaskIntoConstraints = NO; [self 
    addSubview:self.selectionIndicator]; [NSLayoutConstraint activateConstraints:@[
        [self.buttonStack.centerXAnchor constraintEqualToAnchor:self.centerXAnchor], [self.buttonStack.centerYAnchor constraintEqualToAnchor:self.centerYAnchor], 
        [self.selectionIndicator.bottomAnchor
            constraintEqualToAnchor:self.bottomAnchor], [self.selectionIndicator.heightAnchor constraintEqualToConstant:3.0], 
        [self.selectionIndicator.widthAnchor
            constraintEqualToConstant:38.0] ]]; self.selectedPage = PCLPageTypeLaunch; [self updateButtonAppearance];
}
- (void)pageButtonPressed:(UIButton *)sender { PCLPageType page = (PCLPageType)sender.tag; [self selectPage:page animated:YES]; if ([self.delegate 
    respondsToSelector:
         @selector(topBarView:didSelectPage:)]) { [self.delegate topBarView:self didSelectPage:page];
    }
}
- (void)selectPage:(PCLPageType)page animated:(BOOL)animated { if (page < 0 || page >= self.buttons.count) { return;
    }
    _selectedPage = page; [self updateButtonAppearance]; UIButton *button = self.buttons[page]; void (^changes)(void) = ^{ self.selectionIndicator.center = 
            CGPointMake(button.center.x,
                        self.selectionIndicator.center.y);
    };
    if (animated) { [UIView animateWithDuration:0.20 animations:changes];
    } else {
        changes();
    }
}
- (void)updateButtonAppearance { for (NSInteger i = 0; i < self.buttons.count; i++) { UIButton *button = self.buttons[i]; if (i == self.selectedPage) { [button 
            setTitleColor:[UIColor labelColor]
                         forState:UIControlStateNormal]; button.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
        } else {
            [button setTitleColor:[UIColor secondaryLabelColor] forState:UIControlStateNormal]; button.titleLabel.font = [UIFont systemFontOfSize:17 
                                  weight:UIFontWeightRegular];
        }
    }
}
- (void)layoutSubviews { [super layoutSubviews]; if (self.selectedPage < self.buttons.count) { UIButton *button = self.buttons[self.selectedPage]; 
        self.selectionIndicator.center =
            CGPointMake(button.center.x, CGRectGetHeight(self.bounds) - 1.5);
    }
}
@end
