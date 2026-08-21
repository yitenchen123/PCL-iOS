#import "PCLLaunchArguments.h"
#import "PCLClasspathBuilder.h"
#import "PCLJavaManager.h"

@implementation PCLLaunchArguments

+ (NSDictionary *)buildArgumentsForVersion:(PCLVersionInfo *)version
                                   profile:(NSDictionary *)profile
                                    config:(NSDictionary *)config {
    
    NSString *gameDir = [self gameDirectoryForProfile:profile version:version];
    NSString *assetsDir = [[PCLVersionManager sharedManager] assetsDirectory];
    NSString *assetIndex = version.assets ?: version.assetIndex;
    NSString *playerName = profile[@"username"] ?: profile[@"name"] ?: @"Player";
    NSString *versionName = version.versionId;
    
    // Determine if modern args (1.13+) or legacy
    BOOL isModernArgs = [self isModernVersion:version];
    
    // Build classpath
    NSString *classpath = [PCLClasspathBuilder buildClasspathForVersion:version];
    
    // Build JVM arguments
    NSMutableArray *jvmArgs = [NSMutableArray array];
    
    // Memory settings
    NSInteger minMemory = [config[@"minMemory"] integerValue] ?: 512;
    NSInteger maxMemory = [config[@"maxMemory"] integerValue] ?: 2048;
    [jvmArgs addObject:[NSString stringWithFormat:@"-Xms%ldM", (long)minMemory]];
    [jvmArgs addObject:[NSString stringWithFormat:@"-Xmx%ldM", (long)maxMemory]];
    
    // Required JVM options
    [jvmArgs addObject:@"-XX:+UseG1GC"];
    [jvmArgs addObject:@"-XX:-OmitStackTraceInFastThrow"];
    [jvmArgs addObject:@"-XX:+UnlockExperimentalVMOptions"];
    [jvmArgs addObject:@"-XX:G1NewSizePercent=20"];
    [jvmArgs addObject:@"-XX:G1MaxNewSizePercent=40"];
    [jvmArgs addObject:@"-XX:G1HeapRegionSize=8M"];
    [jvmArgs addObject:@"-XX:G1ReservePercent=20"];
    [jvmArgs addObject:@"-Djava.awt.headless=false"];
    
    // Renderer-specific JVM args
    PCLRenderRenderer renderer = [PCLRendererManager selectedRenderer];
    if (renderer == PCLRenderRendererGL4ES) {
        [jvmArgs addObject:@"-Dorg.lwjgl.opengl.libname=libgl4es.dylib"];
    } else if (renderer == PCLRenderRendererMetalANGLE) {
        [jvmArgs addObject:@"-Dorg.lwjgl.opengl.libname=libEGL.dylib"];
    }
    
    // Custom JVM args from config
    NSString *customJvmArgs = config[@"jvmArguments"];
    if (customJvmArgs.length > 0) {
        NSArray *customs = [customJvmArgs componentsSeparatedByString:@" "];
        for (NSString *arg in customs) {
            NSString *trimmed = [arg stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if (trimmed.length > 0) {
                [jvmArgs addObject:trimmed];
            }
        }
    }
    
    // Game arguments
    NSMutableArray *gameArgs = [NSMutableArray array];
    NSDictionary *varValues = @{
        @"auth_player_name": playerName,
        @"version_name": versionName,
        @"game_directory": gameDir,
        @"assets_root": assetsDir,
        @"assets_index_name": assetIndex,
        @"auth_uuid": profile[@"uuid"] ?: @"0",
        @"auth_access_token": profile[@"accessToken"] ?: @"0",
        @"user_type": profile[@"type"] ?: @"msa",
        @"version_type": version.versionType ?: @"release",
        @"user_properties": @"{}",
        @"auth_session": profile[@"accessToken"] ?: @"0",
        @"game_assets": assetsDir
    };
    
    if (isModernArgs) {
        // Modern arguments (1.13+) - --key value format
        NSArray *modernArgs = @[
            @"--width", @"1280",
            @"--height", @"720",
            @"--fullscreen", @"false",
            @"--autoConnect", @"false",
            @"--disableMultiplayer", @"false",
            @"--disableChat", @"false"
        ];
        [gameArgs addObjectsFromArray:modernArgs];
        
        // Apply minecraftArguments if present in JSON
        if (version.minecraftArguments.length > 0) {
            NSArray *mcArgs = [version.minecraftArguments componentsSeparatedByString:@" "];
            for (NSString *arg in mcArgs) {
                NSString *trimmed = [arg stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                NSString *replaced = [self replaceVariables:trimmed withValues:varValues error:nil];
                if (replaced.length > 0) {
                    [gameArgs addObject:replaced];
                }
            }
        }
    } else {
        // Legacy arguments - space-separated
        NSArray *legacyArgs = @[
            @"--width", @"1280",
            @"--height", @"720"
        ];
        [gameArgs addObjectsFromArray:legacyArgs];
        
        if (version.minecraftArguments.length > 0) {
            NSArray *mcArgs = [version.minecraftArguments componentsSeparatedByString:@" "];
            for (NSString *arg in mcArgs) {
                NSString *replaced = [self replaceVariables:arg withValues:varValues error:nil];
                if (replaced.length > 0) {
                    [gameArgs addObject:replaced];
                }
            }
        }
    }
    
    return @{
        @"mainClass": version.mainClass ?: @"net.minecraft.client.main.Main",
        @"jvmArguments": [jvmArgs copy],
        @"gameArguments": [gameArgs copy],
        @"classpath": classpath,
        @"gameDirectory": gameDir,
        @"javaPath": [[PCLJavaManager sharedManager] findJavaPathForMCVersion:version.versionId]
    };
}

+ (NSString *)replaceVariables:(NSString *)string
                    withValues:(NSDictionary *)values
                         error:(NSError **)error {
    if (!string.length) return string;
    
    NSMutableString *result = [string mutableCopy];
    [values enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        NSString *placeholder = [NSString stringWithFormat:@"${%@}", key];
        [result replaceOccurrencesOfString:placeholder
                               withString:value ?: @""
                                  options:0
                                    range:NSMakeRange(0, result.length)];
    }];
    
    return [result copy];
}

+ (BOOL)areModsLoadedForVersion:(NSString *)version {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:[NSString stringWithFormat:@"modsLoaded_%@", version]];
}

#pragma mark - Private Helpers

+ (BOOL)isModernVersion:(PCLVersionInfo *)version {
    // 1.13+ uses the modern argument format
    if ([version.versionId hasPrefix:@"1."]) {
        NSArray *parts = [version.versionId componentsSeparatedByString:@"."];
        if (parts.count >= 2) {
            NSInteger minor = [parts[1] integerValue];
            if (minor >= 13) return YES;
        }
    } else if ([version.versionId hasPrefix:@"2"] || [version.versionId hasPrefix:@"3"]) {
        return YES;
    }
    return NO;
}

+ (NSString *)gameDirectoryForProfile:(NSDictionary *)profile version:(PCLVersionInfo *)version {
    if (profile[@"gameDir"]) {
        return profile[@"gameDir"];
    }
    return [[PCLVersionManager sharedManager] instanceDirectoryWithName:version.versionId];
}

@end
