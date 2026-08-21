#import "PCLCurseForgeViewController.h"
#import "PCLCurseForgeAPI.h"
#import "PCLNetworkUtils.h"
#import "PCLDownloadManager.h"
#import <QuartzCore/QuartzCore.h>

static UIColor *PCLColor(NSUInteger rgb) {
    return [UIColor colorWithRed:((rgb >> 16) & 255) / 255.0
                           green:((rgb >> 8) & 255) / 255.0
                            blue:(rgb & 255) / 255.0
                           alpha:1.0];
}

static NSString *PCLFormatDownloads(long long downloads) {
    if (downloads >= 1000000) {
        return [NSString stringWithFormat:@"%.1fM", downloads / 1000000.0];
    } else if (downloads >= 1000) {
        return [NSString stringWithFormat:@"%.1fK", downloads / 1000.0];
    }
    return [NSString stringWithFormat:@"%lld", downloads];
}

@interface PCLCurseForgeModCell : UITableViewCell
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *authorLabel;
@property (nonatomic, strong) UILabel *downloadsLabel;
@property (nonatomic, strong) UILabel *descriptionLabel;
@property (nonatomic, strong) UIButton *installButton;
@property (nonatomic, copy) void (^onInstall)(void);
@end

@implementation PCLCurseForgeModCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor whiteColor];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.iconImageView = [[UIImageView alloc] init];
    self.iconImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.iconImageView.layer.cornerRadius = 8;
    self.iconImageView.clipsToBounds = YES;
    self.iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.iconImageView.backgroundColor = PCLColor(0xF0F0F0);
    [self.contentView addSubview:self.iconImageView];
    
    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    self.nameLabel.textColor = PCLColor(0x343D4A);
    self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.nameLabel];
    
    self.authorLabel = [[UILabel alloc] init];
    self.authorLabel.font = [UIFont systemFontOfSize:12];
    self.authorLabel.textColor = PCLColor(0x1370F3);
    self.authorLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.authorLabel];
    
    self.downloadsLabel = [[UILabel alloc] init];
    self.downloadsLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    self.downloadsLabel.textColor = PCLColor(0x8C8C8C);
    self.downloadsLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.downloadsLabel];
    
    self.descriptionLabel = [[UILabel alloc] init];
    self.descriptionLabel.font = [UIFont systemFontOfSize:12];
    self.descriptionLabel.textColor = PCLColor(0x8C8C8C);
    self.descriptionLabel.numberOfLines = 2;
    self.descriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.descriptionLabel];
    
    self.installButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.installButton setTitle:@"安装" forState:UIControlStateNormal];
    [self.installButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.installButton.backgroundColor = PCLColor(0x1370F3);
    self.installButton.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    self.installButton.layer.cornerRadius = 6;
    self.installButton.clipsToBounds = YES;
    self.installButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.installButton addTarget:self action:@selector(installTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.installButton];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.iconImageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:12],
        [self.iconImageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:12],
        [self.iconImageView.widthAnchor constraintEqualToConstant:48],
        [self.iconImageView.heightAnchor constraintEqualToConstant:48],
        
        [self.nameLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:12],
        [self.nameLabel.leadingAnchor constraintEqualToAnchor:self.iconImageView.trailingAnchor constant:10],
        [self.nameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.installButton.leadingAnchor constant:-8],
        
        [self.authorLabel.topAnchor constraintEqualToAnchor:self.nameLabel.bottomAnchor constant:2],
        [self.authorLabel.leadingAnchor constraintEqualToAnchor:self.nameLabel.leadingAnchor],
        
        [self.downloadsLabel.topAnchor constraintEqualToAnchor:self.authorLabel.bottomAnchor constant:2],
        [self.downloadsLabel.leadingAnchor constraintEqualToAnchor:self.nameLabel.leadingAnchor],
        
        [self.descriptionLabel.topAnchor constraintEqualToAnchor:self.downloadsLabel.bottomAnchor constant:4],
        [self.descriptionLabel.leadingAnchor constraintEqualToAnchor:self.nameLabel.leadingAnchor],
        [self.descriptionLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-12],
        [self.descriptionLabel.bottomAnchor constraintLessThanOrEqualToAnchor:self.contentView.bottomAnchor constant:-12],
        
        [self.installButton.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [self.installButton.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-12],
        [self.installButton.widthAnchor constraintEqualToConstant:60],
        [self.installButton.heightAnchor constraintEqualToConstant:32]
    ]];
}

