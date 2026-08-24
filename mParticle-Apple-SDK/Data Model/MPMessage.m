#import "MPMessage.h"
#import "MPSession.h"
#import "MPILogger.h"
#import "mParticle.h"
@import mParticle_Apple_SDK_Swift;

@interface MPMessage()
@property (nonatomic, strong) MPMessagePRIVATE *implementation;
@property (nonatomic, strong) NSData *messageData;
@end

@implementation MPMessage

- (instancetype)initWithSessionId:(NSNumber *)sessionId messageId:(int64_t)messageId UUID:(NSString *)uuid messageType:(NSString *)messageType messageData:(NSData *)messageData timestamp:(NSTimeInterval)timestamp uploadStatus:(MPUploadStatus)uploadStatus userId:(NSNumber *)userId dataPlanId:(NSString *)dataPlanId dataPlanVersion:(NSNumber *)dataPlanVersion {
    self = [super init];
    if (self) {
        _implementation = [[MPMessagePRIVATE alloc] initWithSessionId:sessionId
                                                            messageId:messageId
                                                                 UUID:uuid
                                                          messageType:messageType
                                                          messageData:messageData ?: [NSData data]
                                                            timestamp:timestamp
                                                         uploadStatus:(NSInteger)uploadStatus
                                                               userId:userId
                                                           dataPlanId:dataPlanId
                                                      dataPlanVersion:dataPlanVersion];
        _uuid = uuid;
    }
    return self;
}

+ (void)fixInvalidKeysInDictionary:(NSMutableDictionary *)messageDictionary messageInfo:(NSDictionary *)messageInfo {
    [MPMessagePRIVATE fixInvalidKeysInDictionary:messageDictionary messageInfo:messageInfo];
}

- (instancetype)initWithSession:(MPSession *)session messageType:(NSString *)messageType messageInfo:(NSDictionary *)messageInfo uploadStatus:(MPUploadStatus)uploadStatus UUID:(NSString *)uuid timestamp:(NSTimeInterval)timestamp userId:(NSNumber *)userId  dataPlanId:(NSString *)dataPlanId dataPlanVersion:(NSNumber *)dataPlanVersion {
    NSNumber *sessionId = nil;
    if (session) {
        sessionId = @(session.sessionId);
    }

    NSData *messageData = [MPMessagePRIVATE sanitizedJSONDataFromMessageInfo:messageInfo];
    return [self initWithSessionId:sessionId
                         messageId:0
                              UUID:uuid
                       messageType:messageType
                       messageData:messageData
                         timestamp:timestamp
                      uploadStatus:uploadStatus
                            userId:userId
                        dataPlanId:dataPlanId
                   dataPlanVersion:dataPlanVersion];
}

- (void)truncateMessageDataProperty:(NSString *)property toLength:(NSInteger)length {
    [self.implementation truncateMessageDataProperty:property toLength:length];
}

- (NSNumber *)sessionId { return self.implementation.sessionId; }
- (void)setSessionId:(NSNumber *)sessionId { self.implementation.sessionId = sessionId; }
- (int64_t)messageId { return self.implementation.messageId; }
- (void)setMessageId:(int64_t)messageId { self.implementation.messageId = messageId; }
- (NSString *)uuid { return self.implementation.uuid; }
- (void)setUuid:(NSString *)uuid { self.implementation.uuid = uuid; _uuid = uuid; }
- (NSString *)messageType { return self.implementation.messageType; }
- (NSData *)messageData { return self.implementation.messageData; }
- (void)setMessageData:(NSData *)messageData { self.implementation.messageData = messageData ?: [NSData data]; }
- (NSTimeInterval)timestamp { return self.implementation.timestamp; }
- (void)setTimestamp:(NSTimeInterval)timestamp { self.implementation.timestamp = timestamp; }
- (MPUploadStatus)uploadStatus { return (MPUploadStatus)self.implementation.uploadStatus; }
- (void)setUploadStatus:(MPUploadStatus)uploadStatus { self.implementation.uploadStatus = (NSInteger)uploadStatus; }
- (NSNumber *)userId { return self.implementation.userId; }
- (void)setUserId:(NSNumber *)userId { self.implementation.userId = userId; }
- (NSString *)dataPlanId { return self.implementation.dataPlanId; }
- (void)setDataPlanId:(NSString *)dataPlanId { self.implementation.dataPlanId = dataPlanId; }
- (NSNumber *)dataPlanVersion { return self.implementation.dataPlanVersion; }
- (void)setDataPlanVersion:(NSNumber *)dataPlanVersion { self.implementation.dataPlanVersion = dataPlanVersion; }
- (BOOL)shouldUploadEvent { return self.implementation.shouldUploadEvent; }
- (void)setShouldUploadEvent:(BOOL)shouldUploadEvent { self.implementation.shouldUploadEvent = shouldUploadEvent; }

