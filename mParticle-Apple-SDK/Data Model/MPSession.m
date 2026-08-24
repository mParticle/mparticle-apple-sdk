#import "MPSession.h"
#import "MPIConstants.h"
#import "MPPersistenceController.h"
@import mParticle_Apple_SDK_Swift;

@interface MPSession ()
@property (nonatomic, strong) MPSessionPRIVATE *implementation;
@end

@implementation MPSession

- (instancetype)init {
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSNumber *mpId = [MPPersistenceController_PRIVATE mpId];
    return [self initWithSessionId:0
                              UUID:[[NSUUID UUID] UUIDString]
                    backgroundTime:0.0
                         startTime:now
                           endTime:now
                        attributes:nil
             numberOfInterruptions:0
                      eventCounter:0
                       suspendTime:0
                            userId:mpId
                    sessionUserIds:[mpId stringValue]
                           appInfo:nil
                        deviceInfo:nil];
}

- (instancetype)initWithStartTime:(NSTimeInterval)timestamp userId:(NSNumber *)userId {
    return [self initWithStartTime:timestamp userId:userId uuid:nil];
}

- (instancetype)initWithStartTime:(NSTimeInterval)timestamp userId:(NSNumber *)userId uuid:(NSString *)uuid {
    NSString *uuidString = uuid ?: [[NSUUID UUID] UUIDString];
    return [self initWithSessionId:0
                              UUID:uuidString
                    backgroundTime:0.0
                         startTime:timestamp
                           endTime:timestamp
                        attributes:nil
             numberOfInterruptions:0
                      eventCounter:0
                       suspendTime:0
                            userId:userId
                    sessionUserIds:[userId stringValue]
                           appInfo:nil
                        deviceInfo:nil];
}

- (instancetype)initWithSessionId:(int64_t)sessionId
                             UUID:(NSString *)uuid
                   backgroundTime:(NSTimeInterval)backgroundTime
                        startTime:(NSTimeInterval)startTime
                          endTime:(NSTimeInterval)endTime
                       attributes:(NSMutableDictionary *)attributesDictionary
            numberOfInterruptions:(uint)numberOfInterruptions
                     eventCounter:(uint)eventCounter
                      suspendTime:(NSTimeInterval)suspendTime
                           userId:(NSNumber *)userId
                   sessionUserIds:(NSString *)sessionUserIds
                          appInfo:(nullable NSDictionary<NSString *,id> *)appInfo
                       deviceInfo:(nullable NSDictionary *)deviceInfo
{
    self = [super init];
    if (!self) {
        return nil;
    }

    _implementation = [[MPSessionPRIVATE alloc] initWithSessionId:sessionId
                                                             uuid:uuid
                                                   backgroundTime:backgroundTime
                                                        startTime:startTime
                                                          endTime:endTime
                                                       attributes:attributesDictionary
                                            numberOfInterruptions:numberOfInterruptions
                                                     eventCounter:eventCounter
                                                      suspendTime:suspendTime
                                                           userId:userId
                                                   sessionUserIds:sessionUserIds
                                                  applicationInfo:appInfo
                                                       deviceInfo:deviceInfo];
    _uuid = _implementation.uuid;
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Session\n Id: %lld\n UUID: %@\n Background time: %.0f\n Foreground time: %.0f\n Start: %.0f\n End: %.0f\n Length: %.0f\n EventCounter: %d\n Persisted: %d\n Interruptions: %d\n Attributes: %@\n", self.sessionId, self.uuid, self.backgroundTime, self.foregroundTime, self.startTime, self.endTime, self.length, self.eventCounter, self.persisted, self.numberOfInterruptions, self.attributesDictionary];
}

- (BOOL)isEqual:(MPSession *)object {
    if (MPIsNull(object) || ![object isKindOfClass:[MPSession class]]) {
        return NO;
    }
    return [self.implementation isEqualToSession:object.implementation];
}

