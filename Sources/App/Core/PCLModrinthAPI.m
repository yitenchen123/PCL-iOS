#import "PCLModrinthAPI.h"
#import "PCLNetworkUtils.h"

static NSString * const kModrinthBaseURL = @"https://api.modrinth.com/v2";
static NSString * const kModrinthCDNURL = @"https://cdn.modrinth.com";

@implementation PCLModrinthProject
@end

@implementation PCLModrinthVersion
@end

@implementation PCLModrinthFileInfo
@end

@implementation PCLModrinthCategory
@end

@implementation PCLModrinthSearchResult
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

#pragma mark - Utility Strings

+ (NSString *)loaderString:(PCLModrinthModLoader)loader {
    switch (loader) {
        case PCLModrinthModLoaderForge: return @"forge";
        case PCLModrinthModLoaderFabric: return @"fabric";
        case PCLModrinthModLoaderNeoForge: return @"neoforge";
        case PCLModrinthModLoaderQuilt: return @"quilt";
        case PCLModrinthModLoaderLiteLoader: return @"liteloader";
        case PCLModrinthModLoaderCauldron: return @"cauldron";
        case PCLModrinthModLoaderRisugami: return @"risugami";
    }
    return @"";
}

+ (NSString *)projectTypeString:(PCLModrinthProjectType)type {
    switch (type) {
        case PCLModrinthProjectTypeMod: return @"mod";
        case PCLModrinthProjectTypeModpack: return @"modpack";
        case PCLModrinthProjectTypeResourcePack: return @"resourcepack";
        case PCLModrinthProjectTypeShader: return @"shader";
    }
    return @"mod";
}

+ (NSString *)sortTypeString:(PCLModrinthSortType)type {
    switch (type) {
        case PCLModrinthSortTypeRelevance: return @"relevance";
        case PCLModrinthSortTypeDownloads: return @"downloads";
        case PCLModrinthSortTypeNewest: return @"newest";
        case PCLModrinthSortTypeUpdated: return @"updated";
        case PCLModrinthSortTypeFollowers: return @"follows";
    }
    return @"relevance";
}

#pragma mark - Search

- (void)searchProjects:(NSString *)query
               filters:(NSDictionary *)filters
                 limit:(NSInteger)limit
                offset:(NSInteger)offset
            completion:(void (^)(PCLModrinthSearchResult *, NSError *))completion {
    
    NSMutableDictionary *params = [NSMutableDictionary array];
    params[@"limit"] = @(limit);
    params[@"offset"] = @(offset);
    
    if (query.length > 0) {
        params[@"query"] = query;
    }
    
    NSMutableArray *facets = [NSMutableArray array];
    
    NSString *projectType = filters[@"projectType"];
    if (projectType) {
        [facets addObject:[NSString stringWithFormat:@"[\"project_type:%@\"]", projectType]];
    }
    
    NSString *loader = filters[@"loader"];
    if (loader) {
        [facets addObject:[NSString stringWithFormat:@"[\"categories:%@\"]", loader]];
    }
    
    NSString *gameVersion = filters[@"gameVersion"];
    if (gameVersion) {
        [facets addObject:[NSString stringWithFormat:@"[\"versions:%@\"]", gameVersion]];
    }
    
    NSString *category = filters[@"category"];
    if (category) {
        [facets addObject:[NSString stringWithFormat:@"[\"categories:%@\"]", category]];
    }
    
    if (facets.count > 0) {
        NSString *facetsString = [NSString stringWithFormat:@"[%@]", [facets componentsJoinedByString:@","]];
        params[@"facets"] = facetsString;
    }
    
    NSString *sortType = filters[@"sortType"] ?: @"relevance";
    params[@"index"] = sortType;
    
    NSString *url = [kModrinthBaseURL stringByAppendingString:@"/search"];
    
    [PCLNetworkUtils GET:url parameters:params headers:nil completion:^(NSData *data, NSURLResponse *response, NSError *error) {
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
        
        PCLModrinthSearchResult *result = [[PCLModrinthSearchResult alloc] init];
        result.totalHits = [json[@"total_hits"] longLongValue];
        result.offset = [json[@"offset"] integerValue];
        result.limit = [json[@"limit"] integerValue];
        
        NSArray *hits = json[@"hits"] ?: @[];
        NSMutableArray *projects = [NSMutableArray array];
        
        for (NSDictionary *dict in hits) {
            PCLModrinthProject *project = [self parseProjectFromDict:dict];
            if (project) {
                [projects addObject:project];
            }
        }
        
        result.hits = projects;
        if (completion) completion(result, nil);
    }];
}

