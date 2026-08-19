#import "PCLLaunchViewController.h"
#import "PCLLaunchLeftView.h"
#import "PCLLaunchRightView.h"
#import <QuartzCore/QuartzCore.h>

@interface PCLLaunchViewController ()

@property (nonatomic, strong) PCLLaunchLeftView *leftView;
@property (nonatomic, strong) PCLLaunchRightView *rightView;

@property (nonatomic, copy) NSArray<NSString *> *instances;

@property (nonatomic, strong) CAGradientLayer *backgroundGradient;
@property (nonatomic, strong) UIView *leftShadowView;
@property (nonatomic, strong) CAGradientLayer *leftShadowGradient;

@end

@implementation PCLLaunchViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor =
        [UIColor colorWithRed:251.0/255.0
                        green:251.0/255.0
                         blue:251.0/255.0
                        alpha:1.0];

    [self buildCEBackground];
    [self buildUI];
    [self reloadInstances];
}

- (void)buildCEBackground {
    self.backgroundGradient = [CAGradientLayer layer];
    self.backgroundGradient.colors = @[
        (id)[UIColor colorWithRed:.68 green:.80 blue:.98 alpha:1].CGColor,
        (id)[UIColor colorWithRed:.92 green:.96 blue:1 alpha:1].CGColor,
        (id)[UIColor colorWithRed:.76 green:.84 blue:.99 alpha:1].CGColor
    ];
    self.backgroundGradient.locations = @[@0,@.4,@1];
    self.backgroundGradient.startPoint = CGPointMake(.9,0);
    self.backgroundGradient.endPoint = CGPointMake(.1,1);
    [self.view.layer insertSublayer:self.backgroundGradient atIndex:0];
}

- (void)buildUI {
    self.leftView =
        [[PCLLaunchLeftView alloc] init];

    self.rightView =
        [[PCLLaunchRightView alloc] init];

    [self.view addSubview:self.leftView];
    [self.view addSubview:self.rightView];
    self.leftShadowView = [[UIView alloc] init];
    self.leftShadowView.userInteractionEnabled = NO;
    self.leftShadowGradient = [CAGradientLayer layer];
    self.leftShadowGradient.colors = @[
        (id)[UIColor colorWithWhite:0 alpha:.04].CGColor,
        (id)[UIColor colorWithWhite:0 alpha:0].CGColor
    ];
    self.leftShadowGradient.startPoint = CGPointMake(0,.5);
    self.leftShadowGradient.endPoint = CGPointMake(1,.5);
    [self.leftShadowView.layer addSublayer:self.leftShadowGradient];
    [self.view addSubview:self.leftShadowView];

    __weak typeof(self) weakSelf = self;

    self.leftView.onSelectInstance = ^{
        [weakSelf selectInstance];
    };

    self.leftView.onInstanceSettings = ^{
        [weakSelf instanceSettings];
    };

    self.leftView.onLaunch = ^{
        [weakSelf launchMinecraft];
    };

    self.leftView.onCreateProfile = ^{
        [weakSelf createProfile];
    };

    self.leftView.onSwitchProfile = ^{
        [weakSelf switchProfile];
    };

    self.leftView.onSkinOptions = ^{
        [weakSelf skinOptions];
    };

    self.leftView.onEditProfile = ^{
        [weakSelf editProfile];
    };

    self.rightView.onCloseHint = ^{
        [NSUserDefaults.standardUserDefaults
            setBool:YES
             forKey:@"PCLLaunchHintHidden"];
    };

    BOOL hintHidden =
        [NSUserDefaults.standardUserDefaults
            boolForKey:@"PCLLaunchHintHidden"];

    [self.rightView
        setHintHidden:hintHidden];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat w=CGRectGetWidth(self.view.bounds);
    CGFloat h=CGRectGetHeight(self.view.bounds);
    CGFloat scale=MIN(w/850.0,h/417.2);
    CGFloat pageH=h;
    CGFloat leftW=self.leftPanelWidth>0 ? MIN(self.leftPanelWidth,w) : 300.0*scale;
    scale=MIN(scale,leftW/300.0);
    CGFloat y=0.0;
    self.backgroundGradient.frame=self.view.bounds;
    self.leftView.frame=CGRectMake(0,y,leftW,pageH);
    self.leftView.designScale=scale;
    self.rightView.designScale=scale;
    self.rightView.frame=CGRectMake(leftW,y,MAX(0,w-leftW),pageH);
    self.leftShadowView.frame=CGRectMake(leftW,y,4*scale,pageH);
    self.leftShadowGradient.frame=self.leftShadowView.bounds;
}

