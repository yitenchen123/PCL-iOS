#import "PCLDownloadRightView.h"
#import "PCLCEPageAnimator.h"
#import "PCLNetworkUtils.h"
#import "PCLVersionManager.h"
#import "PCLDownloadManager.h"
#import "PCLModLoaderAPI.h"
#import "PCLProfileStore.h"
#import <QuartzCore/QuartzCore.h>

static UIColor *PCLColor(NSUInteger rgb) {
    return [UIColor colorWithRed:((rgb >> 16) & 255) / 255.0
                           green:((rgb >> 8) & 255) / 255.0
                            blue:(rgb & 255) / 255.0
                           alpha:1.0];
}

@interface PCLDownloadVersionCell : UITableViewCell
@property (nonatomic, strong) UILabel *versionLabel;
@property (nonatomic, strong) UILabel *typeLabel;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UIButton *downloadButton;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, copy) void (^onDownload)(void);
@end

@implementation PCLDownloadVersionCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor clearColor];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.versionLabel = [[UILabel alloc] init];
    self.versionLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    self.versionLabel.textColor = PCLColor(0x343D4A);
    self.versionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.versionLabel];
    
    self.typeLabel = [[UILabel alloc] init];
    self.typeLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    self.typeLabel.textColor = [UIColor whiteColor];
    self.typeLabel.backgroundColor = PCLColor(0x1370F3);
    self.typeLabel.layer.cornerRadius = 3;
    self.typeLabel.clipsToBounds = YES;
    self.typeLabel.textAlignment = NSTextAlignmentCenter;
    self.typeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.typeLabel];
    
    self.dateLabel = [[UILabel alloc] init];
    self.dateLabel.font = [UIFont systemFontOfSize:12];
    self.dateLabel.textColor = PCLColor(0x8C8C8C);
    self.dateLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.dateLabel];
    
    self.downloadButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.downloadButton setTitle:@"下载" forState:UIControlStateNormal];
    [self.downloadButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.downloadButton.backgroundColor = PCLColor(0x1370F3);
    self.downloadButton.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    self.downloadButton.layer.cornerRadius = 6;
    self.downloadButton.clipsToBounds = YES;
    self.downloadButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.downloadButton addTarget:self action:@selector(downloadTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.downloadButton];
    
    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.progressView.translatesAutoresizingMaskIntoConstraints = NO;
    self.progressView.progressTintColor = PCLColor(0x1370F3);
    self.progressView.trackTintColor = PCLColor(0xE0EAFD);
    self.progressView.hidden = YES;
    [self.contentView addSubview:self.progressView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.versionLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:14],
        [self.versionLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
        
        [self.typeLabel.centerYAnchor constraintEqualToAnchor:self.versionLabel.centerYAnchor],
        [self.typeLabel.leadingAnchor constraintEqualToAnchor:self.versionLabel.trailingAnchor constant:8],
        [self.typeLabel.widthAnchor constraintEqualToConstant:42],
        [self.typeLabel.heightAnchor constraintEqualToConstant:18],
        [self.typeLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.downloadButton.leadingAnchor constant:-12],
        
        [self.dateLabel.topAnchor constraintEqualToAnchor:self.versionLabel.bottomAnchor constant:4],
        [self.dateLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
        [self.dateLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-14],
        
        [self.downloadButton.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [self.downloadButton.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
        [self.downloadButton.widthAnchor constraintEqualToConstant:72],
        [self.downloadButton.heightAnchor constraintEqualToConstant:32],
        
        [self.progressView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
        [self.progressView.trailingAnchor constraintEqualToAnchor:self.downloadButton.leadingAnchor constant:-12],
        [self.progressView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-8]
    ]];
}

- (void)downloadTapped {
    if (self.onDownload) self.onDownload();
}

@end

@interface PCLDownloadRightView () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIStackView *cardStackView;
@property (nonatomic, strong) UIView *filterCard;
@property (nonatomic, strong) UISegmentedControl *typeFilter;
@property (nonatomic, strong) UITableView *versionTableView;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *allVersions;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *filteredVersions;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIView *loadingView;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic) PCLDownloadTab currentTab;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@end

@implementation PCLDownloadRightView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _allVersions = [NSMutableArray array];
        _filteredVersions = [NSMutableArray array];
        _currentTab = PCLDownloadTabMinecraft;
        [self setupView];
    }
    return self;
}

