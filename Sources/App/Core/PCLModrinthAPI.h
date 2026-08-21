#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PCLModrinthProject : NSObject
@property (nonatomic, strong) NSString *projectID;
@property (nonatomic, strong) NSString *slug;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *descriptionText;
@property (nonatomic, strong) NSString *iconUrl;
@property (nonatomic, strong) NSString *author;
@property (nonatomic, assign) NSInteger downloads;
@property (nonatomic, assign) NSInteger downloadCount;
@property (nonatomic, assign) NSInteger followerCount;
@property (nonatomic, strong) NSString *projectType; // mod, modpack, resourcepack
@end

@interface PCLModrinthFileInfo : NSObject
@property (nonatomic, strong) NSString *fileName;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, assign) NSInteger size;
@property (nonatomic, assign) BOOL isPrimary;
@property (nonatomic, assign) NSInteger downloads;
@end

@interface PCLModrinthVersion : NSObject
@property (nonatomic, strong) NSString *versionID;
@property (nonatomic, strong) NSString *versionNumber;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSArray<NSString *> *gameVersions;
@property (nonatomic, strong) NSArray<NSString *> *loaders;
@property (nonatomic, strong) NSArray<NSDictionary *> *files;
@property (nonatomic, strong) NSArray<PCLModrinthFileInfo *> *fileInfos;
@property (nonatomic, assign) NSInteger downloads;
@end

typedef NS_ENUM(NSInteger, PCLModrinthProjectType) {
    PCLModrinthProjectTypeMod = 0,
    PCLModrinthProjectTypeModpack,
    PCLModrinthProjectTypeResourcePack,
    PCLModrinthProjectTypeShader
};

typedef NS_ENUM(NSInteger, PCLModrinthModLoader) {
    PCLModrinthModLoaderForge = 0,
    PCLModrinthModLoaderFabric,
    PCLModrinthModLoaderNeoForge,
    PCLModrinthModLoaderQuilt
};

typedef NS_ENUM(NSInteger, PCLModrinthSortType) {
    PCLModrinthSortTypeRelevance = 0,
    PCLModrinthSortTypeDownloads,
    PCLModrinthSortTypeNewest,
    PCLModrinthSortTypeUpdated
};

@interface PCLModrinthSearchResult : NSObject
@property (nonatomic, strong) NSArray<PCLModrinthProject *> *hits;
@property (nonatomic, assign) NSInteger totalHits;
@end

@interface PCLModrinthAPI : NSObject

+ (instancetype)sharedAPI;

// Search (legacy - simple)
- (void)searchWithQuery:(NSString *)query
               facets:(nullable NSString *)facets
                   page:(NSInteger)page
               pageSize:(NSInteger)pageSize
             completion:(void(^)(NSArray<PCLModrinthProject *> *projects, NSError *error))completion;

// Search (PCL-CE风格：完整筛选)
- (void)searchProjects:(NSString *)query
            projectType:(PCLModrinthProjectType)projectType
                 loader:(PCLModrinthModLoader)loader
            gameVersion:(NSString *)gameVersion
               category:(nullable NSString *)category
               sortType:(PCLModrinthSortType)sortType
                  limit:(NSInteger)limit
                 offset:(NSInteger)offset
             completion:(void(^)(PCLModrinthSearchResult *result, NSError *error))completion;

// Get project
- (void)getProject:(NSString *)slugOrID
        completion:(void(^)(PCLModrinthProject *project, NSError *error))completion;

// Get versions (legacy - all versions)
- (void)getVersionsForProject:(NSString *)slugOrID
                   completion:(void(^)(NSArray<PCLModrinthVersion *> *versions, NSError *error))completion;

// Get versions (PCL-CE风格：带筛选)
- (void)versionsForProject:(NSString *)projectID
                    facets:(NSDictionary *)facets
                completion:(void(^)(NSArray<PCLModrinthVersion *> *versions, NSError *error))completion;

// Get version by ID
- (void)getVersion:(NSString *)versionID
        completion:(void(^)(NSDictionary *versionInfo, NSError *error))completion;

// Get latest version by game version and loader
- (void)getLatestVersionForProject:(NSString *)slugOrID
                       gameVersion:(NSString *)gameVersion
                            loader:(NSString *)loader
                        completion:(void(^)(PCLModrinthVersion *version, NSError *error))completion;

// Search with filters dictionary (for modpacks, etc.)
- (void)searchProjects:(NSString *)query
               filters:(NSDictionary *)filters
                 limit:(NSInteger)limit
                offset:(NSInteger)offset
            completion:(void(^)(PCLModrinthSearchResult *result, NSError *error))completion;

// Download file
- (void)downloadFile:(PCLModrinthFileInfo *)file
              toPath:(NSString *)path
            progress:(void(^)(double progress))progress
          completion:(void(^)(BOOL success, NSError *error))completion;

// Helper: convert sort type to API string
+ (NSString *)sortTypeString:(PCLModrinthSortType)sortType;

@end

NS_ASSUME_NONNULL_END
