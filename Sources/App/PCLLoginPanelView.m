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
    b.layer.borderWidth=1;
    b.layer.borderColor=PCLLoginColor(0x8A8A8A).CGColor;
    b.layer.cornerRadius=3;
    return b;
}

- (UITextField *)field:(NSString *)placeholder {
    UITextField *f=[[UITextField alloc] init];
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


- (void)buildMicrosoftPage {

    self.msPage=[[UIView alloc] init];

    [self addSubview:self.msPage];

    UIImageView *icon=[[UIImageView alloc] initWithImage:

        [UIImage systemImageNamed:@"person.crop.circle"]];

    icon.tag=200;

    icon.tintColor=PCLLoginColor(0x4B5D73);

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
    buy.alpha=.35;
    web.alpha=.35;
    buy.layer.borderWidth=0;
    web.layer.borderWidth=0;
    buy.alpha=.35;
    web.alpha=.35;
    [self.msPage addSubview:buy];
    [self.msPage addSubview:web];

    UIButton *back=[self button:@"«  返回"];
    back.tag=204;
    back.layer.borderWidth=0;
    back.alpha=.35;
    back.layer.borderWidth=0;
    back.alpha=.35;
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
    UIButton *b302=[self button:@"行业规范"];
    b302.tag=302;
    [self.offlinePage addSubview:b302];
    UIButton *b303=[self button:@"旧版"];
    b303.tag=303;
    [self.offlinePage addSubview:b303];
    UIButton *b304=[self button:@"自定义"];
    b304.tag=304;
    [self.offlinePage addSubview:b304];

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
- (void)showOffline { [self showPage:self.offlinePage]; }
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
    msIcon.frame=CGRectMake((w-40*s)/2,20*s,40*s,40*s);

    UIButton *ms=[self.msPage viewWithTag:201];
    ms.frame=CGRectMake((w-120*s)/2,84*s,120*s,30*s);

    UIButton *buy=[self.msPage viewWithTag:202];
    UIButton *web=[self.msPage viewWithTag:203];
    buy.frame=CGRectMake(22*s,135*s,100*s,28*s);
    web.frame=CGRectMake(w-122*s,135*s,100*s,28*s);

    UIButton *msBack=[self.msPage viewWithTag:204];
    msBack.frame=CGRectMake((w-70*s)/2,184*s,70*s,28*s);

    UILabel *name=[self.offlinePage viewWithTag:300];
    name.frame=CGRectMake(0,20*s,55*s,28*s);
    self.offlineName.frame=CGRectMake(60*s,20*s,w-60*s,28*s);

    UILabel *uuid=[self.offlinePage viewWithTag:301];
    uuid.frame=CGRectMake(55*s,64*s,w-55*s,22*s);

    CGFloat bw=(w-60*s)/3;
    for (NSInteger i=0;i<3;i++) {
        UIButton *b=[self.offlinePage viewWithTag:302+i];
        b.frame=CGRectMake((50+i*bw)*s,94*s,bw-5*s,26*s);
    }

    UIButton *ob=[self.offlinePage viewWithTag:305];
    UIButton *oc=[self.offlinePage viewWithTag:306];
    ob.frame=CGRectMake(w/2-65*s,160*s,55*s,28*s);
    oc.frame=CGRectMake(w/2+10*s,160*s,55*s,28*s);

    self.authServer.frame=CGRectMake(55*s,20*s,w-55*s,28*s);

    self.authEmail.frame=CGRectMake(55*s,60*s,w-55*s,28*s);
    self.authPassword.frame=CGRectMake(55*s,100*s,w-55*s,28*s);

    UIButton *reg=[self.authPage viewWithTag:403];
    reg.frame=CGRectMake(w-90*s,134*s,90*s,26*s);

    UIButton *ab=[self.authPage viewWithTag:404];
    UIButton *al=[self.authPage viewWithTag:405];
    ab.frame=CGRectMake(w/2-65*s,174*s,55*s,28*s);
    al.frame=CGRectMake(w/2+10*s,174*s,55*s,28*s);

    self.statusLabel.font=[UIFont systemFontOfSize:11*s];
    self.statusLabel.frame=CGRectMake(0,215*s,w,18*s);
}

@end