- (void)setupView {
    self.backgroundColor = [UIColor clearColor];
    
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.refreshControl = [[UIRefreshControl alloc] init];
    [self.scrollView.refreshControl addTarget:self action:@selector(refreshData) forControlEvents:UIControlEventValueChanged];
    [self addSubview:self.scrollView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
    ]];
    
    self.cardStackView = [[UIStackView alloc] init];
    self.cardStackView.translatesAutoresizingMaskIntoConstraints = NO;
    self.cardStackView.axis = UILayoutConstraintAxisVertical;
    self.cardStackView.spacing = 16;
    self.cardStackView.alignment = UIStackViewAlignmentFill;
    self.cardStackView.distribution = UIStackViewDistributionFill;
    [self.scrollView addSubview:self.cardStackView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.cardStackView.topAnchor constraintEqualToAnchor:self.scrollView.topAnchor constant:16],
        [self.cardStackView.leadingAnchor constraintEqualToAnchor:self.scrollView.leadingAnchor constant:16],
        [self.cardStackView.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor constant:-16],
        [self.cardStackView.bottomAnchor constraintEqualToAnchor:self.scrollView.bottomAnchor constant:-16],
        [self.cardStackView.widthAnchor constraintEqualToAnchor:self.scrollView.widthAnchor constant:-32]
    ]];
    
    [self buildFilterCard];
    [self buildVersionListCard];
    [self buildLoadingView];
}

- (void)buildFilterCard {
    self.filterCard = [[UIView alloc] init];
    self.filterCard.backgroundColor = [UIColor whiteColor];
    self.filterCard.layer.cornerRadius = 10;
    self.filterCard.layer.shadowColor = [UIColor blackColor].CGColor;
    self.filterCard.layer.shadowOpacity = 0.06;
    self.filterCard.layer.shadowRadius = 8;
    self.filterCard.layer.shadowOffset = CGSizeMake(0, 2);
    self.filterCard.translatesAutoresizingMaskIntoConstraints = NO;
    
    UILabel *filterTitle = [[UILabel alloc] init];
    filterTitle.text = @"筛选";
    filterTitle.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    filterTitle.textColor = PCLColor(0x343D4A);
    filterTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [self.filterCard addSubview:filterTitle];
    
    self.typeFilter = [[UISegmentedControl alloc] initWithItems:@[@"全部", @"正式版", @"快照版", @"旧版本"]];
    self.typeFilter.selectedSegmentIndex = 0;
    self.typeFilter.translatesAutoresizingMaskIntoConstraints = NO;
    self.typeFilter.backgroundColor = PCLColor(0xF5F5F5);
    [self.typeFilter addTarget:self action:@selector(filterChanged:) forControlEvents:UIControlEventValueChanged];
    [self.filterCard addSubview:self.typeFilter];
    
    [NSLayoutConstraint activateConstraints:@[
        [filterTitle.topAnchor constraintEqualToAnchor:self.filterCard.topAnchor constant:16],
        [filterTitle.leadingAnchor constraintEqualToAnchor:self.filterCard.leadingAnchor constant:16],
        [filterTitle.trailingAnchor constraintEqualToAnchor:self.filterCard.trailingAnchor constant:-16],
        
        [self.typeFilter.topAnchor constraintEqualToAnchor:filterTitle.bottomAnchor constant:12],
        [self.typeFilter.leadingAnchor constraintEqualToAnchor:self.filterCard.leadingAnchor constant:16],
        [self.typeFilter.trailingAnchor constraintEqualToAnchor:self.filterCard.trailingAnchor constant:-16],
        [self.typeFilter.bottomAnchor constraintEqualToAnchor:self.filterCard.bottomAnchor constant:-16],
        [self.typeFilter.heightAnchor constraintEqualToConstant:36]
    ]];
    
    [self.cardStackView addArrangedSubview:self.filterCard];
}

