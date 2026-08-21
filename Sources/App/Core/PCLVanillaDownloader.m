#import "PCLVanillaDownloader.h"
#import "PCLDownloadManager.h"
#import "PCLLogger.h"
#import "PCLAssetDownloader.h"
#import "PCLLibraryDownloader.h"
#import <CommonCrypto/CommonDigest.h>

static NSString *const kVersionManifestURL = @"https://piston-meta.mojang.com/mc/game/version_manifest_v2.json";

@interface PCLVanillaDownloader ()

@property (nonatomic, readwrite) PCLVanillaDownloadStep currentStep;
@property (nonatomic, readwrite, getter=isDownloading) BOOL downloading;
@property (nonatomic, copy) NSString *currentVersionId;
@property (nonatomic, copy) PCLVanillaDownloadProgressBlock progressBlock;
@property (nonatomic, copy) PCLVanillaDownloadCompletionBlock completionBlock;
@property (nonatomic, strong) NSDictionary *versionJson;
@property (nonatomic, strong) PCLVersionInfo *versionInfo;
@property (nonatomic, strong) NSArray<NSDictionary *> *manifestVersions;

@end

@implementation PCLVanillaDownloader

+ (instancetype)sharedDownloader {
    static PCLVanillaDownloader *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PCLVanillaDownloader alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _currentStep = PCLVanillaDownloadStepIdle;
    }
    return self;
}

#pragma mark - Public Methods

- (void)downloadVersion:(NSString *)versionId
               progress:(PCLVanillaDownloadProgressBlock)progress
             completion:(PCLVanillaDownloadCompletionBlock)completion {
    
    if (self.isDownloading) {
        if (completion) {
            completion(NO, [NSError errorWithDomain:@"PCLVanillaDownloader" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Another download is in progress"}]);
        }
        return;
    }
    
    self.downloading = YES;
    self.currentVersionId = versionId;
    self.progressBlock = progress;
    self.completionBlock = completion;
    
    [[PCLLogger sharedLogger] info:[NSString stringWithFormat:@"[VanillaDownloader] Starting download for version: %@", versionId]];
    
    [self executeDownloadSteps];
}

- (void)cancelDownload {
    self.downloading = NO;
    self.currentStep = PCLVanillaDownloadStepIdle;
    [[PCLLogger sharedLogger] info:@"[VanillaDownloader] Download cancelled"];
}

- (NSArray<NSDictionary *> *)availableReleases {
    NSMutableArray *releases = [NSMutableArray array];
    for (NSDictionary *v in self.manifestVersions) {
        if ([v[@"type"] isEqualToString:@"release"]) {
            [releases addObject:v];
        }
    }
    return releases;
}

- (NSArray<NSDictionary *> *)availableSnapshots {
    NSMutableArray *snapshots = [NSMutableArray array];
    for (NSDictionary *v in self.manifestVersions) {
        if ([v[@"type"] isEqualToString:@"snapshot"]) {
            [snapshots addObject:v];
        }
    }
    return snapshots;
}

- (NSArray<NSDictionary *> *)availableOldVersions {
    NSMutableArray *old = [NSMutableArray array];
    for (NSDictionary *v in self.manifestVersions) {
        NSString *type = v[@"type"];
        if ([type isEqualToString:@"old_alpha"] || [type isEqualToString:@"old_beta"]) {
            [old addObject:v];
        }
    }
    return old;
}

#pragma mark - Download Steps

- (void)executeDownloadSteps {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self step1FetchManifest];
    });
}