- (void)installTapped {
    if (self.onInstall) self.onInstall();
}

@end

@interface PCLCurseForgeViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>

@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UIView *filterBar;
@property (nonatomic, strong) UISegmentedControl *loaderFilter;
@property (nonatomic, strong) UISegmentedControl *sortFilter;
@property (nonatomic, strong) UIButton *versionFilterButton;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<PCLCurseForgeMod *> *mods;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, strong) UIButton *apiKeyButton;

@property (nonatomic, assign) NSInteger currentOffset;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) BOOL hasMore;
@property (nonatomic, copy) NSString *currentQuery;
@property (nonatomic, assign) PCLCurseForgeModLoader currentLoader;
@property (nonatomic, assign) PCLCurseForgeSortField currentSort;
@property (nonatomic, copy) NSString *currentGameVersion;
@property (nonatomic, strong) NSArray<NSString *> *gameVersions;

@property (nonatomic, strong) PCLCurseForgeMod *selectedMod;
@property (nonatomic, strong) NSArray<PCLCurseForgeFile *> *selectedModFiles;

@end

@implementation PCLCurseForgeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"CurseForge";
    self.view.backgroundColor = PCLColor(0xF5F7FA);
    
    self.mods = [NSMutableArray array];
    self.currentOffset = 0;
    self.hasMore = YES;
    self.currentQuery = @"";
    self.currentLoader = PCLCurseForgeModLoaderAny;
    self.currentSort = PCLCurseForgeSortFieldTotalDownloads;
    self.currentGameVersion = @"1.20.4";
    self.gameVersions = @[@"1.21", @"1.20.4", @"1.20.2", @"1.20.1", @"1.20", @"1.19.4", @"1.18.2"];
    
    [self setupUI];
    [self checkAPIKey];
}

#pragma mark - Setup

