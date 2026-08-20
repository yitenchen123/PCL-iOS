#import "PCLProfileStore.h"

static NSString *const PCLProfilesKey=@"PCLProfiles";
static NSString *const PCLSelectedKey=@"PCLSelectedProfileID";

@implementation PCLProfileStore

+ (NSString *)identifierForProfile:(NSDictionary *)p {
    NSString *type=p[@"type"] ?: @"unknown";
    NSString *uuid=p[@"uuid"] ?: p[@"username"] ?: @"";
    NSString *server=p[@"server"] ?: @"";
    return [NSString stringWithFormat:@"%@|%@|%@",
        type,uuid,server];
}

+ (NSMutableArray *)mutableProfiles {
    NSUserDefaults *d=NSUserDefaults.standardUserDefaults;
    NSArray *saved=[d arrayForKey:PCLProfilesKey];
    NSMutableArray *out=saved
        ? saved.mutableCopy : NSMutableArray.array;

    if (out.count) return out;

    NSString *name=[d stringForKey:@"PCLProfileUsername"];
    if (!name.length) return out;

    NSMutableDictionary *old=
        [@{@"username":name} mutableCopy];

    NSDictionary *map=@{
        @"uuid":@"PCLProfileUUID",
        @"type":@"PCLProfileType",
        @"server":@"PCLProfileServer",
        @"credentialPrefix":@"PCLCredentialPrefix"
    };

    for (NSString *key in map) {
        id value=[d objectForKey:map[key]];
        if (value) old[key]=value;
    }

    old[@"identifier"]=[self identifierForProfile:old];
    [out addObject:old];
    [d setObject:out forKey:PCLProfilesKey];
    [d setObject:old[@"identifier"] forKey:PCLSelectedKey];
    return out;
}

+ (void)syncLegacy:(NSDictionary *)profile {
    NSUserDefaults *d=NSUserDefaults.standardUserDefaults;

    NSDictionary *map=@{
        @"username":@"PCLProfileUsername",
        @"uuid":@"PCLProfileUUID",
        @"type":@"PCLProfileType",
        @"server":@"PCLProfileServer",
        @"credentialPrefix":@"PCLCredentialPrefix"
    };

    for (NSString *key in map) {
        id value=profile[key];
        if (value) [d setObject:value forKey:map[key]];
        else [d removeObjectForKey:map[key]];
    }
}

+ (NSArray *)profiles {
    return [[self mutableProfiles] copy];
}

+ (void)saveAndSelectProfile:(NSDictionary *)profile {
    NSMutableArray *list=[self mutableProfiles];
    NSMutableDictionary *copy=profile.mutableCopy;
    NSString *pid=[self identifierForProfile:copy];
    copy[@"identifier"]=pid;

    NSInteger index=NSNotFound;
    for (NSInteger i=0;i<list.count;i++)
        if ([list[i][@"identifier"] isEqual:pid]) index=i;

    if (index==NSNotFound) [list addObject:copy];
    else list[index]=copy;

    NSUserDefaults *d=NSUserDefaults.standardUserDefaults;
    [d setObject:list forKey:PCLProfilesKey];
    [d setObject:pid forKey:PCLSelectedKey];
    [self syncLegacy:copy];
}

+ (NSDictionary *)selectedProfile {
    NSArray *list=[self mutableProfiles];
    NSString *pid=[NSUserDefaults.standardUserDefaults
        stringForKey:PCLSelectedKey];

    for (NSDictionary *p in list) {
        if ([p[@"identifier"] isEqual:pid]) {
            [self syncLegacy:p];
            return p;
        }
    }

    NSDictionary *first=list.firstObject;
    if (first) {
        [NSUserDefaults.standardUserDefaults
            setObject:first[@"identifier"] forKey:PCLSelectedKey];
        [self syncLegacy:first];
    }
    return first;
}

+ (void)selectProfileWithIdentifier:(NSString *)identifier {
    for (NSDictionary *p in [self mutableProfiles]) {
        if (![p[@"identifier"] isEqual:identifier]) continue;

        [NSUserDefaults.standardUserDefaults
            setObject:identifier forKey:PCLSelectedKey];
        [self syncLegacy:p];
        return;
    }
}

+ (void)replaceProfileWithIdentifier:(NSString *)identifier

                              profile:(NSDictionary *)profile

                               select:(BOOL)select {

    NSMutableArray *list=[self mutableProfiles];

    NSInteger index=NSNotFound;

    for (NSInteger i=0;i<list.count;i++)

        if ([list[i][@"identifier"] isEqual:identifier])

            index=i;

    if (index==NSNotFound) return;


    NSMutableDictionary *copy=profile.mutableCopy;
    NSString *newID=[self identifierForProfile:copy];
    copy[@"identifier"]=newID;
    list[index]=copy;

    NSUserDefaults *d=
        NSUserDefaults.standardUserDefaults;
    [d setObject:list forKey:PCLProfilesKey];

    NSString *current=
        [d stringForKey:PCLSelectedKey];

    if (select || [current isEqual:identifier]) {
        [d setObject:newID forKey:PCLSelectedKey];
        [self syncLegacy:copy];
    }
}

+ (void)removeProfileWithIdentifier:(NSString *)identifier {
    NSMutableArray *list=[self mutableProfiles];
    NSInteger index=NSNotFound;

    for (NSInteger i=0;i<list.count;i++)
        if ([list[i][@"identifier"] isEqual:identifier])
            index=i;

    if (index==NSNotFound) return;

    NSUserDefaults *d=
        NSUserDefaults.standardUserDefaults;

    BOOL selected=[[d stringForKey:PCLSelectedKey]
        isEqual:identifier];

    [list removeObjectAtIndex:index];
    [d setObject:list forKey:PCLProfilesKey];

    if (!selected) return;

    NSDictionary *next=list.firstObject;
    if (next) {
        [d setObject:next[@"identifier"]
              forKey:PCLSelectedKey];
        [self syncLegacy:next];
        return;
    }

    [d removeObjectForKey:PCLSelectedKey];

    for (NSString *key in @[
        @"PCLProfileUsername",@"PCLProfileUUID",
        @"PCLProfileType",@"PCLProfileServer",
        @"PCLCredentialPrefix"])
        [d removeObjectForKey:key];
}

@end
