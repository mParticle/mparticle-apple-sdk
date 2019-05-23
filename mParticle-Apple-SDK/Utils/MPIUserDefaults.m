#import "MPIUserDefaults.h"
#import "MPPersistenceController.h"
#import "MPIConstants.h"
#import "MPILogger.h"
#import "MParticle.h"
#import "MPKitConfiguration.h"
#import "MPArchivist.h"

@interface MParticle ()

@property (nonatomic, strong, readonly) MPPersistenceController *persistenceController;

@end

static MPIUserDefaults *standardUserDefaults = nil;
static NSString * sharedGroupID = nil;

NSString *const kitFileExtension = @"eks";

static NSString *const NSUserDefaultsPrefix = @"mParticle::";

@implementation MPIUserDefaults

#pragma mark Private methods
- (NSArray<NSString *> *)userSpecificKeys {
    NSArray<NSString *> *userSpecificKeys = @[
                                              @"lud",               /* kMPAppLastUseDateKey */
                                              @"lc",                /* kMPAppLaunchCountKey */
                                              @"lcu",               /* kMPAppLaunchCountSinceUpgradeKey */
                                              @"ua",                /* kMPUserAttributeKey */
                                              @"ui",                /* kMPUserIdentityArrayKey */
                                              @"ck",                /* kMPRemoteConfigCookiesKey */
                                              @"ltv",               /* kMPLifeTimeValueKey */
                                              @"is_ephemeral",      /* kMPIsEphemeralKey */
                                              @"last_date_used",    /* kMPLastIdentifiedDate  */
                                              @"consent_state",     /* kMPConsentStateKey  */
                                              @"fsu",               /* kMPFirstSeenUser */
                                              @"lsu"                /* kMPLastSeenUser */
                                              ];
    return userSpecificKeys;
}

- (NSArray<NSString *> *)extensionExcludedKeys {
    NSArray<NSString *> *extensionExcludedKeys = @[
                                              ];
    return extensionExcludedKeys;
}

- (NSString *)globalKeyForKey:(NSString *)key {
    NSString *globalKey = [NSString stringWithFormat:@"%@%@", NSUserDefaultsPrefix, key];
    return globalKey;
}

- (NSString *)userKeyForKey:(NSString *)key userId:(NSNumber *)userId {
    NSString *userKey = [NSString stringWithFormat:@"%@%@::%@", NSUserDefaultsPrefix, userId, key];
    return userKey;
}

- (NSArray<NSNumber *> *)userIDsInUserDefaults {
    NSArray *keyArray = [[[self customUserDefaults] dictionaryRepresentation] allKeys];
    
    NSMutableSet<NSNumber *> *uniqueUserIDs = [[NSMutableSet alloc] init];
    for (NSString *key in keyArray) {
        if ([[self customUserDefaults] objectForKey:key] != nil) {
            NSArray *keyComponents = [key componentsSeparatedByString:@"::"];
            if (keyComponents.count == 3) {
                NSNumber *userID = [NSNumber numberWithLongLong:[(NSString *)keyComponents[1] longLongValue]];
                [uniqueUserIDs addObject:userID];
            }
        }
    }

    return [uniqueUserIDs allObjects];
}

- (BOOL)isUserSpecificKey:(NSString *)keyName {
    NSArray<NSString *> *userSpecificKeys = [self userSpecificKeys];
    
    if ([userSpecificKeys containsObject:keyName]) {
        return YES;
    }
    else {
        return NO;
    }
}

- (NSString *)prefixedKey:(NSString *)keyName userId:(NSNumber *)userId {
    NSString *prefixedKey = nil;
    if (![self isUserSpecificKey:keyName]) {
        prefixedKey = [self globalKeyForKey:keyName];
        return prefixedKey;
    }
    else {
        NSString *prefixedKey = [self userKeyForKey:keyName userId:userId];
        return prefixedKey;
    }
}

- (NSUserDefaults *)customUserDefaults {
    if (sharedGroupID) {
        // Create and share access to an NSUserDefaults object
        return [[NSUserDefaults alloc] initWithSuiteName: sharedGroupID];
    } else {
        return [NSUserDefaults standardUserDefaults];
    }
}

#pragma mark Public class methods
+ (nonnull instancetype)standardUserDefaults {
    static dispatch_once_t predicate;
    
    dispatch_once(&predicate, ^{
        standardUserDefaults = [[MPIUserDefaults alloc] init];
    });

    return standardUserDefaults;
}

#pragma mark Public methods

- (id)mpObjectForKey:(NSString *)key userId:(NSNumber *)userId {
    NSString *prefixedKey = [self prefixedKey:key userId:userId];
    
    // If the shared key is set but that attribute hasn't been set in the shared user this defaults to getting the info for standard user info
    id mpObject = [[self customUserDefaults] objectForKey:prefixedKey];
    if (mpObject) {
        return mpObject;
    } else {
        return [[NSUserDefaults standardUserDefaults] objectForKey:prefixedKey];
    }
}