- (void)step1FetchManifest {
    self.currentStep = PCLVanillaDownloadStepFetchingManifest;
    [self reportProgress:0.0 stepProgress:0.0 message:@"正在获取版本清单..."];
    
    [[PCLLogger sharedLogger] info:@"[VanillaDownloader] Step 1: Fetching version manifest"];
    
    [[PCLVersionManager sharedManager] fetchRemoteManifest:^(NSArray<NSDictionary *> *versions, NSError *error) {
        if (error || !versions) {
            [self failWithError:error ?: [NSError errorWithDomain:@"PCLVanillaDownloader" code:-2 userInfo:@{NSLocalizedDescriptionKey: @"Failed to fetch version manifest"}]];
            return;
        }
        
        self.manifestVersions = versions;
        
        NSDictionary *targetVersion = nil;
        for (NSDictionary *v in versions) {
            if ([v[@"id"] isEqualToString:self.currentVersionId]) {
                targetVersion = v;
                break;
            }
        }
        
        if (!targetVersion) {
            [self failWithError:[NSError errorWithDomain:@"PCLVanillaDownloader" code:-3 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Version '%@' not found in manifest", self.currentVersionId]}]];
            return;
        }
        
        [self reportProgress:0.05 stepProgress:1.0 message:@"版本清单获取完成"];
        [self step2DownloadVersionJson:targetVersion];
    }];
}

- (void)step2DownloadVersionJson:(NSDictionary *)versionEntry {
    self.currentStep = PCLVanillaDownloadStepDownloadingVersionJson;
    [self reportProgress:0.05 stepProgress:0.0 message:@"正在下载版本JSON..."];
    
    [[PCLLogger sharedLogger] info:@"[VanillaDownloader] Step 2: Downloading version JSON"];
    
    NSString *versionUrl = versionEntry[@"url"];
    if (!versionUrl) {
        [self failWithError:[NSError errorWithDomain:@"PCLVanillaDownloader" code:-4 userInfo:@{NSLocalizedDescriptionKey: @"Version URL is missing"}]];
        return;
    }
    
    NSString *versionId = versionEntry[@"id"];
    NSString *versionsDir = [[PCLVersionManager sharedManager] versionsDirectory];
    NSString *versionDir = [versionsDir stringByAppendingPathComponent:versionId];
    NSString *jsonPath = [versionDir stringByAppendingPathComponent:[versionId stringByAppendingString:@".json"]];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm createDirectoryAtPath:versionDir withIntermediateDirectories:YES attributes:nil error:nil];
    
    NSString *mirroredUrl = [[PCLDownloadManager sharedManager] replaceURLWithDownloadSource:versionUrl];
    
    __weak typeof(self) weakSelf = self;
    [[PCLDownloadManager sharedManager] downloadFile:mirroredUrl toPath:jsonPath sha1:nil success:^{
        __strong typeof(weakSelf) self = weakSelf;
        [self reportProgress:0.10 stepProgress:1.0 message:@"版本JSON下载完成"];
        [self step3ParseVersionJson:jsonPath];
    } failure:^(NSError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        [self failWithError:error];
    }];
}

- (void)step3ParseVersionJson:(NSString *)jsonPath {
    self.currentStep = PCLVanillaDownloadStepParsingVersionJson;
    [self reportProgress:0.10 stepProgress:0.0 message:@"正在解析版本信息..."];
    
    [[PCLLogger sharedLogger] info:@"[VanillaDownloader] Step 3: Parsing version JSON"];
    
    NSData *data = [NSData dataWithContentsOfFile:jsonPath];
    if (!data) {
        [self failWithError:[NSError errorWithDomain:@"PCLVanillaDownloader" code:-5 userInfo:@{NSLocalizedDescriptionKey: @"Failed to read version JSON file"}]];
        return;
    }
    
    NSError *jsonError = nil;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
    if (jsonError) {
        [self failWithError:jsonError];
        return;
    }
    
    self.versionJson = dict;
    self.versionInfo = [[PCLVersionManager sharedManager] parseVersionJson:dict];
    self.versionInfo.versionId = self.currentVersionId;
    self.versionInfo.jsonPath = jsonPath;
    
    // Handle inheritsFrom - merge parent version data
    NSString *inheritsFrom = dict[@"inheritsFrom"];
    if (inheritsFrom && inheritsFrom.length > 0) {
        [[PCLLogger sharedLogger] info:[NSString stringWithFormat:@"[VanillaDownloader] Version inherits from: %@", inheritsFrom]];
        [self handleInheritsFrom:inheritsFrom childJson:dict];
        return;
    }
    
    [self reportProgress:0.15 stepProgress:1.0 message:@"版本信息解析完成"];
    [self step4DownloadClient];
}

- (void)handleInheritsFrom:(NSString *)parentVersionId childJson:(NSDictionary *)childJson {
    [[PCLLogger sharedLogger] info:[NSString stringWithFormat:@"[VanillaDownloader] Handling inheritsFrom: %@", parentVersionId]];
    
    NSString *versionsDir = [[PCLVersionManager sharedManager] versionsDirectory];
    NSString *parentJsonPath = [[versionsDir stringByAppendingPathComponent:parentVersionId] stringByAppendingPathComponent:[parentVersionId stringByAppendingString:@".json"]];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSDictionary *parentJson = nil;
    
    if ([fm fileExistsAtPath:parentJsonPath]) {
        NSData *parentData = [NSData dataWithContentsOfFile:parentJsonPath];
        parentJson = [NSJSONSerialization JSONObjectWithData:parentData options:0 error:nil];
    }
    
    if (!parentJson) {
        [[PCLLogger sharedLogger] warning:[NSString stringWithFormat:@"[VanillaDownloader] Parent version JSON not found locally, attempting to download: %@", parentVersionId]];
        
        // Find parent in manifest
        NSDictionary *parentEntry = nil;
        for (NSDictionary *v in self.manifestVersions) {
            if ([v[@"id"] isEqualToString:parentVersionId]) {
                parentEntry = v;
                break;
            }
        }
        
        if (!parentEntry) {
            [[PCLLogger sharedLogger] warning:@"[VanillaDownloader] Parent version not found in manifest, proceeding without merge"];
            [self reportProgress:0.15 stepProgress:1.0 message:@"版本信息解析完成(无父版本)"];
            [self step4DownloadClient];
            return;
        }
        
        NSString *parentUrl = parentEntry[@"url"];
        NSString *mirroredUrl = [[PCLDownloadManager sharedManager] replaceURLWithDownloadSource:parentUrl];
        
        __weak typeof(self) weakSelf = self;
        [[PCLDownloadManager sharedManager] downloadFile:mirroredUrl toPath:parentJsonPath sha1:nil success:^{
            __strong typeof(weakSelf) self = weakSelf;
            NSData *parentData = [NSData dataWithContentsOfFile:parentJsonPath];
            NSDictionary *pJson = [NSJSONSerialization JSONObjectWithData:parentData options:0 error:nil];
            [self mergeParentJson:pJson intoChild:childJson];
            [self reportProgress:0.15 stepProgress:1.0 message:@"版本信息解析完成"];
            [self step4DownloadClient];
        } failure:^(NSError *error) {
            __strong typeof(weakSelf) self = weakSelf;
            [[PCLLogger sharedLogger] warning:@"[VanillaDownloader] Failed to download parent JSON, proceeding without merge"];
            [self reportProgress:0.15 stepProgress:1.0 message:@"版本信息解析完成(无父版本)"];
            [self step4DownloadClient];
        }];
        return;
    }
    
    [self mergeParentJson:parentJson intoChild:childJson];
    [self reportProgress:0.15 stepProgress:1.0 message:@"版本信息解析完成"];
    [self step4DownloadClient];
}

- (void)mergeParentJson:(NSDictionary *)parentJson intoChild:(NSDictionary *)childJson {
    NSMutableDictionary *merged = [parentJson mutableCopy];
    
    // Override with child values
    [childJson enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([key isEqualToString:@"libraries"]) {
            // Merge libraries: child libraries come first
            NSArray *parentLibs = parentJson[@"libraries"] ?: @[];
            NSArray *childLibs = childJson[@"libraries"] ?: @[];
            NSMutableArray *combinedLibs = [NSMutableArray arrayWithArray:childLibs];
            [combinedLibs addObjectsFromArray:parentLibs];
            merged[key] = combinedLibs;
        } else if ([key isEqualToString:@"downloads"]) {
            // Merge downloads, child overrides parent
            NSMutableDictionary *mergedDownloads = [(parentJson[@"downloads"] ?: @{}) mutableCopy];
            [mergedDownloads addEntriesFromDictionary:obj];
            merged[key] = mergedDownloads;
        } else {
            merged[key] = obj;
        }
    }];
    
    self.versionJson = merged;
    self.versionInfo = [[PCLVersionManager sharedManager] parseVersionJson:merged];
    self.versionInfo.versionId = self.currentVersionId;
    
    // Write merged JSON back
    NSString *versionsDir = [[PCLVersionManager sharedManager] versionsDirectory];
    NSString *jsonPath = [[versionsDir stringByAppendingPathComponent:self.currentVersionId] stringByAppendingPathComponent:[self.currentVersionId stringByAppendingString:@".json"]];
    NSData *mergedData = [NSJSONSerialization dataWithJSONObject:merged options:NSJSONWritingPrettyPrinted error:nil];
    [mergedData writeToFile:jsonPath atomically:YES];
    self.versionInfo.jsonPath = jsonPath;
}

