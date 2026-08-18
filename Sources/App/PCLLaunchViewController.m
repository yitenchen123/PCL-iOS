#import "PCLLaunchViewController.h"
#import "PCLLaunchLeftView.h"
#import "PCLLaunchRightView.h"

@interface PCLLaunchViewController ()

@property (nonatomic, strong) PCLLaunchLeftView *leftView;
@property (nonatomic, strong) PCLLaunchRightView *rightView;

@property (nonatomic, copy) NSArray<NSString *> *instances;

@end

@implementation PCLLaunchViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor =
        [UIColor colorWithRed:251.0/255.0
                        green:251.0/255.0
                         blue:251.0/255.0
                        alpha:1.0];

    [self buildUI];
    [self reloadInstances];
}

- (void)buildUI {
    self.leftView =
        [[PCLLaunchLeftView alloc] init];

    self.rightView =
        [[PCLLaunchRightView alloc] init];

    [self.view addSubview:self.leftView];
    [self.view addSubview:self.rightView];

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

    CGFloat width =
        CGRectGetWidth(self.view.bounds);

    CGFloat height =
        CGRectGetHeight(self.view.bounds);

    CGFloat scale =
        MIN(width / 850.0,
            height / 417.2);

    CGFloat canvasWidth =
        850.0 * scale;

    CGFloat canvasHeight =
        417.2 * scale;

    CGFloat originX =
        (width - canvasWidth) / 2.0;

    CGFloat originY =
        (height - canvasHeight) / 2.0;

    self.leftView.frame =
        CGRectMake(originX,
                   originY,
                   300.0 * scale,
                   canvasHeight);

    self.rightView.frame =
        CGRectMake(originX + 300.0 * scale,
                   originY,
                   550.0 * scale,
                   canvasHeight);
}

- (NSArray<NSString *> *)versionRoots {
    NSString *documents =
        NSSearchPathForDirectoriesInDomains(
            NSDocumentDirectory,
            NSUserDomainMask,
            YES).firstObject;

    NSString *library =
        NSSearchPathForDirectoriesInDomains(
            NSLibraryDirectory,
            NSUserDomainMask,
            YES).firstObject;

    return @[
        [documents stringByAppendingPathComponent:
            @".minecraft/versions"],

        [documents stringByAppendingPathComponent:
            @"minecraft/versions"],

        [library stringByAppendingPathComponent:
            @"Application Support/minecraft/versions"],

        [library stringByAppendingPathComponent:
            @"minecraft/versions"]
    ];
}

- (void)reloadInstances {
    NSFileManager *fm =
        NSFileManager.defaultManager;

    NSMutableOrderedSet *found =
        [NSMutableOrderedSet orderedSet];

    for (NSString *root in [self versionRoots]) {
        NSArray *files =
            [fm contentsOfDirectoryAtPath:root
                                    error:nil];

        for (NSString *name in files) {
            NSString *folder =
                [root stringByAppendingPathComponent:name];

            NSString *json =
                [folder stringByAppendingPathComponent:
                    [name stringByAppendingString:@".json"]];

            if ([fm fileExistsAtPath:json]) {
                [found addObject:name];
            }
        }
    }

    self.instances =
        [[found array]
            sortedArrayUsingSelector:
                @selector(localizedCaseInsensitiveCompare:)];

    NSString *saved =
        [NSUserDefaults.standardUserDefaults
            stringForKey:@"PCLSelectedInstance"];

    if (![self.instances containsObject:saved]) {
        saved = self.instances.firstObject;
    }

    if (saved.length) {
        [NSUserDefaults.standardUserDefaults
            setObject:saved
               forKey:@"PCLSelectedInstance"];
    } else {
        [NSUserDefaults.standardUserDefaults
            removeObjectForKey:@"PCLSelectedInstance"];
    }

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

        if (!name.length ||
            name.length > 16) {
            return;
        }

        [NSUserDefaults.standardUserDefaults
            setObject:name
               forKey:@"PCLProfileUsername"];

        [weakSelf.leftView reloadState];
    }]];

    [self presentViewController:editor
                       animated:YES
                     completion:nil];
}

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
