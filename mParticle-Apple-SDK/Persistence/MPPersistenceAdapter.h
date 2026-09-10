#import <Foundation/Foundation.h>

@class MPCookie;
@class MPConsumerInfo;
@class MPForwardRecord;
@class MPIntegrationAttributes;
@class MPMessage;
@class MParticle;
@class MPSession;
@class MPUpload;

NS_ASSUME_NONNULL_BEGIN

/// Objective-C contract-type boundary around the Swift persistence store.
/// This adapter is temporary for values whose public Objective-C runtime types
/// cannot be constructed by the Swift target.
@interface MPPersistenceAdapter : NSObject

- (instancetype)initWithMParticle:(MParticle *)mParticle;
- (NSDictionary<NSString *, NSDictionary *> *)appAndDeviceInfoForSessionId:(NSNumber *)sessionId;
- (nullable NSArray<MPForwardRecord *> *)fetchForwardRecords;
- (void)saveForwardRecord:(MPForwardRecord *)forwardRecord;
- (void)deleteForwardRecordsIds:(NSArray<NSNumber *> *)recordIds;
- (nullable NSArray<MPIntegrationAttributes *> *)fetchIntegrationAttributes;
- (nullable NSDictionary *)fetchIntegrationAttributesForId:(NSNumber *)integrationId;
- (void)saveIntegrationAttributes:(MPIntegrationAttributes *)integrationAttributes;
- (void)deleteIntegrationAttributesForIntegrationId:(NSNumber *)integrationId;
- (void)deleteAllIntegrationAttributes;
- (nullable MPConsumerInfo *)fetchConsumerInfoForUserId:(NSNumber *)userId;
- (nullable NSArray<MPCookie *> *)fetchCookiesForUserId:(NSNumber *)userId;
- (void)saveConsumerInfo:(MPConsumerInfo *)consumerInfo;
- (void)updateConsumerInfo:(MPConsumerInfo *)consumerInfo;
- (void)moveContentFromMpidZeroToMpid:(NSNumber *)mpid;
- (void)updateSession:(MPSession *)session;
- (void)saveUpload:(MPUpload *)upload;
- (void)deleteUpload:(MPUpload *)upload;
- (void)resetDatabase;
- (void)resetDatabaseForWorkspaceSwitching;

@end

NS_ASSUME_NONNULL_END
