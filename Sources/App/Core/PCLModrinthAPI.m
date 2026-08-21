#import "PCLModrinthAPI.h"

@implementation PCLModrinthProject
@end

@implementation PCLModrinthFileInfo
@end

@implementation PCLModrinthVersion
@end

@implementation PCLModrinthSearchResult
@end

@interface PCLModrinthAPI ()
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) dispatch_queue_t callbackQueue;
@end

@implementation PCLModrinthAPI

+ (instancetype)sharedAPI {
    static PCLModrinthAPI *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PCLModrinthAPI alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _callbackQueue = dispatch_get_main_queue();
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.timeoutIntervalForRequest = 30;
        _session = [NSURLSession sessionWithConfiguration:config];
    }
    return self;
}

- (void)searchWithQuery:(NSString *)query
                 facets:(NSString *)facets
                   page:(NSInteger)page
               pageSize:(NSInteger)pageSize
             completion:(void(^)(NSArray<PCLModrinthProject *> *projects, NSError *error))completion {
    
    NSString *encodedQuery = [query stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString *urlString = [NSString stringWithFormat:@"https://api.modrinth.com/v2/search?query=%@&limit=%ld&offset=%ld",
                          encodedQuery, (long)pageSize, (long)(page * pageSize)];
    if (facets) {
        urlString = [urlString stringByAppendingFormat:@"&facets=%@", facets];
    }
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [req setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [req setValue:@"PCL-iOS/1.0" forHTTPHeaderField:@"User-Agent"];
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            dispatch_async(self.callbackQueue, ^{ completion(nil, error); });
            return;
        }
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSArray *hits = json[@"hits"];
        NSMutableArray *projects = [NSMutableArray array];
        for (NSDictionary *hit in hits) {
            PCLModrinthProject *p = [[PCLModrinthProject alloc] init];
            p.projectID = hit[@"project_id"] ?: @"";
            p.slug = hit[@"slug"] ?: @"";
            p.title = hit[@"title"] ?: @"";
            p.descriptionText = hit[@"description"] ?: @"";
            p.iconUrl = hit[@"icon_url"] ?: @"";
            p.downloadCount = [hit[@"downloads"] integerValue];
            p.followerCount = [hit[@"follows"] integerValue];
            p.projectType = hit[@"project_type"] ?: @"mod";
            [projects addObject:p];
        }
        dispatch_async(self.callbackQueue, ^{ completion(projects, nil); });
    }];
    [task resume];
}

- (void)getProject:(NSString *)slugOrID completion:(void(^)(PCLModrinthProject *project, NSError *error))completion {
    NSString *urlString = [NSString stringWithFormat:@"https://api.modrinth.com/v2/project/%@", slugOrID];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [req setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            dispatch_async(self.callbackQueue, ^{ completion(nil, error); });
            return;
        }
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        PCLModrinthProject *p = [[PCLModrinthProject alloc] init];
        p.projectID = json[@"id"] ?: @"";
        p.slug = json[@"slug"] ?: @"";
        p.title = json[@"title"] ?: @"";
        p.descriptionText = json[@"description"] ?: @"";
        p.iconUrl = json[@"icon_url"] ?: @"";
        p.downloadCount = [json[@"downloads"] integerValue];
        p.followerCount = [json[@"followers"] integerValue];
        p.projectType = json[@"project_type"] ?: @"mod";
        dispatch_async(self.callbackQueue, ^{ completion(p, nil); });
    }];
    [task resume];
}

- (void)getVersionsForProject:(NSString *)slugOrID completion:(void(^)(NSArray<PCLModrinthVersion *> *versions, NSError *error))completion {
    NSString *urlString = [NSString stringWithFormat:@"https://api.modrinth.com/v2/project/%@/version", slugOrID];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [req setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            dispatch_async(self.callbackQueue, ^{ completion(nil, error); });
            return;
        }
        NSArray *arr = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSMutableArray *versions = [NSMutableArray array];
        for (NSDictionary *v in arr) {
            PCLModrinthVersion *ver = [[PCLModrinthVersion alloc] init];
            ver.versionID = v[@"id"] ?: @"";
            ver.versionNumber = v[@"version_number"] ?: @"";
            ver.name = v[@"name"] ?: @"";
            ver.gameVersions = v[@"game_versions"] ?: @[];
            ver.loaders = v[@"loaders"] ?: @[];
            ver.files = v[@"files"] ?: @[];
            [versions addObject:ver];
        }
        dispatch_async(self.callbackQueue, ^{ completion(versions, nil); });
    }];
    [task resume];
}

- (void)getVersion:(NSString *)versionID completion:(void(^)(NSDictionary *versionInfo, NSError *error))completion {
    NSString *urlString = [NSString stringWithFormat:@"https://api.modrinth.com/v2/version/%@", versionID];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [req setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            dispatch_async(self.callbackQueue, ^{ completion(nil, error); });
            return;
        }
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        dispatch_async(self.callbackQueue, ^{ completion(json, nil); });
    }];
    [task resume];
}

