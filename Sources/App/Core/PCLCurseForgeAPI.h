#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PCLCurseForgeModLoader) {
    PCLCurseForgeModLoaderAny = 0,
    PCLCurseForgeModLoaderForge = 1,
    PCLCurseForgeModLoaderCauldron = 2,
    PCLCurseForgeModLoaderLiteLoader = 3,
    PCLCurseForgeModLoaderFabric = 4,
    PCLCurseForgeModLoaderQuilt = 5,
    PCLCurseForgeModLoaderNeoForge = 6
};

typedef NS_ENUM(NSInteger, PCLCurseForgeSortField) {
    PCLCurseForgeSortFieldFeatured = 1,
    PCLCurseForgeSortFieldPopularity = 2,
    PCLCurseForgeSortFieldLastUpdated = 3,
    PCLCurseForgeSortFieldName = 4,
    PCLCurseForgeSortFieldAuthor = 5,
    PCLCurseForgeSortFieldTotalDownloads = 6,
    PCLCurseForgeSortFieldTrending = 7
};

typedef NS_ENUM(NSInteger, PCLCurseForgeSortOrder) {
    PCLCurseForgeSortOrderAsc = 1,
    PCLCurseForgeSortOrderDesc = 2
};

typedef NS_ENUM(NSInteger, PCLCurseForgeGameId) {
    PCLCurseForgeGameIdMinecraft = 432
};

@interface PCLCurseForgeMod : NSObject
@property (nonatomic, assign) NSInteger modId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *slug;
@property (nonatomic, copy) NSString *summary;
@property (nonatomic, copy) NSString *downloadUrl;
@property (nonatomic, assign) long long downloadCount;
@property (nonatomic, assign) double popularityScore;
@property (nonatomic, copy) NSString *authorName;
@property (nonatomic, copy) NSString *authorUrl;
@property (nonatomic, copy) NSString *iconUrl;
@property (nonatomic, copy) NSString *dateModified;
@property (nonatomic, copy) NSString *dateCreated;
@property (nonatomic, copy) NSString *dateReleased;
@property (nonatomic, copy) NSString *latestFileDate;
@property (nonatomic, assign) BOOL isFeatured;
@property (nonatomic, copy) NSArray<NSString *> *categories;
@property (nonatomic, copy) NSArray<NSString *> *gameVersions;
@property (nonatomic, copy) NSString *logoThumbnailUrl;
@end

@interface PCLCurseForgeFile : NSObject
@property (nonatomic, assign) NSInteger fileId;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *displayName;
@property (nonatomic, copy) NSString *downloadUrl;
@property (nonatomic, assign) long long fileLength;
@property (nonatomic, copy) NSString *dateModified;
@property (nonatomic, copy) NSString *gameVersion;
@property (nonatomic, copy) NSArray<NSString *> *gameVersions;
@property (nonatomic, copy) NSString *fileFingerprint;
@property (nonatomic, assign) BOOL isAvailable;
@property (nonatomic, assign) BOOL isRequired;
@end

@interface PCLCurseForgeCategory : NSObject
@property (nonatomic, assign) NSInteger categoryId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *slug;
@property (nonatomic, copy) NSString *iconUrl;
@property (nonatomic, copy) NSString *dateModified;
@property (nonatomic, assign) NSInteger parentCategoryId;
@property (nonatomic, assign) NSInteger classId;
@property (nonatomic, assign) BOOL isClass;
@end

@interface PCLCurseForgeSearchResult : NSObject
@property (nonatomic, copy) NSArray<PCLCurseForgeMod *> *data;
@property (nonatomic, copy) NSDictionary *pagination;
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, assign) NSInteger pageSize;
@property (nonatomic, assign) NSInteger resultCount;
@property (nonatomic, assign) NSInteger totalCount;
@end

@interface PCLCurseForgeAPI : NSObject

@property (nonatomic, copy) NSString *apiKey;
@property (nonatomic, assign) PCLCurseForgeGameId gameId;

+ (instancetype)sharedAPI;

+ (void)setAPIKey:(NSString *)apiKey;
+ (NSString *)apiKey;

- (void)searchMods:(NSString *)query
      gameVersion:(NSString *)gameVersion
         modLoader:(PCLCurseForgeModLoader)modLoader
          category:(NSString *)categoryName
              sort:(PCLCurseForgeSortField)sortField
         sortOrder:(PCLCurseForgeSortOrder)sortOrder
             limit:(NSInteger)limit
            offset:(NSInteger)offset
        completion:(void (^)(PCLCurseForgeSearchResult *result, NSError *error))completion;

- (void)searchMods:(NSString *)query
      gameVersion:(NSString *)gameVersion
         modLoader:(PCLCurseForgeModLoader)modLoader
          category:(NSString *)categoryId
              sort:(PCLCurseForgeSortField)sortField
             limit:(NSInteger)limit
            offset:(NSInteger)offset
        completion:(void (^)(PCLCurseForgeSearchResult *result, NSError *error))completion;

- (void)modWithId:(NSInteger)modId
       completion:(void (^)(PCLCurseForgeMod *mod, NSError *error))completion;

- (void)filesForMod:(NSInteger)modId
     gameVersion:(NSString *)gameVersion
       modLoader:(PCLCurseForgeModLoader)modLoader
      completion:(void (^)(NSArray<PCLCurseForgeFile *> *files, NSError *error))completion;

- (void)downloadUrlForFile:(NSInteger)modId
                   fileId:(NSInteger)fileId
               completion:(void (^)(NSString *downloadUrl, NSError *error))completion;

- (void)categoriesForGameId:(PCLCurseForgeGameId)gameId
                 completion:(void (^)(NSArray<PCLCurseForgeCategory *> *categories, NSError *error))completion;

- (void)downloadFile:(PCLCurseForgeFile *)file
              toPath:(NSString *)path
            progress:(void (^)(double progress))progress
          completion:(void (^)(BOOL success, NSError *error))completion;

@end
