#import "PCLCurseForgeAPI.h"
#import "PCLNetworkUtils.h"

static NSString * const kCurseForgeBaseURL = @"https://api.curseforge.com/v1";
static NSString * const kCurseForgeAPIKeyKey = @"PCLCurseForgeAPIKey";
static NSString * const kCurseForgeGameVersionTypeID = @"68441";

@implementation PCLCurseForgeMod
@end

@implementation PCLCurseForgeFile
@end

@implementation PCLCurseForgeCategory
@end

@implementation PCLCurseForgeSearchResult
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
        _gameId = PCLCurseForgeGameIdMinecraft;
        _apiKey = [[NSUserDefaults standardUserDefaults] stringForKey:kCurseForgeAPIKeyKey] ?: @"";
    }
    return self;
}

#pragma mark - API Key Management

+ (void)setAPIKey:(NSString *)apiKey {
    [[NSUserDefaults standardUserDefaults] setObject:apiKey forKey:kCurseForgeAPIKeyKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [PCLCurseForgeAPI sharedAPI].apiKey = apiKey;
}

+ (NSString *)apiKey {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kCurseForgeAPIKeyKey] ?: @"";
}

#pragma mark - Headers

- (NSDictionary *)requestHeaders {
    NSMutableDictionary *headers = [NSMutableDictionary dictionary];
    headers[@"Accept"] = @"application/json";
    headers[@"x-api-key"] = self.apiKey ?: @"";
    return headers;
}

#pragma mark - Search

- (void)searchMods:(NSString *)query
      gameVersion:(NSString *)gameVersion
         modLoader:(PCLCurseForgeModLoader)modLoader
          category:(NSString *)categoryName
              sort:(PCLCurseForgeSortField)sortField
         sortOrder:(PCLCurseForgeSortOrder)sortOrder
             limit:(NSInteger)limit
            offset:(NSInteger)offset
        completion:(void (^)(PCLCurseForgeSearchResult *, NSError *))completion {
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"gameId"] = @(self.gameId);
    params[@"pageSize"] = @(limit > 0 ? limit : 20);
    params[@"index"] = @(offset);
    params[@"sortField"] = @(sortField);
    params[@"sortOrder"] = sortOrder == PCLCurseForgeSortOrderAsc ? @"asc" : @"desc";
    params[@"gameVersionTypeId"] = kCurseForgeGameVersionTypeID;
    
    if (query.length > 0) {
        params[@"searchFilter"] = query;
    }
    if (gameVersion.length > 0) {
        params[@"gameVersion"] = gameVersion;
    }
    if (modLoader != PCLCurseForgeModLoaderAny) {
        params[@"modLoaderType"] = @(modLoader);
    }
    if (categoryName.length > 0) {
        params[@"classId"] = categoryName;
    }
    
    NSString *url = [kCurseForgeBaseURL stringByAppendingString:@"/mods/search"];
    
    [PCLNetworkUtils GET:url parameters:params headers:[self requestHeaders] completion:^(NSData *data, NSURLResponse *response, NSError *error) {
        [self handleCurseSearchResponse:data response:response error:error completion:completion];
    }];
}

- (void)searchMods:(NSString *)query
      gameVersion:(NSString *)gameVersion
         modLoader:(PCLCurseForgeModLoader)modLoader
          category:(NSString *)categoryId
              sort:(PCLCurseForgeSortField)sortField
             limit:(NSInteger)limit
            offset:(NSInteger)offset
        completion:(void (^)(PCLCurseForgeSearchResult *, NSError *))completion {
    [self searchMods:query gameVersion:gameVersion modLoader:modLoader category:categoryId sort:sortField sortOrder:PCLCurseForgeSortOrderDesc limit:limit offset:offset completion:completion];
}

- (void)handleCurseSearchResponse:(NSData *)data
                         response:(NSURLResponse *)response
                           error:(NSError *)error
                      completion:(void (^)(PCLCurseForgeSearchResult *, NSError *))completion {
    if (error) {
        if (completion) completion(nil, error);
        return;
    }
    
    NSError *jsonError = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
    if (jsonError) {
        if (completion) completion(nil, jsonError);
        return;
    }
    
    PCLCurseForgeSearchResult *result = [[PCLCurseForgeSearchResult alloc] init];
    result.pagination = json[@"pagination"];
    NSDictionary *pagination = json[@"pagination"];
    if (pagination) {
        result.index = [pagination[@"index"] integerValue];
        result.pageSize = [pagination[@"pageSize"] integerValue];
        result.resultCount = [pagination[@"resultCount"] integerValue];
        result.totalCount = [pagination[@"totalCount"] integerValue];
    }
    
    NSArray *dataArray = json[@"data"] ?: @[];
    NSMutableArray *mods = [NSMutableArray array];
    
    for (NSDictionary *dict in dataArray) {
        PCLCurseForgeMod *mod = [self parseModFromDict:dict];
        if (mod) {
            [mods addObject:mod];
        }
    }
    
    result.data = mods;
    if (completion) completion(result, nil);
}