- (void)buildVersionListCard {
    UIView *listCard = [[UIView alloc] init];
    listCard.backgroundColor = [UIColor whiteColor];
    listCard.layer.cornerRadius = 10;
    listCard.layer.shadowColor = [UIColor blackColor].CGColor;
    listCard.layer.shadowOpacity = 0.06;
    listCard.layer.shadowRadius = 8;
    listCard.layer.shadowOffset = CGSizeMake(0, 2);
    listCard.translatesAutoresizingMaskIntoConstraints = NO;
    
    UILabel *listTitle = [[UILabel alloc] init];
    listTitle.text = @"可用版本";
    listTitle.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    listTitle.textColor = PCLColor(0x343D4A);
    listTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [listCard addSubview:listTitle];
    
    self.versionTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.versionTableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.versionTableView.delegate = self;
    self.versionTableView.dataSource = self;
    self.versionTableView.backgroundColor = [UIColor clearColor];
    self.versionTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.versionTableView.rowHeight = 72;
    self.versionTableView.scrollEnabled = NO;
    self.versionTableView.allowsSelection = NO;
    [self.versionTableView registerClass:[PCLDownloadVersionCell class] forCellReuseIdentifier:@"VersionCell"];
    [listCard addSubview:self.versionTableView];
    
    self.emptyLabel = [[UILabel alloc] init];
    self.emptyLabel.text = @"暂无可用版本";
    self.emptyLabel.font = [UIFont systemFontOfSize:14];
    self.emptyLabel.textColor = PCLColor(0x8C8C8C);
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.emptyLabel.hidden = YES;
    self.emptyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [listCard addSubview:self.emptyLabel];
    
    [NSLayoutConstraint activateConstraints:@[
        [listTitle.topAnchor constraintEqualToAnchor:listCard.topAnchor constant:16],
        [listTitle.leadingAnchor constraintEqualToAnchor:listCard.leadingAnchor constant:16],
        [listTitle.trailingAnchor constraintEqualToAnchor:listCard.trailingAnchor constant:-16],
        
        [self.versionTableView.topAnchor constraintEqualToAnchor:listTitle.bottomAnchor constant:12],
        [self.versionTableView.leadingAnchor constraintEqualToAnchor:listCard.leadingAnchor],
        [self.versionTableView.trailingAnchor constraintEqualToAnchor:listCard.trailingAnchor],
        [self.versionTableView.bottomAnchor constraintEqualToAnchor:listCard.bottomAnchor constant:-8],
        [self.versionTableView.heightAnchor constraintEqualToConstant:400],
        
        [self.emptyLabel.centerXAnchor constraintEqualToAnchor:listCard.centerXAnchor],
        [self.emptyLabel.centerYAnchor constraintEqualToAnchor:listCard.centerYAnchor],
        [self.emptyLabel.heightAnchor constraintEqualToConstant:44]
    ]];
    
    [self.cardStackView addArrangedSubview:listCard];
}

