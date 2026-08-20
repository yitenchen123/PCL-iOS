#import "PCLLoginPanelView.h"

static UIColor *PCLLoginColor(NSUInteger rgb) {
    return [UIColor colorWithRed:((rgb>>16)&255)/255.0
        green:((rgb>>8)&255)/255.0 blue:(rgb&255)/255.0 alpha:1];
}


@interface PCLLoginPanelView ()


@property(nonatomic,strong) UIView *msPage;

@property(nonatomic,strong) UIView *offlinePage;

@property(nonatomic,strong) UIView *authPage;

@property(nonatomic,strong) UILabel *statusLabel;


@property(nonatomic,strong) UITextField *offlineName;
@property(nonatomic,strong) UILabel *offlineUuidTitle;
@property(nonatomic,strong) UITextField *offlineUuid;
@property(nonatomic) NSInteger uuidMode;
@property(nonatomic,strong) UITextField *authServer;
@property(nonatomic,strong) UITextField *authEmail;
@property(nonatomic,strong) UITextField *authPassword;
@end

@implementation PCLLoginPanelView

- (instancetype)initWithFrame:(CGRect)frame {
    self=[super initWithFrame:frame];
    if (!self) return nil;
    [self buildMicrosoftPage];
    [self buildOfflinePage];
    [self buildAuthPage];
    return self;
}

- (UIButton *)button:(NSString *)text {
    UIButton *b=[UIButton buttonWithType:UIButtonTypeCustom];
    [b setTitle:text forState:UIControlStateNormal];
    [b setTitleColor:PCLLoginColor(0x343D4A)
             forState:UIControlStateNormal];
    b.titleLabel.font=[UIFont systemFontOfSize:13];
    b.layer.borderWidth=1;
    b.layer.borderColor=PCLLoginColor(0x8A8A8A).CGColor;
    b.layer.cornerRadius=3;
    return b;
}

- (UITextField *)field:(NSString *)placeholder {
    UITextField *f=[[UITextField alloc] init];
    f.font=[UIFont systemFontOfSize:13];
    f.placeholder=placeholder;
    f.borderStyle=UITextBorderStyleNone;
    f.layer.borderWidth=1;
    f.layer.borderColor=PCLLoginColor(0xAAAAAA).CGColor;
    f.layer.cornerRadius=3;
    f.leftView=[[UIView alloc] initWithFrame:CGRectMake(0,0,8,1)];
    f.leftViewMode=UITextFieldViewModeAlways;
    return f;
}

- (void)showPage:(UIView *)page {
    self.msPage.hidden=page!=self.msPage;
    self.offlinePage.hidden=page!=self.offlinePage;
    self.authPage.hidden=page!=self.authPage;
    self.statusLabel.text=@"";
}


- (UIButton *)radio:(NSString *)text {
    UIButton *b=[UIButton buttonWithType:UIButtonTypeCustom];
    [b setTitle:text forState:UIControlStateNormal];
    [b setTitleColor:PCLLoginColor(0x343D4A)
             forState:UIControlStateNormal];
    b.titleLabel.font=[UIFont systemFontOfSize:12];
    b.contentHorizontalAlignment=
        UIControlContentHorizontalAlignmentLeft;

    UIView *ring=[[UIView alloc] init];
    ring.tag=9301;
    ring.layer.borderWidth=1.3;
    ring.layer.cornerRadius=5;
    [b addSubview:ring];

    UIView *dot=[[UIView alloc] init];
    dot.tag=9302;

    dot.layer.cornerRadius=2.5;
    dot.hidden=YES;
    dot.backgroundColor=PCLLoginColor(0x1370F3);
    [ring addSubview:dot];
    return b;
}

- (void)buildMicrosoftPage {

    self.msPage=[[UIView alloc] init];

    [self addSubview:self.msPage];

    UIImageView *icon=[[UIImageView alloc] initWithImage:

        [UIImage systemImageNamed:@"person"]];

    icon.tag=200;

    icon.tintColor=PCLLoginColor(0x4B5D73);
    icon.alpha=0.7;
    icon.contentMode=UIViewContentModeScaleAspectFit;

    [self.msPage addSubview:icon];


    UIButton *login=[self button:@"开始正版验证"];
    login.tag=201;
    login.layer.borderColor=PCLLoginColor(0x0B5BCB).CGColor;
    [login setTitleColor:PCLLoginColor(0x0B5BCB)
                forState:UIControlStateNormal];
    [login addTarget:self action:@selector(msStart)
        forControlEvents:UIControlEventTouchUpInside];
    [self.msPage addSubview:login];

    UIButton *buy=[self button:@"»  购买正版"];
    buy.tag=202;
    UIButton *web=[self button:@"»  前往官网"];
    web.tag=203;
    buy.layer.borderWidth=0;
    web.layer.borderWidth=0;
    buy.alpha=.30;
    web.alpha=.30;
    buy.layer.borderWidth=0;
    web.layer.borderWidth=0;
    buy.alpha=.30;
    web.alpha=.30;
    [self.msPage addSubview:buy];
    [self.msPage addSubview:web];

    UIButton *back=[self button:@"«  返回"];
    back.tag=204;
    back.layer.borderWidth=0;
    back.alpha=.30;
    back.layer.borderWidth=0;
    back.alpha=.30;
    [back addTarget:self action:@selector(closePressed)
        forControlEvents:UIControlEventTouchUpInside];
    [self.msPage addSubview:back];
}

