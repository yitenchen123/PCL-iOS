#import <UIKit/UIKit.h>

typedef void (^PCLAuthStatusBlock)(NSString *text);
typedef void (^PCLAuthResultBlock)(
    NSDictionary *profile, NSString *error);

@interface PCLAccountAuthenticator : NSObject

- (instancetype)initWithAnchorView:(UIView *)view;

- (void)startMicrosoftWithStatus:(PCLAuthStatusBlock)status
                      completion:(PCLAuthResultBlock)completion;

+ (void)loginAuthlibServer:(NSString *)server
                  username:(NSString *)username
                  password:(NSString *)password
                    status:(PCLAuthStatusBlock)status
                completion:(PCLAuthResultBlock)completion;

+ (NSString *)offlineUUIDForName:(NSString *)name
                          legacy:(BOOL)legacy;

+ (BOOL)setSecret:(NSString *)value key:(NSString *)key;
+ (NSString *)secretForKey:(NSString *)key;
@end
