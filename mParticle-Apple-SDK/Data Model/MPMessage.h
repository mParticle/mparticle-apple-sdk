#import "MPDataModelAbstract.h"
#import "MPIConstants.h"
#import "MPDataModelProtocol.h"

@class MPSession;

@interface MPMessage : MPDataModelAbstract <NSCopying, NSCoding, MPDataModelProtocol>

@property (nonatomic, strong, readonly, nonnull) NSString *messageType;
@property (nonatomic, strong, readonly, nonnull) NSData *messageData;
@property (nonatomic, unsafe_unretained) NSTimeInterval timestamp;
@property (nonatomic, unsafe_unretained) int64_t messageId;
@property (nonatomic, unsafe_unretained) int64_t sessionId;
@property (nonatomic, unsafe_unretained, nonnull) NSNumber *userId;
@property (nonatomic, unsafe_unretained) MPUploadStatus uploadStatus;

- (nonnull instancetype)initWithSessionId:(int64_t)sessionId
                                messageId:(int64_t)messageId
                                     UUID:(nonnull NSString *)uuid
                              messageType:(nonnull NSString *)messageType
                              messageData:(nonnull NSData *)messageData
                                timestamp:(NSTimeInterval)timestamp
                             uploadStatus:(MPUploadStatus)uploadStatus
                                   userId:(nonnull NSNumber *)userId;



- (nonnull instancetype)initWithSession:(nullable MPSession *)session messageType:(nonnull NSString *)messageType messageInfo:(nonnull NSDictionary *)messageInfo uploadStatus:(MPUploadStatus)uploadStatus UUID:(nonnull NSString *)uuid timestamp:(NSTimeInterval)timestamp userId:(nonnull NSNumber *)userId;

@end
