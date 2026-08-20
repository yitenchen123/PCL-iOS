#import "PCLLoginPanelView.h"
#import "PCLAccountAuthenticator.h"
#import "PCLProfileStore.h"

static UIColor *PCLLoginColor(NSUInteger rgb) {
    return [UIColor colorWithRed:((rgb>>16)&255)/255.0
        green:((rgb>>8)&255)/255.0 blue:(rgb&255)/255.0 alpha:1];
}


@interface PCLLoginPanelView ()


@property(nonatomic,strong) UIView *msPage;

@property(nonatomic,strong) UIView *offlinePage;

@property(nonatomic,strong) UIView *authPage;
@property(nonatomic,weak) UIView *currentPage;

@property(nonatomic,strong) UILabel *statusLabel;


@property(nonatomic,strong) UITextField *offlineName;
@property(nonatomic,strong) UILabel *offlineUuidTitle;
@property(nonatomic,strong) UITextField *offlineUuid;
@property(nonatomic) NSInteger uuidMode;
@property(nonatomic,copy) NSString *editingProfileIdentifier;
@property(nonatomic,strong) UITextField *authServer;
@property(nonatomic,strong) UITextField *authEmail;
@property(nonatomic,strong) UITextField *authPassword;
@property(nonatomic,strong) UILabel *authServerName;
@property(nonatomic,strong) UIView *authServerMenu;
@property(nonatomic,strong) PCLAccountAuthenticator *microsoftAuth;
@end

@implementation PCLLoginPanelView

- (instancetype)initWithFrame:(CGRect)frame {
    self=[super initWithFrame:frame];
    if (!self) return nil;
    [self buildMicrosoftPage];
    [self buildOfflinePage];
    [self buildAuthPage];
    self.msPage.hidden=YES;
    self.offlinePage.hidden=YES;
    self.authPage.hidden=YES;
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
    f.textColor=PCLLoginColor(0x404040);
    f.tintColor=PCLLoginColor(0x1370F3);
    f.backgroundColor=
        [UIColor colorWithWhite:1 alpha:0x55/255.0];
    f.keyboardAppearance=UIKeyboardAppearanceLight;
    if (placeholder.length) {
        f.attributedPlaceholder=
            [[NSAttributedString alloc] initWithString:placeholder
            attributes:@{NSForegroundColorAttributeName:
                PCLLoginColor(0x8C8C8C)}];
    }
    f.borderStyle=UITextBorderStyleNone;
    f.layer.borderWidth=1;
    f.layer.borderColor=PCLLoginColor(0x96C0F9).CGColor;
    f.layer.cornerRadius=3;
    f.leftView=[[UIView alloc] initWithFrame:CGRectMake(0,0,8,1)];
    f.leftViewMode=UITextFieldViewModeAlways;
    [f addTarget:self action:@selector(fieldFocus:)
        forControlEvents:UIControlEventEditingDidBegin];
    [f addTarget:self action:@selector(fieldBlur:)
        forControlEvents:UIControlEventEditingDidEnd];
    return f;
}

- (void)fieldFocus:(UITextField *)field {
    [UIView animateWithDuration:.10 animations:^{
        field.layer.borderColor=
            PCLLoginColor(0x1370F3).CGColor;
        field.backgroundColor=
            PCLLoginColor(0xE0EAFD);
    }];
}


- (void)fieldBlur:(UITextField *)field {
    [UIView animateWithDuration:.10 animations:^{
        field.layer.borderColor=
            PCLLoginColor(0x96C0F9).CGColor;
        field.backgroundColor=
            [UIColor colorWithWhite:1 alpha:0x55/255.0];
    }];
}

