#import "MPMessage.h"
#import "MPSession.h"
#import "MPILogger.h"
#import "mParticle.h"

@interface MPMessage()

@property (nonatomic, strong) NSData *messageData;
@property (nonatomic, strong) NSString *messageType;

@end


@implementation MPMessage

- (instancetype)initWithSessionId:(NSNumber *)sessionId messageId:(int64_t)messageId UUID:(NSString *)uuid messageType:(NSString *)messageType messageData:(NSData *)messageData timestamp:(NSTimeInterval)timestamp uploadStatus:(MPUploadStatus)uploadStatus userId:(NSNumber *)userId dataPlanId:(NSString *)dataPlanId dataPlanVersion:(NSNumber *)dataPlanVersion {
    self = [super init];
    if (self) {
        _sessionId = sessionId;
        _messageId = messageId;
        _uuid = uuid;
        _messageType = messageType;
        _messageData = messageData;
        _timestamp = timestamp;
        _uploadStatus = uploadStatus;
        _userId = userId;
        _dataPlanId = dataPlanId;
        _dataPlanVersion = dataPlanVersion;
    }
    
    return self;
}

- (instancetype)initWithSession:(MPSession *)session messageType:(NSString *)messageType messageInfo:(NSDictionary *)messageInfo uploadStatus:(MPUploadStatus)uploadStatus UUID:(NSString *)uuid timestamp:(NSTimeInterval)timestamp userId:(NSNumber *)userId  dataPlanId:(NSString *)dataPlanId dataPlanVersion:(NSNumber *)dataPlanVersion {
    NSNumber *sessionId = nil;
    
    if (session) {
        sessionId = @(session.sessionId);
    }
    
    return [self initWithSessionId:sessionId
                         messageId:0
                              UUID:uuid
                       messageType:messageType
                       messageData:[NSJSONSerialization dataWithJSONObject:messageInfo options:0 error:nil]
                         timestamp:timestamp
                      uploadStatus:uploadStatus
                            userId:userId
                        dataPlanId:dataPlanId
                   dataPlanVersion:dataPlanVersion];
}

- (NSString *)description {
    NSString *serializedString = [self serializedString];
    
    return [NSString stringWithFormat:@"Message\n Id: %lld\n UUID: %@\n Session: %@\n Type: %@\n timestamp: %.0f\n Data Plan: %@ %@\n Content: %@\n", self.messageId, self.uuid, self.sessionId, self.messageType, self.timestamp, self.dataPlanId, self.dataPlanVersion, serializedString];
}

- (BOOL)isEqual:(MPMessage *)object {
    if (MPIsNull(object) || ![object isKindOfClass:[MPMessage class]]) {
        return NO;
    }
    
    BOOL sessionIdsEqual = (_sessionId == nil && object.sessionId == nil) || [_sessionId isEqual:object.sessionId];
    BOOL dataPlanIdEqual = (_dataPlanId == nil && object.dataPlanId == nil) || [_dataPlanId isEqual:object.dataPlanId];
    BOOL dataPlanVersionEqual = (_dataPlanVersion == nil && object.dataPlanVersion == nil) || [_dataPlanVersion isEqual:object.dataPlanVersion];
    
    BOOL isEqual = sessionIdsEqual &&
    _messageId == object.messageId &&
    _timestamp == object.timestamp &&
    [_messageType isEqualToString:object.messageType] &&
    [_messageData isEqualToData:object.messageData] &&
    dataPlanIdEqual &&
    dataPlanVersionEqual;
    
    return isEqual;
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
    MPMessage *copyObject = [[MPMessage alloc] initWithSessionId:[_sessionId copy]
                                                       messageId:_messageId
                                                            UUID:[_uuid copy]
                                                     messageType:[_messageType copy]
                                                     messageData:[_messageData copy]
                                                       timestamp:_timestamp
                                                    uploadStatus:_uploadStatus
                                                          userId:_userId
                                                      dataPlanId:[_dataPlanId copy]
                                                 dataPlanVersion:[_dataPlanVersion copy]];
    
    return copyObject;
}

#pragma mark NSSecureCoding
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.sessionId forKey:@"sessionId"];
    [coder encodeInt64:self.messageId forKey:@"messageId"];
    [coder encodeObject:self.uuid forKey:@"uuid"];
    [coder encodeObject:self.messageType forKey:@"messageType"];
    [coder encodeObject:self.messageData forKey:@"messageData"];
    [coder encodeDouble:self.timestamp forKey:@"timestamp"];
    [coder encodeInteger:self.uploadStatus forKey:@"uploadStatus"];
    [coder encodeInt64:_userId.longLongValue forKey:@"mpid"];
    [coder encodeObject:self.dataPlanId forKey:@"dataPlanId"];
    [coder encodeObject:self.dataPlanVersion forKey:@"dataPlanVersion"];
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
    
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

#pragma mark Public methods
- (NSDictionary *)dictionaryRepresentation {
    NSError *error = nil;
    NSDictionary *dictionaryRepresentation = nil;
    
    @try {
        dictionaryRepresentation = [NSJSONSerialization JSONObjectWithData:_messageData options:0 error:&error];
        
        if (error != nil) {
            MPILogError(@"Error serializing message.");
        }
    } @catch (NSException *exception) {
        MPILogError(@"Exception serializing message.");
    }
    
    return dictionaryRepresentation;
}

- (NSString *)serializedString {
    NSString *serializedString = [[NSString alloc] initWithData:_messageData encoding:NSUTF8StringEncoding];
    return serializedString;
}

@end