- (void)searchProjects:(NSString *)query
          projectType:(PCLModrinthProjectType)projectType
               loader:(PCLModrinthModLoader)loader
          gameVersion:(NSString *)gameVersion
             category:(NSString *)category
             sortType:(PCLModrinthSortType)sortType
                limit:(NSInteger)limit
               offset:(NSInteger)offset
           completion:(void (^)(PCLModrinthSearchResult *, NSError *))completion {
    
    NSMutableDictionary *filters = [NSMutableDictionary dictionary];
    if (projectType != PCLModrinthProjectTypeMod || YES) {
        filters[@"projectType"] = [PCLModrinthAPI projectTypeString:projectType];
    }
    if (loader != PCLModrinthModLoaderForge || gameVersion.length > 0) {
        filters[@"loader"] = [PCLModrinthAPI loaderString:loader];
    }
    if (gameVersion.length > 0) {
        filters[@"gameVersion"] = gameVersion;
    }
    if (category.length > 0) {
        filters[@"category"] = category;
    }
    filters[@"sortType"] = [PCLModrinthAPI sortTypeString:sortType];
    
    [self searchProjects:query filters:filters limit:limit offset:offset completion:completion];
}

#pragma mark - Project Details

- (void)projectWithId:(NSString *)projectId
           completion:(void (^)(PCLModrinthProject *, NSError *))completion {
    
    NSString *url = [NSString stringWithFormat:@"%@/project/%@", kModrinthBaseURL, projectId];
    
    [PCLNetworkUtils GET:url parameters:nil headers:nil completion:^(NSData *data, NSURLResponse *response, NSError *error) {
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
        
        PCLModrinthProject *project = [self parseProjectDetailFromDict:json];
        if (completion) completion(project, nil);
    }];
}

#pragma mark - Versions

- (void)versionsForProject:(NSString *)projectId
                   facets:(NSDictionary *)facets
               completion:(void (^)(NSArray<PCLModrinthVersion *> *, NSError *))completion {
    
    NSMutableString *url = [NSMutableString stringWithFormat:@"%@/project/%@/version", kModrinthBaseURL, projectId];
    
    if (facets) {
        NSString *gameVersion = facets[@"gameVersion"];
        NSString *loader = facets[@"loader"];
        
        if (gameVersion.length > 0 || loader.length > 0) {
            [url appendString:@"?"];
            NSMutableArray *paramArray = [NSMutableArray array];
            if (gameVersion.length > 0) {
                [paramArray addObject:[NSString stringWithFormat:@"game_versions=[\"%@\"]", gameVersion]];
            }
            if (loader.length > 0) {
                [paramArray addObject:[NSString stringWithFormat:@"loaders=[\"%@\"]", loader]];
            }
            [url appendString:[paramArray componentsJoinedByString:@"&"]];
        }
    }
    
    [PCLNetworkUtils GET:url parameters:nil headers:nil completion:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            if (completion) completion(nil, error);
            return;
        }
        
        NSError *jsonError = nil;
        NSArray *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError) {
            if (completion) completion(nil, jsonError);
            return;
        }
        
        NSMutableArray *versions = [NSMutableArray array];
        for (NSDictionary *dict in json) {
            PCLModrinthVersion *version = [self parseVersionFromDict:dict];
            if (version) {
                [versions addObject:version];
            }
        }
        
        if (completion) completion(versions, nil);
    }];
}

