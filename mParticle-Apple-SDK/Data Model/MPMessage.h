#import "MPDataModelAbstract.h"
#import "MPIConstants.h"
#import "MPDataModelProtocol.h"

@class MPSession;

@interface MPMessage : MPDataModelAbstract <NSCopying, NSSecureCoding, MPDataModelProtocol>

@property (nonatomic, strong, readonly, nonnull) NSString *messageType;
@property (nonatomic, strong, readonly, nonnull) NSData *messageData;
@property (nonatomic) NSTimeInterval timestamp;
@property (nonatomic) int64_t messageId;
@property (nonatomic, strong, nullable) NSNumber *sessionId;
@property (nonatomic, strong, nonnull) NSNumber *userId;
@property (nonatomic, strong, nullable) NSString *dataPlanId;
@property (nonatomic, strong, nullable) NSNumber *dataPlanVersion;
@property (nonatomic) MPUploadStatus uploadStatus;
@property (nonatomic) BOOL shouldUploadEvent;

- (nonnull instancetype)initWithSessionId:(nullable NSNumber *)sessionId
                                messageId:(int64_t)messageId
                                     UUID:(nonnull NSString *)uuid
                              messageType:(nonnull NSString *)messageType
                              messageData:(nonnull NSData *)messageData
                                timestamp:(NSTimeInterval)timestamp
                             uploadStatus:(MPUploadStatus)uploadStatus
                                   userId:(nonnull NSNumber *)userId
                               dataPlanId:(nullable NSString *)dataPlanId
                          dataPlanVersion:(nullable NSNumber *)dataPlanVersion;



- (nonnull instancetype)initWithSession:(nullable MPSession *)session
                            messageType:(nonnull NSString *)messageType
                            messageInfo:(nonnull NSDictionary *)messageInfo
                           uploadStatus:(MPUploadStatus)uploadStatus
                                   UUID:(nonnull NSString *)uuid
                              timestamp:(NSTimeInterval)timestamp
                                 userId:(nonnull NSNumber *)userId
                             dataPlanId:(nullable NSString *)dataPlanId
                        dataPlanVersion:(nullable NSNumber *)dataPlanVersion;

- (void)truncateMessageDataProperty:(nonnull NSString *)property
                           toLength:(NSInteger)length;

+ (void)fixInvalidKeysInDictionary:(nonnull NSMutableDictionary*)messageDictionary
                       messageInfo:(nonnull NSDictionary*) messageInfo;

@end
