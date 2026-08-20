#import "PCLCEProfileTypeDialog.h"
#import <QuartzCore/QuartzCore.h>
#import <math.h>

static UIImage *PCLAuthIcon(
    PCLProfileAuthType type, CGFloat size, UIColor *color) {
    UIGraphicsBeginImageContextWithOptions(
        CGSizeMake(size,size),NO,0);
    CGContextRef c=UIGraphicsGetCurrentContext();
    CGContextScaleCTM(c,size/24.0,size/24.0);

    CGContextSetStrokeColorWithColor(c,color.CGColor);
    CGContextSetLineWidth(c,2.0);
    CGContextSetLineCap(c,kCGLineCapRound);
    CGContextSetLineJoin(c,kCGLineJoinRound);

    if (type==PCLProfileAuthMicrosoft) {
        CGContextMoveToPoint(c,20,13);
        CGContextAddCurveToPoint(c,20,17.3,17.2,20.3,12,22);
        CGContextAddCurveToPoint(c,6.8,20.3,4,17.3,4,13);
        CGContextAddLineToPoint(c,4,6);

        CGContextAddCurveToPoint(c,4,5.4,4.4,5,5,5);
        CGContextAddCurveToPoint(c,7.3,5,9.7,3.8,11.3,2.4);
        CGContextAddCurveToPoint(c,11.7,2.1,12.3,2.1,12.7,2.4);
        CGContextAddCurveToPoint(c,14.3,3.8,16.7,5,19,5);
        CGContextAddCurveToPoint(c,19.6,5,20,5.4,20,6);
        CGContextClosePath(c);
        CGContextStrokePath(c);

        CGContextMoveToPoint(c,9,12);
        CGContextAddLineToPoint(c,11,14);
        CGContextAddLineToPoint(c,15,10);
        CGContextStrokePath(c);
    }

    if (type==PCLProfileAuthThirdParty) {
        for (NSValue *v in @[
            [NSValue valueWithCGRect:CGRectMake(16,16,6,6)],
            [NSValue valueWithCGRect:CGRectMake(2,16,6,6)],
            [NSValue valueWithCGRect:CGRectMake(9,2,6,6)]]) {
            UIBezierPath *r=[UIBezierPath bezierPathWithRoundedRect:
                v.CGRectValue cornerRadius:1];
            r.lineWidth=2; [color setStroke]; [r stroke];
        }

        CGContextMoveToPoint(c,5,16);
        CGContextAddLineToPoint(c,5,13);
        CGContextAddQuadCurveToPoint(c,5,12,6,12);
        CGContextAddLineToPoint(c,18,12);
        CGContextAddQuadCurveToPoint(c,19,12,19,13);
        CGContextAddLineToPoint(c,19,16);
        CGContextMoveToPoint(c,12,12);
        CGContextAddLineToPoint(c,12,8);
        CGContextStrokePath(c);
    }

    if (type==PCLProfileAuthOffline) {
        CGContextMoveToPoint(c,9,17);
        CGContextAddLineToPoint(c,7,17);
        CGContextAddCurveToPoint(c,4.2,17,2,14.8,2,12);
        CGContextAddCurveToPoint(c,2,9.2,4.2,7,7,7);
        CGContextMoveToPoint(c,15,7);
        CGContextAddLineToPoint(c,17,7);

        CGContextAddCurveToPoint(c,19.8,7,22,9.2,22,12);
        CGContextAddCurveToPoint(c,22,13.1,21.6,14.1,21,15);
        CGContextMoveToPoint(c,8,12);
        CGContextAddLineToPoint(c,12,12);
        CGContextMoveToPoint(c,2,2);
        CGContextAddLineToPoint(c,22,22);
        CGContextStrokePath(c);
    }

    UIImage *image=UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}


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
    b.layer.borderColor=
        [UIColor colorWithWhite:.42 alpha:1].CGColor;
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
        type:PCLProfileAuthMicrosoft];
    UIButton *off=[self row:@"离线验证"
        type:PCLProfileAuthOffline];
    UIButton *auth=[self row:@"第三方验证"
        type:PCLProfileAuthThirdParty];

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
             type:(PCLProfileAuthType)type {
    UIButton *b=[UIButton buttonWithType:UIButtonTypeCustom];
    b.tag=100+type;
    b.contentHorizontalAlignment=
        UIControlContentHorizontalAlignmentLeft;

    UIColor *gray=[UIColor colorWithWhite:.27 alpha:1];
    [b setTitle:title forState:UIControlStateNormal];
    [b setTitleColor:gray forState:UIControlStateNormal];
    b.layer.cornerRadius=6;
    b.adjustsImageWhenHighlighted=NO;

    UIView *check=[[UIView alloc] init];
    check.tag=9001;
    check.hidden=YES;
    check.backgroundColor=
        [UIColor colorWithRed:.075 green:.44 blue:.95 alpha:1];
    check.layer.cornerRadius=2;
    check.userInteractionEnabled=NO;
    [b addSubview:check];

    [b addTarget:self action:@selector(rowPressed:)
        forControlEvents:UIControlEventTouchUpInside];
    return b;
}