- (void)getLatestVersionForProject:(NSString *)slugOrID
                       gameVersion:(NSString *)gameVersion
                            loader:(NSString *)loader
                        completion:(void(^)(PCLModrinthVersion *version, NSError *error))completion {
    NSString *urlString = [NSString stringWithFormat:@"https://api.modrinth.com/v2/project/%@/version?game_versions=[\"%@\"]&loaders=[\"%@\"]",
                          slugOrID, gameVersion, loader];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [req setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            dispatch_async(self.callbackQueue, ^{ completion(nil, error); });
            return;
        }
        NSArray *arr = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if (arr.count == 0) {
            dispatch_async(self.callbackQueue, ^{ completion(nil, nil); });
            return;
        }
        NSDictionary *v = arr.firstObject;
        PCLModrinthVersion *ver = [[PCLModrinthVersion alloc] init];
        ver.versionID = v[@"id"] ?: @"";
        ver.versionNumber = v[@"version_number"] ?: @"";
        ver.name = v[@"name"] ?: @"";
        ver.gameVersions = v[@"game_versions"] ?: @[];
        ver.loaders = v[@"loaders"] ?: @[];
        ver.files = v[@"files"] ?: @[];
        dispatch_async(self.callbackQueue, ^{ completion(ver, nil); });
    }];
    [task resume];
}

#pragma mark - PCL-CE Style API (完整筛选)

- (void)searchProjects:(NSString *)query
            projectType:(PCLModrinthProjectType)projectType
                 loader:(PCLModrinthModLoader)loader
            gameVersion:(NSString *)gameVersion
               category:(NSString *)category
               sortType:(PCLModrinthSortType)sortType
                  limit:(NSInteger)limit
                 offset:(NSInteger)offset
             completion:(void(^)(PCLModrinthSearchResult *result, NSError *error))completion {
    
    // Build facets
    NSMutableArray *facetsArray = [NSMutableArray array];
    
    // Project type
    NSString *typeStr = @[@"mod", @"modpack", @"resourcepack", @"shader"][projectType];
    [facetsArray addObject:[NSString stringWithFormat:@"[\"project_type:%@\"]", typeStr]];
    
    // Game version
    if (gameVersion) {
        [facetsArray addObject:[NSString stringWithFormat:@"[\"versions:%@\"]", gameVersion]];
    }
    
    // Loader
    NSString *loaderStr = @[@"forge", @"fabric", @"neoforge", @"quilt"][loader];
    [facetsArray addObject:[NSString stringWithFormat:@"[\"categories:%@\"]", loaderStr]];
    
    NSString *facets = [NSString stringWithFormat:@"[%@]", [facetsArray componentsJoinedByString:@","]];
    
    // Sort
    NSString *sortStr = @[@"relevance", @"downloads", @"newest"][sortType];
    
    NSString *encodedQuery = [query stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString *urlString = [NSString stringWithFormat:
                          @"https://api.modrinth.com/v2/search?query=%@&facets=%@&sort=%@&limit=%ld&offset=%ld",
                          encodedQuery ?: @"", facets, sortStr, (long)limit, (long)offset];
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [req setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [req setValue:@"PCL-iOS/1.0" forHTTPHeaderField:@"User-Agent"];
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            dispatch_async(self.callbackQueue, ^{ completion(nil, error); });
            return;
        }
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        PCLModrinthSearchResult *result = [[PCLModrinthSearchResult alloc] init];
        
        NSArray *hits = json[@"hits"] ?: @[];
        NSInteger totalHits = [json[@"total_hits"] integerValue];
        
        NSMutableArray *projects = [NSMutableArray array];
        for (NSDictionary *hit in hits) {
            PCLModrinthProject *p = [[PCLModrinthProject alloc] init];
            p.projectID = hit[@"project_id"] ?: @"";
            p.slug = hit[@"slug"] ?: @"";
            p.title = hit[@"title"] ?: @"";
            p.descriptionText = hit[@"description"] ?: @"";
            p.iconUrl = hit[@"icon_url"] ?: @"";
            p.author = hit[@"author"] ?: @"";
            p.downloads = [hit[@"downloads"] integerValue];
            p.downloadCount = p.downloads;
            p.projectType = hit[@"project_type"] ?: @"mod";
            [projects addObject:p];
        }
        
        result.hits = projects;
        result.totalHits = totalHits;
        dispatch_async(self.callbackQueue, ^{ completion(result, nil); });
    }];
    [task resume];
}

