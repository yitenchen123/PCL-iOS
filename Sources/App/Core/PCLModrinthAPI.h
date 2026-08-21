#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PCLModrinthProject : NSObject
@property (nonatomic, strong) NSString *projectID;
@property (nonatomic, strong) NSString *slug;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *descriptionText;
@property (nonatomic, strong) NSString *iconUrl;
@property (nonatomic, assign) NSInteger downloadCount;
@property (nonatomic, assign) NSInteger followerCount;
@property (nonatomic, strong) NSString *projectType; // mod, modpack, resourcepack
@end

@interface PCLModrinthVersion : NSObject
@property (nonatomic, strong) NSString *versionID;
@property (nonatomic, strong) NSString *versionNumber;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSArray<NSString *> *gameVersions;
@property (nonatomic, strong) NSArray<NSString *> *loaders;
@property (nonatomic, strong) NSArray<NSDictionary *> *files;
@end

@interface PCLModrinthAPI : NSObject

+ (instancetype)sharedAPI;

// Search
- (void)searchWithQuery:(NSString *)query
               facets:(nullable NSString *)facets
                   page:(NSInteger)page
               pageSize:(NSInteger)pageSize
             completion:(void(^)(NSArray<PCLModrinthProject *> *projects, NSError *error))completion;

// Get project
- (void)getProject:(NSString *)slugOrID
        completion:(void(^)(PCLModrinthProject *project, NSError *error))completion;

// Get versions
- (void)getVersionsForProject:(NSString *)slugOrID
                   completion:(void(^)(NSArray<PCLModrinthVersion *> *versions, NSError *error))completion;

// Get version by ID
- (void)getVersion:(NSString *)versionID
        completion:(void(^)(NSDictionary *versionInfo, NSError *error))completion;

// Get latest version by game version and loader
- (void)getLatestVersionForProject:(NSString *)slugOrID
                       gameVersion:(NSString *)gameVersion
                            loader:(NSString *)loader
                        completion:(void(^)(PCLModrinthVersion *version, NSError *error))completion;

@end

NS_ASSUME_NONNULL_END
