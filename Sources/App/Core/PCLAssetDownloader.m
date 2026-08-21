#import "PCLAssetDownloader.h"
#import "PCLDownloadManager.h"
#import "PCLLogger.h"

static const NSInteger kPCLAssetMaxConcurrentDownloads = 8;

@interface PCLAssetDownloader ()

@property (nonatomic, copy) PCLAssetDownloadProgressBlock progressBlock;
@property (nonatomic, copy) PCLAssetDownloadCompletionBlock completionBlock;
@property (nonatomic, strong) NSArray<NSDictionary *> *assetObjects;
@property (nonatomic, assign) NSInteger totalAssets;
@property (nonatomic, assign) NSInteger completedAssets;
@property (nonatomic, assign) NSInteger failedAssets;
@property (nonatomic, strong) NSOperationQueue *downloadQueue;
@property (nonatomic, strong) NSString *assetsDir;
@property (nonatomic, assign) BOOL cancelled;

@end

@implementation PCLAssetDownloader

+ (void)downloadAssetsWithIndexId:(NSString *)indexId
                        assetsDir:(NSString *)assetsDir
                         progress:(PCLAssetDownloadProgressBlock)progress
                       completion:(PCLAssetDownloadCompletionBlock)completion {
    
    NSString *indexPath = [[assetsDir stringByAppendingPathComponent:@"indexes"] stringByAppendingPathComponent:[indexId stringByAppendingString:@".json"]];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:indexPath]) {
        if (completion) {
            completion(NO, [NSError errorWithDomain:@"PCLAssetDownloader" code:-1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Asset index not found: %@", indexPath]}]);
        }
        return;
    }
    
    NSData *data = [NSData dataWithContentsOfFile:indexPath];
    NSError *jsonError = nil;
    NSDictionary *indexJson = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
    
    if (jsonError) {
        if (completion) {
            completion(NO, jsonError);
        }
        return;
    }
    
    [self downloadAssetsWithIndexJson:indexJson assetsDir:assetsDir progress:progress completion:completion];
}

+ (void)downloadAssetsWithIndexJson:(NSDictionary *)indexJson
                          assetsDir:(NSString *)assetsDir
                           progress:(PCLAssetDownloadProgressBlock)progress
                         completion:(PCLAssetDownloadCompletionBlock)completion {
    
    PCLAssetDownloader *downloader = [[PCLAssetDownloader alloc] init];
    downloader.progressBlock = progress;
    downloader.completionBlock = completion;
    downloader.assetsDir = assetsDir;
    downloader.downloadQueue = [[NSOperationQueue alloc] init];
    downloader.downloadQueue.maxConcurrentOperationCount = kPCLAssetMaxConcurrentDownloads;
    downloader.downloadQueue.name = @"com.pcl-ios.asset-download";
    
    [downloader startDownloadWithIndexJson:indexJson];
}

- (void)startDownloadWithIndexJson:(NSDictionary *)indexJson {
    NSDictionary *objects = indexJson[@"objects"];
    if (!objects || objects.count == 0) {
        [[PCLLogger sharedLogger] info:@"[AssetDownloader] No assets to download"];
        if (self.completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.completionBlock(YES, nil);
            });
        }
        return;
    }
    
    // Collect all asset entries
    NSMutableArray *assetList = [NSMutableArray array];
    for (NSString *key in objects) {
        NSDictionary *entry = objects[key];
        NSString *hash = entry[@"hash"];
        long long size = [entry[@"size"] longLongValue];
        if (hash && hash.length >= 2) {
            [assetList addObject:@{
                @"key": key,
                @"hash": hash,
                @"size": @(size)
            }];
        }
    }
    
    self.assetObjects = assetList;
    self.totalAssets = assetList.count;
    self.completedAssets = 0;
    self.failedAssets = 0;
    
    [[PCLLogger sharedLogger] info:[NSString stringWithFormat:@"[AssetDownloader] Starting download of %ld assets", (long)self.totalAssets]];
    
    [self reportProgress:0.0 message:[NSString stringWithFormat:@"准备下载 %ld 个资源文件...", (long)self.totalAssets]];
    
    // Download all assets concurrently
    dispatch_group_t group = dispatch_group_create();
    
    for (NSDictionary *asset in self.assetObjects) {
        if (self.cancelled) break;
        
        dispatch_group_enter(group);
        
        NSString *hash = asset[@"hash"];
        NSString *key = asset[@"key"];
        long long size = [asset[@"size"] longLongValue];
        
        [self downloadSingleAsset:hash key:key size:size withGroup:group];
    }
    
    dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (self.cancelled) {
            if (self.completionBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.completionBlock(NO, [NSError errorWithDomain:@"PCLAssetDownloader" code:-2 userInfo:@{NSLocalizedDescriptionKey: @"Download cancelled"}]);
                });
            }
            return;
        }
        
        if (self.failedAssets > 0) {
            [[PCLLogger sharedLogger] warning:[NSString stringWithFormat:@"[AssetDownloader] %ld assets failed to download", (long)self.failedAssets]];
        }
        
        [[PCLLogger sharedLogger] info:[NSString stringWithFormat:@"[AssetDownloader] Completed: %ld/%ld assets", (long)self.completedAssets, (long)self.totalAssets]];
        
        if (self.completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.completionBlock(self.failedAssets == 0, self.failedAssets > 0 ? [NSError errorWithDomain:@"PCLAssetDownloader" code:-3 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"%ld assets failed", (long)self.failedAssets]}] : nil);
            });
        }
    });
}

