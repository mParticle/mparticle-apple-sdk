#import "MPUpload.h"
#import "MPSession.h"
#import "MPIConstants.h"

@implementation MPUpload

- (instancetype)initWithSession:(MPSession *)session uploadDictionary:(NSDictionary *)uploadDictionary {
    NSData *uploadData = [NSJSONSerialization dataWithJSONObject:uploadDictionary options:0 error:nil];
    
    return [self initWithSessionId:session.sessionId
                          uploadId:0
                              UUID:uploadDictionary[kMPMessageIdKey]
                        uploadData:uploadData
                         timestamp:[uploadDictionary[kMPTimestampKey] doubleValue]];
}

- (instancetype)initWithSessionId:(int64_t)sessionId uploadId:(int64_t)uploadId UUID:(NSString *)uuid uploadData:(NSData *)uploadData timestamp:(NSTimeInterval)timestamp {
    self = [super init];
    if (self) {
        _sessionId = sessionId;
        _uploadId = uploadId;
        _uuid = uuid;
        _timestamp = timestamp;
        _uploadData = uploadData;
    }
    
    return self;
}

- (NSString *)description {
    NSDictionary *dictionaryRepresentation = [self dictionaryRepresentation];
    
    return [NSString stringWithFormat:@"Upload\n Id: %lld\n UUID: %@\n Content: %@\n timestamp: %.0f\n", self.uploadId, self.uuid, dictionaryRepresentation, self.timestamp];
}

- (BOOL)isEqual:(MPUpload *)object {
    if (MPIsNull(object) || ![object isKindOfClass:[MPUpload class]]) {
        return NO;
    }
    
    BOOL isEqual = _sessionId == object.sessionId &&
                   _uploadId == object.uploadId &&
                   _timestamp == object.timestamp &&
                   [_uploadData isEqualToData:object.uploadData];
    
    return isEqual;
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
    MPUpload *copyObject = [[MPUpload alloc] initWithSessionId:_sessionId
                                                      uploadId:_uploadId
                                                          UUID:[_uuid copy]
                                                    uploadData:[_uploadData copy]
                                                     timestamp:_timestamp];
    
    return copyObject;
}

#pragma mark Public methods
- (NSDictionary *)dictionaryRepresentation {
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:_uploadData options:0 error:nil];
    return dictionary;
}

- (NSString *)serializedString {
    NSString *serializedString = [[NSString alloc] initWithData:_uploadData encoding:NSUTF8StringEncoding];
    return serializedString;
}

@end
