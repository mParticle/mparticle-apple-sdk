#import "MPPersistenceController.h"

#import "MPIConstants.h"
#import "MPConsentSerialization.h"
#import "MPConsentState.h"
#import "MPConsumerInfo.h"
#import "MPForwardRecord.h"
#import "MPIntegrationAttributes.h"
#import "MPPersistenceUploadSettingsCodec.h"
#import "MPStateMachine.h"
#import "MPUploadSettings.h"
#import "MPUserDefaultsConnector.h"
#import "MParticle.h"

@import mParticle_Apple_SDK_Swift;

@interface MParticle ()
@property (nonatomic, strong, readonly) MPStateMachine_PRIVATE *stateMachine;
@property (nonatomic, strong) MPNetworkOptions *networkOptions;
- (MPLog *)getLogger;
@end

@interface MPPersistenceUploadSettingsProvider : NSObject <MPUploadSettingsProviding>
@end

@implementation MPPersistenceUploadSettingsProvider

- (NSObject *)currentUploadSettings {
    MParticle *mParticle = [MParticle sharedInstance];
    return [MPUploadSettings currentUploadSettingsWithStateMachine:mParticle.stateMachine
                                                    networkOptions:mParticle.networkOptions];
}

@end

@interface MPPersistenceController_PRIVATE ()
@property (nonatomic, strong) MPPersistenceStorePRIVATE *store;
@property (nonatomic, strong) MPPersistenceFileSystemPRIVATE *fileSystem;
@property (nonatomic, strong) MPPersistenceUploadSettingsCodec *uploadSettingsCodec;
@end

@implementation MPPersistenceController_PRIVATE

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    MPLog *logger = [MParticle sharedInstance].getLogger;
    _fileSystem = [[MPPersistenceFileSystemPRIVATE alloc] initWithLogger:logger];
    [_fileSystem migrateLegacyDatabaseDirectoryIfNeeded];
    [_fileSystem removeLegacySessionNumberFileIfNeeded];
    _uploadSettingsCodec = [[MPPersistenceUploadSettingsCodec alloc] init];

    MPDatabaseMigratorPRIVATE *migrator =
        [[MPDatabaseMigratorPRIVATE alloc] initWithDatabaseVersions:[MPPersistenceSchemaPRIVATE databaseVersions]
                                                         fileSystem:_fileSystem
                                                             logger:logger
                                             uploadSettingsProvider:[[MPPersistenceUploadSettingsProvider alloc] init]
                                               uploadSettingsCodec:_uploadSettingsCodec];
    NSNumber *version = [migrator versionNeedingMigration];
    if (version) {
        [migrator migrateFromVersion:version];
    }

    _store = [[MPPersistenceStorePRIVATE alloc] initWithFileSystem:_fileSystem
                                                            logger:logger
                                               uploadSettingsCodec:_uploadSettingsCodec];
    return self;
}

+ (NSNumber *)mpId {
    MPUserDefaults *userDefaults = MPUserDefaultsConnector.userDefaults;
    return userDefaults[@"mpid"] ?: @0;
}

+ (void)setMpid:(NSNumber *)mpId {
    MPUserDefaults *userDefaults = MPUserDefaultsConnector.userDefaults;
    userDefaults[@"mpid"] = mpId;
    [userDefaults synchronize];
}

+ (NSString *)databaseDirectoryPath {
    MPPersistenceFileSystemPRIVATE *fileSystem =
        [[MPPersistenceFileSystemPRIVATE alloc] initWithLogger:[MParticle sharedInstance].getLogger];
    return [fileSystem databaseDirectoryPath];
}

+ (MPConsentState *)consentStateForMpid:(NSNumber *)mpid {
    NSString *string = [MPUserDefaultsConnector.userDefaults mpObjectForKey:kMPConsentStateKey userId:mpid];
    return string ? [MPConsentSerialization consentStateFromString:string] : nil;
}

+ (void)setConsentState:(MPConsentState *)state forMpid:(NSNumber *)mpid {
    MPUserDefaults *userDefaults = MPUserDefaultsConnector.userDefaults;
    if (!state) {
        [userDefaults removeMPObjectForKey:kMPConsentStateKey userId:mpid];
    } else {
        NSString *string = [MPConsentSerialization stringFromConsentState:state];
        if (!string) {
            return;
        }
        [userDefaults setMPObject:string forKey:kMPConsentStateKey userId:mpid];
    }
    [userDefaults synchronize];
}

