#import "MPUpload.h"
#import "MPSession.h"
#import "MPIConstants.h"
#import "mParticle.h"
#import "MPStateMachine.h"

@interface MParticle()
@property (nonatomic, strong) MPStateMachine *stateMachine;
@end

@implementation MPUploadSettings

+ (MPUploadSettings *)currentUploadSettings {
    MParticle *mParticle = [MParticle sharedInstance];
    MPUploadSettings *uploadSettings = [[MPUploadSettings alloc] initWithApiKey:mParticle.stateMachine.apiKey
                                                                         secret:mParticle.stateMachine.secret
                                                                     eventsHost:mParticle.networkOptions.eventsHost
                                                             eventsTrackingHost:mParticle.networkOptions.eventsTrackingHost
                                                    overridesEventsSubdirectory:mParticle.networkOptions.overridesEventsSubdirectory
                                                                      aliasHost:mParticle.networkOptions.aliasHost
                                                              aliasTrackingHost:mParticle.networkOptions.aliasTrackingHost
                                                     overridesAliasSubdirectory:mParticle.networkOptions.overridesAliasSubdirectory
                                                                     eventsOnly:mParticle.networkOptions.eventsOnly];
    return uploadSettings;
}

- (instancetype)initWithApiKey:(nonnull NSString *)apiKey secret:(nonnull NSString *)secret eventsHost:(nullable NSString *)eventsHost eventsTrackingHost:(nullable NSString *)eventsTrackingHost overridesEventsSubdirectory:(BOOL)overridesEventsSubdirectory aliasHost:(nullable NSString *)aliasHost aliasTrackingHost:(nullable NSString *)aliasTrackingHost overridesAliasSubdirectory:(BOOL)overridesAliasSubdirectory eventsOnly:(BOOL)eventsOnly {
    if (self = [super init]) {
        _apiKey = apiKey;
        _secret = secret;
        _eventsHost = eventsHost;
        _eventsTrackingHost = eventsTrackingHost;
        _overridesEventsSubdirectory = overridesEventsSubdirectory;
        _aliasHost = aliasHost;
        _aliasTrackingHost = aliasTrackingHost;
        _overridesAliasSubdirectory = overridesAliasSubdirectory;
        _eventsOnly = eventsOnly;
    }
    return self;
}