- (void)setupUI {
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.placeholder = "搜索 CurseForge Mods...";
    self.searchBar.delegate = self;
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchBar.backgroundColor = [UIColor whiteColor];
    self.searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.searchBar];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.searchBar.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.searchBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:8],
        [self.searchBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-50],
        [self.searchBar.heightAnchor constraintEqualToConstant:44]
    ]];
    
    self.apiKeyButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.apiKeyButton setTitle:@"🔑" forState:UIControlStateNormal];
    self.apiKeyButton.titleLabel.font = [UIFont systemFontOfSize:18];
    self.apiKeyButton.backgroundColor = [UIColor whiteColor];
    self.apiKeyButton.layer.cornerRadius = 4;
    self.apiKeyButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.apiKeyButton addTarget:self action:@selector(apiKeyButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.apiKeyButton];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.apiKeyButton.topAnchor constraintEqualToAnchor:self.searchBar.topAnchor],
        [self.apiKeyButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-8],
        [self.apiKeyButton.widthAnchor constraintEqualToConstant:44],
        [self.apiKeyButton.heightAnchor constraintEqualToConstant:44]
    ]];
    
    self.filterBar = [[UIView alloc] init];
    self.filterBar.backgroundColor = [UIColor whiteColor];
    self.filterBar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.filterBar];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.filterBar.topAnchor constraintEqualToAnchor:self.searchBar.bottomAnchor],
        [self.filterBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.filterBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.filterBar.heightAnchor constraintEqualToConstant:44]
    ]];
    
    self.loaderFilter = [[UISegmentedControl alloc] initWithItems:@[@"全部", @"Forge", @"Fabric", @"NeoForge"]];
    self.loaderFilter.selectedSegmentIndex = 0;
    self.loaderFilter.translatesAutoresizingMaskIntoConstraints = NO;
    [self.loaderFilter addTarget:self action:@selector(loaderChanged:) forControlEvents:UIControlEventValueChanged];
    [self.filterBar addSubview:self.loaderFilter];
    
    self.versionFilterButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.versionFilterButton setTitle:self.currentGameVersion forState:UIControlStateNormal];
    [self.versionFilterButton setTitleColor:PCLColor(0x343D4A) forState:UIControlStateNormal];
    self.versionFilterButton.backgroundColor = PCLColor(0xF0F0F0);
    self.versionFilterButton.layer.cornerRadius = 4;
    self.versionFilterButton.titleLabel.font = [UIFont systemFontOfSize:12];
    self.versionFilterButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.versionFilterButton addTarget:self action:@selector(versionFilterTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.filterBar addSubview:self.versionFilterButton];
    
    self.sortFilter = [[UISegmentedControl alloc] initWithItems:@[@"下载", @"热门", @"最新"]];
    self.sortFilter.selectedSegmentIndex = 0;
    self.sortFilter.translatesAutoresizingMaskIntoConstraints = NO;
    [self.sortFilter addTarget:self action:@selector(sortChanged:) forControlEvents:UIControlEventValueChanged];
    [self.filterBar addSubview:self.sortFilter];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.loaderFilter.leadingAnchor constraintEqualToAnchor:self.filterBar.leadingAnchor constant:8],
        [self.loaderFilter.centerYAnchor constraintEqualToAnchor:self.filterBar.centerYAnchor],
        [self.loaderFilter.widthAnchor constraintEqualToConstant:140],
        
        [self.versionFilterButton.leadingAnchor constraintEqualToAnchor:self.loaderFilter.trailingAnchor constant:8],
        [self.versionFilterButton.centerYAnchor constraintEqualToAnchor:self.filterBar.centerYAnchor],
        [self.versionFilterButton.widthAnchor constraintEqualToConstant:70],
        [self.versionFilterButton.heightAnchor constraintEqualToConstant:28],
        
        [self.sortFilter.leadingAnchor constraintEqualToAnchor:self.versionFilterButton.trailingAnchor constant:8],
        [self.sortFilter.centerYAnchor constraintEqualToAnchor:self.filterBar.centerYAnchor],
        [self.sortFilter.widthAnchor constraintEqualToConstant:120]
    ]];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = 110;
    [self.tableView registerClass:[PCLCurseForgeModCell class] forCellReuseIdentifier:@"CurseForgeCell"];
    [self.view addSubview:self.tableView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.filterBar.bottomAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor}
    ]];
    
    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    self.loadingIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    self.loadingIndicator.hidesWhenStopped = YES;
    [self.view addSubview:self.loadingIndicator];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.loadingIndicator.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.loadingIndicator.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor]
    ]];
    
    self.emptyLabel = [[UILabel alloc] init];
    self.emptyLabel.text = @"暂无结果";
    self.emptyLabel.font = [UIFont systemFontOfSize:14];
    self.emptyLabel.textColor = PCLColor(0x8C8C8C);
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.emptyLabel.hidden = YES;
    self.emptyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.emptyLabel];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.emptyLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.emptyLabel.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor]
    ]];
}

#pragma mark - API Key

- (void)checkAPIKey {
    NSString *key = [PCLCurseForgeAPI apiKey];
    if (key.length == 0) {
        [self showAPIKeyPrompt];
    } else {
        [self loadMods];
    }
}

- (void)showAPIKeyPrompt {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"需要 API Key"
                                                                  message:@"请输入 CurseForge API Key 以浏览和下载模组。您可以在 https://console.curseforge.com 获取。"
                                                           preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = "API Key";
        textField.secureTextEntry = NO;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *key = alert.textFields.firstObject.text ?: @"";
        if (key.length > 0) {
            [PCLCurseForgeAPI setAPIKey:key];
            [self loadMods];
        }
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)apiKeyButtonTapped {
    NSString *existingKey = [PCLCurseForgeAPI apiKey];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"CurseForge API Key"
                                                                  message:@"管理您的 API Key"
                                                           preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = "API Key";
        textField.text = existingKey;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *key = alert.textFields.firstObject.text ?: @"";
        [PCLCurseForgeAPI setAPIKey:key];
        [self reloadMods];
    }]];
    
    if (existingKey.length > 0) {
        [alert addAction:[UIAlertAction actionWithTitle:@"清除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            [PCLCurseForgeAPI setAPIKey:@""];
            [self.mods removeAllObjects];
            [self.tableView reloadData];
            self.emptyLabel.hidden = NO;
            self.emptyLabel.text = @"请输入 API Key";
        }]];
    }
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Data Loading

