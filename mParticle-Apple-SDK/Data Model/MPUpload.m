#import "MPUpload.h"
#import "MPIConstants.h"
#import "MPUploadSettings.h"
@import mParticle_Apple_SDK_Swift;

@interface MPUpload ()
@property (nonatomic, strong) MPUploadPRIVATE *implementation;
@end

@implementation MPUpload

- (instancetype)initWithSessionId:(NSNumber *)sessionId uploadDictionary:(NSDictionary *)uploadDictionary dataPlanId:(nullable NSString *)dataPlanId dataPlanVersion:(nullable NSNumber *)dataPlanVersion uploadSettings:(nonnull MPUploadSettings *)uploadSettings {
    NSData *uploadData = [MPUploadPRIVATE serializedUploadFromDictionary:uploadDictionary];
    if (!uploadData) {
        return nil;
    }

    NSDictionary *safeDictionary = [NSJSONSerialization JSONObjectWithData:uploadData options:0 error:nil];
    return [self initWithSessionId:sessionId
                          uploadId:0
                              UUID:safeDictionary[kMPMessageIdKey]
                        uploadData:uploadData
                         timestamp:[safeDictionary[kMPTimestampKey] doubleValue]
                        uploadType:MPUploadTypeMessage
                        dataPlanId:dataPlanId
                   dataPlanVersion:dataPlanVersion
                    uploadSettings:uploadSettings];
}

- (instancetype)initWithSessionId:(NSNumber *)sessionId uploadId:(int64_t)uploadId UUID:(NSString *)uuid uploadData:(NSData *)uploadData timestamp:(NSTimeInterval)timestamp uploadType:(MPUploadType)uploadType dataPlanId:(nullable NSString *)dataPlanId dataPlanVersion:(nullable NSNumber *)dataPlanVersion uploadSettings:(nonnull MPUploadSettings *)uploadSettings {
    self = [super init];
    if (self) {
        _implementation = [[MPUploadPRIVATE alloc] initWithSessionId:sessionId
                                                            uploadId:uploadId
                                                                UUID:uuid
                                                          uploadData:uploadData
                                                           timestamp:timestamp
                                                          uploadType:uploadType
                                                          dataPlanId:dataPlanId
                                                     dataPlanVersion:dataPlanVersion];
        _uuid = uuid;
        _uploadSettings = uploadSettings;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Upload\n Id: %lld\n UUID: %@\n Content: %@\n timestamp: %.0f\n Data Plan: %@ %@\n", self.uploadId, self.uuid, [self dictionaryRepresentation], self.timestamp, self.dataPlanId, self.dataPlanVersion];
}

- (BOOL)isEqual:(MPUpload *)object {
    if (MPIsNull(object) || ![object isKindOfClass:[MPUpload class]]) {
        return NO;
    }
    return [self.implementation isEqualToUpload:object.implementation];
}

- (NSUInteger)hash {
    return (NSUInteger)self.implementation.hash;
}

- (id)copyWithZone:(NSZone *)zone {
    MPUploadPRIVATE *copyImpl = [self.implementation copyUpload];
    MPUpload *copyObject = [[MPUpload alloc] initWithSessionId:copyImpl.sessionId
                                                      uploadId:copyImpl.uploadId
                                                          UUID:copyImpl.uuid
                                                    uploadData:copyImpl.uploadData
                                                     timestamp:copyImpl.timestamp
                                                    uploadType:(MPUploadType)copyImpl.uploadType
                                                    dataPlanId:copyImpl.dataPlanId
                                               dataPlanVersion:copyImpl.dataPlanVersion
                                                uploadSettings:[self.uploadSettings copy]];
    copyObject.containsOptOutMessage = copyImpl.containsOptOutMessage;
    return copyObject;
}

- (NSNumber *)sessionId { return self.implementation.sessionId; }
- (void)setSessionId:(NSNumber *)sessionId { self.implementation.sessionId = sessionId; }
- (int64_t)uploadId { return self.implementation.uploadId; }
- (void)setUploadId:(int64_t)uploadId { self.implementation.uploadId = uploadId; }
- (NSString *)uuid { return self.implementation.uuid; }
- (void)setUuid:(NSString *)uuid { self.implementation.uuid = uuid; _uuid = uuid; }
- (NSData *)uploadData { return self.implementation.uploadData; }
- (void)setUploadData:(NSData *)uploadData { self.implementation.uploadData = uploadData; }
- (NSTimeInterval)timestamp { return self.implementation.timestamp; }
- (void)setTimestamp:(NSTimeInterval)timestamp { self.implementation.timestamp = timestamp; }
- (MPUploadType)uploadType { return (MPUploadType)self.implementation.uploadType; }
- (void)setUploadType:(MPUploadType)uploadType { self.implementation.uploadType = uploadType; }
- (BOOL)containsOptOutMessage { return self.implementation.containsOptOutMessage; }
- (void)setContainsOptOutMessage:(BOOL)containsOptOutMessage { self.implementation.containsOptOutMessage = containsOptOutMessage; }
- (NSString *)dataPlanId { return self.implementation.dataPlanId; }
- (void)setDataPlanId:(NSString *)dataPlanId { self.implementation.dataPlanId = dataPlanId; }
- (NSNumber *)dataPlanVersion { return self.implementation.dataPlanVersion; }
- (void)setDataPlanVersion:(NSNumber *)dataPlanVersion { self.implementation.dataPlanVersion = dataPlanVersion; }

- (NSDictionary *)dictionaryRepresentation {
    return [self.implementation dictionaryRepresentation];
}

- (NSString *)serializedString {
    return [self.implementation serializedString];
}

@end