- (void)step4DownloadClient {
    self.currentStep = PCLVanillaDownloadStepDownloadingClient;
    [self reportProgress:0.15 stepProgress:0.0 message:@"正在下载客户端JAR..."];
    
    [[PCLLogger sharedLogger] info:@"[VanillaDownloader] Step 4: Downloading client JAR"];
    
    NSDictionary *downloads = self.versionJson[@"downloads"];
    NSDictionary *clientDownload = downloads[@"client"];
    
    if (!clientDownload) {
        [[PCLLogger sharedLogger] warning:@"[VanillaDownloader] No client download info, skipping"];
        [self reportProgress:0.25 stepProgress:1.0 message:@"客户端JAR跳过(无信息)"];
        [self step5DownloadAssetIndex];
        return;
    }
    
    NSString *clientUrl = clientDownload[@"url"];
    NSString *clientSha1 = clientDownload[@"sha1"];
    long long clientSize = [clientDownload[@"size"] longLongValue];
    
    NSString *versionsDir = [[PCLVersionManager sharedManager] versionsDirectory];
    NSString *clientPath = [[versionsDir stringByAppendingPathComponent:self.currentVersionId] stringByAppendingPathComponent:[self.currentVersionId stringByAppendingString:@".jar"]];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:clientPath] && clientSha1.length > 0) {
        NSString *existingSHA1 = [self sha1OfFile:clientPath];
        if ([existingSHA1 isEqualToString:clientSha1]) {
            [[PCLLogger sharedLogger] info:@"[VanillaDownloader] Client JAR already exists and verified"];
            [self reportProgress:0.25 stepProgress:1.0 message:@"客户端JAR已存在"];
            [self step5DownloadAssetIndex];
            return;
        }
    }
    
    NSString *mirroredUrl = [[PCLDownloadManager sharedManager] replaceURLWithDownloadSource:clientUrl];
    
    __weak typeof(self) weakSelf = self;
    [[PCLDownloadManager sharedManager] downloadFile:mirroredUrl toPath:clientPath sha1:clientSha1 success:^{
        __strong typeof(weakSelf) self = weakSelf;
        [[PCLLogger sharedLogger] info:@"[VanillaDownloader] Client JAR downloaded successfully"];
        [self reportProgress:0.25 stepProgress:1.0 message:@"客户端JAR下载完成"];
        [self step5DownloadAssetIndex];
    } failure:^(NSError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        [self failWithError:error];
    }];
}

