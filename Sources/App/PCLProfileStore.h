#import <Foundation/Foundation.h>

@interface PCLProfileStore : NSObject
+ (NSArray<NSDictionary *> *)profiles;
+ (NSDictionary *)selectedProfile;
+ (void)saveAndSelectProfile:(NSDictionary *)profile;
+ (void)selectProfileWithIdentifier:(NSString *)identifier;
+ (void)replaceProfileWithIdentifier:(NSString *)identifier
                              profile:(NSDictionary *)profile
                               select:(BOOL)select;
+ (void)removeProfileWithIdentifier:(NSString *)identifier;
+ (NSString *)identifierForProfile:(NSDictionary *)profile;
@end
