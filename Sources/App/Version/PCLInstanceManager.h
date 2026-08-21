#import <Foundation/Foundation.h>

@interface PCLInstance : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *versionId;
@property (nonatomic, copy) NSString *gameDir;
@property (nonatomic, copy) NSString *javaArgs;
@property (nonatomic, assign) NSInteger resolutionWidth;
@property (nonatomic, assign) NSInteger resolutionHeight;
@property (nonatomic, copy) NSString *javaVersion;
@property (nonatomic, copy) NSString *created;
@property (nonatomic, assign) NSInteger memoryMaxMB;
@property (nonatomic, assign) BOOL autoSelectJava;
@property (nonatomic, copy) NSString *gameArguments;

- (NSDictionary *)toDictionary;
+ (instancetype)instanceFromDictionary:(NSDictionary *)dict;

@end

extern NSString *const PCLCurrentInstanceNameKey;

@interface PCLInstanceManager : NSObject

+ (instancetype)sharedManager;

- (NSArray<PCLInstance *> *)allInstances;
- (BOOL)createInstanceWithName:(NSString *)name versionId:(NSString *)versionId;
- (BOOL)deleteInstanceWithName:(NSString *)name;
- (PCLInstance *)instanceWithName:(NSString *)name;
- (void)selectInstance:(PCLInstance *)instance;
- (PCLInstance *)currentInstance;
- (BOOL)saveInstance:(PCLInstance *)instance;

@end