- (NSUInteger)hash {
    return (NSUInteger)self.implementation.hash;
}

- (id)copyWithZone:(NSZone *)zone {
    MPSession *copyObject = [[[self class] allocWithZone:zone] init];
    copyObject.implementation = [self.implementation copySession];
    copyObject.uuid = copyObject.implementation.uuid;
    return copyObject;
}

- (NSMutableDictionary *)attributesDictionary {
    return self.implementation.attributesDictionary;
}

- (void)setAttributesDictionary:(NSMutableDictionary *)attributesDictionary {
    self.implementation.attributesDictionary = attributesDictionary ?: [NSMutableDictionary dictionary];
}

- (NSTimeInterval)backgroundTime {
    return self.implementation.backgroundTime;
}

- (void)setBackgroundTime:(NSTimeInterval)backgroundTime {
    self.implementation.backgroundTime = backgroundTime;
}

- (NSTimeInterval)foregroundTime {
    return self.implementation.foregroundTime;
}

- (NSTimeInterval)startTime {
    return self.implementation.startTime;
}

- (void)setStartTime:(NSTimeInterval)startTime {
    self.implementation.startTime = startTime;
}

- (NSTimeInterval)endTime {
    return self.implementation.endTime;
}

- (void)setEndTime:(NSTimeInterval)endTime {
    [self.implementation applyEndTime:endTime];
}

- (NSTimeInterval)length {
    BOOL needsKVO = self.implementation.length == 0 && self.implementation.endTime > self.implementation.startTime;
    if (needsKVO) {
        [self willChangeValueForKey:@"length"];
    }
    NSTimeInterval length = [self.implementation resolveLength];
    if (needsKVO) {
        [self didChangeValueForKey:@"length"];
    }
    return length;
}

- (void)setLength:(NSTimeInterval)length {
    self.implementation.length = length;
}

- (NSTimeInterval)suspendTime {
    return self.implementation.suspendTime;
}

- (uint)eventCounter {
    return self.implementation.eventCounter;
}

- (uint)numberOfInterruptions {
    return self.implementation.numberOfInterruptions;
}

- (int64_t)sessionId {
    return self.implementation.sessionId;
}

- (void)setSessionId:(int64_t)sessionId {
    self.implementation.sessionId = sessionId;
}

- (BOOL)persisted {
    return self.implementation.persisted;
}

- (NSNumber *)userId {
    return self.implementation.userId;
}

- (void)setUserId:(NSNumber *)userId {
    self.implementation.userId = userId;
}

- (NSString *)sessionUserIds {
    return self.implementation.sessionUserIds;
}

- (void)setSessionUserIds:(NSString *)sessionUserIds {
    self.implementation.sessionUserIds = sessionUserIds;
}

- (NSDictionary<NSString *, id> *)appInfo {
    return self.implementation.applicationInfo;
}

- (void)setAppInfo:(NSDictionary<NSString *, id> *)appInfo {
    self.implementation.applicationInfo = appInfo;
}

- (NSDictionary *)deviceInfo {
    return self.implementation.deviceInfo;
}

- (void)setDeviceInfo:(NSDictionary *)deviceInfo {
    self.implementation.deviceInfo = deviceInfo;
}

- (NSString *)uuid {
    return self.implementation.uuid;
}

- (void)setUuid:(NSString *)uuid {
    self.implementation.uuid = uuid;
    _uuid = uuid;
}

- (void)incrementCounter {
    [self willChangeValueForKey:@"eventCounter"];
    [self.implementation incrementCounter];
    [self didChangeValueForKey:@"eventCounter"];
}

- (void)suspendSession {
    [self willChangeValueForKey:@"numberOfInterruptions"];
    [self willChangeValueForKey:@"suspendTime"];
    [self.implementation suspendSession];
    [self didChangeValueForKey:@"numberOfInterruptions"];
    [self didChangeValueForKey:@"suspendTime"];
}

@end
