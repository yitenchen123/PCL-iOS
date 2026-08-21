#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, PCLDownloadTab) {
    PCLDownloadTabMinecraft = 0,
    PCLDownloadTabMod,
    PCLDownloadTabModpack,
    PCLDownloadTabDataPack,
    PCLDownloadTabResourcePack,
    PCLDownloadTabShader,
    PCLDownloadTabWorld,
    PCLDownloadTabFavorites,
    PCLDownloadTabClientInstall,
    PCLDownloadTabOptiFine,
    PCLDownloadTabForge,
    PCLDownloadTabNeoForge,
    PCLDownloadTabFabric,
    PCLDownloadTabLiteLoader
};

@interface PCLDownloadViewController : UIViewController

@property (nonatomic, assign) CGFloat leftPanelWidth;
@property (nonatomic, copy) void (^onSelectInstallTab)(PCLDownloadTab tab);

@property (nonatomic, copy) void (^onCreateProfile)(void);

@property (nonatomic, copy) void (^onLaunch)(void);

@property (nonatomic, copy) void (^onSelectInstance)(void);
@property (nonatomic, copy) void (^onInstanceSettings)(void);
@property (nonatomic, copy) void (^onSkinOptions)(void);
@property (nonatomic, copy) void (^onEditProfile)(void);

@property (nonatomic, copy) void (^onCloseHint)(void);

@property (nonatomic, copy) void (^onOpenDownload)(void);
- (void)dismissTransientUI;
- (void)prepareCEEnterAnimation;
- (void)playCEEnterAnimation;
- (void)playCEExitWithCompletion:(dispatch_block_t)completion;
- (void)reloadState;

@end