- (void)loadMods {
    if (self.isLoading) return;
    
    if ([PCLCurseForgeAPI apiKey].length == 0) {
        self.emptyLabel.hidden = NO;
        self.emptyLabel.text = @"请输入 API Key";
        return;
    }
    
    self.isLoading = YES;
    self.emptyLabel.hidden = YES;
    
    if (self.currentOffset == 0) {
        [self.loadingIndicator startAnimating];
    }
    
    PCLCurseForgeModLoader loaders[] = {
        PCLCurseForgeModLoaderAny,
        PCLCurseForgeModLoaderForge,
        PCLCurseForgeModLoaderFabric,
        PCLCurseForgeModLoaderNeoForge
    };
    
    PCLCurseForgeSortField sortFields[] = {
        PCLCurseForgeSortFieldTotalDownloads,
        PCLCurseForgeSortFieldPopularity,
        PCLCurseForgeSortFieldLastUpdated
    };
    
    [[PCLCurseForgeAPI sharedAPI] searchMods:self.currentQuery
                               gameVersion:self.currentGameVersion
                                  modLoader:loaders[self.loaderFilter.selectedSegmentIndex]
                                   category:nil
                                       sort:sortFields[self.sortFilter.selectedSegmentIndex]
                                  sortOrder:PCLCurseForgeSortOrderDesc
                                      limit:20
                                     offset:self.currentOffset
                                 completion:^(PCLCurseForgeSearchResult *result, NSError *error) {
        self.isLoading = NO;
        [self.loadingIndicator stopAnimating];
        
        if (error) {
            NSLog(@"[CurseForge] Search failed: %@", error);
            if (self.mods.count == 0) {
                self.emptyLabel.hidden = NO;
                self.emptyLabel.text = @"加载失败，请检查 API Key";
            }
            return;
        }
        
        if (self.currentOffset == 0) {
            [self.mods removeAllObjects];
        }
        
        [self.mods addObjectsFromArray:result.data];
        self.hasMore = (self.currentOffset + result.resultCount) < result.totalCount;
        self.currentOffset += result.resultCount;
        
        self.emptyLabel.hidden = (self.mods.count > 0);
        self.emptyLabel.text = self.currentQuery.length > 0 ? @"未找到匹配的 Mods" : @"暂无 Mods";
        [self.tableView reloadData];
    }];
}

- (void)reloadMods {
    self.currentOffset = 0;
    self.hasMore = YES;
    [self loadMods];
}

#pragma mark - Actions

- (void)loaderChanged:(UISegmentedControl *)sender {
    [self reloadMods];
}

- (void)sortChanged:(UISegmentedControl *)sender {
    [self reloadMods];
}

- (void)versionFilterTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"选择游戏版本" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    for (NSString *version in self.gameVersions) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:version style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            self.currentGameVersion = version;
            [self.versionFilterButton setTitle:version forState:UIControlStateNormal];
            [self reloadMods];
        }];
        [alert addAction:action];
    }
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    UIPopoverPresentationController *popover = alert.popoverPresentationController;
    if (popover) {
        popover.sourceView = self.versionFilterButton;
        popover.sourceRect = self.versionFilterButton.bounds;
    }
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Install

- (void)installMod:(PCLCurseForgeMod *)mod {
    self.selectedMod = mod;
    
    [[PCLCurseForgeAPI sharedAPI] filesForMod:mod.modId
                               gameVersion:self.currentGameVersion
                                 modLoader:self.currentLoader
                                completion:^(NSArray<PCLCurseForgeFile *> *files, NSError *error) {
        if (error || files.count == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showInstallError:error ?: [NSError errorWithDomain:@"PCLCurseForge" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"无可用文件"}]];
            });
            return;
        }
        
        self.selectedModFiles = files;
        PCLCurseForgeFile *latestFile = files[0];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showFileSelector:files forMod:mod];
        });
    }];
}

