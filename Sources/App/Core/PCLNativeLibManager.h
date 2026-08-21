#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PCLNativeLibType) {
    PCLNativeLibTypeRenderer = 0,
    PCLNativeLibTypeAudio,
    PCLNativeLibTypeInput,
    PCLNativeLibTypeVulkan,
    PCLNativeLibTypeSystem
};

@interface PCLNativeLib : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *path;
@property (nonatomic, assign) PCLNativeLibType type;
@property (nonatomic, assign) BOOL isAvailable;
@end

@interface PCLNativeLibManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, readonly) NSArray<PCLNativeLib *> *allLibs;
@property (nonatomic, readonly) NSArray<PCLNativeLib *> *rendererLibs;
@property (nonatomic, readonly) NSArray<PCLNativeLib *> *audioLibs;
@property (nonatomic, readonly) NSArray<PCLNativeLib *> *inputLibs;
@property (nonatomic, readonly) NSArray<PCLNativeLib *> *vulkanLibs;

- (NSString *)pathForLib:(NSString *)name;
- (BOOL)isAvailable:(NSString *)name;
- (NSString *)glfwPath;
- (NSString *)sdl3Path;
- (NSString *)moltenVKPath;
- (NSString *)openALPath;
- (NSString *)rendererPath:(NSString *)rendererName;

@end
