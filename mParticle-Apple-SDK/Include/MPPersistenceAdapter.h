#import <Foundation/Foundation.h>

@class MPCookie;
@class MPConsumerInfo;
@class MPForwardRecord;
@class MPIntegrationAttributes;
@class MPPersistenceStorePRIVATE;
@class MPSession;
@class MPUpload;

NS_ASSUME_NONNULL_BEGIN

@protocol MPPersistenceAdapting <NSObject>
@optional
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

/// Marshals Objective-C contract types at the boundary of the Swift store.
@interface MPPersistenceAdapter : NSObject <MPPersistenceAdapting>
- (instancetype)initWithStore:(MPPersistenceStorePRIVATE *)store NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