- (void)reloadInstances {
    self.instances = @[];

    [NSUserDefaults.standardUserDefaults
        removeObjectForKey:@"PCLSelectedInstance"];

    [self.leftView reloadState];
}

- (void)selectInstance {
    [self temporaryMessage:
        @"实例选择页正在按 PCL CE 重做。"];
}

- (void)instanceSettings {
    NSString *instance =
        [NSUserDefaults.standardUserDefaults
            stringForKey:@"PCLSelectedInstance"];

    if (!instance.length) {
        [self temporaryMessage:@"请先选择实例。"];
        return;
    }

    [self temporaryMessage:
        [NSString stringWithFormat:
            @"当前实例：%@",
            instance]];
}


- (void)createProfile {
    UIAlertController *p =
        [UIAlertController alertControllerWithTitle:
            @"新建档案 - 选择验证类型"
        message:nil preferredStyle:UIAlertControllerStyleAlert];

    __weak typeof(self) weakSelf = self;

    [p addAction:[UIAlertAction actionWithTitle:@"正版验证"
        style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        [weakSelf createMicrosoftProfile];
    }]];

    [p addAction:[UIAlertAction actionWithTitle:@"第三方验证"
        style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        [weakSelf createThirdPartyProfile];
    }]];

    [p addAction:[UIAlertAction actionWithTitle:@"离线验证"
        style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        [weakSelf createOfflineProfile];
    }]];

    [p addAction:[UIAlertAction actionWithTitle:@"取消"
        style:UIAlertActionStyleCancel handler:nil]];

    [self presentViewController:p animated:YES completion:nil];
}

