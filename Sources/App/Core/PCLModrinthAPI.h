#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

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
    PCLModrinthModLoaderQuilt,
    PCLModrinthModLoaderLiteLoader,
    PCLModrinthModLoaderCauldron,
    PCLModrinthModLoaderRisugami
};

typedef NS_ENUM(NSInteger, PCLModrinthSortType) {
    PCLModrinthSortTypeRelevance = 0,
    PCLModrinthSortTypeDownloads,
    PCLModrinthSortTypeNewest,
    PCLModrinthSortTypeUpdated,
    PCLModrinthSortTypeFollowers
};

@interface PCLModrinthProject : NSObject
@property (nonatomic, copy) NSString *projectId;
@property (nonatomic, copy) NSString *slug;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *descriptionText;
@property (nonatomic, copy) NSString *author;
@property (nonatomic, assign) long long downloads;
@property (nonatomic, assign) long long followers;
@property (nonatomic, copy) NSString *iconUrl;
@property (nonatomic, copy) NSString *dateCreated;
@property (nonatomic, copy) NSString *dateModified;
@property (nonatomic, copy) NSString *latestVersion;
@property (nonatomic, copy) NSArray<NSString *> *categories;
@property (nonatomic, copy) NSArray<NSString *> *gameVersions;
@property (nonatomic, copy) NSArray<NSString *> *loaders;
@property (nonatomic, copy) NSString *license;
@property (nonatomic, copy) NSString *galleryImageUrls;
@property (nonatomic, copy) NSString *bugUrl;
@property (nonatomic, copy) NSString *sourceUrl;
@property (nonatomic, copy) NSString *wikiUrl;
@property (nonatomic, assign) PCLModrinthProjectType projectType;
@end

@interface PCLModrinthVersion : NSObject
@property (nonatomic, copy) NSString *versionId;
@property (nonatomic, copy) NSString *versionNumber;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *changelog;
@property (nonatomic, copy) NSString *datePublished;
@property (nonatomic, assign) long long downloads;
@property (nonatomic, copy) NSArray<NSString *> *gameVersions;
@property (nonatomic, copy) NSArray<NSString *> *loaders;
@property (nonatomic, copy) NSArray<NSDictionary *> *files;
@property (nonatomic, copy) NSString *versionType;
@property (nonatomic, copy) NSString *projectId;
@end

@interface PCLModrinthFileInfo : NSObject
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *sha1;
@property (nonatomic, assign) long long size;
@property (nonatomic, assign) BOOL isPrimary;
@end

@interface PCLModrinthCategory : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *categoryId;
@property (nonatomic, copy) NSString *icon;
@property (nonatomic, copy) NSString *header;
@property (nonatomic, assign) PCLModrinthProjectType projectType;
@end

@interface PCLModrinthSearchResult : NSObject
@property (nonatomic, copy) NSArray<PCLModrinthProject *> *hits;
@property (nonatomic, assign) long long totalHits;
@property (nonatomic, assign) NSInteger offset;
@property (nonatomic, assign) NSInteger limit;
@end

@interface PCLModrinthAPI : NSObject

+ (instancetype)sharedAPI;

- (void)searchProjects:(NSString *)query
               filters:(NSDictionary *)filters
                 limit:(NSInteger)limit
                offset:(NSInteger)offset
            completion:(void (^)(PCLModrinthSearchResult *result, NSError *error))completion;

- (void)searchProjects:(NSString *)query
          projectType:(PCLModrinthProjectType)projectType
               loader:(PCLModrinthModLoader)loader
          gameVersion:(NSString *)gameVersion
             category:(NSString *)category
             sortType:(PCLModrinthSortType)sortType
                limit:(NSInteger)limit
               offset:(NSInteger)offset
           completion:(void (^)(PCLModrinthSearchResult *result, NSError *error))completion;

- (void)projectWithId:(NSString *)projectId
           completion:(void (^)(PCLModrinthProject *project, NSError *error))completion;

- (void)versionsForProject:(NSString *)projectId
                   facets:(NSDictionary *)facets
               completion:(void (^)(NSArray<PCLModrinthVersion *> *versions, NSError *error))completion;

- (void)versionFiles:(NSString *)versionId
          completion:(void (^)(NSArray<PCLModrinthFileInfo *> *files, NSError *error))completion;

- (void)categories:(void (^)(NSArray<PCLModrinthCategory *> *categories, NSError *error))completion;

- (void)downloadFile:(PCLModrinthFileInfo *)fileInfo
              toPath:(NSString *)path
            progress:(void (^)(double progress))progress
          completion:(void (^)(BOOL success, NSError *error))completion;

+ (NSString *)loaderString:(PCLModrinthModLoader)loader;
+ (NSString *)projectTypeString:(PCLModrinthProjectType)type;
+ (NSString *)sortTypeString:(PCLModrinthSortType)type;

@end