+ (MPConsentState *)deviceConsentState {
    NSString *string = [MPUserDefaultsConnector.userDefaults mpObjectForKey:kMPConsentDeviceStateKey userId:@0];
    return string ? [MPConsentSerialization consentStateFromString:string] : nil;
}

+ (void)setDeviceConsentState:(MPConsentState *)state {
    MPUserDefaults *userDefaults = MPUserDefaultsConnector.userDefaults;
    if (!state) {
        [userDefaults removeMPObjectForKey:kMPConsentDeviceStateKey userId:@0];
    } else {
        NSString *string = [MPConsentSerialization stringFromConsentState:state];
        if (!string) {
            return;
        }
        [userDefaults setMPObject:string forKey:kMPConsentDeviceStateKey userId:@0];
    }
    [userDefaults synchronize];
}

+ (MPConsentState *)effectiveConsentStateForMpid:(NSNumber *)mpid {
    return [self deviceConsentState] ?: (mpid ? [self consentStateForMpid:mpid] : nil);
}

+ (NSInteger)maxBytesPerEvent:(NSString *)messageType {
    return [MPPersistenceSchemaPRIVATE maxBytesPerEventForMessageType:messageType];
}

+ (NSInteger)maxBytesPerBatch:(NSString *)messageType {
    return [MPPersistenceSchemaPRIVATE maxBytesPerBatchForMessageType:messageType];
}

- (BOOL)isDatabaseOpen {
    return [self.store isDatabaseOpen];
}

- (NSString *)databasePath {
    return self.store.databasePath;
}

- (BOOL)openDatabase {
    return [self.store openDatabase];
}

- (BOOL)closeDatabase {
    return [self.store closeDatabase];
}

- (void)resetDatabase {
    [self.store resetDatabase];
}

- (void)resetDatabaseForWorkspaceSwitching {
    [self.store resetDatabaseForWorkspaceSwitching];
}

- (void)purgeMemory {
    [self.store purgeMemory];
}

- (void)deleteRecordsOlderThan:(NSTimeInterval)timestamp {
    [self.store deleteRecordsOlderThan:timestamp];
}

- (MPSession *)archiveSession:(MPSession *)session {
    return [self.store archiveSession:session];
}

- (void)saveSession:(MPSession *)session {
    [self.store saveSession:session];
}

- (void)updateSession:(MPSession *)session {
    [self.store updateSession:session];
}

- (NSMutableArray<MPSession *> *)fetchSessions {
    return [self.store fetchSessions];
}

- (NSArray<MPSession *> *)fetchPossibleSessionsFromCrash {
    return [self.store fetchPossibleSessionsFromCrash];
}

- (MPSession *)fetchPreviousSession {
    return [self.store fetchPreviousSession];
}

- (void)deletePreviousSession {
    [self.store deletePreviousSession];
}

- (void)deleteSession:(MPSession *)session {
    [self.store deleteSession:session];
}

- (void)deleteAllSessionsExcept:(MPSession *)session {
    [self.store deleteAllSessionsExcept:session];
}

- (NSDictionary<NSString *, NSDictionary *> *)appAndDeviceInfoForSessionId:(NSNumber *)sessionId {
    return [self.store appAndDeviceInfoForSessionId:sessionId];
}

- (void)saveMessage:(MPMessage *)message {
    if (!message) {
        return;
    }
    [self.store saveMessage:message];
}

- (void)deleteMessages:(NSArray<MPMessage *> *)messages {
    [self.store deleteMessages:messages];
}

- (void)deleteNetworkPerformanceMessages {
    [self.store deleteNetworkPerformanceMessages];
}

- (NSMutableDictionary *)fetchMessagesForUploading {
    return [self.store fetchMessagesForUploading];
}

- (MPMessage *)fetchSessionEndMessageInSession:(MPSession *)session {
    return [self.store fetchSessionEndMessageInSession:session];
}

- (NSArray<MPMessage *> *)fetchUploadedMessagesInSession:(MPSession *)session {
    return [self.store fetchUploadedMessagesInSession:session];
}

- (void)saveBreadcrumb:(MPMessage *)message {
    [self.store saveBreadcrumb:message];
}

- (NSArray<MPBreadcrumb *> *)fetchBreadcrumbs {
    return [self.store fetchBreadcrumbs];
}