- (void)buildLoadingView {
    self.loadingView = [[UIView alloc] init];
    self.loadingView.backgroundColor = PCLColor(0xF5F5F5);
    self.loadingView.layer.cornerRadius = 10;
    self.loadingView.translatesAutoresizingMaskIntoConstraints = NO;
    self.loadingView.hidden = YES;
    [self addSubview:self.loadingView];
    
    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    self.loadingIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    [self.loadingView addSubview:self.loadingIndicator];
    
    UILabel *loadingLabel = [[UILabel alloc] init];
    loadingLabel.text = @"正在加载版本列表...";
    loadingLabel.font = [UIFont systemFontOfSize:14];
    loadingLabel.textColor = PCLColor(0x8C8C8C);
    loadingLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.loadingView addSubview:loadingLabel];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.loadingView.topAnchor constraintEqualToAnchor:self.topAnchor constant:16],
        [self.loadingView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:16],
        [self.loadingView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-16],
        [self.loadingView.heightAnchor constraintEqualToConstant:120],
        
        [self.loadingIndicator.centerXAnchor constraintEqualToAnchor:self.loadingView.centerXAnchor constant:-60],
        [self.loadingIndicator.centerYAnchor constraintEqualToAnchor:self.loadingView.centerYAnchor],
        
        [loadingLabel.centerYAnchor constraintEqualToAnchor:self.loadingView.centerYAnchor],
        [loadingLabel.leadingAnchor constraintEqualToAnchor:self.loadingIndicator.trailingAnchor constant:8]
    ]];
}

- (void)switchToTab:(PCLDownloadTab)tab {
    self.currentTab = tab;
    
    NSString *titles[] = {
        @"Minecraft", @"Mod", @"整合包", @"数据包", @"资源包", @"光影", @"世界", @"收藏",
        @"客户端安装", @"OptiFine", @"Forge", @"NeoForge", @"Fabric", @"LiteLoader"
    };
    
    NSInteger index = (NSInteger)tab;
    if (index >= 0 && index < 14) {
        [self setTitle:titles[index]];
    }
    
    [self refreshData];
}

- (void)setTitle:(NSString *)title {
    UILabel *titleLabel = nil;
    for (UIView *subview in self.subviews) {
        if ([subview isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)subview;
            if (label.font.pointSize == 20) {
                titleLabel = label;
                break;
            }
        }
    }
    if (!titleLabel) return;
    titleLabel.text = title;
}

- (void)refreshData {
    if (self.currentTab == PCLDownloadTabMinecraft || self.currentTab == PCLDownloadTabClientInstall) {
        [self loadMinecraftVersions];
    } else {
        [self loadModLoaderVersions];
    }
}

- (void)loadMinecraftVersions {
    self.loadingView.hidden = NO;
    [self.loadingIndicator startAnimating];
    self.emptyLabel.hidden = YES;
    
    [[PCLVersionManager sharedManager] fetchRemoteManifest:^(NSArray<NSDictionary *> *versions, NSError *error) {
        self.loadingView.hidden = YES;
        [self.loadingIndicator stopAnimating];
        [self.scrollView.refreshControl endRefreshing];
        
        if (error) {
            NSLog(@"[Download] Failed to fetch manifest: %@", error);
            return;
        }
        
        [self.allVersions removeAllObjects];
        [self.allVersions addObjectsFromArray:versions];
        [self applyFilter];
    }];
}

- (void)loadModLoaderVersions {
    [self.allVersions removeAllObjects];
    
    if (self.currentTab == PCLDownloadTabForge) {
        [self loadForgeVersions];
    } else if (self.currentTab == PCLDownloadTabFabric) {
        [self loadFabricVersions];
    } else if (self.currentTab == PCLDownloadTabNeoForge) {
        [self loadNeoForgeVersions];
    } else if (self.currentTab == PCLDownloadTabOptiFine) {
        [self loadOptiFineVersions];
    } else {
        [self.filteredVersions removeAllObjects];
        [self.versionTableView reloadData];
        self.emptyLabel.hidden = NO;
        self.emptyLabel.text = @"该功能正在开发中";
    }
}

- (void)loadForgeVersions {
    self.loadingView.hidden = NO;
    [self.loadingIndicator startAnimating];
    
    [[PCLModLoaderAPI sharedAPI] fetchForgeVersions:@"1.20.4" completion:^(NSArray *versions, NSError *error) {
        self.loadingView.hidden = YES;
        [self.loadingIndicator stopAnimating];
        [self.scrollView.refreshControl endRefreshing];
        
        if (versions.count > 0) {
            [self.allVersions removeAllObjects];
            for (id v in versions) {
                if ([v isKindOfClass:[NSDictionary class]]) {
                    [self.allVersions addObject:v];
                }
            }
            [self applyFilter];
        }
    }];
}

