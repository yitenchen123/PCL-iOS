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
    CGFloat scale=MIN(1.0, MIN(w/850.0,h/417.2));
    CGFloat pageH=h;
    CGFloat leftW=self.leftPanelWidth>0 ? MIN(self.leftPanelWidth,w) : 300.0*scale;
    CGFloat y=0.0;
    self.backgroundGradient.frame=self.view.bounds;
    self.leftView.frame=CGRectMake(0,y,leftW,pageH);
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
    UIAlertController *editor =
        [UIAlertController
            alertControllerWithTitle:@"创建档案"
                             message:@"离线登录"
                      preferredStyle:UIAlertControllerStyleAlert];

    [editor addTextFieldWithConfigurationHandler:
        ^(UITextField *field) {
        field.placeholder = @"玩家名";
        field.autocapitalizationType =
            UITextAutocapitalizationTypeNone;
    }];
    [editor addAction:
        [UIAlertAction
            actionWithTitle:@"取消"
                      style:UIAlertActionStyleCancel
                    handler:nil]];

    __weak typeof(self) weakSelf = self;

    [editor addAction:
        [UIAlertAction
            actionWithTitle:@"创建"
                      style:UIAlertActionStyleDefault
                    handler:^(__unused UIAlertAction *action) {
        NSString *name =
            [editor.textFields.firstObject.text
                stringByTrimmingCharactersInSet:
                    NSCharacterSet.whitespaceAndNewlineCharacterSet];

        if (!name.length || name.length > 16)
            return;

        [NSUserDefaults.standardUserDefaults
            setObject:name
               forKey:@"PCLProfileUsername"];

        [weakSelf.leftView reloadState];
    }]];

    [self presentViewController:editor
                       animated:YES
                     completion:nil];
}

- (void)switchProfile {
    [NSUserDefaults.standardUserDefaults
        removeObjectForKey:@"PCLProfileUsername"];

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

    if (!profile.length || !instance.length)
        return;
    NSString *message =
        [NSString stringWithFormat:
            @"档案：%@\n实例：%@",
            profile,
            instance];

    [self temporaryMessage:message];
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