- (void)versionFiles:(NSString *)versionId
          completion:(void (^)(NSArray<PCLModrinthFileInfo *> *, NSError *))completion {
    
    NSString *url = [NSString stringWithFormat:@"%@/version/%@", kModrinthBaseURL, versionId];
    
    [PCLNetworkUtils GET:url parameters:nil headers:nil completion:^(NSData *data, NSURLResponse *response, NSError *error) {
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
        
        NSArray *files = json[@"files"] ?: @[];
        NSMutableArray *fileInfos = [NSMutableArray array];
        
        for (NSDictionary *dict in files) {
            PCLModrinthFileInfo *info = [[PCLModrinthFileInfo alloc] init];
            info.fileName = dict[@"filename"] ?: @"";
            info.url = dict[@"url"] ?: @"";
            NSDictionary *hashes = dict[@"hashes"] ?: @{};
            info.sha1 = hashes[@"sha1"] ?: @"";
            info.size = [dict[@"size"] longLongValue];
            info.isPrimary = [dict[@"primary"] boolValue];
            [fileInfos addObject:info];
        }
        
        if (completion) completion(fileInfos, nil);
    }];
}

#pragma mark - Categories

- (void)categories:(void (^)(NSArray<PCLModrinthCategory *> *, NSError *))completion {
    
    NSString *url = [kModrinthBaseURL stringByAppendingString:@"/tag/category"];
    
    [PCLNetworkUtils GET:url parameters:nil headers:nil completion:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            if (completion) completion(nil, error);
            return;
        }
        
        NSError *jsonError = nil;
        NSArray *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError) {
            if (completion) completion(nil, jsonError);
            return;
        }
        
        NSMutableArray *categories = [NSMutableArray array];
        for (NSDictionary *dict in json) {
            PCLModrinthCategory *cat = [[PCLModrinthCategory alloc] init];
            cat.name = dict[@"name"] ?: @"";
            cat.header = dict[@"header"] ?: @"";
            cat.icon = dict[@"icon"] ?: @"";
            NSString *projectTypeStr = dict[@"project_type"] ?: @"mod";
            if ([projectTypeStr isEqualToString:@"mod"]) {
                cat.projectType = PCLModrinthProjectTypeMod;
            } else if ([projectTypeStr isEqualToString:@"modpack"]) {
                cat.projectType = PCLModrinthProjectTypeModpack;
            } else if ([projectTypeStr isEqualToString:@"resourcepack"]) {
                cat.projectType = PCLModrinthProjectTypeResourcePack;
            } else if ([projectTypeStr isEqualToString:@"shader"]) {
                cat.projectType = PCLModrinthProjectTypeShader;
            }
            cat.categoryId = cat.name;
            [categories addObject:cat];
        }
        
        if (completion) completion(categories, nil);
    }];
}

#pragma mark - Download