- (void)showPage:(UIView *)page {
    if (self.currentPage==page) {
        page.hidden=NO;
        page.alpha=1;
        return;
    }

    UIView *old=self.currentPage;
    self.currentPage=page;

    if (!old || self.hidden || self.superview.alpha<0.05) {
        for (UIView *p in @[
            self.msPage,self.offlinePage,self.authPage])
            p.hidden=p!=page;
        page.alpha=1;
        return;
    }

    self.userInteractionEnabled=NO;

    [UIView animateWithDuration:.10 animations:^{
        old.alpha=0;
    } completion:^(BOOL done) {
        old.hidden=YES;
        old.alpha=1;
        page.hidden=NO;
        page.alpha=0;

        [UIView animateWithDuration:.10 animations:^{
            page.alpha=1;
        } completion:^(BOOL done) {
            self.userInteractionEnabled=YES;
        }];
    }];
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
    ring.userInteractionEnabled=NO;
    ring.layer.borderWidth=1.3;
    ring.layer.cornerRadius=5;
    ring.backgroundColor=
        [UIColor colorWithWhite:1 alpha:0x55/255.0];
    [b addSubview:ring];

    UIView *dot=[[UIView alloc] init];
    dot.tag=9302;
    dot.userInteractionEnabled=NO;

    dot.layer.cornerRadius=2.5;
    dot.hidden=YES;
    dot.backgroundColor=PCLLoginColor(0x0B5BCB);
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

    self.offlineName=[self field:nil];
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
    self.offlineUuidTitle.textAlignment=
        NSTextAlignmentCenter;

    self.offlineUuid=[self field:nil];
    [self.offlinePage addSubview:self.offlineUuidTitle];
    [self.offlinePage addSubview:self.offlineUuid];

    UIButton *back=[self button:@"返回"];
    back.tag=305;
    [back addTarget:self action:@selector(closePressed)
        forControlEvents:UIControlEventTouchUpInside];

    UIButton *create=[self button:@"创建"];
    create.tag=306;
    create.layer.borderColor=PCLLoginColor(0x0B5BCB).CGColor;
    [create setTitleColor:PCLLoginColor(0x0B5BCB)
                 forState:UIControlStateNormal];

    [create addTarget:self action:@selector(createOffline)
        forControlEvents:UIControlEventTouchUpInside];
    [self.offlinePage addSubview:back];
    [self.offlinePage addSubview:create];
}

- (void)buildAuthPage {
    self.authPage=[[UIView alloc] init];
    [self addSubview:self.authPage];
    self.authServerName=[[UILabel alloc] init];
    self.authServerName.hidden=YES;
    self.authServerName.textAlignment=NSTextAlignmentCenter;
    self.authServerName.textColor=PCLLoginColor(0x343D4A);
    [self.authPage addSubview:self.authServerName];

    self.authServer=[self field:@"验证服务器"];
    self.authEmail=[self field:@"邮箱"];
    self.authPassword=[self field:@"密码"];
    self.authPassword.secureTextEntry=YES;
    self.authServer.placeholder=nil;
    UIButton *drop=[UIButton buttonWithType:UIButtonTypeCustom];
    [drop setImage:[UIImage systemImageNamed:@"chevron.down"]
          forState:UIControlStateNormal];
    drop.tintColor=PCLLoginColor(0x737373);
    drop.frame=CGRectMake(0,0,28,28);
    [drop addTarget:self action:@selector(toggleAuthServerMenu)
        forControlEvents:UIControlEventTouchUpInside];
    self.authServer.rightView=drop;
    self.authServer.rightViewMode=UITextFieldViewModeAlways;
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
    self.authServerMenu=[[UIView alloc] init];
    self.authServerMenu.hidden=YES;
    self.authServerMenu.backgroundColor=PCLLoginColor(0xFBFBFB);
    self.authServerMenu.layer.borderWidth=1;
    self.authServerMenu.layer.borderColor=
        PCLLoginColor(0x96C0F9).CGColor;
    self.authServerMenu.layer.cornerRadius=3;

    NSArray *servers=@[@"预设 - LittleSkin",@"自定义"];
    for (NSInteger i=0;i<servers.count;i++) {
        UIButton *item=[UIButton buttonWithType:UIButtonTypeCustom];
        item.tag=440+i;
        [item setTitle:servers[i] forState:UIControlStateNormal];
        [item setTitleColor:PCLLoginColor(0x343D4A)
                   forState:UIControlStateNormal];
        item.contentHorizontalAlignment=
            UIControlContentHorizontalAlignmentLeft;

        item.contentEdgeInsets=UIEdgeInsetsMake(0,8,0,0);
        [item addTarget:self action:@selector(authServerChoice:)
            forControlEvents:UIControlEventTouchUpInside];
        [self.authServerMenu addSubview:item];
    }

    [self.authPage addSubview:self.authServerMenu];



    UIButton *back=[self button:@"返回"];
    back.tag=404;
    [back addTarget:self action:@selector(closePressed)
        forControlEvents:UIControlEventTouchUpInside];

    UIButton *login=[self button:@"登录"];
    login.tag=405;
    login.layer.borderColor=PCLLoginColor(0x0B5BCB).CGColor;
    [login setTitleColor:PCLLoginColor(0x0B5BCB)
                forState:UIControlStateNormal];

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
    self.editingProfileIdentifier=nil;
    self.offlineName.enabled=YES;

    UIButton *create=
        [self.offlinePage viewWithTag:306];
    [create setTitle:@"创建"
            forState:UIControlStateNormal];

    self.offlineName.text=@"";
    self.offlineUuid.text=@"";
    self.statusLabel.text=@"";
    self.uuidMode=0;
    [self uuidPressed:[self.offlinePage viewWithTag:302]];
    [self showPage:self.offlinePage];
}
- (void)editOfflineProfile:(NSDictionary *)profile {
    self.editingProfileIdentifier=
        profile[@"identifier"];

    self.offlineName.text=profile[@"username"];
    self.offlineName.enabled=NO;
    self.offlineUuid.text=profile[@"uuid"];
    self.statusLabel.text=@"";

    self.uuidMode=2;

    [self uuidPressed:
        [self.offlinePage viewWithTag:304]];

    UIButton *save=
        [self.offlinePage viewWithTag:306];
    [save setTitle:@"保存"
          forState:UIControlStateNormal];

    [self showPage:self.offlinePage];
}