- (void)saveUpload:(MPUpload *)upload {
    self.store.optedOut = [MParticle sharedInstance].stateMachine.optOut;
    [self.store saveUpload:upload];
}

- (NSArray<MPUpload *> *)fetchUploads {
    return [self.store fetchUploads];
}

- (void)deleteUpload:(MPUpload *)upload {
    [self.store deleteUpload:upload];
}

- (void)deleteUploadId:(int64_t)uploadId {
    [self.store deleteUploadId:uploadId];
}

- (BOOL)saveUploads:(NSArray<MPUpload *> *)uploads deleteMessages:(NSArray<MPMessage *> *)messages {
    self.store.optedOut = [MParticle sharedInstance].stateMachine.optOut;
    return [self.store saveUploads:uploads deleteMessages:messages];
}

- (void)saveForwardRecord:(MPForwardRecord *)forwardRecord {
    MPForwardRecordPRIVATE *record =
        [[MPForwardRecordPRIVATE alloc] initWithId:(int64_t)forwardRecord.forwardRecordId
                                   dataDictionary:forwardRecord.dataDictionary
                                             mpid:forwardRecord.mpid];
    [self.store saveForwardRecord:record];
    forwardRecord.forwardRecordId = record.forwardRecordId;
}

- (NSArray<MPForwardRecord *> *)fetchForwardRecords {
    NSArray<MPForwardRecordPRIVATE *> *records = [self.store fetchForwardRecords];
    if (records.count == 0) {
        return nil;
    }
    NSMutableArray<MPForwardRecord *> *result = [NSMutableArray arrayWithCapacity:records.count];
    for (MPForwardRecordPRIVATE *record in records) {
        MPForwardRecord *wrapper =
            [[MPForwardRecord alloc] initWithId:(int64_t)record.forwardRecordId
                                dataDictionary:record.dataDictionary
                                          mpid:record.mpid];
        [result addObject:wrapper];
    }
    return result;
}

- (void)deleteForwardRecordsIds:(NSArray<NSNumber *> *)forwardRecordsIds {
    [self.store deleteForwardRecordsIds:forwardRecordsIds];
}

- (void)saveIntegrationAttributes:(MPIntegrationAttributes *)integrationAttributes {
    MPIntegrationAttributesPRIVATE *attributes =
        [[MPIntegrationAttributesPRIVATE alloc] initWithIntegrationId:integrationAttributes.integrationId
                                                            attributes:integrationAttributes.attributes];
    if (attributes) {
        [self.store saveIntegrationAttributes:attributes];
    }
}

- (NSArray<MPIntegrationAttributes *> *)fetchIntegrationAttributes {
    NSArray<MPIntegrationAttributesPRIVATE *> *attributes = [self.store fetchIntegrationAttributes];
    if (attributes.count == 0) {
        return nil;
    }
    NSMutableArray<MPIntegrationAttributes *> *result =
        [NSMutableArray arrayWithCapacity:attributes.count];
    for (MPIntegrationAttributesPRIVATE *value in attributes) {
        MPIntegrationAttributes *wrapper =
            [[MPIntegrationAttributes alloc] initWithIntegrationId:value.integrationId
                                                        attributes:value.attributes];
        if (wrapper) {
            [result addObject:wrapper];
        }
    }
    return result;
}

- (NSDictionary *)fetchIntegrationAttributesForId:(NSNumber *)integrationId {
    return [self.store fetchIntegrationAttributesForId:integrationId];
}

- (void)deleteIntegrationAttributesForIntegrationId:(NSNumber *)integrationId {
    [self.store deleteIntegrationAttributesForIntegrationId:integrationId];
}

- (void)deleteAllIntegrationAttributes {
    [self.store deleteAllIntegrationAttributes];
}

- (NSArray<MPCookie *> *)fetchCookiesForUserId:(NSNumber *)userId {
    NSArray<NSDictionary *> *rawCookies = [self.store fetchRawCookiesForUserId:userId];
    if (rawCookies.count == 0) {
        return nil;
    }
    NSMutableArray<MPCookie *> *cookies = [NSMutableArray arrayWithCapacity:rawCookies.count];
    for (NSDictionary *rawCookie in rawCookies) {
        MPCookie *cookie = [[MPCookie alloc] init];
        cookie.cookieId = [rawCookie[@"id"] longLongValue];
        cookie.content = [self nullableString:rawCookie[@"content"]];
        cookie.domain = [self nullableString:rawCookie[@"domain"]];
        cookie.expiration = [self nullableString:rawCookie[@"expiration"]];
        cookie.name = [self nullableString:rawCookie[@"name"]] ?: @"";
        [cookies addObject:cookie];
    }
    return cookies;
}

