#import "MPDataModelAbstract.h"

@interface MPSession : MPDataModelAbstract <NSCopying>

@property (nonatomic, strong, nonnull) NSMutableDictionary *attributesDictionary;
@property (nonatomic, unsafe_unretained) NSTimeInterval backgroundTime;
@property (nonatomic, unsafe_unretained, readonly) NSTimeInterval foregroundTime;
@property (nonatomic, unsafe_unretained) NSTimeInterval startTime;
@property (nonatomic, unsafe_unretained) NSTimeInterval endTime;
@property (nonatomic, unsafe_unretained) NSTimeInterval length;
@property (nonatomic, unsafe_unretained, readonly) NSTimeInterval suspendTime;
@property (nonatomic, unsafe_unretained, readonly) uint eventCounter;
@property (nonatomic, unsafe_unretained, readonly) uint numberOfInterruptions;
@property (nonatomic, unsafe_unretained) int64_t sessionId;
@property (nonatomic, unsafe_unretained, readonly) BOOL persisted;
@property (nonatomic, strong, readwrite, nonnull) NSNumber *userId;
@property (nonatomic, strong, readwrite, nonnull) NSString *sessionUserIds;
@property (nonatomic, strong, readwrite, nullable) NSDictionary<NSString *, id> *appInfo;
@property (nonatomic, strong, readwrite, nullable) NSDictionary *deviceInfo;


- (nonnull instancetype)initWithStartTime:(NSTimeInterval)timestamp userId:(nonnull NSNumber *)userId;
- (nonnull instancetype)initWithStartTime:(NSTimeInterval)timestamp userId:(nonnull NSNumber *)userId uuid:(nullable NSString *)uuid;

- (nonnull instancetype)initWithSessionId:(int64_t)sessionId
                                     UUID:(nonnull NSString *)uuid
                           backgroundTime:(NSTimeInterval)backgroundTime
                                startTime:(NSTimeInterval)startTime
                                  endTime:(NSTimeInterval)endTime
                               attributes:(nullable NSMutableDictionary *)attributesDictionary
                    numberOfInterruptions:(uint)numberOfInterruptions
                             eventCounter:(uint)eventCounter
                              suspendTime:(NSTimeInterval)suspendTime
                                   userId:(nonnull NSNumber *)userId
                           sessionUserIds:(nonnull NSString *)sessionUserIds
                                  appInfo:(nullable NSDictionary<NSString *, id> *)appInfo
                               deviceInfo:(nullable NSDictionary *)deviceInfo
                            __attribute__((objc_designated_initializer));

- (void)incrementCounter;
- (void)suspendSession;

@end