- (void)setMPObject:(id)value forKey:(NSString *)key userId:(nonnull NSNumber *)userId {
    NSString *prefixedKey = [self prefixedKey:key userId:userId];
    
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:prefixedKey];
    if (sharedGroupID && ![self.extensionExcludedKeys containsObject:key]) {
        [[[NSUserDefaults alloc] initWithSuiteName: sharedGroupID] setObject:value forKey:prefixedKey];
    }
}

- (void)removeMPObjectForKey:(NSString *)key userId:(nonnull NSNumber *)userId {
    NSString *prefixedKey = [self prefixedKey:key userId:userId];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:prefixedKey];
    if (sharedGroupID) {
        [[[NSUserDefaults alloc] initWithSuiteName: sharedGroupID] removeObjectForKey:prefixedKey];
    }
}

- (void)removeMPObjectForKey:(NSString *)key {
    [self removeMPObjectForKey:key userId:[MPPersistenceController mpId]];
}

- (void)synchronize {
    [[NSUserDefaults standardUserDefaults] synchronize];
    if (sharedGroupID) {
        [[[NSUserDefaults alloc] initWithSuiteName: sharedGroupID] synchronize];
    }
}

- (void)migrateUserKeysWithUserId:(NSNumber *)userId {
    NSArray<NSString *> *userSpecificKeys = [self userSpecificKeys];
    NSUserDefaults *userDefaults = [self customUserDefaults];
    
    [userSpecificKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *globalKey = [self globalKeyForKey:key];
        NSString *userKey = [self userKeyForKey:key userId:userId];
        id value = [userDefaults objectForKey:globalKey];
        [userDefaults setObject:value forKey:userKey];
        [userDefaults removeObjectForKey:globalKey];
    }];
    [userDefaults synchronize];
}

- (void)migrateFirstLastSeenUsers {
    NSNumber *globalFirstSeenDateMs = [self mpObjectForKey:@"ict" /* kMPAppInitialLaunchTimeKey */ userId:[MPPersistenceController mpId]];
    NSNumber *globalLastSeenDateMs = @([NSDate date].timeIntervalSince1970 * 1000);
    NSArray<MParticleUser *> *users = [MParticle sharedInstance].identity.getAllUsers;
    for (MParticleUser *user in users) {
        [self setMPObject:globalFirstSeenDateMs forKey:kMPFirstSeenUser userId:user.userId];
        [self setMPObject:globalLastSeenDateMs forKey:kMPLastSeenUser userId:user.userId];
    }
}

-(void)setSharedGroupIdentifier:(NSString *)groupIdentifier {
    NSString *storedGroupID = [self mpObjectForKey:kMPUserIdentitySharedGroupIdentifier userId:[MPPersistenceController mpId]];
    sharedGroupID = groupIdentifier;
    
    if ([sharedGroupID isEqualToString: storedGroupID] || (!storedGroupID && !sharedGroupID)) {
        // Do nothing, we only want to update NSUserDefaults on a change
    } else if (sharedGroupID != nil && ![sharedGroupID isEqualToString:@""]) {
        [self migrateToSharedGroupIdentifier:sharedGroupID];
    } else {
        [self migrateFromSharedGroupIdentifier];
    }
}

- (void)migrateToSharedGroupIdentifier:(NSString *)groupIdentifier {
    //Set up our identities to be shared between the main app and its extensions
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    NSUserDefaults *groupUserDefaults = [[NSUserDefaults alloc] initWithSuiteName: groupIdentifier];
    
    NSString *prefixedKey = [self prefixedKey:kMPUserIdentitySharedGroupIdentifier userId:[MPPersistenceController mpId]];
    [standardUserDefaults setObject:groupIdentifier forKey:prefixedKey];
    [groupUserDefaults setObject:groupIdentifier forKey:prefixedKey];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF CONTAINS %@", NSUserDefaultsPrefix];
    NSArray *mParticleKeys = [[[standardUserDefaults dictionaryRepresentation] allKeys] filteredArrayUsingPredicate:predicate];
    
    for (NSString *key in mParticleKeys) {
        if (![self.extensionExcludedKeys containsObject:key]) {
            [groupUserDefaults setObject:[standardUserDefaults objectForKey:key] forKey:key];
        }
    }
}

- (void)migrateFromSharedGroupIdentifier {
    //Revert to the original way of storing our user identity info
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    NSUserDefaults *groupUserDefaults = [[NSUserDefaults alloc] initWithSuiteName: self[kMPUserIdentitySharedGroupIdentifier]];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF CONTAINS %@", NSUserDefaultsPrefix];
    NSArray *mParticleGroupKeys = [[[groupUserDefaults dictionaryRepresentation] allKeys] filteredArrayUsingPredicate:predicate];
    
    for (NSString *key in mParticleGroupKeys) {
        [groupUserDefaults removeObjectForKey:key];
    }
    
    NSString *prefixedKey = [self prefixedKey:kMPUserIdentitySharedGroupIdentifier userId:[MPPersistenceController mpId]];
    [groupUserDefaults removeObjectForKey:prefixedKey];
    [standardUserDefaults removeObjectForKey:prefixedKey];
}

