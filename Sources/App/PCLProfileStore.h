#import <Foundation/Foundation.h>

@interface PCLProfileStore : NSObject
+ (NSArray<NSDictionary *> *)profiles;
+ (NSDictionary *)selectedProfile;
+ (void)saveAndSelectProfile:(NSDictionary *)profile;
+ (void)selectProfileWithIdentifier:(NSString *)identifier;
+ (NSString *)identifierForProfile:(NSDictionary *)profile;
@end
