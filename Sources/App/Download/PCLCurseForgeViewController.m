#import "PCLCurseForgeViewController.h"
#import "PCLCurseForgeAPI.h"

@interface PCLCurseForgeViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) NSArray<PCLCurseForgeMod *> *mods;
@property (nonatomic, strong) NSString *currentQuery;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;

@end

@implementation PCLCurseForgeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"CurseForge";
    self.view.backgroundColor = [UIColor colorWithRed:251.0/255.0 green:251.0/255.0 blue:251.0/255.0 alpha:1.0];
    self.mods = @[];
    self.currentQuery = @"";
    
    [self setupUI];
    [self checkAPIKey];
}

- (void)setupUI {
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.placeholder = @"搜索 Mod...";
    self.searchBar.delegate = self;
    self.searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.searchBar];
    
    self.tableView = [[UITableView alloc] initWithStyle:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:self.tableView];
    
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    self.spinner.hidesWhenStopped = YES;
    self.spinner.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.spinner];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.searchBar.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.searchBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.searchBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        
        [self.tableView.topAnchor constraintEqualToAnchor:self.searchBar.bottomAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        
        [self.spinner.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.spinner.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
    ]];
}

- (void)checkAPIKey {
    if (![[PCLCurseForgeAPI sharedAPI] currentAPIKey]) {
        [self showAPIKeyAlert];
    } else {
        [self loadMods];
    }
}

- (void)showAPIKeyAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"CurseForge API Key"
                                                                message:@"请输入 CurseForge API Key。可在 https://console.curseforge.com 获取。"
                                                         preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"API Key";
        textField.secureTextEntry = YES;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *key = alert.textFields.firstObject.text;
        if (key.length > 0) {
            [[PCLCurseForgeAPI sharedAPI] setAPIKey:key];
            [self loadMods];
        }
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)loadMods {
    [self.spinner startAnimating];
    self.mods = @[];
    [self.tableView reloadData];
    
    if (self.currentQuery.length == 0) {
        self.currentQuery = @"popular";
    }
    
    [[PCLCurseForgeAPI sharedAPI] searchModsWithQuery:self.currentQuery
                                          gameVersion:nil
                                             category:nil
                                                 page:0
                                            pageSize:20
                                          completion:^(NSArray<PCLCurseForgeMod *> *mods, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.spinner stopAnimating];
            if (error) {
                [self showError:error.localizedDescription];
                return;
            }
            self.mods = mods;
            [self.tableView reloadData];
        });
    }];
}

- (void)showError:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"错误" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.mods.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CurseForgeCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"CurseForgeCell"];
        cell.backgroundColor = [UIColor clearColor];
    }
    PCLCurseForgeMod *mod = self.mods[indexPath.row];
    cell.textLabel.text = mod.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ | 下载: %ld", mod.summary, (long)mod.downloadCount];
    return cell;
}

#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    self.currentQuery = searchBar.text.length > 0 ? searchBar.text : @"popular";
    [self loadMods];
}

@end
