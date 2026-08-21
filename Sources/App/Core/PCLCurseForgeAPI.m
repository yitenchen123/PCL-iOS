#import "PCLCurseForgeAPI.h"

@implementation PCLCurseForgeFile
@end

@implementation PCLCurseForgeMod
@end

@interface PCLCurseForgeAPI ()
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) dispatch_queue_t callbackQueue;
@end

@implementation PCLCurseForgeAPI

+ (instancetype)sharedAPI {
    static PCLCurseForgeAPI *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PCLCurseForgeAPI alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _gameId = 432;
        _callbackQueue = dispatch_get_main_queue();
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.timeoutIntervalForRequest = 30;
        _session = [NSURLSession sessionWithConfiguration:config];
        _apiKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"CurseForgeAPIKey"];
    }
    return self;
}

- (void)setAPIKey:(NSString *)key {
    self.apiKey = key;
    [[NSUserDefaults standardUserDefaults] setObject:key forKey:@"CurseForgeAPIKey"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (nullable NSString *)currentAPIKey {
    if (self.apiKey) return self.apiKey;
    NSString *stored = [[NSUserDefaults standardUserDefaults] stringForKey:@"CurseForgeAPIKey"];
    if (stored) {
        self.apiKey = stored;
        return stored;
    }
    return nil;
}

- (NSMutableURLRequest *)requestWithPath:(NSString *)path query:(NSDictionary *)query {
    NSString *base = @"https://api.curseforge.com";
    NSString *urlString = [base stringByAppendingPathComponent:path];
    if (query.count > 0) {
        NSMutableArray *pairs = [NSMutableArray array];
        for (NSString *key in query) {
            NSString *val = [query[key] stringValue];
            NSString *encoded = [val stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
            [pairs addObject:[NSString stringWithFormat:@"%@=%@", key, encoded]];
        }
        urlString = [urlString stringByAppendingFormat:@"?%@", [pairs componentsJoinedByString:@"&"]];
    }
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [req setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSString *key = [self currentAPIKey];
    if (key) {
        [req setValue:key forHTTPHeaderField:@"x-api-key"];
    }
    return req;
}

- (void)searchModsWithQuery:(NSString *)query
                gameVersion:(NSString *)gameVersion
                   category:(NSString *)category
                       page:(NSInteger)page
                   pageSize:(NSInteger)pageSize
                 completion:(void(^)(NSArray<PCLCurseForgeMod *> *mods, NSError *error))completion {
    
    if (![self currentAPIKey]) {
        dispatch_async(self.callbackQueue, ^{
            completion(nil, [NSError errorWithDomain:@"PCLCurseForgeAPI" code:401 userInfo:@{NSLocalizedDescriptionKey: @"CurseForge API Key not set. Please configure in Settings."}]);
        });
        return;
    }
    
    NSMutableDictionary *params = [@{
        @"gameId": @(self.gameId),
        @"classId": @(6), // Mods
        @"pageSize": @(pageSize),
        @"index": @(page * pageSize),
    } mutableCopy];
    
    if (query.length > 0) params[@"searchFilter"] = query;
    if (gameVersion) params[@"gameVersion"] = gameVersion;
    if (category) params[@"classId"] = category;
    
    NSMutableURLRequest *req = [self requestWithPath:@"/v1/mods/search" query:params];
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            dispatch_async(self.callbackQueue, ^{ completion(nil, error); });
            return;
        }
        NSError *jsonError;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError) {
            dispatch_async(self.callbackQueue, ^{ completion(nil, jsonError); });
            return;
        }
        NSArray *dataArr = json[@"data"];
        NSMutableArray *mods = [NSMutableArray array];
        for (NSDictionary *modDict in dataArr) {
            PCLCurseForgeMod *mod = [[PCLCurseForgeMod alloc] init];
            mod.modId = [modDict[@"id"] integerValue];
            mod.name = modDict[@"name"] ?: @"";
            mod.summary = modDict[@"summary"] ?: @"";
            mod.downloadCount = [modDict[@"downloadCount"] integerValue];
            NSDictionary *logo = modDict[@"logo"];
            mod.iconUrl = logo[@"url"] ?: @"";
            mod.websiteUrl = modDict[@"links"][@"websiteUrl"] ?: @"";
            [mods addObject:mod];
        }
        dispatch_async(self.callbackQueue, ^{ completion(mods, nil); });
    }];
    [task resume];
}

- (void)getModWithId:(NSInteger)modId completion:(void(^)(PCLCurseForgeMod *mod, NSError *error))completion {
    NSString *path = [NSString stringWithFormat:@"/v1/mods/%ld", (long)modId];
    NSMutableURLRequest *req = [self requestWithPath:path query:nil];
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            dispatch_async(self.callbackQueue, ^{ completion(nil, error); });
            return;
        }
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSDictionary *modDict = json[@"data"];
        PCLCurseForgeMod *mod = [[PCLCurseForgeMod alloc] init];
        mod.modId = [modDict[@"id"] integerValue];
        mod.name = modDict[@"name"] ?: @"";
        mod.summary = modDict[@"summary"] ?: @"";
        mod.downloadCount = [modDict[@"downloadCount"] integerValue];
        NSDictionary *logo = modDict[@"logo"];
        mod.iconUrl = logo[@"url"] ?: @"";
        mod.websiteUrl = modDict[@"links"][@"websiteUrl"] ?: @"";
        dispatch_async(self.callbackQueue, ^{ completion(mod, nil); });
    }];
    [task resume];
}

- (void)getFilesForMod:(NSInteger)modId completion:(void(^)(NSArray<PCLCurseForgeFile *> *files, NSError *error))completion {
    NSString *path = [NSString stringWithFormat:@"/v1/mods/%ld/files", (long)modId];
    NSMutableURLRequest *req = [self requestWithPath:path query:nil];
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            dispatch_async(self.callbackQueue, ^{ completion(nil, error); });
            return;
        }
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSArray *dataArr = json[@"data"];
        NSMutableArray *files = [NSMutableArray array];
        for (NSDictionary *fileDict in dataArr) {
            PCLCurseForgeFile *file = [[PCLCurseForgeFile alloc] init];
            file.fileId = [fileDict[@"id"] integerValue];
            file.fileName = fileDict[@"fileName"] ?: @"";
            file.downloadUrl = fileDict[@"downloadUrl"] ?: @"";
            file.fileSize = [fileDict[@"fileLength"] integerValue];
            NSArray *gameVersions = fileDict[@"gameVersions"];
            file.gameVersion = gameVersions.firstObject ?: @"";
            [files addObject:file];
        }
        dispatch_async(self.callbackQueue, ^{ completion(files, nil); });
    }];
    [task resume];
}

- (void)downloadFile:(PCLCurseForgeFile *)file
              toPath:(NSString *)path
            progress:(void(^)(double progress))progress
          completion:(void(^)(BOOL success, NSError *error))completion {
    
    if (!file.downloadUrl) {
        completion(NO, [NSError errorWithDomain:@"PCLCurseForgeAPI" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"No download URL"}]);
        return;
    }
    
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:file.downloadUrl]];
    NSURLSessionDownloadTask *task = [self.session downloadTaskWithRequest:req completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        if (error) {
            completion(NO, error);
            return;
        }
        NSError *moveError;
        [[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:path] error:&moveError];
        completion(moveError == nil, moveError);
    }];
    [task resume];
}

@end
