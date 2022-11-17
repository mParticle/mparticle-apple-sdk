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
        _shouldUploadEvent = YES;
    }
    
    return self;
}

+ (void)fixInvalidKeysInDictionary:(NSMutableDictionary*)messageDictionary messageInfo:(NSDictionary*) messageInfo{
    for (NSString *key in messageInfo) {
        if ([messageInfo[key] isKindOfClass:[NSDictionary class]]) {
            if (![NSJSONSerialization isValidJSONObject: messageInfo[key]]) {
                NSMutableDictionary *temp = [messageDictionary[key] mutableCopy];
                [MPMessage fixInvalidKeysInDictionary:temp messageInfo:messageInfo[key]];
                messageDictionary[key] = temp;
            }
        } else {
            if ([messageInfo[key] isKindOfClass:[NSNumber class]]) {
                NSNumber *value = (NSNumber *)messageInfo[key];
                if(value.doubleValue == INFINITY || value.doubleValue == -INFINITY || isnan(value.doubleValue)) {
                    MPILogVerbose(@"Invalid Message Data for key: %@", key);
                    MPILogVerbose(@"Value should not be infinite. Removing value from message data");
                    messageDictionary[key] = nil;
                }
                
            }
        }
    }
    return;
}

- (instancetype)initWithSession:(MPSession *)session messageType:(NSString *)messageType messageInfo:(NSDictionary *)messageInfo uploadStatus:(MPUploadStatus)uploadStatus UUID:(NSString *)uuid timestamp:(NSTimeInterval)timestamp userId:(NSNumber *)userId  dataPlanId:(NSString *)dataPlanId dataPlanVersion:(NSNumber *)dataPlanVersion {
    NSNumber *sessionId = nil;
    
    if (session) {
        sessionId = @(session.sessionId);
    }
    
    NSMutableDictionary *messageDictionary = messageInfo.mutableCopy;
    if (![NSJSONSerialization isValidJSONObject: messageInfo]) {
        [MPMessage fixInvalidKeysInDictionary:messageDictionary messageInfo:messageInfo];
    }
    
    return [self initWithSessionId:sessionId
                         messageId:0
                              UUID:uuid
                       messageType:messageType
                       messageData:[NSJSONSerialization dataWithJSONObject:messageDictionary options:0 error:nil]
                         timestamp:timestamp
                      uploadStatus:uploadStatus
                            userId:userId
                        dataPlanId:dataPlanId
                   dataPlanVersion:dataPlanVersion];
}

- (void)truncateMessageDataProperty:(nonnull NSString *)property
                           toLength:(NSInteger)length
{
    NSMutableDictionary *messageDataDict = [[NSJSONSerialization JSONObjectWithData:self.messageData options:0 error:nil] mutableCopy];
    NSString *propertyValue = messageDataDict[property];
    if(!propertyValue) {
        return;
    }
    
    NSData *propertyValueData = [propertyValue dataUsingEncoding:NSUTF8StringEncoding];
    NSData *propertyValueDataTruncated = [propertyValueData subdataWithRange:NSMakeRange(0, MIN(propertyValueData.length, length))];
    NSString * propertyValueTruncated = [[NSString alloc] initWithData:propertyValueDataTruncated encoding:NSUTF8StringEncoding];
    
    messageDataDict[property] = propertyValueTruncated;
    self.messageData = [NSJSONSerialization dataWithJSONObject:messageDataDict options:0 error:nil];
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
    _shouldUploadEvent == object.shouldUploadEvent &&
    dataPlanIdEqual &&
    dataPlanVersionEqual;
    
    return isEqual;
}

- (NSUInteger)hash {
    return [self.sessionId hash] ^ [self.dataPlanId hash] ^ [self.dataPlanVersion hash] ^ self.messageId ^ (NSUInteger)self.timestamp ^ [self.messageType hash] ^ [self.messageData hash]  ^ (NSUInteger)self.shouldUploadEvent;
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
    copyObject.shouldUploadEvent = _shouldUploadEvent;
    
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
        _shouldUploadEvent = [coder decodeBoolForKey:@"shouldUploadEvent"];
    }
    
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