- (MPConsumerInfo *)fetchConsumerInfoForUserId:(NSNumber *)userId {
    NSDictionary *rawInfo = [self.store fetchRawConsumerInfoForUserId:userId];
    if (!rawInfo) {
        return nil;
    }
    MPConsumerInfo *consumerInfo = [[MPConsumerInfo alloc] init];
    consumerInfo.consumerInfoId = [rawInfo[@"id"] longLongValue];
    consumerInfo.uniqueIdentifier = [self nullableString:rawInfo[@"uniqueIdentifier"]];
    consumerInfo.cookies = [self fetchCookiesForUserId:userId];
    return consumerInfo;
}

- (void)saveConsumerInfo:(MPConsumerInfo *)consumerInfo {
    NSNumber *mpid = [MPPersistenceController_PRIVATE mpId];
    NSMutableArray<NSDictionary *> *rawCookies = [NSMutableArray array];
    for (MPCookie *cookie in consumerInfo.cookies) {
        if (!cookie.expired) {
            [rawCookies addObject:[self rawCookie:cookie consumerInfoId:0 mpid:mpid]];
        }
    }
    consumerInfo.consumerInfoId =
        [self.store saveRawConsumerInfoForMpid:mpid
                             uniqueIdentifier:consumerInfo.uniqueIdentifier
                                      cookies:rawCookies];
    NSArray<NSDictionary *> *savedCookies = [self.store fetchRawCookiesForUserId:mpid];
    for (MPCookie *cookie in consumerInfo.cookies) {
        for (NSDictionary *saved in savedCookies) {
            if ([cookie.name isEqualToString:[self nullableString:saved[@"name"]]]) {
                cookie.cookieId = [saved[@"id"] longLongValue];
                break;
            }
        }
    }
}

- (void)updateConsumerInfo:(MPConsumerInfo *)consumerInfo {
    NSNumber *mpid = [MPPersistenceController_PRIVATE mpId];
    for (MPCookie *cookie in consumerInfo.cookies) {
        NSDictionary *raw = [self rawCookie:cookie
                             consumerInfoId:consumerInfo.consumerInfoId
                                        mpid:mpid];
        if (cookie.expired) {
            if (cookie.cookieId != 0) {
                [self.store deleteCookieId:cookie.cookieId];
            }
        } else if (cookie.cookieId == 0) {
            [self.store saveRawCookie:raw];
        } else {
            [self.store updateRawCookie:raw];
        }
    }
}

- (void)deleteCookie:(MPCookie *)cookie {
    [self.store deleteCookieId:cookie.cookieId];
}

- (void)deleteConsumerInfo {
    [self.store deleteConsumerInfo];
}

- (void)moveContentFromMpidZeroToMpid:(NSNumber *)mpid {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary<NSString *, id> *dictionary = [userDefaults dictionaryRepresentation];
    [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
        if (![key hasPrefix:@"mParticle::0"]) {
            return;
        }
        NSString *newKey = [MPPersistenceSchemaPRIVATE remappedUserDefaultsKey:key mpid:mpid];
        if (newKey && !dictionary[newKey]) {
            [userDefaults setObject:value forKey:newKey];
        }
        [userDefaults removeObjectForKey:key];
    }];
    [self.store moveDatabaseContentFromMpidZeroToMpid:mpid];
}

- (NSDictionary *)rawCookie:(MPCookie *)cookie
             consumerInfoId:(int64_t)consumerInfoId
                        mpid:(NSNumber *)mpid {
    return @{
        @"id": @(cookie.cookieId),
        @"consumerInfoId": @(consumerInfoId),
        @"content": cookie.content ?: [NSNull null],
        @"domain": cookie.domain ?: [NSNull null],
        @"expiration": cookie.expiration ?: [NSNull null],
        @"name": cookie.name ?: @"",
        @"mpid": mpid
    };
}

- (NSString *)nullableString:(id)value {
    return [value isKindOfClass:[NSString class]] ? value : nil;
}

@end