- (void)showFileSelector:(NSArray<PCLCurseForgeFile *> *)files forMod:(PCLCurseForgeMod *)mod {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"选择文件"
                                                                  message:mod.name
                                                           preferredStyle:UIAlertControllerStyleActionSheet];
    
    NSInteger limit = MIN(files.count, 10);
    for (NSInteger i = 0; i < limit; i++) {
        PCLCurseForgeFile *file = files[i];
        NSString *title = [NSString stringWithFormat:@"%@ (%@)", file.displayName, file.gameVersion];
        UIAlertAction *action = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            [self downloadFile:file forMod:mod];
        }];
        [alert addAction:action];
    }
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    UIPopoverPresentationController *popover = alert.popoverPresentationController;
    if (popover) {
        popover.sourceView = self.view;
        popover.sourceRect = CGRectMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2, 0, 0);
    }
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)downloadFile:(PCLCurseForgeFile *)file forMod:(PCLCurseForgeMod *)mod {
    if (file.downloadUrl.length == 0) {
        [[PCLCurseForgeAPI sharedAPI] downloadUrlForFile:mod.modId
                                                 fileId:file.fileId
                                             completion:^(NSString *downloadUrl, NSError *error) {
            if (error || downloadUrl.length == 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showInstallError:error ?: [NSError errorWithDomain:@"PCLCurseForge" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"无法获取下载链接"}]];
                });
                return;
            }
            
            [self performDownload:file downloadUrl:downloadUrl forMod:mod];
        }];
    } else {
        [self performDownload:file downloadUrl:file.downloadUrl forMod:mod];
    }
}

- (void)performDownload:(PCLCurseForgeFile *)file downloadUrl:(NSString *)downloadUrl forMod:(PCLCurseForgeMod *)mod {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *modsDir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"curseforge_mods"];
    [fm createDirectoryAtPath:modsDir withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *targetPath = [modsDir stringByAppendingPathComponent:file.fileName];
    
    PCLDownloadTask *task = [[PCLDownloadTask alloc] init];
    task.url = downloadUrl;
    task.targetPath = targetPath;
    task.displayName = [NSString stringWithFormat:@"%@ - %@", mod.name, file.displayName];
    task.resourceType = PCLResourceTypeMod;
    
    [[PCLDownloadManager sharedManager] addTask:task];
    [[PCLDownloadManager sharedManager] startDownload:task];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"开始下载"
                                                                  message:[NSString stringWithFormat:@"%@ 已开始下载", file.displayName]
                                                           preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showInstallError:(NSError *)error {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"下载失败"
                                                                  message:error.localizedDescription ?: @"未知错误"
                                                           preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    self.currentQuery = searchBar.text ?: @"";
    [self reloadMods];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (searchText.length == 0) {
        self.currentQuery = @"";
        [self reloadMods];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.mods.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PCLCurseForgeModCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CurseForgeCell" forIndexPath:indexPath];
    
    PCLCurseForgeMod *mod = self.mods[indexPath.row];
    
    cell.nameLabel.text = mod.name;
    cell.authorLabel.text = [NSString stringWithFormat:@"by %@", mod.authorName];
    cell.downloadsLabel.text = [NSString stringWithFormat:@"⬇ %@", PCLFormatDownloads(mod.downloadCount)];
    cell.descriptionLabel.text = mod.summary;
    
    if (cell.iconImageView && mod.iconUrl.length > 0) {
        NSURL *url = [NSURL URLWithString:mod.iconUrl];
        if (url) {
            NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                if (data) {
                    UIImage *image = [UIImage imageWithData:data];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        cell.iconImageView.image = image;
                    });
                }
            }];
            [task resume];
        }
    }
    
    __weak typeof(self) weakSelf = self;
    cell.onInstall = ^{
        [weakSelf installMod:mod];
    };
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == self.mods.count - 5 && self.hasMore && !self.isLoading) {
        [self loadMods];
    }
}

@end
