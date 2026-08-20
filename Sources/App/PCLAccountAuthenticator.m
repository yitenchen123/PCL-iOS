#import "PCLAccountAuthenticator.h"
#import <AuthenticationServices/AuthenticationServices.h>
#import <Security/Security.h>
#import <CommonCrypto/CommonDigest.h>

static NSString *const PCLMSClient=@"00000000402b5328";
static NSString *const PCLMSCallback=@"ms-xal-00000000402b5328";

@interface PCLAccountAuthenticator ()
<ASWebAuthenticationPresentationContextProviding>
@property(nonatomic,weak) UIView *anchorView;
@property(nonatomic,strong) ASWebAuthenticationSession *webSession;
@property(nonatomic,copy) PCLAuthStatusBlock statusBlock;
@property(nonatomic,copy) PCLAuthResultBlock resultBlock;
@property(nonatomic,copy) NSString *msaRefreshToken;
@end

static void PCLStatus(PCLAuthStatusBlock block, NSString *text) {
    if (!block) return;
    dispatch_async(dispatch_get_main_queue(), ^{ block(text); });
}

static void PCLResult(PCLAuthResultBlock block,
                      NSDictionary *profile, NSString *error) {
    if (!block) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        block(profile,error);
    });
}

static void PCLJSONRequest(
    NSString *method, NSString *urlText, NSDictionary *body,
    NSDictionary *headers,
    void (^done)(NSDictionary *,NSInteger,NSError *)) {

    NSURL *url=[NSURL URLWithString:urlText];
    NSMutableURLRequest *r=[NSMutableURLRequest requestWithURL:url];
    r.HTTPMethod=method;

    [r setValue:@"application/json" forHTTPHeaderField:@"Accept"];

    for (NSString *key in headers)
        [r setValue:headers[key] forHTTPHeaderField:key];

    if (body) {
        [r setValue:@"application/json"
 forHTTPHeaderField:@"Content-Type"];
        r.HTTPBody=[NSJSONSerialization dataWithJSONObject:body
                                                   options:0 error:nil];
    }

    [[[NSURLSession sharedSession] dataTaskWithRequest:r
        completionHandler:^(NSData *data,
                            NSURLResponse *response,
                            NSError *error) {
        NSInteger code=
            [(NSHTTPURLResponse *)response statusCode];
        NSDictionary *json=nil;
        if (data.length)
            json=[NSJSONSerialization JSONObjectWithData:data
                                                  options:0 error:nil];
        done(json,code,error);
    }] resume];
}

static NSString *PCLServerError(NSDictionary *json, NSInteger code) {
    id text=json[@"errorMessage"] ?: json[@"error_description"]
        ?: json[@"error"] ?: json[@"cause"];

    if ([text isKindOfClass:NSString.class] &&
        [text length]) return text;

    return [NSString stringWithFormat:@"服务器返回错误（%ld）",
                                      (long)code];
}

@implementation PCLAccountAuthenticator