- (void)buildOfflinePage {
    self.offlinePage=[[UIView alloc] init];
    [self addSubview:self.offlinePage];

    UILabel *name=[[UILabel alloc] init];
    name.tag=300;
    name.text=@"玩家 ID";
    [self.offlinePage addSubview:name];

    self.offlineName=[self field:@"3 - 16 位玩家 ID"];
    [self.offlinePage addSubview:self.offlineName];

    UILabel *uuid=[[UILabel alloc] init];
    uuid.tag=301;
    uuid.text=@"UUID 标准";
    uuid.textAlignment=NSTextAlignmentCenter;
    [self.offlinePage addSubview:uuid];
    NSArray *names=@[@"行业规范",@"旧版",@"自定义"];
    for (NSInteger i=0;i<3;i++) {
        UIButton *b=[self radio:names[i]];
        b.tag=302+i;
        [b addTarget:self action:@selector(uuidPressed:)
            forControlEvents:UIControlEventTouchUpInside];
        [self.offlinePage addSubview:b];
    }

    self.offlineUuidTitle=[[UILabel alloc] init];
    self.offlineUuidTitle.text=@"UUID";
    self.offlineUuid=[self field:nil];
    [self.offlinePage addSubview:self.offlineUuidTitle];
    [self.offlinePage addSubview:self.offlineUuid];

    UIButton *back=[self button:@"返回"];
    back.tag=305;
    [back addTarget:self action:@selector(closePressed)
        forControlEvents:UIControlEventTouchUpInside];

    UIButton *create=[self button:@"创建"];
    create.tag=306;

    [create addTarget:self action:@selector(createOffline)
        forControlEvents:UIControlEventTouchUpInside];
    [self.offlinePage addSubview:back];
    [self.offlinePage addSubview:create];
}

- (void)buildAuthPage {
    self.authPage=[[UIView alloc] init];
    [self addSubview:self.authPage];

    self.authServer=[self field:@"验证服务器"];
    self.authEmail=[self field:@"邮箱"];
    self.authPassword=[self field:@"密码"];
    self.authPassword.secureTextEntry=YES;
    self.authServer.placeholder=nil;
    self.authEmail.placeholder=nil;
    self.authPassword.placeholder=nil;

    NSArray *labels=@[@"服务器",@"邮箱",@"密码"];
    for (NSInteger i=0;i<3;i++) {
        UILabel *label=[[UILabel alloc] init];
        label.tag=410+i;
        label.text=labels[i];
        [self.authPage addSubview:label];
    }


    [self.authPage addSubview:self.authServer];
    [self.authPage addSubview:self.authEmail];
    [self.authPage addSubview:self.authPassword];

    UIButton *reg=[self button:@"注册账号"];
    reg.tag=403;
    reg.layer.borderWidth=0;
    [self.authPage addSubview:reg];

    UIButton *back=[self button:@"返回"];
    back.tag=404;
    [back addTarget:self action:@selector(closePressed)
        forControlEvents:UIControlEventTouchUpInside];

    UIButton *login=[self button:@"登录"];
    login.tag=405;

    [login addTarget:self action:@selector(authLogin)
        forControlEvents:UIControlEventTouchUpInside];
    [self.authPage addSubview:back];
    [self.authPage addSubview:login];

    self.statusLabel=[[UILabel alloc] init];
    self.statusLabel.textAlignment=NSTextAlignmentCenter;
    [self addSubview:self.statusLabel];
}

- (void)showMicrosoft { [self showPage:self.msPage]; }
- (void)showOffline {
    [self showPage:self.offlinePage];
    self.uuidMode=0;
    [self uuidPressed:[self.offlinePage viewWithTag:302]];
}
- (void)showThirdParty { [self showPage:self.authPage]; }

- (void)closePressed {
    if (self.onClose) self.onClose();
}

- (void)msStart {
    self.statusLabel.text=@"正版验证接口正在接入";
}

- (void)authLogin {
    self.statusLabel.text=@"第三方验证接口正在接入";
}

