#import "PCLCEProfileTypeDialog.h"
#import <QuartzCore/QuartzCore.h>
#import <math.h>

@interface PCLCEProfileTypeDialog ()
@property(nonatomic,strong) UIView *card;
@property(nonatomic,strong) UILabel *titleLabel;
@property(nonatomic,strong) UIView *titleLine;

@property(nonatomic,strong) NSArray<UIButton *> *rows;
@property(nonatomic,strong) UIButton *continueButton;
@property(nonatomic,strong) UIButton *cancelButton;
@property(nonatomic) NSInteger selected;
@property(nonatomic) CGFloat scale;
@end

@implementation PCLCEProfileTypeDialog

- (instancetype)initWithFrame:(CGRect)frame {
    self=[super initWithFrame:frame];
    if (!self) return nil;

    self.selected=-1;
    self.backgroundColor=UIColor.clearColor;
    [self buildUI];
    return self;
}

- (UIButton *)ceButton:(NSString *)title {
    UIButton *b=[UIButton buttonWithType:UIButtonTypeCustom];
    [b setTitle:title forState:UIControlStateNormal];
    [b setTitleColor:[UIColor colorWithWhite:.25 alpha:1]
             forState:UIControlStateNormal];
    b.layer.borderWidth=1;
    b.layer.cornerRadius=3;
    return b;
}

- (void)buildUI {
    self.card=[[UIView alloc] init];
    self.card.backgroundColor=[UIColor colorWithWhite:.995 alpha:1];
    self.card.layer.shadowColor=UIColor.blackColor.CGColor;
    self.card.layer.shadowOpacity=.28;
    [self addSubview:self.card];

    self.titleLabel=[[UILabel alloc] init];

    self.titleLabel.text=@"新建档案 - 选择验证类型";
    self.titleLabel.textColor=
        [UIColor colorWithRed:.25 green:.43 blue:.61 alpha:1];
    [self.card addSubview:self.titleLabel];

    self.titleLine=[[UIView alloc] init];
    self.titleLine.backgroundColor=self.titleLabel.textColor;
    [self.card addSubview:self.titleLine];

    UIButton *ms=[self row:@"正版验证"
        icon:@"checkmark.shield" type:PCLProfileAuthMicrosoft];
    UIButton *off=[self row:@"离线验证"
        icon:@"link.slash" type:PCLProfileAuthOffline];
    UIButton *auth=[self row:@"第三方验证"
        icon:@"network" type:PCLProfileAuthThirdParty];

    self.rows=@[ms,off,auth];
    for (UIButton *b in self.rows) [self.card addSubview:b];

    self.continueButton=[self ceButton:@"继续"];
    self.continueButton.enabled=NO;
    self.continueButton.alpha=.45;
    [self.continueButton addTarget:self action:@selector(confirmPressed)
        forControlEvents:UIControlEventTouchUpInside];

    self.cancelButton=[self ceButton:@"取消"];
    [self.cancelButton addTarget:self action:@selector(cancelPressed)
        forControlEvents:UIControlEventTouchUpInside];

    [self.card addSubview:self.continueButton];
    [self.card addSubview:self.cancelButton];
}





- (UIButton *)row:(NSString *)title
             icon:(NSString *)icon
             type:(PCLProfileAuthType)type {
    UIButton *b=[UIButton buttonWithType:UIButtonTypeCustom];
    b.tag=100+type;
    b.contentHorizontalAlignment=UIControlContentHorizontalAlignmentLeft;
    [b setTitle:title forState:UIControlStateNormal];

    [b setTitleColor:[UIColor colorWithWhite:.25 alpha:1]
             forState:UIControlStateNormal];
    [b setImage:[UIImage systemImageNamed:icon]
       forState:UIControlStateNormal];
    b.tintColor=[UIColor colorWithWhite:.32 alpha:1];
    b.layer.cornerRadius=3;

    UIView *circle=[[UIView alloc] init];
    circle.tag=9001;
    circle.userInteractionEnabled=NO;
    circle.layer.borderWidth=1.5;
    circle.layer.cornerRadius=7;
    [b addSubview:circle];

    UIView *dot=[[UIView alloc] init];

    dot.tag=9002;
    dot.userInteractionEnabled=NO;
    dot.backgroundColor=[UIColor colorWithRed:.075 green:.44 blue:.95 alpha:1];
    dot.layer.cornerRadius=4;
    dot.hidden=YES;
    [circle addSubview:dot];

    [b addTarget:self action:@selector(rowPressed:)
        forControlEvents:UIControlEventTouchUpInside];
    return b;
}