- (void)showThirdParty {
    if (!self.authServer.text.length)
        self.authServer.text=
            @"https://littleskin.cn/api/yggdrasil";

    self.authEmail.text=@"";
    self.authPassword.text=@"";
    self.statusLabel.text=@"";


    [self showPage:self.authPage];
}

- (void)dismissTransientUI {
    [self endEditing:YES];

    [self.authServerMenu.layer removeAllAnimations];
    self.authServerMenu.alpha=0;
    self.authServerMenu.hidden=YES;
}

- (void)closePressed {
    if (self.onClose) self.onClose();
}

- (void)saveProfile:(NSDictionary *)profile {
    [PCLProfileStore saveAndSelectProfile:profile];

    if (self.onProfileCreated)
        self.onProfileCreated();
}

- (void)setStatus:(NSString *)text error:(BOOL)error {
    self.statusLabel.text=text ?: @"";
    self.statusLabel.textColor=
        error ? PCLLoginColor(0xD84545)
              : PCLLoginColor(0x343D4A);
}

- (NSString *)msPercent:(NSString *)text {
    if ([text containsString:@"Microsoft 登录"]) return @"0%";
    if ([text containsString:@"Microsoft 令牌"]) return @"20%";
    if ([text containsString:@"Xbox Live"]) return @"40%";
    if ([text containsString:@"XSTS"]) return @"60%";
    if ([text containsString:@"登录 Minecraft"]) return @"80%";
    if ([text containsString:@"Minecraft 档案"]) return @"90%";
    return @"0%";
}

- (void)msStart {
    UIButton *button=[self.msPage viewWithTag:201];
    UIButton *back=[self.msPage viewWithTag:204];

    button.enabled=NO;
    back.hidden=YES;
    [button setTitle:@"0%" forState:UIControlStateNormal];
    self.statusLabel.text=@"";

    self.microsoftAuth=
        [[PCLAccountAuthenticator alloc] initWithAnchorView:self];

    __weak typeof(self) weakSelf=self;
    [self.microsoftAuth startMicrosoftWithStatus:^(NSString *text) {
        [button setTitle:[weakSelf msPercent:text]
                forState:UIControlStateNormal];

    } completion:^(NSDictionary *profile,NSString *error) {
        if (profile) {
            [button setTitle:@"100%" forState:UIControlStateNormal];

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,60*NSEC_PER_MSEC),
                dispatch_get_main_queue(), ^{
                [weakSelf saveProfile:profile];
            });
            return;
        }

        button.enabled=YES;
        back.hidden=NO;
        [button setTitle:@"开始正版验证"
                forState:UIControlStateNormal];
        [weakSelf setStatus:error error:YES];
        weakSelf.microsoftAuth=nil;
    }];
}

- (void)toggleAuthServerMenu {
    [self endEditing:YES];

    BOOL show=self.authServerMenu.hidden;
    self.authServerMenu.hidden=NO;
    self.authServerMenu.alpha=show ? 0 : 1;

    [self.authPage bringSubviewToFront:self.authServerMenu];

    [UIView animateWithDuration:.12 animations:^{
        self.authServerMenu.alpha=show ? 1 : 0;
    } completion:^(BOOL done) {
        self.authServerMenu.hidden=!show;
    }];
}