+ (BOOL)setSecret:(NSString *)value key:(NSString *)key {
    if (!value.length || !key.length) return NO;

    NSDictionary *q=@{
        (__bridge id)kSecClass:(__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService:@"com.pcl-ios.account",
        (__bridge id)kSecAttrAccount:key
    };
    SecItemDelete((__bridge CFDictionaryRef)q);

    NSMutableDictionary *add=q.mutableCopy;
    add[(__bridge id)kSecValueData]=
        [value dataUsingEncoding:NSUTF8StringEncoding];
    add[(__bridge id)kSecAttrAccessible]=
        (__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly;

    return SecItemAdd(
        (__bridge CFDictionaryRef)add,NULL)==errSecSuccess;
}

+ (NSString *)secretForKey:(NSString *)key {
    NSDictionary *q=@{
        (__bridge id)kSecClass:(__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService:@"com.pcl-ios.account",
        (__bridge id)kSecAttrAccount:key,
        (__bridge id)kSecReturnData:@YES,
        (__bridge id)kSecMatchLimit:(__bridge id)kSecMatchLimitOne
    };

    CFTypeRef result=NULL;
    if (SecItemCopyMatching((__bridge CFDictionaryRef)q,
                            &result)!=errSecSuccess)
        return nil;

    NSData *data=CFBridgingRelease(result);
    return [[NSString alloc] initWithData:data
                                 encoding:NSUTF8StringEncoding];
}

+ (NSString *)offlineUUIDForName:(NSString *)name
                          legacy:(BOOL)legacy {
    if (!legacy) {
        NSString *source=
            [@"OfflinePlayer:" stringByAppendingString:name];
        NSData *data=[source dataUsingEncoding:NSUTF8StringEncoding];

        unsigned char md[CC_MD5_DIGEST_LENGTH];
        CC_MD5(data.bytes,(CC_LONG)data.length,md);

        md[6]=(md[6]&0x0F)|0x30;
        md[8]=(md[8]&0x3F)|0x80;

        NSMutableString *uuid=[NSMutableString string];
        for (NSInteger i=0;i<16;i++)
            [uuid appendFormat:@"%02x",md[i]];
        return uuid;
    }

    uint64_t hash=5381;
    for (NSUInteger i=0;i<name.length;i++)
        hash=((hash<<5)^hash)^[name characterAtIndex:i];

    NSString *full=[NSString stringWithFormat:@"%016llX%016llX",
        (unsigned long long)name.length,
        (unsigned long long)hash];

    NSMutableString *uuid=full.mutableCopy;
    [uuid replaceCharactersInRange:NSMakeRange(12,1) withString:@"3"];
    [uuid replaceCharactersInRange:NSMakeRange(16,1) withString:@"9"];
    return uuid;
}


+ (void)resolveAuthlibServer:(NSString *)input
    completion:(void (^)(NSString *,NSString *))completion {
    __block NSString *root=[input stringByTrimmingCharactersInSet:
        NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (![root containsString:@"://"])
        root=[@"https://" stringByAppendingString:root];

    NSURL *url=[NSURL URLWithString:root];
    if (!url.host.length) {
        completion(nil,@"验证服务器地址无效");
        return;
    }

    NSMutableURLRequest *r=[NSMutableURLRequest requestWithURL:url];
    r.HTTPMethod=@"HEAD";
    r.timeoutInterval=8;

    [[[NSURLSession sharedSession] dataTaskWithRequest:r
        completionHandler:^(NSData *data,NSURLResponse *response,NSError *error) {

        NSHTTPURLResponse *http=(NSHTTPURLResponse *)response;
        NSString *location=nil;

        for (id key in http.allHeaderFields) {
            if ([[key description] caseInsensitiveCompare:
                @"X-Authlib-Injector-Api-Location"]==NSOrderedSame)
                location=[http.allHeaderFields[key] description];
        }

        if (location.length) {
            NSURL *resolved=[NSURL URLWithString:location
                                  relativeToURL:http.URL];
            root=resolved.absoluteURL.absoluteString ?: root;
        }

        while ([root hasSuffix:@"/"])
            root=[root substringToIndex:root.length-1];

        dispatch_async(dispatch_get_main_queue(), ^{
            completion(root,nil);
        });
    }] resume];
}

+ (void)loginAuthlibServer:(NSString *)input
                  username:(NSString *)username
                  password:(NSString *)password
                    status:(PCLAuthStatusBlock)status
                completion:(PCLAuthResultBlock)completion {

    NSString *server=[input
        stringByTrimmingCharactersInSet:
            NSCharacterSet.whitespaceAndNewlineCharacterSet];

    if (![server containsString:@"://"])
        server=[@"https://" stringByAppendingString:server];

    while ([server hasSuffix:@"/"])
        server=[server substringToIndex:server.length-1];

    NSURLComponents *parts=
        [NSURLComponents componentsWithString:server];
    if (!parts.host.length) {
        PCLResult(completion,nil,@"验证服务器地址无效");
        return;
    }

    BOOL local=[parts.host isEqualToString:@"localhost"] ||
               [parts.host isEqualToString:@"127.0.0.1"];

    if (![parts.scheme.lowercaseString isEqualToString:@"https"]
        && !local) {
        PCLResult(completion,nil,
            @"第三方验证服务器必须使用 HTTPS");
        return;
    }

    PCLStatus(status,@"正在连接第三方验证服务器…");

    NSString *client=
        [[NSUUID UUID].UUIDString
            stringByReplacingOccurrencesOfString:@"-" withString:@""];

    NSDictionary *body=@{
        @"agent":@{@"name":@"Minecraft",@"version":@1},
        @"username":username,
        @"password":password,
        @"clientToken":client,
        @"requestUser":@YES
    };

    NSString *url=[server hasSuffix:@"/authserver"]
        ? [server stringByAppendingString:@"/authenticate"]
        : [server stringByAppendingString:@"/authserver/authenticate"];

    PCLJSONRequest(@"POST",url,body,nil,
        ^(NSDictionary *json, NSInteger code, NSError *error) {
        if (error) {
            PCLResult(completion,nil,error.localizedDescription);
            return;
        }
        if (code<200 || code>=300) {
            PCLResult(completion,nil,PCLServerError(json,code));
            return;
        }

        NSDictionary *profile=json[@"selectedProfile"];
        if (![profile isKindOfClass:NSDictionary.class]) {
            NSArray *list=json[@"availableProfiles"];
            if ([list isKindOfClass:NSArray.class] && list.count)
                profile=list.firstObject;
        }

        NSString *uuid=profile[@"id"];
        NSString *name=profile[@"name"];
        NSString *access=json[@"accessToken"];

        if (!uuid.length || !name.length || !access.length) {
            PCLResult(completion,nil,@"验证服务器没有返回有效角色");
            return;
        }

        NSString *prefix=
            [@"authlib." stringByAppendingString:uuid];
        [self setSecret:access
                    key:[prefix stringByAppendingString:@".access"]];

        NSString *returnedClient=json[@"clientToken"] ?: client;
        [self setSecret:returnedClient
                    key:[prefix stringByAppendingString:@".client"]];

        PCLResult(completion,@{
            @"username":name,
            @"uuid":uuid,
            @"type":@"authlib",
            @"server":server,
            @"credentialPrefix":prefix
        },nil);
    });
}

- (instancetype)initWithAnchorView:(UIView *)view {
    self=[super init];
    if (self) self.anchorView=view;
    return self;
}

- (void)startMicrosoftWithStatus:(PCLAuthStatusBlock)status
                      completion:(PCLAuthResultBlock)completion {
    self.statusBlock=status;
    self.resultBlock=completion;

    NSString *text=
    @"https://login.live.com/oauth20_authorize.srf?"
     "client_id=00000000402b5328&response_type=code&"
     "scope=service%3A%3Auser.auth.xboxlive.com%3A%3AMBI_SSL&"
     "redirect_url=https%3A%2F%2Flogin.live.com%2Foauth20_desktop.srf";

    NSURL *url=[NSURL URLWithString:text];
    __weak typeof(self) weakSelf=self;

    self.webSession=[[ASWebAuthenticationSession alloc]
        initWithURL:url callbackURLScheme:PCLMSCallback
        completionHandler:^(NSURL *callbackURL, NSError *error) {

        if (!callbackURL) {
            NSString *message=
                error.code==ASWebAuthenticationSessionErrorCodeCanceledLogin
                ? @"已取消正版验证"
                : error.localizedDescription;
            PCLResult(weakSelf.resultBlock,nil,message);
            return;
        }

        NSURLComponents *c=
            [NSURLComponents componentsWithURL:callbackURL
                       resolvingAgainstBaseURL:NO];

        NSString *code=nil;
        NSString *authError=nil;
        for (NSURLQueryItem *item in c.queryItems) {
            if ([item.name isEqual:@"code"]) code=item.value;
            if ([item.name isEqual:@"error_description"])
                authError=item.value;
        }

        if (!code.length) {
            PCLResult(weakSelf.resultBlock,nil,
                      authError ?: @"Microsoft 未返回授权码");
            return;
        }

        [weakSelf exchangeMicrosoftCode:code];
    }];

    self.webSession.prefersEphemeralWebBrowserSession=YES;
    self.webSession.presentationContextProvider=self;

    PCLStatus(status,@"等待 Microsoft 登录…");

    if (![self.webSession start])
        PCLResult(completion,nil,@"无法打开 Microsoft 登录页面");
}

- (void)exchangeMicrosoftCode:(NSString *)code {
    PCLStatus(self.statusBlock,@"正在获取 Microsoft 令牌…");

    NSURLComponents *c=[NSURLComponents componentsWithString:
        @"https://login.live.com/oauth20_token.srf"];

    c.queryItems=@[
        [NSURLQueryItem queryItemWithName:@"client_id"
                                    value:PCLMSClient],

        [NSURLQueryItem queryItemWithName:@"code" value:code],
        [NSURLQueryItem queryItemWithName:@"grant_type"
                                    value:@"authorization_code"],
        [NSURLQueryItem queryItemWithName:@"redirect_url"
                                    value:@"https://login.live.com/oauth20_desktop.srf"],
        [NSURLQueryItem queryItemWithName:@"scope"
                                    value:@"service::user.auth.xboxlive.com::MBI_SSL"]
    ];

    PCLJSONRequest(@"GET",c.URL.absoluteString,nil,nil,
        ^(NSDictionary *json, NSInteger status, NSError *error) {
        NSString *access=json[@"access_token"];
        self.msaRefreshToken=json[@"refresh_token"];

        if (error || !access.length) {
            [self failMicrosoft:error.localizedDescription ?:
                PCLServerError(json,status)];
            return;
        }
        [self acquireXBL:access];
    });
}

- (void)acquireXBL:(NSString *)access {
    PCLStatus(self.statusBlock,@"正在验证 Xbox Live…");

    NSDictionary *body=@{
        @"Properties":@{
            @"AuthMethod":@"RPS",
            @"SiteName":@"user.auth.xboxlive.com",
            @"RpsTicket":access
        },
        @"RelyingParty":@"http://auth.xboxlive.com",
        @"TokenType":@"JWT"
    };

    PCLJSONRequest(@"POST",
        @"https://user.auth.xboxlive.com/user/authenticate",
        body,nil,^(NSDictionary *json,NSInteger code,NSError *error) {
        NSString *token=json[@"Token"];
        if (error || !token.length) {
            [self failMicrosoft:error.localizedDescription ?:
                PCLServerError(json,code)];
            return;
        }
        [self acquireXSTS:token];
    });
}

- (void)acquireXSTS:(NSString *)xbl {
    PCLStatus(self.statusBlock,@"正在获取 XSTS 令牌…");

    NSDictionary *body=@{
        @"Properties":@{
            @"SandboxId":@"RETAIL",
            @"UserTokens":@[xbl]
        },
        @"RelyingParty":@"rp://api.minecraftservices.com/",
        @"TokenType":@"JWT"
    };

    PCLJSONRequest(@"POST",
        @"https://xsts.auth.xboxlive.com/xsts/authorize",
        body,nil,^(NSDictionary *json,NSInteger code,NSError *error) {

        NSString *token=json[@"Token"];
        NSArray *xui=json[@"DisplayClaims"][@"xui"];
        NSString *uhs=xui.count ? xui[0][@"uhs"] : nil;

        if (error || !token.length || !uhs.length) {

            NSNumber *xerr=json[@"XErr"];
            NSString *msg=xerr
                ? [NSString stringWithFormat:
                    @"Xbox/XSTS 验证失败（%@）",xerr]
                : PCLServerError(json,code);
            [self failMicrosoft:error.localizedDescription ?: msg];
            return;
        }
        [self acquireMinecraft:token uhs:uhs];
    });
}

- (void)acquireMinecraft:(NSString *)xsts uhs:(NSString *)uhs {
    PCLStatus(self.statusBlock,@"正在登录 Minecraft…");

    NSString *identity=
        [NSString stringWithFormat:@"XBL3.0 x=%@;%@",uhs,xsts];

    PCLJSONRequest(@"POST",
        @"https://api.minecraftservices.com/authentication/login_with_xbox",
        @{@"identityToken":identity},nil,

        ^(NSDictionary *json,NSInteger code,NSError *error) {
        NSString *access=json[@"access_token"];
        if (error || !access.length) {
            [self failMicrosoft:error.localizedDescription ?:
                PCLServerError(json,code)];
            return;
        }
        [self fetchMinecraftProfile:access];
    });
}

- (void)fetchMinecraftProfile:(NSString *)access {
    PCLStatus(self.statusBlock,@"正在获取 Minecraft 档案…");

    NSDictionary *headers=@{
        @"Authorization":
            [@"Bearer " stringByAppendingString:access]
    };

    PCLJSONRequest(@"GET",
        @"https://api.minecraftservices.com/minecraft/profile",
        nil,headers,

        ^(NSDictionary *json,NSInteger code,NSError *error) {
        NSString *uuid=json[@"id"];
        NSString *name=json[@"name"];

        if (error || !uuid.length || !name.length) {
            [self failMicrosoft:error.localizedDescription ?:
                @"该账户没有可用的 Minecraft Java 档案"];
            return;
        }

        NSString *prefix=
            [@"microsoft." stringByAppendingString:uuid];

        [PCLAccountAuthenticator setSecret:access
            key:[prefix stringByAppendingString:@".access"]];

        if (self.msaRefreshToken.length)
            [PCLAccountAuthenticator setSecret:self.msaRefreshToken
                key:[prefix stringByAppendingString:@".refresh"]];

        PCLResult(self.resultBlock,@{
            @"username":name,
            @"uuid":uuid,
            @"type":@"microsoft",
            @"credentialPrefix":prefix
        },nil);
    });
}

- (void)failMicrosoft:(NSString *)message {
    PCLResult(self.resultBlock,nil,
              message.length ? message : @"正版验证失败");
}

- (ASPresentationAnchor)presentationAnchorForWebAuthenticationSession:
    (ASWebAuthenticationSession *)session {
    UIWindow *window=self.anchorView.window;
    return window ?: UIApplication.sharedApplication.windows.firstObject;
}

@end
