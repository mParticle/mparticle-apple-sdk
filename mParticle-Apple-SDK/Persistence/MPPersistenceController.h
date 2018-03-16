#import <Foundation/Foundation.h>
#import "MParticleUserNotification.h"
#import "sqlite3.h"

@class MPSegment;
@class MPMessage;
@class MPSession;
@class MPUpload;
@class MPCookie;
@class MPConsumerInfo;
@class MPForwardRecord;
@class MPBreadcrumb;
@class MPIntegrationAttributes;

#if TARGET_OS_IOS == 1
    @class MParticleUserNotification;
#endif

typedef NS_ENUM(NSUInteger, MPPersistenceOperation) {
    MPPersistenceOperationDelete = 0,
    MPPersistenceOperationFlag
};

@interface MPPersistenceController : NSObject {
@protected
    sqlite3 *mParticleDB;
    dispatch_queue_t dbQueue;
    dispatch_queue_t migrationQueue;
}

@property (nonatomic, readonly, getter = isDatabaseOpen) BOOL databaseOpen;

+ (nonnull instancetype)sharedInstance;
+ (void)addReadyHandler:(void (^ _Nonnull)(void))handler;
+ (nullable NSNumber *)mpId;
+ (void)setMpid:(nonnull NSNumber *)mpId;
- (void)archiveSession:(nonnull MPSession *)session completionHandler:(void (^ _Nullable)(MPSession * _Nullable archivedSession))completionHandler;
- (nullable MPSession *)archiveSessionSync:(nonnull MPSession *)session;
- (BOOL)closeDatabase;
- (void)deleteConsumerInfo;
- (void)deleteCookie:(nonnull MPCookie *)cookie;
- (void)deleteForwardRecordsIds:(nonnull NSArray<NSNumber *> *)forwardRecordsIds;
- (void)deleteAllIntegrationAttributes;
- (void)deleteIntegrationAttributes:(nonnull MPIntegrationAttributes *)integrationAttributes;
- (void)deleteIntegrationAttributesForKitCode:(nonnull NSNumber *)kitCode;
- (void)deleteMessages:(nonnull NSArray<MPMessage *> *)messages;
- (void)deleteNetworkPerformanceMessages;
- (void)deletePreviousSession;
- (void)deleteRecordsOlderThan:(NSTimeInterval)timestamp;
- (void)deleteRecordsOlderThan:(NSTimeInterval)timestamp withDatabase:(sqlite3 * _Nonnull)database;
- (void)deleteSegments;
- (void)deleteAllSessionsExcept:(nullable MPSession *)session;
- (void)deleteSession:(nonnull MPSession *)session;
- (void)deleteSessionSync:(nonnull MPSession *)session;
- (void)deleteUpload:(nonnull MPUpload *)upload;
- (void)deleteUploadId:(int64_t)uploadId;
- (nullable NSArray<MPBreadcrumb *> *)fetchBreadcrumbs;
- (nullable MPConsumerInfo *)fetchConsumerInfoForUserId:(NSNumber * _Nonnull)userId;
- (void)fetchConsumerInfoForUserId:(NSNumber * _Nonnull)userId completionHandler:(void (^ _Nonnull)(MPConsumerInfo * _Nullable consumerInfo))completionHandler;
- (nullable NSArray<MPCookie *> *)fetchCookiesForUserId:(NSNumber * _Nonnull)userId;
- (nullable NSArray<MPForwardRecord *> *)fetchForwardRecords;
- (nullable NSArray<MPIntegrationAttributes *> *)fetchIntegrationAttributes;
- (nullable NSMutableDictionary *)fetchMessagesForUploading;
- (void)fetchMessagesForUploadingWithCompletionHandler:(void (^ _Nonnull)(NSDictionary * _Nullable messages))completionHandler;

- (nullable NSArray<MPSession *> *)fetchPossibleSessionsFromCrash;
- (void)fetchPreviousSession:(void (^ _Nonnull)(MPSession * _Nullable previousSession))completionHandler;
- (nullable MPSession *)fetchPreviousSessionSync;
- (nullable NSArray<MPSegment *> *)fetchSegments;
- (nullable MPMessage *)fetchSessionEndMessageInSession:(nonnull MPSession *)session;
- (void)fetchSessions:(void (^ _Nonnull)(NSMutableArray<MPSession *> * _Nullable sessions))completionHandler;
- (nullable NSArray<MPMessage *> *)fetchMessagesInSession:(nonnull MPSession *)session userId:(nonnull NSNumber *)userId;
- (void)fetchUploadedMessagesInSession:(nonnull MPSession *)session excludeNetworkPerformanceMessages:(BOOL)excludeNetworkPerformance completionHandler:(void (^ _Nonnull)(NSArray<MPMessage *> * _Nullable messages))completionHandler;
- (nullable NSArray<MPMessage *> *)fetchUploadedMessagesInSessionSync:(nonnull MPSession *)session;
- (void)fetchUploadsWithCompletionHandler:(void (^ _Nonnull)(NSArray<MPUpload *> * _Nullable uploads))completionHandler;
- (void)moveContentFromMpidZeroToMpid:(nonnull NSNumber *)mpid;
- (void)purgeMemory;
- (BOOL)openDatabase;
- (void)saveBreadcrumb:(nonnull MPMessage *)message session:(nonnull MPSession *)session;
- (void)saveConsumerInfo:(nonnull MPConsumerInfo *)consumerInfo;
- (void)saveForwardRecord:(nonnull MPForwardRecord *)forwardRecord;
- (void)saveIntegrationAttributes:(nonnull MPIntegrationAttributes *)integrationAttributes;
- (void)saveMessage:(nonnull MPMessage *)message;
- (void)saveSegment:(nonnull MPSegment *)segment;
- (void)saveSession:(nonnull MPSession *)session;
- (void)saveUpload:(nonnull MPUpload *)upload messageIds:(nonnull NSArray<NSNumber *> *)messageIds operation:(MPPersistenceOperation)operation;
- (void)updateConsumerInfo:(nonnull MPConsumerInfo *)consumerInfo;
- (void)updateSession:(nonnull MPSession *)session;

@end