#pragma mark - Mod Details

- (void)modWithId:(NSInteger)modId
       completion:(void (^)(PCLCurseForgeMod *, NSError *))completion {
    
    NSString *url = [NSString stringWithFormat:@"%@/mods/%ld", kCurseForgeBaseURL, (long)modId];
    
    [PCLNetworkUtils GET:url parameters:nil headers:[self requestHeaders] completion:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            if (completion) completion(nil, error);
            return;
        }
        
        NSError *jsonError = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError) {
            if (completion) completion(nil, jsonError);
            return;
        }
        
        NSDictionary *dict = json[@"data"];
        PCLCurseForgeMod *mod = dict ? [self parseModFromDict:dict] : nil;
        if (completion) completion(mod, nil);
    }];
}

#pragma mark - Files

- (void)filesForMod:(NSInteger)modId
     gameVersion:(NSString *)gameVersion
       modLoader:(PCLCurseForgeModLoader)modLoader
      completion:(void (^)(NSArray<PCLCurseForgeFile *> *, NSError *))completion {
    
    NSMutableString *url = [NSMutableString stringWithFormat:@"%@/mods/%ld/files", kCurseForgeBaseURL, (long)modId];
    
    NSMutableArray *queryParams = [NSMutableArray array];
    if (gameVersion.length > 0) {
        [queryParams addObject:[NSString stringWithFormat:@"gameVersion=%@", gameVersion]];
    }
    if (modLoader != PCLCurseForgeModLoaderAny) {
        [queryParams addObject:[NSString stringWithFormat:@"modLoaderType=%ld", (long)modLoader]];
    }
    
    if (queryParams.count > 0) {
        [url appendString:@"?"];
        [url appendString:[queryParams componentsJoinedByString:@"&"]];
    }
    
    [PCLNetworkUtils GET:url parameters:nil headers:[self requestHeaders] completion:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            if (completion) completion(nil, error);
            return;
        }
        
        NSError *jsonError = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError) {
            if (completion) completion(nil, jsonError);
            return;
        }
        
        NSArray *dataArray = json[@"data"] ?: @[];
        NSMutableArray *files = [NSMutableArray array];
        
        for (NSDictionary *dict in dataArray) {
            PCLCurseForgeFile *file = [self parseFileFromDict:dict];
            if (file) {
                [files addObject:file];
            }
        }
        
        if (completion) completion(files, nil);
    }];
}

- (void)downloadUrlForFile:(NSInteger)modId
                   fileId:(NSInteger)fileId
               completion:(void (^)(NSString *, NSError *))completion {
    
    NSString *url = [NSString stringWithFormat:@"%@/mods/%ld/files/%ld/download-url", kCurseForgeBaseURL, (long)modId, (long)fileId];
    
    [PCLNetworkUtils GET:url parameters:nil headers:[self requestHeaders] completion:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            if (completion) completion(nil, error);
            return;
        }
        
        NSError *jsonError = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError) {
            if (completion) completion(nil, jsonError);
            return;
        }
        
        NSString *downloadUrl = json[@"data"] ?: @"";
        if (completion) completion(downloadUrl, nil);
    }];
}

#pragma mark - Categories

- (void)categoriesForGameId:(PCLCurseForgeGameId)gameId
                 completion:(void (^)(NSArray<PCLCurseForgeCategory *> *, NSError *))completion {
    
    NSString *url = [NSString stringWithFormat:@"%@/categories?gameId=%ld", kCurseForgeBaseURL, (long)gameId];
    
    [PCLNetworkUtils GET:url parameters:nil headers:[self requestHeaders] completion:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            if (completion) completion(nil, error);
            return;
        }
        
        NSError *jsonError = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError) {
            if (completion) completion(nil, jsonError);
            return;
        }
        
        NSArray *dataArray = json[@"data"] ?: @[];
        NSMutableArray *categories = [NSMutableArray array];
        
        for (NSDictionary *dict in dataArray) {
            PCLCurseForgeCategory *cat = [self parseCategoryFromDict:dict];
            if (cat) {
                [categories addObject:cat];
            }
        }
        
        if (completion) completion(categories, nil);
    }];
}

#pragma mark - Download