- (void)authServerChoice:(UIButton *)sender {
    self.authServerMenu.hidden=YES;

    if (sender.tag==440) {
        self.authServer.text=
            @"https://littleskin.cn/api/yggdrasil";
        self.authServerName.text=
            @"验证服务器: LittleSkin";
        self.authServerName.hidden=NO;
    } else {
        self.authServer.text=@"";
        self.authServerName.hidden=YES;
        [self.authServer becomeFirstResponder];
    }

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
    UIButton *back=[self.authPage viewWithTag:404];
    login.enabled=NO;
    back.enabled=NO;
    [login setTitle:@"0%" forState:UIControlStateNormal];

    __weak typeof(self) weakSelf=self;
    [PCLAccountAuthenticator resolveAuthlibServer:server
        completion:^(NSString *resolved,NSString *resolveError) {

        if (resolveError) {
            login.enabled=YES;
            back.enabled=YES;
            [login setTitle:@"登录" forState:UIControlStateNormal];
            [weakSelf setStatus:resolveError error:YES];
            return;
        }

        weakSelf.authServer.text=resolved;
        [login setTitle:@"35%" forState:UIControlStateNormal];

        [PCLAccountAuthenticator
            loginAuthlibServer:resolved username:user password:pass
            status:^(NSString *text) {
                [login setTitle:@"70%" forState:UIControlStateNormal];
            } completion:^(NSDictionary *profile,NSString *error) {

                if (profile) {
                    [login setTitle:@"100%" forState:UIControlStateNormal];
                    weakSelf.authPassword.text=@"";

                    dispatch_after(
                        dispatch_time(DISPATCH_TIME_NOW,60*NSEC_PER_MSEC),
                        dispatch_get_main_queue(), ^{
                            [weakSelf saveProfile:profile];
                        });
                    return;
                }

                login.enabled=YES;
                back.enabled=YES;
                [login setTitle:@"登录" forState:UIControlStateNormal];
                [weakSelf setStatus:error error:YES];
            }];
    }];
}

