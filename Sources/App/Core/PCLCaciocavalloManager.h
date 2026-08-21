#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PCLCaciocavalloVersion) {
    PCLCaciocavalloVersion8 = 8,
    PCLCaciocavalloVersion17 = 17
};

@interface PCLCaciocavalloLibrary : NSObject
@property (nonatomic, copy) NSString *artifact;
@property (nonatomic, copy) NSString *version;
@property (nonatomic, assign) PCLCaciocavalloVersion javaVersion;
@property (nonatomic, copy) NSString *classifier;
@end

@interface PCLCaciocavalloManager : NSObject

+ (instancetype)sharedManager;

- (NSString *)caciocavalloDirectory;
- (NSString *)librariesDirectory;

- (NSArray<PCLCaciocavalloLibrary *> *)requiredCaciocavalloForJavaVersion:(NSInteger)javaVersion;
- (PCLCaciocavalloVersion)caciocavalloVersionForJavaVersion:(NSInteger)javaVersion;

- (void)downloadCaciocavallo:(PCLCaciocavalloVersion)version
                    progress:(void (^)(double progress))progress
                  completion:(void (^)(BOOL success, NSError *error))completion;

- (BOOL)isCaciocavalloDownloaded:(PCLCaciocavalloVersion)version;
- (NSString *)caciocavalloClasspath:(PCLCaciocavalloVersion)version;

- (NSString *)downloadURLForCaciocavallo:(PCLCaciocavalloVersion)version;
- (NSString *)localPathForCaciocavallo:(PCLCaciocavalloVersion)version;

@end
