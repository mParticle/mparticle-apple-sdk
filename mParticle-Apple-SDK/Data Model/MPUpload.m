#import "MPUpload.h"
#import "MPSession.h"
#import "MPIConstants.h"
#import "mParticle.h"
#import "MPILogger.h"

@interface MParticle()
@property (nonatomic, strong) MPStateMachine_PRIVATE *stateMachine;
@end

// Recursively deep-copies a JSON-compatible object tree, producing new immutable
// containers at every level. Snapshots each collection before enumerating it,
// breaking shared references with mutable data that other threads may mutate.
// Non-JSON-compatible values are silently dropped.
static id MPDeepCopyJSONObject(id object) {
    if (object == nil || object == [NSNull null]) return object;
    if ([object isKindOfClass:[NSString class]])  return [object copy];
    if ([object isKindOfClass:[NSNumber class]])  return object;

    if ([object isKindOfClass:[NSDictionary class]]) {
        NSDictionary *snapshot = [((NSDictionary *)object) copy];
        NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithCapacity:snapshot.count];
        for (id key in snapshot) {
            if (![key isKindOfClass:[NSString class]]) continue;
            id value = MPDeepCopyJSONObject(snapshot[key]);
            if (value) result[key] = value;
        }
        return [result copy];
    }

    if ([object isKindOfClass:[NSArray class]]) {
        NSArray *snapshot = [((NSArray *)object) copy];
        NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:snapshot.count];
        for (id item in snapshot) {
            id value = MPDeepCopyJSONObject(item);
            if (value) [result addObject:value];
        }
        return [result copy];
    }

    return nil;
}

@implementation MPUpload

- (instancetype)initWithSessionId:(NSNumber *)sessionId uploadDictionary:(NSDictionary *)uploadDictionary dataPlanId:(nullable NSString *)dataPlanId dataPlanVersion:(nullable NSNumber *)dataPlanVersion uploadSettings:(nonnull MPUploadSettings *)uploadSettings {
    NSDictionary *safeDictionary = nil;
    NSData *uploadData = nil;

    @try {
        safeDictionary = (NSDictionary *)MPDeepCopyJSONObject(uploadDictionary);
        if (safeDictionary) {
            uploadData = [NSJSONSerialization dataWithJSONObject:safeDictionary options:0 error:nil];
        }
    } @catch (NSException *exception) {
        MPILogError(@"Exception serializing upload dictionary: %@", exception);
    }

    if (!uploadData) {
        return nil;
    }

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