- (void)downloadFile:(PCLCurseForgeFile *)file
              toPath:(NSString *)path
            progress:(void (^)(double))progress
          completion:(void (^)(BOOL, NSError *))completion {
    
    if (file.downloadUrl.length == 0) {
        if (completion) completion(NO, [NSError errorWithDomain:@"PCLCurseForge" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Empty download URL"}]);
        return;
    }
    
    NSURL *url = [NSURL URLWithString:file.downloadUrl];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *dir = [path stringByDeletingLastPathComponent];
    [fm createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:60];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                if (completion) completion(NO, error);
                return;
            }
            
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (httpResponse.statusCode != 200) {
                if (completion) completion(NO, [NSError errorWithDomain:@"PCLCurseForge" code:httpResponse.statusCode userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"HTTP %ld", (long)httpResponse.statusCode]}]);
                return;
            }
            
            [fm removeItemAtPath:path error:nil];
            NSError *moveError = nil;
            [fm moveItemAtURL:location toURL:[NSURL fileURLWithPath:path] error:&moveError];
            
            if (moveError) {
                if (completion) completion(NO, moveError);
                return;
            }
            
            if (completion) completion(YES, nil);
        });
    }];
    
    [downloadTask resume];
}

#pragma mark - Parsing Helpers

- (PCLCurseForgeMod *)parseModFromDict:(NSDictionary *)dict {
    PCLCurseForgeMod *mod = [[PCLCurseForgeMod alloc] init];
    mod.modId = [dict[@"id"] integerValue];
    mod.name = dict[@"name"] ?: @"";
    mod.slug = dict[@"slug"] ?: @"";
    mod.summary = dict[@"summary"] ?: @"";
    mod.downloadCount = [dict[@"downloadCount"] longLongValue];
    mod.popularityScore = [dict[@"popularityScore"] doubleValue];
    mod.isFeatured = [dict[@"isFeatured"] boolValue];
    mod.dateModified = dict[@"dateModified"] ?: @"";
    mod.dateCreated = dict[@"dateCreated"] ?: @"";
    mod.dateReleased = dict[@"dateReleased"] ?: @"";
    
    NSDictionary *latestFile = [dict[@"latestFiles"] firstObject];
    if (latestFile) {
        mod.latestFileDate = latestFile[@"fileDate"] ?: @"";
    }
    
    NSArray *authors = dict[@"authors"] ?: @[];
    NSDictionary *firstAuthor = [authors firstObject];
    if (firstAuthor) {
        mod.authorName = firstAuthor[@"name"] ?: @"";
        mod.authorUrl = firstAuthor[@"url"] ?: @"";
    }
    
    NSDictionary *logo = dict[@"logo"];
    if (logo) {
        mod.iconUrl = logo[@"url"] ?: @"";
        mod.logoThumbnailUrl = logo[@"thumbnailUrl"] ?: @"";
    } else {
        mod.iconUrl = @"";
        mod.logoThumbnailUrl = @"";
    }
    
    NSMutableArray *categories = [NSMutableArray array];
    for (NSDictionary *cat in (dict[@"categories"] ?: @[])) {
        NSString *catName = cat[@"name"];
        if (catName) [categories addObject:catName];
    }
    mod.categories = categories;
    
    NSMutableArray *gameVersions = [NSMutableArray array];
    for (NSDictionary *file in (dict[@"latestFiles"] ?: @[])) {
        for (NSString *gv in (file[@"gameVersions"] ?: @[])) {
            if (![gameVersions containsObject:gv]) {
                [gameVersions addObject:gv];
            }
        }
    }
    mod.gameVersions = gameVersions;
    
    return mod;
}

- (PCLCurseForgeFile *)parseFileFromDict:(NSDictionary *)dict {
    PCLCurseForgeFile *file = [[PCLCurseForgeFile alloc] init];
    file.fileId = [dict[@"id"] integerValue];
    file.fileName = dict[@"fileName"] ?: @"";
    file.displayName = dict[@"displayName"] ?: @"";
    file.downloadUrl = dict[@"downloadUrl"] ?: @"";
    file.fileLength = [dict[@"fileLength"] longLongValue];
    file.dateModified = dict[@"fileDate"] ?: dict[@"dateModified"] ?: @"";
    file.fileFingerprint = [NSString stringWithFormat:@"%ld", (long)[dict[@"fileFingerprint"] integerValue ?: 0]];
    file.isAvailable = [dict[@"isAvailable"] boolValue];
    file.isRequired = NO;
    file.gameVersions = dict[@"gameVersions"] ?: @[];
    
    if (file.gameVersions.count > 0) {
        file.gameVersion = file.gameVersions[0];
    } else {
        file.gameVersion = @"";
    }
    
    return file;
}

- (PCLCurseForgeCategory *)parseCategoryFromDict:(NSDictionary *)dict {
    PCLCurseForgeCategory *cat = [[PCLCurseForgeCategory alloc] init];
    cat.categoryId = [dict[@"id"] integerValue];
    cat.name = dict[@"name"] ?: @"";
    cat.slug = dict[@"slug"] ?: @"";
    cat.iconUrl = dict[@"iconUrl"] ?: @"";
    cat.dateModified = dict[@"dateModified"] ?: @"";
    cat.parentCategoryId = [dict[@"parentCategoryId"] integerValue];
    cat.classId = [dict[@"classId"] integerValue];
    cat.isClass = [dict[@"isClass"] boolValue];
    return cat;
}

@end