- (void)rowPressed:(UIButton *)sender {
    self.selected=sender.tag-100;
    UIColor *blue=[UIColor colorWithRed:.075 green:.44 blue:.95 alpha:1];

    for (UIButton *row in self.rows) {
        BOOL on=row==sender;
        UIView *circle=[row viewWithTag:9001];
        UIView *dot=[row viewWithTag:9002];

        circle.layer.borderColor=
            (on ? blue : [UIColor colorWithWhite:.55 alpha:1]).CGColor;
        dot.hidden=!on;
    }

    self.continueButton.enabled=YES;
    self.continueButton.alpha=1;
    self.continueButton.layer.borderColor=blue.CGColor;
}

- (void)presentInView:(UIView *)view {
    self.frame=view.bounds;
    self.autoresizingMask=UIViewAutoresizingFlexibleWidth |
                          UIViewAutoresizingFlexibleHeight;
    [view addSubview:self];
    [self setNeedsLayout];
    [self layoutIfNeeded];

    CGFloat r=-4.0*M_PI/180.0;

    self.card.transform=
        CGAffineTransformRotate(
            CGAffineTransformMakeTranslation(0,40*self.scale),r);
    self.card.alpha=0;

    [UIView animateWithDuration:.20 animations:^{
        self.backgroundColor=[UIColor colorWithWhite:0 alpha:90.0/255.0];
    }];

    [UIView animateWithDuration:.30 delay:.06
        usingSpringWithDamping:.78 initialSpringVelocity:0
        options:UIViewAnimationOptionAllowUserInteraction
        animations:^{
            self.card.alpha=1;
            self.card.transform=CGAffineTransformIdentity;
        } completion:nil];
}

- (void)dismissWithType:(NSInteger)type {
    CGFloat r=6.0*M_PI/180.0;

    [UIView animateWithDuration:.15 animations:^{
        self.card.alpha=0;
        self.card.transform=
            CGAffineTransformRotate(
                CGAffineTransformMakeTranslation(0,20*self.scale),r);
        self.backgroundColor=UIColor.clearColor;

    } completion:^(BOOL finished) {
        [self removeFromSuperview];

        if (type>=0) {
            if (self.onSelect) self.onSelect(type);
        } else {
            if (self.onCancel) self.onCancel();
        }
    }];
}

- (void)confirmPressed {
    if (self.selected<0) return;
    [self dismissWithType:self.selected];
}

- (void)cancelPressed {
    [self dismissWithType:-1];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat w=CGRectGetWidth(self.bounds);
    CGFloat h=CGRectGetHeight(self.bounds);
    CGFloat s=MIN(w/850.0,h/417.2);
    self.scale=s;

    CGFloat cw=MIN(400*s,w-50*s);
    CGFloat ch=285*s;

    self.card.frame=CGRectMake((w-cw)/2,(h-ch)/2,cw,ch);
    self.card.layer.cornerRadius=7*s;
    self.card.layer.shadowRadius=20*s;
    self.card.layer.shadowOffset=CGSizeMake(0,2*s);

    self.titleLabel.font=[UIFont systemFontOfSize:23*s];
    self.titleLabel.frame=CGRectMake(29*s,20*s,cw-58*s,32*s);

    self.titleLine.frame=
        CGRectMake(22*s,62*s,cw-44*s,2*s);

    for (NSInteger i=0;i<self.rows.count;i++) {
        UIButton *row=self.rows[i];
        row.frame=CGRectMake(29*s,(81+43*i)*s,cw-58*s,36*s);
        row.titleLabel.font=[UIFont systemFontOfSize:14*s];
        row.contentEdgeInsets=UIEdgeInsetsMake(0,36*s,0,8*s);

        UIView *circle=[row viewWithTag:9001];

        circle.frame=CGRectMake(7*s,11*s,14*s,14*s);
        circle.layer.cornerRadius=7*s;

        UIView *dot=[row viewWithTag:9002];
        dot.frame=CGRectMake(3*s,3*s,8*s,8*s);
        dot.layer.cornerRadius=4*s;
    }

    CGFloat bw=66*s;
    CGFloat by=ch-51*s;

    self.cancelButton.frame=
        CGRectMake(cw-30*s-bw,by,bw,30*s);

    self.continueButton.frame=
        CGRectMake(cw-42*s-bw*2,by,bw,30*s);
}
@end