- (void)downloadSingleAsset:(NSString *)hash key:(NSString *)key size:(long long)size withGroup:(dispatch_group_t)group {
    // Asset path: assets/objects/<hash前2位>/<完整hash>
    NSString *prefix = [hash substringToIndex:2];
    NSString *objectsDir = [self.assetsDir stringByAppendingPathComponent:@"objects"];
    NSString *hashDir = [objectsDir stringByAppendingPathComponent:prefix];
    NSString *filePath = [hashDir stringByAppendingPathComponent:hash];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm createDirectoryAtPath:hashDir withIntermediateDirectories:YES attributes:nil error:nil];
    
    // Check if file already exists and has correct size
    if ([fm fileExistsAtPath:filePath]) {
        NSDictionary *attrs = [fm attributesOfItemAtPath:filePath error:nil];
        long long existingSize = [attrs fileSize];
        if (existingSize == size) {
            @synchronized(self) {
                self.completedAssets++;
            }
            [self reportProgressProgress];
            dispatch_group_leave(group);
            return;
        }
    }
    
    // Download from resources.download.minecraft.net
    NSString *assetUrl = [NSString stringWithFormat:@"https://resources.download.minecraft.net/%@/%@", prefix, hash];
    NSString *mirroredUrl = [[PCLDownloadManager sharedManager] replaceURLWithDownloadSource:assetUrl];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        __block NSError *downloadError = nil;
        
        [[PCLDownloadManager sharedManager] downloadFile:mirroredUrl toPath:filePath sha1:hash success:^{
            dispatch_semaphore_signal(sema);
        } failure:^(NSError *error) {
            downloadError = error;
            dispatch_semaphore_signal(sema);
        }];
        
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        
        if (downloadError) {
            [[PCLLogger sharedLogger] warning:[NSString stringWithFormat:@"[AssetDownloader] Failed to download asset: %@ (%@)", key, downloadError.localizedDescription]];
            @synchronized(self) {
                self.failedAssets++;
            }
        } else {
            // Verify size
            NSDictionary *attrs = [fm attributesOfItemAtPath:filePath error:nil];
            if ([attrs fileSize] != size) {
                [[PCLLogger sharedLogger] warning:[NSString stringWithFormat:@"[AssetDownloader] Size mismatch for %@: expected %lld, got %lld", key, size, [attrs fileSize]]];
                [fm removeItemAtPath:filePath error:nil];
                @synchronized(self) {
                    self.failedAssets++;
                }
            } else {
                @synchronized(self) {
                    self.completedAssets++;
                }
            }
        }
        
        [self reportProgressProgress];
        dispatch_group_leave(group);
    });
}

- (void)reportProgressProgress {
    double progress = self.totalAssets > 0 ? (double)(self.completedAssets + self.failedAssets) / (double)self.totalAssets : 0;
    NSString *msg = [NSString stringWithFormat:@"资源文件: %ld/%ld", (long)(self.completedAssets + self.failedAssets), (long)self.totalAssets];
    [self reportProgress:progress message:msg];
}

- (void)reportProgress:(double)progress message:(NSString *)message {
    if (self.progressBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressBlock(progress, message);
        });
    }
}

@end