static NSString * const kApiKey = @"apiKey";
static NSString * const kSecret = @"secret";
static NSString * const kEventsHost = @"eventsHost";
static NSString * const kEventsTrackingHost = @"eventsTrackingHost";
static NSString * const kOverridesEventsSubdirectory = @"overridesEventsSubdirectory";
static NSString * const kAliasHost = @"aliasHost";
static NSString * const kAliasTrackingHost = @"aliasTrackingHost";
static NSString * const kOverridesAliasSubdirectory = @"overridesAliasSubdirectory";
static NSString * const kEventsOnly = @"eventsOnly";

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder {
    if (self = [super init]) {
        _apiKey = [coder decodeObjectForKey:kApiKey];
        _secret = [coder decodeObjectForKey:kSecret];
        _eventsHost = [coder decodeObjectForKey:kEventsHost];
        _eventsTrackingHost = [coder decodeObjectForKey:kEventsTrackingHost];
        _overridesEventsSubdirectory = [coder decodeBoolForKey:kOverridesEventsSubdirectory];
        _aliasHost = [coder decodeObjectForKey:kAliasHost];
        _aliasTrackingHost = [coder decodeObjectForKey:kAliasTrackingHost];
        _overridesAliasSubdirectory = [coder decodeBoolForKey:kOverridesAliasSubdirectory];
        _eventsOnly = [coder decodeBoolForKey:kEventsOnly];
    }
    return self;
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
    [coder encodeObject:_apiKey forKey:kApiKey];
    [coder encodeObject:_secret forKey:kSecret];
    [coder encodeObject:_eventsHost forKey:kEventsHost];
    [coder encodeObject:_eventsTrackingHost forKey:kEventsTrackingHost];
    [coder encodeBool:_overridesEventsSubdirectory forKey:kOverridesEventsSubdirectory];
    [coder encodeObject:_aliasHost forKey:kAliasHost];
    [coder encodeObject:_aliasTrackingHost forKey:kAliasTrackingHost];
    [coder encodeBool:_overridesAliasSubdirectory forKey:kOverridesAliasSubdirectory];
    [coder encodeBool:_eventsOnly forKey:kEventsOnly];
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (id)copyWithZone:(NSZone *)zone {
    return [[MPUploadSettings alloc] initWithApiKey:_apiKey
                                             secret:_secret
                                         eventsHost:_eventsHost
                                 eventsTrackingHost:_eventsTrackingHost
                        overridesEventsSubdirectory:_overridesEventsSubdirectory
                                          aliasHost:_aliasHost
                                  aliasTrackingHost:_aliasTrackingHost
                         overridesAliasSubdirectory:_overridesAliasSubdirectory
                                         eventsOnly:_eventsOnly];
}

@end

@implementation MPUpload

- (instancetype)initWithSessionId:(NSNumber *)sessionId uploadDictionary:(NSDictionary *)uploadDictionary dataPlanId:(nullable NSString *)dataPlanId dataPlanVersion:(nullable NSNumber *)dataPlanVersion uploadSettings:(nonnull MPUploadSettings *)uploadSettings {
    NSData *uploadData = [NSJSONSerialization dataWithJSONObject:uploadDictionary options:0 error:nil];
    return [self initWithSessionId:sessionId
                          uploadId:0
                              UUID:uploadDictionary[kMPMessageIdKey]
                        uploadData:uploadData
                         timestamp:[uploadDictionary[kMPTimestampKey] doubleValue]
                        uploadType:MPUploadTypeMessage
                        dataPlanId:dataPlanId
                   dataPlanVersion:dataPlanVersion
                    uploadSettings:uploadSettings];
}

- (instancetype)initWithSessionId:(NSNumber *)sessionId uploadId:(int64_t)uploadId UUID:(NSString *)uuid uploadData:(NSData *)uploadData timestamp:(NSTimeInterval)timestamp uploadType:(MPUploadType)uploadType dataPlanId:(nullable NSString *)dataPlanId dataPlanVersion:(nullable NSNumber *)dataPlanVersion uploadSettings:(nonnull MPUploadSettings *)uploadSettings {
    self = [super init];
    if (self) {
        _sessionId = sessionId;
        _uploadId = uploadId;
        _uuid = uuid;
        _timestamp = timestamp;
        _uploadData = uploadData;
        _uploadType = uploadType;
        _containsOptOutMessage = NO;
        _dataPlanId = dataPlanId;
        _dataPlanVersion = dataPlanVersion;
        _uploadSettings = uploadSettings;
    }
    
    return self;
}

- (NSString *)description {
    NSDictionary *dictionaryRepresentation = [self dictionaryRepresentation];
    
    return [NSString stringWithFormat:@"Upload\n Id: %lld\n UUID: %@\n Content: %@\n timestamp: %.0f\n Data Plan: %@ %@\n", self.uploadId, self.uuid, dictionaryRepresentation, self.timestamp, self.dataPlanId, self.dataPlanVersion];
}

- (BOOL)isEqual:(MPUpload *)object {
    if (MPIsNull(object) || ![object isKindOfClass:[MPUpload class]]) {
        return NO;
    }
    BOOL sessionIdsEqual = (_sessionId == nil && object.sessionId == nil) || [_sessionId isEqual:object.sessionId];
    BOOL dataPlanIdEqual = (_dataPlanId == nil && object.dataPlanId == nil) || [_dataPlanId isEqual:object.dataPlanId];
    BOOL dataPlanVersionEqual = (_dataPlanVersion == nil && object.dataPlanVersion == nil) || [_dataPlanVersion isEqual:object.dataPlanVersion];

    BOOL isEqual = sessionIdsEqual &&
    _uploadId == object.uploadId &&
    _timestamp == object.timestamp &&
    dataPlanIdEqual &&
    dataPlanVersionEqual;
    
    return isEqual;
}

- (NSUInteger)hash {
    return [self.sessionId hash] ^ [self.dataPlanId hash] ^ [self.dataPlanVersion hash] ^ self.uploadId ^ (NSUInteger)self.timestamp;
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
    MPUpload *copyObject = [[MPUpload alloc] initWithSessionId:[_sessionId copy]
                                                      uploadId:_uploadId
                                                          UUID:[_uuid copy]
                                                    uploadData:[_uploadData copy]
                                                     timestamp:_timestamp
                                                    uploadType:_uploadType
                                                    dataPlanId:[_dataPlanId copy]
                                               dataPlanVersion:[_dataPlanVersion copy]
                                                uploadSettings:[_uploadSettings copy]];
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