- (NSString *)description {
    return [NSString stringWithFormat:@"Message\n Id: %lld\n UUID: %@\n Session: %@\n Type: %@\n timestamp: %.0f\n Data Plan: %@ %@\n Content: %@\n", self.messageId, self.uuid, self.sessionId, self.messageType, self.timestamp, self.dataPlanId, self.dataPlanVersion, [self serializedString]];
}

- (BOOL)isEqual:(MPMessage *)object {
    if (MPIsNull(object) || ![object isKindOfClass:[MPMessage class]]) {
        return NO;
    }
    return [self.implementation isEqualToMessage:object.implementation];
}

- (NSUInteger)hash {
    return (NSUInteger)self.implementation.hash;
}

- (id)copyWithZone:(NSZone *)zone {
    MPMessagePRIVATE *copyImpl = [self.implementation copyMessage];
    MPMessage *copyObject = [[MPMessage alloc] initWithSessionId:copyImpl.sessionId
                                                       messageId:copyImpl.messageId
                                                            UUID:copyImpl.uuid
                                                     messageType:copyImpl.messageType
                                                     messageData:copyImpl.messageData
                                                       timestamp:copyImpl.timestamp
                                                    uploadStatus:(MPUploadStatus)copyImpl.uploadStatus
                                                          userId:copyImpl.userId
                                                      dataPlanId:copyImpl.dataPlanId
                                                 dataPlanVersion:copyImpl.dataPlanVersion];
    copyObject.shouldUploadEvent = copyImpl.shouldUploadEvent;
    return copyObject;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.sessionId forKey:@"sessionId"];
    [coder encodeInt64:self.messageId forKey:@"messageId"];
    [coder encodeObject:self.uuid forKey:@"uuid"];
    [coder encodeObject:self.messageType forKey:@"messageType"];
    [coder encodeObject:self.messageData forKey:@"messageData"];
    [coder encodeDouble:self.timestamp forKey:@"timestamp"];
    [coder encodeInteger:self.uploadStatus forKey:@"uploadStatus"];
    [coder encodeInt64:self.userId.longLongValue forKey:@"mpid"];
    [coder encodeObject:self.dataPlanId forKey:@"dataPlanId"];
    [coder encodeObject:self.dataPlanVersion forKey:@"dataPlanVersion"];
    [coder encodeBool:self.shouldUploadEvent forKey:@"shouldUploadEvent"];
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [self initWithSessionId:[coder decodeObjectOfClass:[NSNumber class] forKey:@"sessionId"]
                         messageId:[coder decodeInt64ForKey:@"messageId"]
                              UUID:[coder decodeObjectOfClass:[NSString class] forKey:@"uuid"]
                       messageType:[coder decodeObjectOfClass:[NSString class] forKey:@"messageType"]
                       messageData:[coder decodeObjectOfClass:[NSData class] forKey:@"messageData"]
                         timestamp:[coder decodeDoubleForKey:@"timestamp"]
                      uploadStatus:[coder decodeIntegerForKey:@"uploadStatus"]
                            userId:@([coder decodeInt64ForKey:@"mpid"])
                        dataPlanId:[coder decodeObjectOfClass:[NSString class] forKey:@"dataPlanId"]
                   dataPlanVersion:[coder decodeObjectOfClass:[NSNumber class] forKey:@"dataPlanVersion"]];
    if ([coder containsValueForKey:@"shouldUploadEvent"]) {
        self.shouldUploadEvent = [coder decodeBoolForKey:@"shouldUploadEvent"];
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (NSDictionary *)dictionaryRepresentation {
    return [self.implementation dictionaryRepresentation];
}

- (NSString *)serializedString {
    return [self.implementation serializedString];
}

@end