- (void)uuidPressed:(UIButton *)sender {
    self.uuidMode=sender.tag-302;
    UIColor *blue=PCLLoginColor(0x0B5BCB);

    for (NSInteger i=0;i<3;i++) {
        UIButton *b=[self.offlinePage viewWithTag:302+i];
        BOOL on=i==self.uuidMode;

        UIView *ring=[b viewWithTag:9301];
        UIView *dot=[b viewWithTag:9302];
        ring.layer.borderColor=
            (on ? blue : PCLLoginColor(0x343D4A)).CGColor;

        if (on) {
            dot.hidden=NO;
            dot.alpha=0;
            dot.transform=CGAffineTransformMakeScale(.1,.1);
            ring.transform=CGAffineTransformMakeScale(.56,.56);

            [UIView animateWithDuration:.30 delay:.09
                options:UIViewAnimationOptionCurveEaseOut
                animations:^{
                    ring.transform=CGAffineTransformIdentity;
                    dot.transform=CGAffineTransformIdentity;
                    dot.alpha=1;
                } completion:nil];

        } else {
            ring.transform=CGAffineTransformIdentity;

            [UIView animateWithDuration:.15 animations:^{
                dot.alpha=0;
                dot.transform=CGAffineTransformMakeScale(.1,.1);
            } completion:^(BOOL done) {
                dot.hidden=YES;
                dot.transform=CGAffineTransformIdentity;
            }];
        }
    }

    BOOL custom=self.uuidMode==2;

    if (custom) {
        self.offlineUuidTitle.hidden=NO;
        self.offlineUuid.hidden=NO;
        self.offlineUuidTitle.alpha=0;
        self.offlineUuid.alpha=0;
    }

    [self setNeedsLayout];

    [UIView animateWithDuration:.15 animations:^{
        self.offlineUuidTitle.alpha=custom ? 1 : 0;
        self.offlineUuid.alpha=custom ? 1 : 0;
        [self layoutIfNeeded];
    } completion:^(BOOL done) {
        if (!custom) {
            self.offlineUuidTitle.hidden=YES;
            self.offlineUuid.hidden=YES;
        }
    }];
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

    if (self.uuidMode==0) {
        uuid=[PCLAccountAuthenticator
            offlineUUIDForName:name legacy:NO];

    } else if (self.uuidMode==1) {
        uuid=[PCLAccountAuthenticator
            offlineUUIDForName:name legacy:YES];

    } else {
        uuid=[self.offlineUuid.text
            stringByReplacingOccurrencesOfString:@"-" withString:@""];
        NSPredicate *hex=[NSPredicate predicateWithFormat:
            @"SELF MATCHES %@",@"[0-9A-Fa-f]{32}"];
        if (![hex evaluateWithObject:uuid]) {
            [self setStatus:@"自定义 UUID 必须为 32 位十六进制" error:YES];
            return;
        }
    }

    if (self.editingProfileIdentifier.length) {
        for (NSDictionary *old in
            [PCLProfileStore profiles]) {
            if (![old[@"identifier"]
                isEqual:self.editingProfileIdentifier])
                continue;

            NSMutableDictionary *edit=old.mutableCopy;
            edit[@"uuid"]=uuid;
            [PCLProfileStore
                replaceProfileWithIdentifier:
                    self.editingProfileIdentifier
                profile:edit select:YES];

            self.editingProfileIdentifier=nil;

            if (self.onProfileCreated)
                self.onProfileCreated();
            return;
        }
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
    name.textAlignment=NSTextAlignmentCenter;
    UILabel *uuid=[self.offlinePage viewWithTag:301];
    uuid.textColor=PCLLoginColor(0x343D4A);
    self.offlineUuidTitle.textColor=PCLLoginColor(0x343D4A);
    name.font=[UIFont systemFontOfSize:13*s];
    self.offlineName.font=[UIFont systemFontOfSize:13*s];
    self.offlineUuidTitle.font=[UIFont systemFontOfSize:13*s];
    self.offlineUuid.font=[UIFont systemFontOfSize:13*s];
    name.frame=CGRectMake(0,0,50*s,28*s);
    self.offlineName.frame=CGRectMake(50*s,0,w-50*s,28*s);

    uuid.frame=CGRectMake(5*s,38*s,w-5*s,22*s);

    uuid.font=[UIFont systemFontOfSize:13*s
                                weight:UIFontWeightSemibold];

    CGFloat bw=85*s;
    CGFloat radioX=5.0*s;
    for (NSInteger i=0;i<3;i++) {
        UIButton *b=[self.offlinePage viewWithTag:302+i];
        b.frame=CGRectMake(radioX+i*bw,62*s,bw,44*s);
        UIView *ring=[b viewWithTag:9301];
        ring.frame=CGRectMake(1*s,13*s,18*s,18*s);
        ring.layer.cornerRadius=9*s;
        ring.layer.borderWidth=1.1*s;
        UIView *dot=[ring viewWithTag:9302];
        dot.frame=CGRectMake(4.5*s,4.5*s,9*s,9*s);
        dot.layer.cornerRadius=4.5*s;
        b.titleLabel.font=[UIFont systemFontOfSize:13*s];
        b.titleEdgeInsets=UIEdgeInsetsMake(0,26*s,0,0);
    }

    self.offlineUuidTitle.frame=
        CGRectMake(0,116*s,50*s,28*s);
    self.offlineUuid.frame=
        CGRectMake(50*s,116*s,w-50*s,28*s);

    UIButton *ob=[self.offlinePage viewWithTag:305];
    UIButton *oc=[self.offlinePage viewWithTag:306];
    ob.titleLabel.font=[UIFont systemFontOfSize:13*s];
    oc.titleLabel.font=[UIFont systemFontOfSize:13*s];
    CGFloat offlineButtonY=
        (self.uuidMode==2 ? 154.0 : 116.0)*s;
    ob.frame=CGRectMake(80*s,offlineButtonY,50*s,28*s);
    oc.frame=CGRectMake(140*s,offlineButtonY,50*s,28*s);

    self.authServerName.frame=
        CGRectMake(50*s,0,w-50*s,18*s);
    self.authServerName.font=
        [UIFont systemFontOfSize:13*s];

    self.authServer.frame=CGRectMake(50*s,26*s,w-50*s,28*s);

    self.authServerMenu.frame=
        CGRectMake(50*s,54*s,w-50*s,56*s);

    for (NSInteger i=0;i<2;i++) {
        UIButton *item=[self.authServerMenu viewWithTag:440+i];
        item.frame=CGRectMake(0,28*i*s,w-50*s,28*s);
        item.titleLabel.font=[UIFont systemFontOfSize:13*s];
    }

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

    UIButton *ab=[self.authPage viewWithTag:404];
    UIButton *al=[self.authPage viewWithTag:405];
    ab.titleLabel.font=[UIFont systemFontOfSize:13*s];
    al.titleLabel.font=[UIFont systemFontOfSize:13*s];
    ab.frame=CGRectMake(80*s,150*s,50*s,28*s);
    al.frame=CGRectMake(140*s,150*s,50*s,28*s);

    self.statusLabel.font=[UIFont systemFontOfSize:11*s];
    self.statusLabel.frame=CGRectMake(0,190*s,w,18*s);
}

@end
