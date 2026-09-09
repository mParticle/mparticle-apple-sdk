#import "MPPersistenceAdapter.h"

#import "MPConsumerInfo.h"
#import "MPForwardRecord.h"
#import "MPPersistenceUtilities.h"
#import "MPStateMachine.h"
#import "MParticle.h"

@import mParticle_Apple_SDK_Swift;

@interface MParticle ()
@property (nonatomic, strong, readonly) MPStateMachine_PRIVATE *stateMachine;
@end

@interface MPPersistenceAdapter ()
@property (nonatomic, strong) MPPersistenceStorePRIVATE *store;
@end

@implementation MPPersistenceAdapter

- (instancetype)initWithStore:(MPPersistenceStorePRIVATE *)store {
    self = [super init];
    if (self) {
        _store = store;
    }
    return self;
}

- (NSDictionary<NSString *,NSDictionary *> *)appAndDeviceInfoForSessionId:(NSNumber *)sessionId {
    return [self.store appAndDeviceInfoForSessionId:sessionId];
}

- (NSArray<MPForwardRecord *> *)fetchForwardRecords {
    NSArray<MPForwardRecordPRIVATE *> *records = [self.store fetchForwardRecords];
    if (records.count == 0) {
        return nil;
    }
    NSMutableArray<MPForwardRecord *> *result = [NSMutableArray arrayWithCapacity:records.count];
    for (MPForwardRecordPRIVATE *record in records) {
        [result addObject:[[MPForwardRecord alloc] initWithId:(int64_t)record.forwardRecordId
                                              dataDictionary:record.dataDictionary
                                                        mpid:record.mpid]];
    }
    return result;
}

- (void)saveForwardRecord:(MPForwardRecord *)forwardRecord {
    MPForwardRecordPRIVATE *record =
        [[MPForwardRecordPRIVATE alloc] initWithId:(int64_t)forwardRecord.forwardRecordId
                                   dataDictionary:forwardRecord.dataDictionary
                                             mpid:forwardRecord.mpid];
    [self.store saveForwardRecord:record];
    forwardRecord.forwardRecordId = record.forwardRecordId;
}

- (void)deleteForwardRecordsIds:(NSArray<NSNumber *> *)recordIds {
    [self.store deleteForwardRecordsIds:recordIds];
}

- (NSArray<MPIntegrationAttributes *> *)fetchIntegrationAttributes {
    return [self.store fetchIntegrationAttributes];
}

- (NSDictionary *)fetchIntegrationAttributesForId:(NSNumber *)integrationId {
    return [self.store fetchIntegrationAttributesForId:integrationId];
}

- (void)saveIntegrationAttributes:(MPIntegrationAttributes *)integrationAttributes {
    [self.store saveIntegrationAttributes:integrationAttributes];
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
    NSArray<MPCookie *> *cookies = [self fetchCookiesForUserId:userId];
    if (cookies.count == 0) {
        return nil;
    }
    MPConsumerInfo *consumerInfo = [[MPConsumerInfo alloc] init];
    consumerInfo.cookies = cookies;
    return consumerInfo;
}

- (void)saveConsumerInfo:(MPConsumerInfo *)consumerInfo {
    NSNumber *mpid = MPPersistenceUtilities.mpId;
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
    NSNumber *mpid = MPPersistenceUtilities.mpId;
    for (MPCookie *cookie in consumerInfo.cookies) {
        NSDictionary *raw = [self rawCookie:cookie
                             consumerInfoId:consumerInfo.consumerInfoId
                                        mpid:mpid];
        if (cookie.expired) {
            if (cookie.cookieId != 0) {
                [self.store deleteCookieId:cookie.cookieId];
            }
        } else if (cookie.cookieId == 0) {
            cookie.cookieId = [self.store saveRawCookie:raw];
        } else {
            [self.store updateRawCookie:raw];
        }
    }
}

- (void)moveContentFromMpidZeroToMpid:(NSNumber *)mpid {
    NSUserDefaults *userDefaults = NSUserDefaults.standardUserDefaults;
    NSDictionary<NSString *, id> *dictionary = userDefaults.dictionaryRepresentation;
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

- (void)updateSession:(MPSession *)session {
    [self.store updateSession:session];
}

- (void)saveUpload:(MPUpload *)upload {
    [self.store saveUpload:upload optedOut:MParticle.sharedInstance.stateMachine.optOut];
}

- (void)deleteUpload:(MPUpload *)upload {
    [self.store deleteUpload:upload];
}

- (void)resetDatabase {
    [self.store resetDatabase];
}

- (void)resetDatabaseForWorkspaceSwitching {
    [self.store resetDatabaseForWorkspaceSwitching];
}

- (NSDictionary *)rawCookie:(MPCookie *)cookie
             consumerInfoId:(int64_t)consumerInfoId
                        mpid:(NSNumber *)mpid {
    return @{
        @"id": @(cookie.cookieId),
        @"consumerInfoId": @(consumerInfoId),
        @"content": cookie.content ?: NSNull.null,
        @"domain": cookie.domain ?: NSNull.null,
        @"expiration": cookie.expiration ?: NSNull.null,
        @"name": cookie.name ?: @"",
        @"mpid": mpid
    };
}

- (NSString *)nullableString:(id)value {
    return [value isKindOfClass:NSString.class] ? value : nil;
}

@end
