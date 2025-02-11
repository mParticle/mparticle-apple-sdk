#import "MPSession.h"
#import "MPIConstants.h"
#import "MPPersistenceController.h"
#import "MPApplication.h"

NSString *const sessionUUIDKey = @"sessionId";

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
    self = [self initWithStartTime:timestamp userId:userId uuid:nil];
    
    return self;
}

- (instancetype)initWithStartTime:(NSTimeInterval)timestamp userId:(NSNumber *)userId uuid:(NSString *)uuid {
    NSString *uuidString = uuid ?: [[NSUUID UUID] UUIDString];
    self = [self initWithSessionId:0
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
    
    return self;
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
    
    _sessionId = sessionId;
    _uuid = uuid;
    _backgroundTime = backgroundTime;
    _startTime = startTime;
    _endTime = endTime;
    _length = _endTime - _startTime;
    _eventCounter = eventCounter;
    _persisted = sessionId != 0;
    _numberOfInterruptions = numberOfInterruptions;
    _suspendTime = suspendTime;
    _sessionUserIds = sessionUserIds;
    _appInfo = appInfo;
    _deviceInfo = deviceInfo;
    
    _attributesDictionary = attributesDictionary != nil ? attributesDictionary : [[NSMutableDictionary alloc] init];
    
    _userId = userId;

    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Session\n Id: %lld\n UUID: %@\n Background time: %.0f\n Foreground time: %.0f\n Start: %.0f\n End: %.0f\n Length: %.0f\n EventCounter: %d\n Persisted: %d\n Interruptions: %d\n Attributes: %@\n", self.sessionId, self.uuid, self.backgroundTime, self.foregroundTime, self.startTime, self.endTime, self.length, self.eventCounter, self.persisted, self.numberOfInterruptions, self.attributesDictionary];
}

- (BOOL)isEqual:(MPSession *)object {
    if (MPIsNull(object) || ![object isKindOfClass:[MPSession class]]) {
        return NO;
    }
    
    BOOL isEqual = _sessionId == object.sessionId &&
                   _eventCounter == object.eventCounter &&
                   [_uuid isEqualToString:object.uuid];
    
    return isEqual;
}

- (NSUInteger)hash {
    return self.sessionId ^ self.eventCounter ^ [self.uuid hash];
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
    MPSession *copyObject = [[MPSession alloc] initWithSessionId:_sessionId
                                                            UUID:[_uuid copy]
                                                  backgroundTime:_backgroundTime
                                                       startTime:_startTime
                                                         endTime:_endTime
                                                      attributes:[_attributesDictionary mutableCopy]
                                           numberOfInterruptions:_numberOfInterruptions
                                                    eventCounter:_eventCounter
                                                     suspendTime:_suspendTime
                                                          userId:_userId
                                                  sessionUserIds:_sessionUserIds
                                                         appInfo:_appInfo
                                                      deviceInfo:_deviceInfo];
    
    return copyObject;
}

#pragma mark Public accessors
- (NSTimeInterval)foregroundTime {
    NSTimeInterval foreground = _length - _backgroundTime;
    // Don't allow negative foreground time
    return foreground < 0.0 ? 0.0 : foreground;
}

- (void)setEndTime:(NSTimeInterval)endTime {
    if (endTime > _startTime) {
        _endTime = endTime;
        _length = _endTime - _startTime;
    } else if (_length > 0) {
        _endTime = _startTime + _length;
    } else {
        _endTime = _startTime;
    }
}

- (NSTimeInterval)length {//slx
    if (_length == 0 && _endTime > _startTime) {
        [self willChangeValueForKey:@"length"];
        _length = _endTime - _startTime;
        [self didChangeValueForKey:@"length"];
    }
    
    return _length;
}

- (void)setSessionId:(int64_t)sessionId {
    _sessionId = sessionId;
    _persisted = sessionId != 0;
}

#pragma mark Public methods
- (void)incrementCounter {
    [self willChangeValueForKey:@"eventCounter"];
    ++_eventCounter;
    [self didChangeValueForKey:@"eventCounter"];
}

- (void)suspendSession {
    [self willChangeValueForKey:@"numberOfInterruptions"];
    [self willChangeValueForKey:@"suspendTime"];

    ++_numberOfInterruptions;
    _suspendTime = [[NSDate date] timeIntervalSince1970];
    
    [self didChangeValueForKey:@"numberOfInterruptions"];
    [self didChangeValueForKey:@"suspendTime"];
}

@end
