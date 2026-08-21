#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PCLNativeLibType) {
    PCLNativeLibTypeRenderer = 0,
    PCLNativeLibTypeAudio,
    PCLNativeLibTypeInput
};

@interface PCLNativeLib : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *filename;
@property (nonatomic, assign) PCLNativeLibType type;
@property (nonatomic, copy) NSString *downloadURL;
@property (nonatomic, assign) BOOL isRequired;
@end

@interface PCLNativeLibManager : NSObject

+ (instancetype)sharedManager;

- (NSString *)nativeLibDirectory;
- (NSString *)rendererLibDirectory;
- (NSString *)audioLibDirectory;
- (NSString *)inputLibDirectory;

- (NSArray<PCLNativeLib *> *)requiredNativeLibs;
- (NSArray<PCLNativeLib *> *)requiredNativeLibsForType:(PCLNativeLibType)type;

- (void)downloadNativeLibs:(void (^)(double progress, NSString *currentLib))progress
                completion:(void (^)(BOOL success, NSError *error))completion;

- (NSString *)nativeLibPath:(NSString *)libName;
- (BOOL)isNativeLibAvailable:(NSString *)libName;

- (NSArray<NSString *> *)rendererDylibs;
- (NSArray<NSString *> *)audioDylibs;
- (NSArray<NSString *> *)inputDylibs;
- (NSArray<NSString *> *)allRequiredDylibPaths;

@end