- (void)versionsForProject:(NSString *)projectID
                    facets:(NSDictionary *)facets
                completion:(void(^)(NSArray<PCLModrinthVersion *> *versions, NSError *error))completion {
    
    NSString *urlString = [NSString stringWithFormat:@"https://api.modrinth.com/v2/project/%@/version", projectID];
    
    // Add query params from facets
    NSMutableArray *params = [NSMutableArray array];
    NSString *gameVersion = facets[@"gameVersion"];
    if (gameVersion) {
        [params addObject:[NSString stringWithFormat:@"game_versions=[\"%@\"]", gameVersion]];
    }
    if (params.count > 0) {
        urlString = [urlString stringByAppendingFormat:@"?%@", [params componentsJoinedByString:@"&"]];
    }
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [req setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            dispatch_async(self.callbackQueue, ^{ completion(nil, error); });
            return;
        }
        NSArray *arr = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSMutableArray *versions = [NSMutableArray array];
        for (NSDictionary *v in arr) {
            PCLModrinthVersion *ver = [[PCLModrinthVersion alloc] init];
            ver.versionID = v[@"id"] ?: @"";
            ver.versionNumber = v[@"version_number"] ?: @"";
            ver.name = v[@"name"] ?: @"";
            ver.gameVersions = v[@"game_versions"] ?: @[];
            ver.loaders = v[@"loaders"] ?: @[];
            ver.files = v[@"files"] ?: @[];
            ver.downloads = [v[@"downloads"] integerValue];
            
            // Parse fileInfos
            NSMutableArray *fileInfos = [NSMutableArray array];
            for (NSDictionary *fileDict in v[@"files"]) {
                PCLModrinthFileInfo *fi = [[PCLModrinthFileInfo alloc] init];
                fi.fileName = fileDict[@"filename"] ?: @"";
                fi.url = fileDict[@"url"] ?: @"";
                fi.size = [fileDict[@"size"] integerValue];
                fi.isPrimary = [fileDict[@"primary"] boolValue];
                fi.downloads = 0;
                [fileInfos addObject:fi];
            }
            ver.fileInfos = fileInfos;
            [versions addObject:ver];
        }
        dispatch_async(self.callbackQueue, ^{ completion(versions, nil); });
    }];
    [task resume];
}

- (void)downloadFile:(PCLModrinthFileInfo *)file
              toPath:(NSString *)path
            progress:(void(^)(double progress))progress
          completion:(void(^)(BOOL success, NSError *error))completion {
    
    if (!file.url) {
        completion(NO, [NSError errorWithDomain:@"PCLModrinthAPI" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"No download URL"}]);
        return;
    }
    
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:file.url]];
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

#pragma mark - Search with Filters Dictionary

- (void)searchProjects:(NSString *)query
               filters:(NSDictionary *)filters
                 limit:(NSInteger)limit
                offset:(NSInteger)offset
            completion:(void(^)(PCLModrinthSearchResult *result, NSError *error))completion {
    
    // Build facets from filters dictionary
    NSMutableArray *facetsArray = [NSMutableArray array];
    
    NSString *projectType = filters[@"projectType"];
    if (projectType) {
        [facetsArray addObject:[NSString stringWithFormat:@"[\"project_type:%@\"]", projectType]];
    }
    
    NSString *gameVersion = filters[@"gameVersion"];
    if (gameVersion) {
        [facetsArray addObject:[NSString stringWithFormat:@"[\"versions:%@\"]", gameVersion]];
    }
    
    NSString *category = filters[@"category"];
    if (category) {
        [facetsArray addObject:[NSString stringWithFormat:@"[\"categories:%@\"]", category]];
    }
    
    NSString *facets = [NSString stringWithFormat:@"[%@]", [facetsArray componentsJoinedByString:@","]];
    
    // Sort
    NSString *sortStr = filters[@"sortType"] ?: @"relevance";
    
    NSString *encodedQuery = [query stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString *urlString = [NSString stringWithFormat:
                          @"https://api.modrinth.com/v2/search?query=%@&facets=%@&sort=%@&limit=%ld&offset=%ld",
                          encodedQuery ?: @"", facets, sortStr, (long)limit, (long)offset];
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [req setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [req setValue:@"PCL-iOS/1.0" forHTTPHeaderField:@"User-Agent"];
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            dispatch_async(self.callbackQueue, ^{ completion(nil, error); });
            return;
        }
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        PCLModrinthSearchResult *result = [[PCLModrinthSearchResult alloc] init];
        
        NSArray *hits = json[@"hits"] ?: @[];
        NSInteger totalHits = [json[@"total_hits"] integerValue];
        
        NSMutableArray *projects = [NSMutableArray array];
        for (NSDictionary *hit in hits) {
            PCLModrinthProject *p = [[PCLModrinthProject alloc] init];
            p.projectID = hit[@"project_id"] ?: @"";
            p.slug = hit[@"slug"] ?: @"";
            p.title = hit[@"title"] ?: @"";
            p.descriptionText = hit[@"description"] ?: @"";
            p.iconUrl = hit[@"icon_url"] ?: @"";
            p.author = hit[@"author"] ?: @"";
            p.downloads = [hit[@"downloads"] integerValue];
            p.downloadCount = p.downloads;
            p.projectType = hit[@"project_type"] ?: @"mod";
            [projects addObject:p];
        }
        
        result.hits = projects;
        result.totalHits = totalHits;
        dispatch_async(self.callbackQueue, ^{ completion(result, nil); });
    }];
    [task resume];
}

+ (NSString *)sortTypeString:(PCLModrinthSortType)sortType {
    switch (sortType) {
        case PCLModrinthSortTypeRelevance: return @"relevance";
        case PCLModrinthSortTypeDownloads: return @"downloads";
        case PCLModrinthSortTypeNewest: return @"newest";
        case PCLModrinthSortTypeUpdated: return @"updated";
    }
}

@end