- (void)step5DownloadAssetIndex {
    self.currentStep = PCLVanillaDownloadStepDownloadingAssetIndex;
    [self reportProgress:0.25 stepProgress:0.0 message:@"正在下载资源索引..."];
    
    [[PCLLogger sharedLogger] info:@"[VanillaDownloader] Step 5: Downloading asset index"];
    
    NSDictionary *assetIndexInfo = self.versionJson[@"assetIndex"];
    if (!assetIndexInfo) {
        [[PCLLogger sharedLogger] warning:@"[VanillaDownloader] No asset index info, skipping"];
        [self step6DownloadLibraries];
        return;
    }
    
    NSString *assetIndexUrl = assetIndexInfo[@"url"];
    NSString *assetIndexSha1 = assetIndexInfo[@"sha1"];
    NSString *assetIndexId = assetIndexInfo[@"id"];
    
    NSString *assetsDir = [[PCLVersionManager sharedManager] assetsDirectory];
    NSString *indexDir = [assetsDir stringByAppendingPathComponent:@"indexes"];
    NSString *indexPath = [indexDir stringByAppendingPathComponent:[assetIndexId stringByAppendingString:@".json"]];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm createDirectoryAtPath:indexDir withIntermediateDirectories:YES attributes:nil error:nil];
    
    if ([fm fileExistsAtPath:indexPath] && assetIndexSha1.length > 0) {
        NSString *existingSHA1 = [self sha1OfFile:indexPath];
        if ([existingSHA1 isEqualToString:assetIndexSha1]) {
            [[PCLLogger sharedLogger] info:@"[VanillaDownloader] Asset index already exists and verified"];
            [self reportProgress:0.30 stepProgress:1.0 message:@"资源索引已存在"];
            [self step6DownloadLibraries];
            return;
        }
    }
    
    NSString *mirroredUrl = [[PCLDownloadManager sharedManager] replaceURLWithDownloadSource:assetIndexUrl];
    
    __weak typeof(self) weakSelf = self;
    [[PCLDownloadManager sharedManager] downloadFile:mirroredUrl toPath:indexPath sha1:assetIndexSha1 success:^{
        __strong typeof(weakSelf) self = weakSelf;
        [[PCLLogger sharedLogger] info:@"[VanillaDownloader] Asset index downloaded successfully"];
        [self reportProgress:0.30 stepProgress:1.0 message:@"资源索引下载完成"];
        [self step6DownloadLibraries];
    } failure:^(NSError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        [self failWithError:error];
    }];
}

