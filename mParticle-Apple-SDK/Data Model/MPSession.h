#import "MPDataModelAbstract.h"

@interface MPSession : MPDataModelAbstract <NSCopying>

@property (nonatomic, strong, nonnull) NSMutableDictionary *attributesDictionary;
@property (nonatomic) NSTimeInterval backgroundTime;
@property (nonatomic, readonly) NSTimeInterval foregroundTime;
@property (nonatomic) NSTimeInterval startTime;
@property (nonatomic) NSTimeInterval endTime;
@property (nonatomic) NSTimeInterval length;
@property (nonatomic, readonly) NSTimeInterval suspendTime;
@property (nonatomic, readonly) uint eventCounter;
@property (nonatomic, readonly) uint numberOfInterruptions;
@property (nonatomic) int64_t sessionId;
@property (nonatomic, readonly) BOOL persisted;
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
