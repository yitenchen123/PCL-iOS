#import "PCLLibraryDownloader.h"
#import "PCLDownloadManager.h"
#import "PCLVersionManager.h"
#import "PCLLogger.h"
#import <CommonCrypto/CommonDigest.h>

static const NSInteger kPCLLibraryMaxConcurrentDownloads = 8;

@interface PCLLibraryDownloader ()

@property (nonatomic, copy) PCLLibraryDownloadProgressBlock progressBlock;
@property (nonatomic, copy) PCLLibraryDownloadCompletionBlock completionBlock;
@property (nonatomic, strong) NSArray<NSDictionary *> *libraries;
@property (nonatomic, copy) NSString *versionId;
@property (nonatomic, assign) NSInteger totalLibraries;
@property (nonatomic, assign) NSInteger completedLibraries;
@property (nonatomic, assign) NSInteger failedLibraries;
@property (nonatomic, assign) BOOL cancelled;

@end

@implementation PCLLibraryDownloader

+ (void)downloadLibraries:(NSArray<NSDictionary *> *)libraries
                versionId:(NSString *)versionId
                 progress:(PCLLibraryDownloadProgressBlock)progress
               completion:(PCLLibraryDownloadCompletionBlock)completion {
    
    PCLLibraryDownloader *downloader = [[PCLLibraryDownloader alloc] init];
    downloader.progressBlock = progress;
    downloader.completionBlock = completion;
    downloader.libraries = libraries;
    downloader.versionId = versionId;
    
    [downloader startDownload];
}

- (void)startDownload {
    // Filter libraries that need to be downloaded
    NSMutableArray *librariesToDownload = [NSMutableArray array];
    
    for (NSDictionary *lib in self.libraries) {
        if ([self shouldDownloadLibrary:lib]) {
            [librariesToDownload addObject:lib];
        }
    }
    
    self.libraries = librariesToDownload;
    self.totalLibraries = librariesToDownload.count;
    self.completedLibraries = 0;
    self.failedLibraries = 0;
    
    [[PCLLogger sharedLogger] info:[NSString stringWithFormat:@"[LibraryDownloader] Starting download of %ld libraries", (long)self.totalLibraries]];
    
    if (self.totalLibraries == 0) {
        if (self.completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.completionBlock(YES, nil);
            });
        }
        return;
    }
    
    [self reportProgress:0.0 message:[NSString stringWithFormat:@"准备下载 %ld 个库文件...", (long)self.totalLibraries]];
    
    // Download libraries concurrently
    dispatch_group_t group = dispatch_group_create();
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = kPCLLibraryMaxConcurrentDownloads;
    queue.name = @"com.pcl-ios.library-download";
    
    for (NSDictionary *lib in self.libraries) {
        if (self.cancelled) break;
        
        dispatch_group_enter(group);
        
        [queue addOperationWithBlock:^{
            [self downloadSingleLibrary:lib withGroup:group];
        }];
    }
    
    dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (self.cancelled) {
            if (self.completionBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.completionBlock(NO, [NSError errorWithDomain:@"PCLLibraryDownloader" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Download cancelled"}]);
                });
            }
            return;
        }
        
        if (self.failedLibraries > 0) {
            [[PCLLogger sharedLogger] warning:[NSString stringWithFormat:@"[LibraryDownloader] %ld libraries failed to download", (long)self.failedLibraries]];
        }
        
        [[PCLLogger sharedLogger] info:[NSString stringWithFormat:@"[LibraryDownloader] Completed: %ld/%ld libraries", (long)self.completedLibraries, (long)self.totalLibraries]];
        
        if (self.completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.completionBlock(self.failedLibraries == 0, self.failedLibraries > 0 ? [NSError errorWithDomain:@"PCLLibraryDownloader" code:-2 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"%ld libraries failed", (long)self.failedLibraries]}] : nil);
            });
        }
    });
}

#pragma mark - Library Parsing

- (BOOL)shouldDownloadLibrary:(NSDictionary *)lib {
    // Check rules for platform-specific libraries
    NSArray *rules = lib[@"rules"];
    if (rules && rules.count > 0) {
        return [self evaluateRules:rules];
    }
    return YES;
}

- (BOOL)evaluateRules:(NSArray *)rules {
    BOOL allowed = NO;
    
    for (NSDictionary *rule in rules) {
        NSString *action = rule[@"action"];
        NSDictionary *os = rule[@"os"];
        
        if (os) {
            NSString *osName = os[@"name"];
            // On iOS, we want linux/macos libraries for compatibility
            if ([osName isEqualToString:@"windows"]) {
                if ([action isEqualToString:@"allow"]) {
                    // Skip this rule for Windows only
                    continue;
                } else {
                    continue;
                }
            }
        }
        
        if ([action isEqualToString:@"allow"]) {
            allowed = YES;
        } else if ([action isEqualToString:@"disallow"]) {
            allowed = NO;
        }
    }
    
    return allowed;
}