- (void)downloadFile:(PCLModrinthFileInfo *)fileInfo
              toPath:(NSString *)path
            progress:(void (^)(double))progress
          completion:(void (^)(BOOL, NSError *))completion {
    
    if (fileInfo.url.length == 0) {
        if (completion) completion(NO, [NSError errorWithDomain:@"PCLModrinth" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Empty download URL"}]);
        return;
    }
    
    NSURL *url = [NSURL URLWithString:fileInfo.url];
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
                if (completion) completion(NO, [NSError errorWithDomain:@"PCLModrinth" code:httpResponse.statusCode userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"HTTP %ld", (long)httpResponse.statusCode]}]);
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

- (PCLModrinthProject *)parseProjectFromDict:(NSDictionary *)dict {
    PCLModrinthProject *project = [[PCLModrinthProject alloc] init];
    project.projectId = dict[@"project_id"] ?: dict[@"slug"] ?: @"";
    project.slug = dict[@"slug"] ?: @"";
    project.title = dict[@"title"] ?: @"";
    project.descriptionText = dict[@"description"] ?: @"";
    project.author = dict[@"author"] ?: @"";
    project.downloads = [dict[@"downloads"] longLongValue];
    project.followers = [dict[@"follows"] longLongValue];
    project.iconUrl = dict[@"icon_url"] ?: @"";
    project.dateCreated = dict[@"date_created"] ?: @"";
    project.dateModified = dict[@"date_modified"] ?: @"";
    project.latestVersion = dict[@"latest_version"] ?: @"";
    project.categories = dict[@"categories"] ?: @[];
    project.gameVersions = dict[@"versions"] ?: @[];
    project.license = dict[@"license"] ?: @"";
    project.galleryImageUrls = @"";
    project.bugUrl = dict[@"bug_url"] ?: @"";
    project.sourceUrl = dict[@"source_url"] ?: @"";
    project.wikiUrl = dict[@"wiki_url"] ?: @"";
    
    NSString *projectTypeStr = dict[@"project_type"] ?: @"mod";
    if ([projectTypeStr isEqualToString:@"modpack"]) {
        project.projectType = PCLModrinthProjectTypeModpack;
    } else if ([projectTypeStr isEqualToString:@"resourcepack"]) {
        project.projectType = PCLModrinthProjectTypeResourcePack;
    } else if ([projectTypeStr isEqualToString:@"shader"]) {
        project.projectType = PCLModrinthProjectTypeShader;
    } else {
        project.projectType = PCLModrinthProjectTypeMod;
    }
    
    return project;
}

- (PCLModrinthProject *)parseProjectDetailFromDict:(NSDictionary *)dict {
    PCLModrinthProject *project = [[PCLModrinthProject alloc] init];
    project.projectId = dict[@"id"] ?: @"";
    project.slug = dict[@"slug"] ?: @"";
    project.title = dict[@"title"] ?: @"";
    project.descriptionText = dict[@"description"] ?: @"";
    project.author = @"";
    project.downloads = [dict[@"downloads"] longLongValue];
    project.followers = [dict[@"followers"] longLongValue];
    project.iconUrl = dict[@"icon_url"] ?: @"";
    project.dateCreated = dict[@"published"] ?: @"";
    project.dateModified = dict[@"updated"] ?: @"";
    project.latestVersion = dict[@"versions"] ? [dict[@"versions"] lastObject] : @"";
    project.categories = dict[@"categories"] ?: @[];
    project.gameVersions = dict[@"game_versions"] ?: @[];
    project.loaders = dict[@"loaders"] ?: @[];
    project.license = dict[@"license"] ? (dict[@"license"][@"id"] ?: dict[@"license"]) : @"";
    project.sourceUrl = dict[@"source_url"] ?: @"";
    project.wikiUrl = dict[@"wiki_url"] ?: @"";
    project.bugUrl = dict[@"issues_url"] ?: @"";
    
    NSString *projectTypeStr = dict[@"project_type"] ?: @"mod";
    if ([projectTypeStr isEqualToString:@"modpack"]) {
        project.projectType = PCLModrinthProjectTypeModpack;
    } else if ([projectTypeStr isEqualToString:@"resourcepack"]) {
        project.projectType = PCLModrinthProjectTypeResourcePack;
    } else if ([projectTypeStr isEqualToString:@"shader"]) {
        project.projectType = PCLModrinthProjectTypeShader;
    } else {
        project.projectType = PCLModrinthProjectTypeMod;
    }
    
    return project;
}

- (PCLModrinthVersion *)parseVersionFromDict:(NSDictionary *)dict {
    PCLModrinthVersion *version = [[PCLModrinthVersion alloc] init];
    version.versionId = dict[@"id"] ?: @"";
    version.versionNumber = dict[@"version_number"] ?: @"";
    version.name = dict[@"name"] ?: @"";
    version.changelog = dict[@"changelog"] ?: @"";
    version.datePublished = dict[@"date_published"] ?: @"";
    version.downloads = [dict[@"downloads"] longLongValue];
    version.gameVersions = dict[@"game_versions"] ?: @[];
    version.loaders = dict[@"loaders"] ?: @[];
    version.files = dict[@"files"] ?: @[];
    version.versionType = dict[@"version_type"] ?: @"";
    version.projectId = dict[@"project_id"] ?: @"";
    return version;
}

@end