- (NSDictionary *)getConfiguration {
    NSNumber *userID = [[[MParticle sharedInstance] identity] currentUser].userId;
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    
    if (![[NSUserDefaults standardUserDefaults] objectForKey:kMResponseConfigurationMigrationKey]) {
        [self migrateConfiguration];
    }
    
    NSData *configurationData = [userDefaults mpObjectForKey:kMResponseConfigurationKey userId:userID];
    if (MPIsNull(configurationData)) {
        return nil;
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSDictionary *configuration = nil;
    @try {
        configuration = [NSKeyedUnarchiver unarchiveObjectWithData:configurationData];
    } @catch (NSException *e) {
        MPILogError(@"Got an exception trying to unarchive configuration: %@", e);
        return nil;
    }
#pragma clang diagnostic pop
    
    if (![configuration isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    return configuration;
}

- (NSArray *)getKitConfigurations {
    NSArray *configuration = [self getConfiguration][kMPRemoteConfigKitsKey];
    return configuration;
}

- (void)setConfiguration:(NSDictionary *)responseConfiguration andETag:(NSString *)eTag {
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    
    if (!responseConfiguration || !eTag) {
        MPILogDebug(@"Set Configuration Failed /neTag: %@ /nConfiguration: %@", eTag, responseConfiguration);
        
        return;
    }
    
    NSData *configuration = nil;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    @try {
        configuration = [NSKeyedArchiver archivedDataWithRootObject:responseConfiguration];
    } @catch (NSException *e) {
        MPILogError(@"Got an exception trying to archive configuration: %@", e);
        return;
    }
#pragma clang diagnostic pop
    
    NSNumber *userID = [[[MParticle sharedInstance] identity] currentUser].userId;
    
    [userDefaults setMPObject:eTag forKey:kMPHTTPETagHeaderKey userId:userID];
    [userDefaults setMPObject:configuration forKey:kMResponseConfigurationKey userId:userID];
}

- (void)migrateConfiguration {
    NSNumber *userID = [[[MParticle sharedInstance] identity] currentUser].userId;
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    NSString *eTag = [userDefaults mpObjectForKey:kMPHTTPETagHeaderKey userId:userID];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *stateMachineDirectoryPath = STATE_MACHINE_DIRECTORY_PATH;
    NSString *configurationPath = [stateMachineDirectoryPath stringByAppendingPathComponent:@"RequestConfig.cfg"];
    
    NSDictionary *configuration = [userDefaults mpObjectForKey:kMResponseConfigurationKey userId:userID];
    
    if ([fileManager fileExistsAtPath:configurationPath]) {
        if (eTag) {
            NSDictionary *directoryContents = [MPArchivist unarchiveObjectOfClass:[NSDictionary class] withFile:configurationPath error:nil];

            [userDefaults setConfiguration:directoryContents andETag:eTag];
        } else {
            [fileManager removeItemAtPath:configurationPath error:nil];
            [self deleteConfiguration];
        }
    } else if ((eTag && !configuration) || (!eTag && configuration)) {
        [self deleteConfiguration];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:@1 forKey:kMResponseConfigurationMigrationKey];
    MPILogDebug(@"Configuration Migration Complete");
}

- (void)deleteConfiguration {
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    
    [userDefaults removeMPObjectForKey:kMResponseConfigurationKey];
    [userDefaults removeMPObjectForKey:kMPHTTPETagHeaderKey];
    
    MPILogDebug(@"Configuration Deleted");
}

- (void)resetDefaults {
    NSUserDefaults * defs = [NSUserDefaults standardUserDefaults];
    NSDictionary * dict = [defs dictionaryRepresentation];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF CONTAINS %@", NSUserDefaultsPrefix];
    NSArray *mParticleKeys = [dict.allKeys filteredArrayUsingPredicate:predicate];
    
    if (sharedGroupID) {
        [self setSharedGroupIdentifier:nil];
    }
    
    for (id key in mParticleKeys) {
        [defs removeObjectForKey:key];
    }
    
    [defs synchronize];
}

- (BOOL)isExistingUserId:(NSNumber *)userId {
    NSDate *dateLastIdentified = [self mpObjectForKey:kMPLastIdentifiedDate userId:userId];
    if (dateLastIdentified != nil) {
        return true;
    }
    
    return false;
}

#pragma mark Objective-C Literals
- (id)objectForKeyedSubscript:(NSString *const)key {
    if ([key isEqualToString:@"mpid"]) {
        return [self mpObjectForKey:key userId:@0];
    }
    return [self mpObjectForKey:key userId:[MPPersistenceController mpId]];
}

- (void)setObject:(id)obj forKeyedSubscript:(NSString *)key {
    if (obj) {
        if ([key isEqualToString:@"mpid"]) {
            [self setMPObject:obj forKey:key userId:@0];
        } else {
            [self setMPObject:obj forKey:key userId:[MPPersistenceController mpId]];
        }
    } else {
        [self removeMPObjectForKey:key userId:[MPPersistenceController mpId]];
    }
}


@end