- (void)refreshRows {
    CGFloat s=self.scale>0 ? self.scale : 1;
    UIColor *blue=[UIColor colorWithRed:.075 green:.44 blue:.95 alpha:1];
    UIColor *gray=[UIColor colorWithWhite:.27 alpha:1];

    for (UIButton *row in self.rows) {
        BOOL on=(row.tag-100)==self.selected;
        UIColor *c=on ? blue : gray;

        row.titleLabel.font=
            [UIFont systemFontOfSize:15*s
                              weight:UIFontWeightRegular];
        row.titleLabel.adjustsFontSizeToFitWidth=NO;
        row.titleLabel.minimumScaleFactor=1.0;

        for (NSNumber *state in @[@0,@1,@4]) {
            [row setTitleColor:c
                      forState:state.unsignedIntegerValue];
        }

        UIImage *icon=PCLAuthIcon(row.tag-100,26*s,c);

        [row setImage:icon forState:UIControlStateNormal];
        [row setImage:icon forState:UIControlStateHighlighted];
        [row setImage:icon forState:UIControlStateSelected];

        [row viewWithTag:9001].hidden=!on;
        row.backgroundColor=on
            ? [blue colorWithAlphaComponent:.055]
            : UIColor.clearColor;
    }
}

- (void)rowPressed:(UIButton *)sender {
    self.selected=sender.tag-100;
    [self refreshRows];

    UIColor *blue=
        [UIColor colorWithRed:.075 green:.44 blue:.95 alpha:1];

    self.continueButton.enabled=YES;
    self.continueButton.alpha=1;

    self.continueButton.layer.borderColor=blue.CGColor;
    [self.continueButton setTitleColor:blue
                              forState:UIControlStateNormal];
}

- (void)presentInView:(UIView *)view {
    self.frame=view.bounds;
    self.autoresizingMask=
        UIViewAutoresizingFlexibleWidth |
        UIViewAutoresizingFlexibleHeight;
    [view addSubview:self];
    [self layoutIfNeeded];

    CGFloat r=-4.0*M_PI/180.0;
    self.card.transform=
        CGAffineTransformRotate(
            CGAffineTransformMakeTranslation(0,40*self.scale),r);
    self.card.alpha=0;

    [UIView animateWithDuration:.20 animations:^{
        self.backgroundColor=[UIColor colorWithWhite:0 alpha:90.0/255.0];
    }];

    [UIView animateWithDuration:.12 delay:.06
        options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.card.alpha=1;
    } completion:nil];

    [UIView animateKeyframesWithDuration:.30 delay:.06
        options:UIViewKeyframeAnimationOptionCalculationModeCubic
        animations:^{
        [UIView addKeyframeWithRelativeStartTime:0 duration:.78 animations:^{
            self.card.transform=
                CGAffineTransformMakeTranslation(0,-2*self.scale);
        }];

        [UIView addKeyframeWithRelativeStartTime:.78 duration:.22 animations:^{
            self.card.transform=CGAffineTransformIdentity;
        }];
    } completion:nil];
}


        [UIView addKeyframeWithRelativeStartTime:.78 duration:.22 animations:^{
            self.card.transform=CGAffineTransformIdentity;
        }];
    } completion:nil];
}

- (void)dismissWithType:(NSInteger)type {
    CGFloat r=6.0*M_PI/180.0;
    CGAffineTransform out=
        CGAffineTransformRotate(
            CGAffineTransformMakeTranslation(0,20*self.scale),r);

    UIViewAnimationOptions opt=
        UIViewAnimationOptionBeginFromCurrentState |
        UIViewAnimationOptionAllowUserInteraction |
        UIViewAnimationOptionCurveEaseOut;

    [UIView animateWithDuration:.15 delay:0 options:opt animations:^{
        self.card.transform=out;
    } completion:nil];

    [UIView animateWithDuration:.08 delay:.02 options:opt animations:^{
        self.card.alpha=0;
    } completion:nil];

    [UIView animateWithDuration:.20 delay:.03 options:opt animations:^{
        self.backgroundColor=UIColor.clearColor;
    } completion:^(BOOL done) {
        [self removeFromSuperview];

        if (type>=0) {
            if (self.onSelect) self.onSelect(type);
        } else if (self.onCancel) {
            self.onCancel();
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
        row.frame=CGRectMake(
            29*s,(78+42*i)*s,cw-58*s,42*s);
        row.layer.cornerRadius=6*s;
        row.titleLabel.font=
            [UIFont systemFontOfSize:15*s
                weight:UIFontWeightRegular];
        row.contentEdgeInsets=
            UIEdgeInsetsMake(0,8*s,0,8*s);
        row.titleEdgeInsets=
            UIEdgeInsetsMake(0,5*s,0,0);
        UIView *check=[row viewWithTag:9001];
        check.frame=CGRectMake(-1*s,6*s,5*s,30*s);
        check.layer.cornerRadius=2*s;
    }


    self.continueButton.titleLabel.font=
        [UIFont systemFontOfSize:13*s];
    self.cancelButton.titleLabel.font=
        [UIFont systemFontOfSize:13*s];

    [self refreshRows];

    CGFloat bw=66*s;
    CGFloat by=ch-51*s;

    self.cancelButton.frame=
        CGRectMake(cw-30*s-bw,by,bw,30*s);

    self.continueButton.frame=
        CGRectMake(cw-42*s-bw*2,by,bw,30*s);
}
@end