- (void)uuidPressed:(UIButton *)sender {
    self.uuidMode=sender.tag-302;
    UIColor *blue=PCLLoginColor(0x1370F3);

    for (NSInteger i=0;i<3;i++) {
        UIButton *b=[self.offlinePage viewWithTag:302+i];
        BOOL on=i==self.uuidMode;

        UIView *ring=[b viewWithTag:9301];
        UIView *dot=[b viewWithTag:9302];
        ring.layer.borderColor=
            (on ? blue : PCLLoginColor(0x777777)).CGColor;
        dot.hidden=!on;
    }

    BOOL custom=self.uuidMode==2;

    self.offlineUuidTitle.hidden=!custom;
    self.offlineUuid.hidden=!custom;
}

- (void)createOffline {
    NSString *name=[self.offlineName.text
        stringByTrimmingCharactersInSet:
            NSCharacterSet.whitespaceAndNewlineCharacterSet];

    NSPredicate *rule=[NSPredicate predicateWithFormat:
        @"SELF MATCHES %@",@"[A-Za-z0-9_]{3,16}"];


    if (![rule evaluateWithObject:name]) {

        self.statusLabel.text=@"玩家 ID 不符合规范";

        return;

    }

    if (self.onOfflineCreate)

        self.onOfflineCreate(name);

}


- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat s=self.designScale>0 ? self.designScale : 1;
    CGFloat w=CGRectGetWidth(self.bounds);

    for (UIView *p in @[
        self.msPage,self.offlinePage,self.authPage])
        p.frame=self.bounds;


    UIImageView *msIcon=[self.msPage viewWithTag:200];
    msIcon.frame=CGRectMake((w-40*s)/2,10*s,40*s,40*s);

    UIButton *ms=[self.msPage viewWithTag:201];
    ms.frame=CGRectMake((w-100*s)/2,75*s,100*s,28*s);

    UIButton *buy=[self.msPage viewWithTag:202];
    UIButton *web=[self.msPage viewWithTag:203];
    buy.frame=CGRectMake(22*s,133*s,100*s,24*s);
    web.frame=CGRectMake(w-122*s,133*s,100*s,24*s);

    UIButton *msBack=[self.msPage viewWithTag:204];
    msBack.frame=CGRectMake((w-70*s)/2,183*s,70*s,24*s);

    UILabel *name=[self.offlinePage viewWithTag:300];
    name.frame=CGRectMake(0,8*s,50*s,28*s);
    self.offlineName.frame=CGRectMake(50*s,8*s,w-50*s,28*s);

    UILabel *uuid=[self.offlinePage viewWithTag:301];
    uuid.frame=CGRectMake(5*s,54*s,w-50*s,22*s);

    CGFloat bw=(w-10*s)/3;
    for (NSInteger i=0;i<3;i++) {
        UIButton *b=[self.offlinePage viewWithTag:302+i];
        b.frame=CGRectMake((5+i*bw)*s,80*s,bw,22*s);
        UIView *ring=[b viewWithTag:9301];
        ring.frame=CGRectMake(4*s,6*s,10*s,10*s);
        [ring viewWithTag:9302].frame=CGRectMake(2.5*s,2.5*s,5*s,5*s);
        b.titleEdgeInsets=UIEdgeInsetsMake(0,18*s,0,0);
    }

    self.offlineUuidTitle.frame=
        CGRectMake(0,118*s,50*s,28*s);
    self.offlineUuid.frame=
        CGRectMake(50*s,118*s,w-50*s,28*s);

    UIButton *ob=[self.offlinePage viewWithTag:305];
    UIButton *oc=[self.offlinePage viewWithTag:306];
    ob.frame=CGRectMake(80*s,168*s,50*s,28*s);
    oc.frame=CGRectMake(140*s,168*s,50*s,28*s);

    self.authServer.frame=CGRectMake(50*s,10*s,w-50*s,28*s);

    self.authEmail.frame=CGRectMake(50*s,48*s,w-50*s,28*s);
    self.authPassword.frame=CGRectMake(50*s,86*s,w-50*s,28*s);

    for (NSInteger i=0;i<3;i++) {
        UILabel *label=[self.authPage viewWithTag:410+i];
        label.font=[UIFont systemFontOfSize:13*s];
        label.frame=CGRectMake(0,(10+38*i)*s,50*s,28*s);
    }

    UIButton *reg=[self.authPage viewWithTag:403];
    reg.frame=CGRectMake(w-90*s,126*s,90*s,24*s);

    UIButton *ab=[self.authPage viewWithTag:404];
    UIButton *al=[self.authPage viewWithTag:405];
    ab.frame=CGRectMake(80*s,166*s,50*s,28*s);
    al.frame=CGRectMake(140*s,166*s,50*s,28*s);

    self.statusLabel.font=[UIFont systemFontOfSize:11*s];
    self.statusLabel.frame=CGRectMake(0,215*s,w,18*s);
}

@end