- (void)step6DownloadLibraries {
    self.currentStep = PCLVanillaDownloadStepDownloadingLibraries;
    [self reportProgress:0.30 stepProgress:0.0 message:@"正在下载库文件..."];
    
    [[PCLLogger sharedLogger] info:@"[VanillaDownloader] Step 6: Downloading libraries"];
    
    NSArray *libraries = self.versionJson[@"libraries"];
    if (!libraries || libraries.count == 0) {
        [[PCLLogger sharedLogger] info:@"[VanillaDownloader] No libraries to download"];
        [self step7DownloadAssets];
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    void (^libProgressBlock)(double, NSString *) = ^(double stepProgress, NSString *msg) {
        __strong typeof(weakSelf) self = weakSelf;
        double overall = 0.30 + stepProgress * 0.35;
        [self reportProgress:overall stepProgress:stepProgress message:msg ?: @"正在下载库文件..."];
    };
    
    void (^libCompletionBlock)(BOOL, NSError *) = ^(BOOL success, NSError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!success) {
            [self failWithError:error];
            return;
        }
        [self reportProgress:0.65 stepProgress:1.0 message:@"库文件下载完成"];
        [self step7DownloadAssets];
    };
    
    [PCLLibraryDownloader downloadLibraries:libraries
                                 versionId:self.currentVersionId
                                  progress:libProgressBlock
                                completion:libCompletionBlock];
}