- (void)loadFabricVersions {
    self.loadingView.hidden = NO;
    [self.loadingIndicator startAnimating];
    
    [[PCLModLoaderAPI sharedAPI] fetchFabricVersions:@"1.20.4" completion:^(NSArray *versions, NSError *error) {
        self.loadingView.hidden = YES;
        [self.loadingIndicator stopAnimating];
        [self.scrollView.refreshControl endRefreshing];
        
        if (versions.count > 0) {
            [self.allVersions removeAllObjects];
            for (id v in versions) {
                NSString *ver = [v valueForKey:@"version"];
                if (ver) {
                    [self.allVersions addObject:@{@"version": ver, @"type": @"fabric"}];
                }
            }
            [self applyFilter];
        }
    }];
}

- (void)loadNeoForgeVersions {
    self.loadingView.hidden = NO;
    [self.loadingIndicator startAnimating];
    
    [[PCLModLoaderAPI sharedAPI] fetchNeoForgeVersions:@"1.20.4" completion:^(NSArray *versions, NSError *error) {
        self.loadingView.hidden = YES;
        [self.loadingIndicator stopAnimating];
        [self.scrollView.refreshControl endRefreshing];
        
        if (versions.count > 0) {
            [self.allVersions removeAllObjects];
            for (id v in versions) {
                NSString *ver = [v valueForKey:@"version"];
                if (ver) {
                    [self.allVersions addObject:@{@"version": ver, @"type": @"neoforge"}];
                }
            }
            [self applyFilter];
        }
    }];
}

- (void)loadOptiFineVersions {
    self.loadingView.hidden = NO;
    [self.loadingIndicator startAnimating];
    
    [[PCLModLoaderAPI sharedAPI] fetchOptiFineVersions:^(NSArray<NSDictionary *> *versions, NSError *error) {
        self.loadingView.hidden = YES;
        [self.loadingIndicator stopAnimating];
        [self.scrollView.refreshControl endRefreshing];
        
        if (versions.count > 0) {
            [self.allVersions removeAllObjects];
            [self.allVersions addObjectsFromArray:versions];
            [self applyFilter];
        }
    }];
}

- (void)filterChanged:(UISegmentedControl *)sender {
    [self applyFilter];
}

