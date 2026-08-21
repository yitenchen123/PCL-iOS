#import "PCLModrinthAPI.h"

@implementation PCLModrinthProject
@end

@implementation PCLModrinthVersion
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

@end