- (void)step7DownloadAssets {
    self.currentStep = PCLVanillaDownloadStepDownloadingAssets;
    [self reportProgress:0.65 stepProgress:0.0 message:@"正在下载资源文件..."];
    
    [[PCLLogger sharedLogger] info:@"[VanillaDownloader] Step 7: Downloading assets"];
    
    NSDictionary *assetIndexInfo = self.versionJson[@"assetIndex"];
    NSString *assetIndexId = assetIndexInfo[@"id"];
    
    if (!assetIndexId) {
        [[PCLLogger sharedLogger] warning:@"[VanillaDownloader] No asset index ID, skipping assets"];
        [self step8ExtractNatives];
        return;
    }
    
    NSString *assetsDir = [[PCLVersionManager sharedManager] assetsDirectory];
    NSString *indexPath = [[assetsDir stringByAppendingPathComponent:@"indexes"] stringByAppendingPathComponent:[assetIndexId stringByAppendingString:@".json"]];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:indexPath]) {
        [[PCLLogger sharedLogger] warning:@"[VanillaDownloader] Asset index file not found, skipping assets"];
        [self step8ExtractNatives];
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    void (^assetProgressBlock)(double, NSString *) = ^(double stepProgress, NSString *msg) {
        __strong typeof(weakSelf) self = weakSelf;
        double overall = 0.65 + stepProgress * 0.25;
        [self reportProgress:overall stepProgress:stepProgress message:msg ?: @"正在下载资源文件..."];
    };
    
    void (^assetCompletionBlock)(BOOL, NSError *) = ^(BOOL success, NSError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!success) {
            [self failWithError:error];
            return;
        }
        [self reportProgress:0.90 stepProgress:1.0 message:@"资源文件下载完成"];
        [self step8ExtractNatives];
    };
    
    [PCLAssetDownloader downloadAssetsWithIndexId:assetIndexId
                                        assetsDir:assetsDir
                                         progress:assetProgressBlock
                                       completion:assetCompletionBlock];
}

- (void)step8ExtractNatives {
    self.currentStep = PCLVanillaDownloadStepExtractingNatives;
    [self reportProgress:0.90 stepProgress:0.0 message:@"正在解压Native库..."];
    
    [[PCLLogger sharedLogger] info:@"[VanillaDownloader] Step 8: Extracting natives"];
    
    NSArray *libraries = self.versionJson[@"libraries"];
    NSString *versionsDir = [[PCLVersionManager sharedManager] versionsDirectory];
    NSString *nativesDir = [[versionsDir stringByAppendingPathComponent:self.currentVersionId] stringByAppendingPathComponent:@"natives"];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm createDirectoryAtPath:nativesDir withIntermediateDirectories:YES attributes:nil error:nil];
    
    // Clean existing natives
    NSArray *existingNatives = [fm contentsOfDirectoryAtPath:nativesDir error:nil];
    for (NSString *file in existingNatives) {
        [fm removeItemAtPath:[nativesDir stringByAppendingPathComponent:file] error:nil];
    }
    
    BOOL foundNatives = NO;
    for (NSDictionary *lib in libraries) {
        NSDictionary *downloads = lib[@"downloads"];
        NSDictionary *classifiers = downloads[@"classifiers"];
        if (!classifiers) continue;
        
        // Determine native classifier for current platform
        // On iOS we use the "natives-osx" or "natives-linux" classifier as fallback
        // since there's no actual native platform for iOS
        NSString *nativeKey = classifiers[@"natives-macos"];
        if (!nativeKey) nativeKey = classifiers[@"natives-osx"];
        if (!nativeKey) nativeKey = classifiers[@"natives-linux"];
        if (!nativeKey) nativeKey = classifiers[@"natives-windows"];
        if (!nativeKey) continue;
        
        NSDictionary *nativeDownload = classifiers[nativeKey];
        NSString *nativeUrl = nativeDownload[@"url"];
        NSString *nativeSha1 = nativeDownload[@"sha1"];
        NSString *nativePath = nativeDownload[@"path"];
        
        if (!nativeUrl || !nativePath) continue;
        
        foundNatives = YES;
        
        // Download native library
        NSString *librariesDir = [[PCLVersionManager sharedManager] librariesDirectory];
        NSString *localNativePath = [librariesDir stringByAppendingPathComponent:nativePath];
        
        NSString *mirroredUrl = [[PCLDownloadManager sharedManager] replaceURLWithDownloadSource:nativeUrl];
        
        // Use semaphore for synchronous extraction within this step
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        __block NSError *downloadError = nil;
        
        [[PCLDownloadManager sharedManager] downloadFile:mirroredUrl toPath:localNativePath sha1:nativeSha1 success:^{
            dispatch_semaphore_signal(sema);
        } failure:^(NSError *error) {
            downloadError = error;
            dispatch_semaphore_signal(sema);
        }];
        
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        
        if (downloadError) {
            [[PCLLogger sharedLogger] warning:[NSString stringWithFormat:@"[VanillaDownloader] Failed to download native: %@", nativePath]];
            continue;
        }
        
        // Extract JAR/ZIP to natives directory
        if ([nativePath hasSuffix:@".jar"] || [nativePath hasSuffix:@".zip"]) {
            [self extractZipAtPath:localNativePath toDir:nativesDir];
        }
    }
    
    if (!foundNatives) {
        [[PCLLogger sharedLogger] info:@"[VanillaDownloader] No native libraries found for this version"];
    }
    
    [self reportProgress:0.95 stepProgress:1.0 message:@"Native库处理完成"];
    [self step9Complete];
}

