#import "PCLDownloadManager.h"
#import <CommonCrypto/CommonDigest.h>

@implementation PCLDownloadTask
@end

@interface PCLDownloadManager ()
@property (nonatomic, strong) NSMutableArray<PCLDownloadTask *> *tasks;
@property (nonatomic, strong) NSOperationQueue *downloadQueue;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, assign) BOOL useBMCLAPI;
@end

@implementation PCLDownloadManager

+ (instancetype)sharedManager {
    static PCLDownloadManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PCLDownloadManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _tasks = [NSMutableArray array];
        _downloadQueue = [[NSOperationQueue alloc] init];
        _downloadQueue.maxConcurrentOperationCount = 4;
        _downloadQueue.name = @"com.pcl-ios.download";
        _useBMCLAPI = YES;
        
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.HTTPMaximumConnectionsPerHost = 8;
        config.timeoutIntervalForRequest = 30;
        _session = [NSURLSession sessionWithConfiguration:config];
    }
    return self;
}

- (NSArray<PCLDownloadTask *> *)allTasks {
    return [self.tasks copy];
}

- (NSArray<PCLDownloadTask *> *)activeTasks {
    NSMutableArray *active = [NSMutableArray array];
    for (PCLDownloadTask *task in self.tasks) {
        if (task.state == PCLDownloadStateDownloading || task.state == PCLDownloadStatePending) {
            [active addObject:task];
        }
    }
    return active;
}

- (void)addTask:(PCLDownloadTask *)task {
    if (!task.taskId) {
        task.taskId = [[NSUUID UUID] UUIDString];
    }
    @synchronized (self.tasks) {
        [self.tasks addObject:task];
    }
}

- (void)removeTask:(PCLDownloadTask *)task {
    @synchronized (self.tasks) {
        [self.tasks removeObject:task];
    }
}

- (void)pauseTask:(PCLDownloadTask *)task {
    task.state = PCLDownloadStatePaused;
}

- (void)resumeTask:(PCLDownloadTask *)task {
    task.state = PCLDownloadStatePending;
    [self startDownload:task];
}

- (void)cancelTask:(PCLDownloadTask *)task {
    task.state = PCLDownloadStateFailed;
    @synchronized (self.tasks) {
        [self.tasks removeObject:task];
    }
}

- (void)retryTask:(PCLDownloadTask *)task {
    task.retryCount = 0;
    task.state = PCLDownloadStatePending;
    task.progress = 0;
    task.completedBytes = 0;
    [self startDownload:task];
}

- (NSString *)replaceURLWithDownloadSource:(NSString *)urlString {
    if (!urlString) return urlString;
    
    NSDictionary *replacements = @{
        @"https://piston-meta.mojang.com": @"https://bmclapi2.bangbang93.com",
        @"https://piston-data.mojang.com": @"https://bmclapi2.bangbang93.com",
        @"https://launchermeta.mojang.com": @"https://bmclapi2.bangbang93.com",
        @"https://libraries.minecraft.net": @"https://bmclapi2.bangbang93.com/libraries",
        @"https://resources.download.minecraft.net": @"https://bmclapi2.bangbang93.com/assets",
        @"https://files.minecraftforge.net/maven": @"https://bmclapi2.bangbang93.com/maven",
        @"https://maven.fabricmc.net": @"https://bmclapi2.bangbang93.com/fabric",
        @"https://maven.neoforged.net": @"https://bmclapi2.bangbang93.com/maven",
        @"https://authlib-injector.yushi.moe": @"https://bmclapi2.bangbang93.com/mirrors/authlib-injector"
    };
    
    for (NSString *original in replacements) {
        if ([urlString hasPrefix:original]) {
            NSString *replacement = replacements[original];
            NSString *path = [urlString substringFromIndex:original.length];
            return [replacement stringByAppendingString:path];
        }
    }
    
    return urlString;
}

- (void)startDownload:(PCLDownloadTask *)task {
    if (task.state == PCLDownloadStatePaused || task.state == PCLDownloadStateCompleted) {
        return;
    }
    
    task.state = PCLDownloadStateDownloading;
    
    NSString *url = self.useBMCLAPI ? [self replaceURLWithDownloadSource:task.url] : task.url;
    
    [self downloadFile:url toPath:task.targetPath sha1:task.sha1 success:^{
        task.state = PCLDownloadStateCompleted;
        task.progress = 1.0;
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(downloadManagerDidComplete:)]) {
                [self.delegate downloadManagerDidComplete:task];
            }
        });
    } failure:^(NSError *error) {
        if (task.retryCount < 2) {
            task.retryCount++;
            if (self.useBMCLAPI) {
                NSLog(@"[Download] Retry with original URL after BMCLAPI failure");
                self.useBMCLAPI = NO;
                [self startDownload:task];
                self.useBMCLAPI = YES;
                return;
            }
        }
        task.state = PCLDownloadStateFailed;
        task.error = error;
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(downloadManagerDidFail:error:)]) {
                [self.delegate downloadManagerDidFail:task error:error];
            }
        });
    }];
}

- (void)downloadFile:(NSString *)urlString
              toPath:(NSString *)path
                 sha1:(NSString *)sha1
             success:(void (^)(void))success
             failure:(void (^)(NSError *error))failure {
    
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        if (failure) failure([NSError errorWithDomain:@"PCLDownload" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Invalid URL"}]);
        return;
    }
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *dir = [path stringByDeletingLastPathComponent];
    [fm createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    
    if ([fm fileExistsAtPath:path] && sha1.length > 0) {
        NSString *existingSHA1 = [self sha1OfFile:path];
        if ([existingSHA1 isEqualToString:sha1]) {
            if (success) success();
            return;
        }
    }
    
    __weak typeof(self) weakSelf = self;
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30];
    
    NSURLSessionDownloadTask *dlTask = [self.session downloadTaskWithRequest:request completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (error) {
            if (failure) failure(error);
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode != 200) {
            if (failure) failure([NSError errorWithDomain:@"PCLDownload" code:httpResponse.statusCode userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"HTTP %ld", (long)httpResponse.statusCode]}]);
            return;
        }
        
        [fm removeItemAtPath:path error:nil];
        NSError *moveError = nil;
        [fm moveItemAtURL:location toURL:[NSURL fileURLWithPath:path] error:&moveError];
        
        if (moveError) {
            if (failure) failure(moveError);
            return;
        }
        
        if (sha1.length > 0) {
            NSString *downloadedSHA1 = [self sha1OfFile:path];
            if (![downloadedSHA1 isEqualToString:sha1]) {
                [fm removeItemAtPath:path error:nil];
                if (failure) failure([NSError errorWithDomain:@"PCLDownload" code:-2 userInfo:@{NSLocalizedDescriptionKey: @"SHA1 mismatch"}]);
                return;
            }
        }
        
        if (success) success();
    }];
    
    [dlTask resume];
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

@end