- (void)applyFilter {
    NSInteger filterIndex = self.typeFilter.selectedSegmentIndex;
    
    [self.filteredVersions removeAllObjects];
    
    for (NSDictionary *version in self.allVersions) {
        NSString *type = version[@"type"] ?: @"";
        
        BOOL shouldInclude = NO;
        switch (filterIndex) {
            case 0: shouldInclude = YES; break;
            case 1: shouldInclude = [type isEqualToString:@"release"]; break;
            case 2: shouldInclude = [type isEqualToString:@"snapshot"]; break;
            case 3: shouldInclude = [type isEqualToString:@"old_alpha"] || [type isEqualToString:@"old_beta"]; break;
        }
        
        if (shouldInclude) {
            [self.filteredVersions addObject:version];
        }
    }
    
    self.emptyLabel.hidden = (self.filteredVersions.count > 0);
    if (self.filteredVersions.count == 0) {
        self.emptyLabel.text = @"没有符合条件的版本";
    }
    
    [self.versionTableView reloadData];
    
    CGFloat rowHeight = 72;
    CGFloat tableHeight = MAX(200, self.filteredVersions.count * rowHeight);
    for (NSLayoutConstraint *constraint in self.versionTableView.constraints) {
        if (constraint.firstAttribute == NSLayoutAttributeHeight) {
            constraint.constant = tableHeight;
            break;
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filteredVersions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PCLDownloadVersionCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VersionCell" forIndexPath:indexPath];
    
    NSDictionary *version = self.filteredVersions[indexPath.row];
    NSString *versionId = version[@"id"] ?: version[@"version"] ?: @"";
    NSString *type = version[@"type"] ?: @"";
    NSString *releaseTime = version[@"releaseTime"] ?: @"";
    
    cell.versionLabel.text = versionId;
    
    if ([type isEqualToString:@"release"]) {
        cell.typeLabel.text = @"正式版";
        cell.typeLabel.backgroundColor = PCLColor(0x1370F3);
    } else if ([type isEqualToString:@"snapshot"]) {
        cell.typeLabel.text = @"快照";
        cell.typeLabel.backgroundColor = PCLColor(0xF39C12);
    } else if ([type isEqualToString:@"old_alpha"]) {
        cell.typeLabel.text = @"Alpha";
        cell.typeLabel.backgroundColor = PCLColor(0x8C8C8C);
    } else if ([type isEqualToString:@"old_beta"]) {
        cell.typeLabel.text = @"Beta";
        cell.typeLabel.backgroundColor = PCLColor(0x8C8C8C);
    } else if ([type isEqualToString:@"forge"]) {
        cell.typeLabel.text = @"Forge";
        cell.typeLabel.backgroundColor = PCLColor(0xE67E22);
    } else if ([type isEqualToString:@"fabric"]) {
        cell.typeLabel.text = @"Fabric";
        cell.typeLabel.backgroundColor = PCLColor(0x9B59B6);
    } else {
        cell.typeLabel.text = type;
        cell.typeLabel.backgroundColor = PCLColor(0x8C8C8C);
    }
    
    if (releaseTime.length > 10) {
        cell.dateLabel.text = [releaseTime substringToIndex:10];
    } else {
        cell.dateLabel.text = releaseTime;
    }
    
    NSString *urlString = version[@"url"] ?: version[@"downloadURL"] ?: version[@"jar"] ?: @"";
    cell.onDownload = ^{
        [self downloadVersion:versionId url:urlString];
    };
    
    return cell;
}

- (void)downloadVersion:(NSString *)versionId url:(NSString *)urlString {
    if (urlString.length == 0) {
        NSLog(@"[Download] No URL for version %@", versionId);
        return;
    }
    
    NSString *versionsDir = [[PCLVersionManager sharedManager] versionsDirectory];
    NSString *versionDir = [versionsDir stringByAppendingPathComponent:versionId];
    NSString *jsonPath = [versionDir stringByAppendingPathComponent:[versionId stringByAppendingString:@".json"]];
    
    PCLDownloadTask *task = [[PCLDownloadTask alloc] init];
    task.url = urlString;
    task.targetPath = jsonPath;
    task.displayName = [NSString stringWithFormat:@"Minecraft %@", versionId];
    task.resourceType = PCLResourceTypeClient;
    
    [[PCLDownloadManager sharedManager] addTask:task];
    [[PCLDownloadManager sharedManager] startDownload:task];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"开始下载" message:[NSString stringWithFormat:@"版本 %@ 已开始下载", versionId] preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    
    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    [rootVC presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Animation

- (void)dismissTransientUI {
}

- (void)prepareCEEnterAnimation {
    self.filterCard.alpha = 0;
    self.filterCard.transform = CGAffineTransformMakeTranslation(0, 20);
    self.versionTableView.alpha = 0;
    self.versionTableView.transform = CGAffineTransformMakeTranslation(0, 20);
}

- (void)playCEEnterAnimation {
    [PCLCEPageAnimator showRightItems:@[self.filterCard] scrollView:self.scrollView];
}

- (void)playCEExitAnimation {
    [PCLCEPageAnimator hideRightItems:@[self.filterCard] scrollView:self.scrollView];
}

- (void)reloadState {
    [self refreshData];
}

@end