- (void)step9Complete {
    self.currentStep = PCLVanillaDownloadStepCompleted;
    [self reportProgress:1.0 stepProgress:1.0 message:@"下载完成!"];
    
    [[PCLLogger sharedLogger] info:[NSString stringWithFormat:@"[VanillaDownloader] Download completed for version: %@", self.currentVersionId]];
    
    self.downloading = NO;
    
    if (self.completionBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.completionBlock(YES, nil);
        });
    }
}

#pragma mark - Helpers

- (void)reportProgress:(double)overallProgress stepProgress:(double)stepProgress message:(NSString *)message {
    if (self.progressBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressBlock(self.currentStep, overallProgress, stepProgress, message);
        });
    }
}

- (void)failWithError:(NSError *)error {
    self.currentStep = PCLVanillaDownloadStepFailed;
    self.downloading = NO;
    
    [[PCLLogger sharedLogger] error:[NSString stringWithFormat:@"[VanillaDownloader] Download failed: %@", error.localizedDescription]];
    
    if (self.completionBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.completionBlock(NO, error);
        });
    }
}

- (NSString *)sha1OfFile:(NSString *)path {
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (!data) return @"";
    
    unsigned char digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, (CC_LONG)data.length, digest);
    
    NSMutableString *result = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        [result appendFormat:@"%02x", digest[i]];
    }
    return result;
}

- (void)extractZipAtPath:(NSString *)zipPath toDir:(NSString *)dir {
    // Use NSTask or system() to unzip on jailbroken devices
    // For non-jailbroken, we'd need a native zip library
    // This is a simplified implementation using NSFileCoordinator
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // Try using unzip command (available on jailbroken iOS)
    NSString *cmd = [NSString stringWithFormat:@"unzip -o -q '%@' -d '%@'", zipPath, dir];
    int result = system(cmd.UTF8String);
    
    if (result != 0) {
        [[PCLLogger sharedLogger] warning:[NSString stringWithFormat:@"[VanillaDownloader] Failed to extract zip: %@", zipPath]];
    } else {
        [[PCLLogger sharedLogger] info:[NSString stringWithFormat:@"[VanillaDownloader] Extracted: %@", zipPath]];
    }
}

@end