- (NSString *)libraryPathForArtifact:(NSDictionary *)artifact {
    NSString *path = artifact[@"path"];
    if (path) {
        return path;
    }
    
    // Parse Maven coordinates: group:name:version
    NSString *name = artifact[@"name"] ?: @"";
    
    // Fallback: parse from name field
    // Format: group:name[:classifier][:version]
    NSArray *components = [name componentsSeparatedByString:@":"];
    if (components.count >= 3) {
        NSString *group = components[0];
        NSString *libName = components[1];
        NSString *version = components[2];
        NSString *classifier = components.count > 3 ? components[3] : nil;
        
        NSString *groupPath = [group stringByReplacingOccurrencesOfString:@"." withString:@"/"];
        NSString *fileName;
        if (classifier.length > 0) {
            fileName = [NSString stringWithFormat:@"%@-%@-%@.jar", libName, version, classifier];
        } else {
            fileName = [NSString stringWithFormat:@"%@-%@.jar", libName, version];
        }
        
        return [NSString stringWithFormat:@"%@/%@/%@/%@", groupPath, libName, version, fileName];
    }
    
    return nil;
}

- (NSString *)mavenUrlForArtifact:(NSDictionary *)artifact {
    NSString *url = artifact[@"url"];
    if (url) return url;
    
    // Build URL from Maven coordinates
    NSString *path = artifact[@"path"];
    if (!path) return nil;
    
    return [NSString stringWithFormat:@"https://libraries.minecraft.net/%@", path];
}

#pragma mark - Download

- (void)downloadSingleLibrary:(NSDictionary *)lib withGroup:(dispatch_group_t)group {
    NSDictionary *downloads = lib[@"downloads"];
    
    // Download main artifact
    NSDictionary *artifact = downloads[@"artifact"];
    if (artifact) {
        [self downloadLibraryArtifact:artifact];
    }
    
    // Download classifiers (includes native libraries)
    NSDictionary *classifiers = downloads[@"classifiers"];
    if (classifiers) {
        for (NSString *classifier in classifiers) {
            NSDictionary *classifierDownload = classifiers[classifier];
            if (classifierDownload) {
                [self downloadLibraryArtifact:classifierDownload];
            }
        }
    }
    
    @synchronized(self) {
        self.completedLibraries++;
    }
    
    [self reportProgress];
    dispatch_group_leave(group);
}

- (void)downloadLibraryArtifact:(NSDictionary *)artifact {
    NSString *path = artifact[@"path"];
    NSString *url = artifact[@"url"];
    NSString *sha1 = artifact[@"sha1"];
    long long size = [artifact[@"size"] longLongValue];
    
    if (!path || !url) return;
    
    NSString *librariesDir = [[PCLVersionManager sharedManager] librariesDirectory];
    NSString *localPath = [librariesDir stringByAppendingPathComponent:path];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // Check if file already exists with correct size
    if ([fm fileExistsAtPath:localPath] && size > 0) {
        NSDictionary *attrs = [fm attributesOfItemAtPath:localPath error:nil];
        if ([attrs fileSize] == size && sha1.length > 0) {
            // Verify SHA1
            NSString *existingSHA1 = [self sha1OfFile:localPath];
            if ([existingSHA1 isEqualToString:sha1]) {
                return; // File already exists and is valid
            }
        }
    }
    
    NSString *mirroredUrl = [[PCLDownloadManager sharedManager] replaceURLWithDownloadSource:url];
    
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    __block NSError *downloadError = nil;
    
    [[PCLDownloadManager sharedManager] downloadFile:mirroredUrl toPath:localPath sha1:sha1 success:^{
        dispatch_semaphore_signal(sema);
    } failure:^(NSError *error) {
        downloadError = error;
        dispatch_semaphore_signal(sema);
    }];
    
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    
    if (downloadError) {
        [[PCLLogger sharedLogger] warning:[NSString stringWithFormat:@"[LibraryDownloader] Failed to download library: %@ (%@)", path, downloadError.localizedDescription]];
        @synchronized(self) {
            self.failedLibraries++;
        }
    } else {
        // Verify size
        if (size > 0) {
            NSDictionary *attrs = [fm attributesOfItemAtPath:localPath error:nil];
            if ([attrs fileSize] != size) {
                [[PCLLogger sharedLogger] warning:[NSString stringWithFormat:@"[LibraryDownloader] Size mismatch for %@: expected %lld, got %lld", path, size, [attrs fileSize]]];
                [fm removeItemAtPath:localPath error:nil];
                @synchronized(self) {
                    self.failedLibraries++;
                }
                return;
            }
        }
        [[PCLLogger sharedLogger] info:[NSString stringWithFormat:@"[LibraryDownloader] Downloaded: %@", path]];
    }
}

#pragma mark - Helpers

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

- (void)reportProgress {
    double progress = self.totalLibraries > 0 ? (double)self.completedLibraries / (double)self.totalLibraries : 0;
    NSString *msg = [NSString stringWithFormat:@"库文件: %ld/%ld", (long)self.completedLibraries, (long)self.totalLibraries];
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