- (void)createMicrosoftProfile {
    UIAlertController *a =
        [UIAlertController alertControllerWithTitle:@"正版验证"
        message:nil preferredStyle:UIAlertControllerStyleAlert];

    __weak typeof(self) weakSelf = self;

    [a addAction:[UIAlertAction actionWithTitle:@"开始正版验证"
        style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) {
        [weakSelf temporaryMessage:@"Microsoft 正版验证接口正在接入。"];
    }]];

    [a addAction:[UIAlertAction actionWithTitle:@"»  购买正版"
        style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) {
        [weakSelf openURL:@"https://www.xbox.com/zh-cn/games/store/minecraft-java-bedrock-edition-for-pc/9nxp44l49shj"];
    }]];

    [a addAction:[UIAlertAction actionWithTitle:@"»  前往官网"
        style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) {
        [weakSelf openURL:@"https://www.minecraft.net/zh-hans"];
    }]];

    [a addAction:[UIAlertAction actionWithTitle:@"«  返回"
        style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

- (void)createOfflineProfile {
    UIAlertController *a =
        [UIAlertController alertControllerWithTitle:@"离线验证"
        message:@"UUID 标准：行业规范"
        preferredStyle:UIAlertControllerStyleAlert];

    [a addTextFieldWithConfigurationHandler:^(UITextField *f) {
        f.placeholder=@"玩家 ID";
        f.autocapitalizationType=UITextAutocapitalizationTypeNone;
    }];

    [a addAction:[UIAlertAction actionWithTitle:@"返回"
        style:UIAlertActionStyleCancel handler:nil]];

    __weak typeof(self) weakSelf=self;

    [a addAction:[UIAlertAction actionWithTitle:@"创建"
        style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) {
        NSString *name=[a.textFields.firstObject.text
            stringByTrimmingCharactersInSet:
                NSCharacterSet.whitespaceAndNewlineCharacterSet];

        NSPredicate *rule=[NSPredicate predicateWithFormat:
            @"SELF MATCHES %@",@"[A-Za-z0-9_]{3,16}"];
        if (![rule evaluateWithObject:name]) {
            [weakSelf temporaryMessage:@"玩家 ID 不符合规范"];
            return;
        }

        NSUserDefaults *d=NSUserDefaults.standardUserDefaults;
        [d setObject:name forKey:@"PCLProfileUsername"];
        [d setObject:@"offline" forKey:@"PCLProfileType"];
        [d setObject:@"standard" forKey:@"PCLProfileUUIDMode"];
        [weakSelf.leftView reloadState];
    }]];

    [self presentViewController:a animated:YES completion:nil];
}

- (void)createThirdPartyProfile {
    UIAlertController *a =
        [UIAlertController alertControllerWithTitle:@"第三方验证"
        message:nil preferredStyle:UIAlertControllerStyleAlert];

    [a addTextFieldWithConfigurationHandler:^(UITextField *f) {
        f.placeholder=@"服务器";
    }];

    [a addTextFieldWithConfigurationHandler:^(UITextField *f) {
        f.placeholder=@"邮箱";
        f.keyboardType=UIKeyboardTypeEmailAddress;
        f.autocapitalizationType=UITextAutocapitalizationTypeNone;
    }];

    [a addTextFieldWithConfigurationHandler:^(UITextField *f) {
        f.placeholder=@"密码";
        f.secureTextEntry=YES;
    }];

    __weak typeof(self) weakSelf=self;

    [a addAction:[UIAlertAction actionWithTitle:@"返回"
        style:UIAlertActionStyleCancel handler:nil]];

    [a addAction:[UIAlertAction actionWithTitle:@"登录"
        style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) {
        if (!a.textFields[0].text.length ||
            !a.textFields[1].text.length ||
            !a.textFields[2].text.length) {

            [weakSelf temporaryMessage:
                @"验证服务器、用户名与密码均不能为空！"];
            return;
        }
        [weakSelf temporaryMessage:@"第三方验证接口正在接入。"];
    }]];
    [self presentViewController:a animated:YES completion:nil];
}

- (void)switchProfile {
    [NSUserDefaults.standardUserDefaults
        removeObjectForKey:@"PCLProfileUsername"];
    [NSUserDefaults.standardUserDefaults
        removeObjectForKey:@"PCLProfileType"];

    [self.leftView reloadState];
}

- (void)skinOptions {
    [self temporaryMessage:
        @"皮肤与披风功能将在账号系统阶段接入。"];
}

- (void)editProfile {
    NSString *name =
        [NSUserDefaults.standardUserDefaults
            stringForKey:@"PCLProfileUsername"];

    if (!name.length)
        return;

    [self temporaryMessage:
        [NSString stringWithFormat:
            @"当前档案：%@",
            name]];
}

- (void)launchMinecraft {
    NSString *profile =
        [NSUserDefaults.standardUserDefaults
            stringForKey:@"PCLProfileUsername"];

    NSString *instance =
        [NSUserDefaults.standardUserDefaults
            stringForKey:@"PCLSelectedInstance"];

    if (!instance.length) {
        if (self.onOpenDownload)
            self.onOpenDownload();
        return;
    }

    if (!profile.length)
        return;
    NSString *message =
        [NSString stringWithFormat:
            @"档案：%@\n实例：%@",
            profile,
            instance];

    [self temporaryMessage:message];
}

- (void)openURL:(NSString *)text {
    NSURL *url=[NSURL URLWithString:text];
    if (!url) return;
    [UIApplication.sharedApplication openURL:url
        options:@{} completionHandler:nil];
}

- (void)temporaryMessage:(NSString *)message {
    UIAlertController *alert =
        [UIAlertController
            alertControllerWithTitle:@"PCL [iOS]"
                             message:message
                      preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:
        [UIAlertAction
            actionWithTitle:@"确定"
                      style:UIAlertActionStyleDefault
                    handler:nil]];

    [self presentViewController:alert
                       animated:YES
                     completion:nil];
}

@end
