#import "PCLLoginPanelView.h"
#import "PCLAccountAuthenticator.h"

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
@property(nonatomic,strong) PCLAccountAuthenticator *microsoftAuth;
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
    [b setTitleColor:PCLLoginColor(0x1370F3)
             forState:UIControlStateHighlighted];
    [b setTitleColor:PCLLoginColor(0xA6A6A6)
             forState:UIControlStateDisabled];
    b.titleLabel.font=[UIFont systemFontOfSize:13];
    b.layer.borderWidth=1;
    b.layer.borderColor=PCLLoginColor(0x8A8A8A).CGColor;
    b.layer.cornerRadius=3;
    return b;
}

- (UITextField *)field:(NSString *)placeholder {
    UITextField *f=[[UITextField alloc] init];
    f.font=[UIFont systemFontOfSize:13];
    f.textColor=PCLLoginColor(0x343D4A);
    f.tintColor=PCLLoginColor(0x1370F3);
    f.backgroundColor=
        [UIColor colorWithWhite:1 alpha:0.42];
    f.keyboardAppearance=UIKeyboardAppearanceLight;
    if (placeholder.length) {
        f.attributedPlaceholder=
            [[NSAttributedString alloc] initWithString:placeholder
            attributes:@{NSForegroundColorAttributeName:
                PCLLoginColor(0x8C8C8C)}];
    }
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
    b.titleLabel.font=[UIFont systemFontOfSize:13];
    [b setTitleColor:PCLLoginColor(0x343D4A)
             forState:UIControlStateHighlighted];
    [b setTitleColor:PCLLoginColor(0x343D4A)
             forState:UIControlStateSelected];
    b.contentHorizontalAlignment=
        UIControlContentHorizontalAlignmentLeft;

    UIView *ring=[[UIView alloc] init];
    ring.tag=9301;
    ring.layer.borderWidth=1.3;
    ring.layer.cornerRadius=5;
    ring.backgroundColor=
        [UIColor colorWithWhite:1 alpha:.45];
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
    back.alpha=1.0;
    [back setTitleColor:PCLLoginColor(0x343D4A)
               forState:UIControlStateNormal];
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
    UIImageView *drop=[[UIImageView alloc]
        initWithImage:[UIImage systemImageNamed:@"chevron.down"]];
    drop.tintColor=PCLLoginColor(0x777777);
    drop.contentMode=UIViewContentModeCenter;
    drop.frame=CGRectMake(0,0,28,28);
    self.authServer.rightView=drop;
    self.authServer.rightViewMode=
        UITextFieldViewModeAlways;
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
    reg.hidden=YES;
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
    self.statusLabel.textColor=PCLLoginColor(0x343D4A);
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

- (void)saveProfile:(NSDictionary *)profile {
    NSUserDefaults *d=NSUserDefaults.standardUserDefaults;

    [d setObject:profile[@"username"]
          forKey:@"PCLProfileUsername"];
    [d setObject:profile[@"uuid"]
          forKey:@"PCLProfileUUID"];
    [d setObject:profile[@"type"]
          forKey:@"PCLProfileType"];

    NSString *server=profile[@"server"];
    NSString *prefix=profile[@"credentialPrefix"];

    if (server) [d setObject:server forKey:@"PCLProfileServer"];
    else [d removeObjectForKey:@"PCLProfileServer"];

    if (prefix) [d setObject:prefix forKey:@"PCLCredentialPrefix"];
    else [d removeObjectForKey:@"PCLCredentialPrefix"];

    if (self.onProfileCreated)
        self.onProfileCreated();
}

- (void)setStatus:(NSString *)text error:(BOOL)error {
    self.statusLabel.text=text ?: @"";
    self.statusLabel.textColor=
        error ? PCLLoginColor(0xD84545)
              : PCLLoginColor(0x343D4A);
}

- (void)msStart {
    UIButton *button=[self.msPage viewWithTag:201];
    button.enabled=NO;

    self.microsoftAuth=
        [[PCLAccountAuthenticator alloc] initWithAnchorView:self];

    __weak typeof(self) weakSelf=self;
    [self.microsoftAuth
        startMicrosoftWithStatus:^(NSString *text) {
            [weakSelf setStatus:text error:NO];
        } completion:^(NSDictionary *profile, NSString *error) {
            button.enabled=YES;
            if (profile) [weakSelf saveProfile:profile];
            else [weakSelf setStatus:error error:YES];
            weakSelf.microsoftAuth=nil;
        }];
}

- (void)authLogin {
    NSString *server=[self.authServer.text
        stringByTrimmingCharactersInSet:
            NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSString *user=[self.authEmail.text
        stringByTrimmingCharactersInSet:
            NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSString *pass=self.authPassword.text;

    if (!server.length || !user.length || !pass.length) {
        [self setStatus:@"服务器、邮箱与密码不能为空" error:YES];
        return;
    }

    UIButton *login=[self.authPage viewWithTag:405];
    login.enabled=NO;

    __weak typeof(self) weakSelf=self;
    [PCLAccountAuthenticator
        loginAuthlibServer:server username:user password:pass
        status:^(NSString *text) {
            [weakSelf setStatus:text error:NO];
        } completion:^(NSDictionary *profile, NSString *error) {
            login.enabled=YES;
            if (profile) {
                weakSelf.authPassword.text=@"";
                [weakSelf saveProfile:profile];
            } else {
                [weakSelf setStatus:error error:YES];
            }
        }];
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
    [self setNeedsLayout];
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

    NSString *uuid=nil;

    if (self.uuidMode==2) {
        uuid=[self.offlineUuid.text
            stringByReplacingOccurrencesOfString:@"-" withString:@""];
        NSPredicate *hex=[NSPredicate predicateWithFormat:
            @"SELF MATCHES %@",@"[0-9A-Fa-f]{32}"];
        if (![hex evaluateWithObject:uuid]) {
            [self setStatus:@"自定义 UUID 必须为 32 位十六进制" error:YES];
            return;
        }
    } else {
        uuid=[PCLAccountAuthenticator offlineUUIDForName:name
            legacy:self.uuidMode==1];
    }

    [self saveProfile:@{
        @"username":name,
        @"uuid":uuid,
        @"type":@"offline"
    }];

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
    ms.titleLabel.font=
        [UIFont systemFontOfSize:14*s];

    UIButton *buy=[self.msPage viewWithTag:202];
    UIButton *web=[self.msPage viewWithTag:203];
    buy.frame=CGRectMake(22*s,133*s,100*s,24*s);
    web.frame=CGRectMake(w-122*s,133*s,100*s,24*s);

    buy.titleLabel.font=[UIFont systemFontOfSize:13*s];
    web.titleLabel.font=[UIFont systemFontOfSize:13*s];

    UIButton *msBack=[self.msPage viewWithTag:204];
    msBack.frame=CGRectMake((w-70*s)/2,183*s,70*s,24*s);
    msBack.titleLabel.font=
        [UIFont systemFontOfSize:13*s];

    UILabel *name=[self.offlinePage viewWithTag:300];
    name.textColor=PCLLoginColor(0x343D4A);
    UILabel *uuid=[self.offlinePage viewWithTag:301];
    uuid.textColor=PCLLoginColor(0x343D4A);
    self.offlineUuidTitle.textColor=PCLLoginColor(0x343D4A);
    name.font=[UIFont systemFontOfSize:13*s];
    self.offlineName.font=[UIFont systemFontOfSize:13*s];
    self.offlineUuidTitle.font=[UIFont systemFontOfSize:13*s];
    self.offlineUuid.font=[UIFont systemFontOfSize:13*s];
    name.frame=CGRectMake(0,0,50*s,28*s);
    self.offlineName.frame=CGRectMake(50*s,0,w-50*s,28*s);

    uuid.frame=CGRectMake(5*s,38*s,w-50*s,22*s);

    uuid.font=[UIFont systemFontOfSize:13*s
                                weight:UIFontWeightSemibold];

    CGFloat bw=(w-10*s)/3;
    for (NSInteger i=0;i<3;i++) {
        UIButton *b=[self.offlinePage viewWithTag:302+i];
        b.frame=CGRectMake(5*s+i*bw,58*s,bw,22*s);
        UIView *ring=[b viewWithTag:9301];
        ring.frame=CGRectMake(1*s,2*s,18*s,18*s);
        ring.layer.cornerRadius=9*s;
        ring.layer.borderWidth=1.1*s;
        UIView *dot=[ring viewWithTag:9302];
        dot.frame=CGRectMake(4.5*s,4.5*s,9*s,9*s);
        dot.layer.cornerRadius=4.5*s;
        b.titleLabel.font=[UIFont systemFontOfSize:13*s];
        b.titleEdgeInsets=UIEdgeInsetsMake(0,26*s,0,0);
    }

    self.offlineUuidTitle.frame=
        CGRectMake(0,94*s,50*s,28*s);
    self.offlineUuid.frame=
        CGRectMake(50*s,94*s,w-50*s,28*s);

    UIButton *ob=[self.offlinePage viewWithTag:305];
    UIButton *oc=[self.offlinePage viewWithTag:306];
    ob.titleLabel.font=[UIFont systemFontOfSize:13*s];
    oc.titleLabel.font=[UIFont systemFontOfSize:13*s];
    CGFloat offlineButtonY=
        (self.uuidMode==2 ? 132.0 : 104.0)*s;
    ob.frame=CGRectMake(80*s,offlineButtonY,50*s,28*s);
    oc.frame=CGRectMake(140*s,offlineButtonY,50*s,28*s);

    self.authServer.frame=CGRectMake(50*s,26*s,w-50*s,28*s);

    self.authEmail.frame=CGRectMake(50*s,64*s,w-50*s,28*s);
    self.authPassword.frame=CGRectMake(50*s,102*s,w-50*s,28*s);

    self.authServer.font=[UIFont systemFontOfSize:13*s];
    self.authEmail.font=[UIFont systemFontOfSize:13*s];
    self.authPassword.font=[UIFont systemFontOfSize:13*s];

    for (NSInteger i=0;i<3;i++) {
        UILabel *label=[self.authPage viewWithTag:410+i];
        label.font=[UIFont systemFontOfSize:13*s];
        label.textColor=PCLLoginColor(0x343D4A);
        label.frame=CGRectMake(0,(26+38*i)*s,50*s,28*s);
    }

    UIButton *reg=[self.authPage viewWithTag:403];
    reg.frame=CGRectMake(w-90*s,126*s,90*s,24*s);

    UIButton *ab=[self.authPage viewWithTag:404];
    UIButton *al=[self.authPage viewWithTag:405];
    ab.titleLabel.font=[UIFont systemFontOfSize:13*s];
    al.titleLabel.font=[UIFont systemFontOfSize:13*s];
    ab.frame=CGRectMake(80*s,150*s,50*s,28*s);
    al.frame=CGRectMake(140*s,150*s,50*s,28*s);

    self.statusLabel.font=[UIFont systemFontOfSize:11*s];
    self.statusLabel.frame=CGRectMake(0,215*s,w,18*s);
}

@end
