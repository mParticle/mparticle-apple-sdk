#import "MPUpload.h"
#import "MPSession.h"
#import "MPIConstants.h"
#import "mParticle.h"
#import "MPILogger.h"
#import "MParticleSwift.h"

@interface MParticle()
@property (nonatomic, strong) MPStateMachine_PRIVATE *stateMachine;
@end

// Creates a JSON-safe snapshot of an object tree.
// Copies containers to reduce concurrent mutation risk, sanitizes non-JSON types,
// and handles edge cases (NaN/Inf, cycles) before NSJSONSerialization.
static id MPJSONSafeObject(id object, NSHashTable *stack, BOOL *didSanitize) {
    if (object == nil || object == [NSNull null]) {
        return object;
    }

    if ([object isKindOfClass:[NSString class]]) {
        return [object copy];
    }

    if ([object isKindOfClass:[NSNumber class]]) {
        double value = [object doubleValue];
        if (isnan(value) || isinf(value)) {
            if (didSanitize) {
                *didSanitize = YES;
            }
            return nil;
        }
        return object;
    }

    if ([object isKindOfClass:[NSDictionary class]]) {
        if ([stack containsObject:object]) {
            if (didSanitize) {
                *didSanitize = YES;
            }
            return nil;
        }
        [stack addObject:object];

        NSDictionary *dictionary = nil;
        @try {
            dictionary = [((NSDictionary *)object) copy];
        } @catch (NSException *exception) {
            if (didSanitize) {
                *didSanitize = YES;
            }
            [stack removeObject:object];
            return nil;
        }
        NSMutableDictionary *sanitized = [[NSMutableDictionary alloc] initWithCapacity:dictionary.count];
        [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if (![key isKindOfClass:[NSString class]]) {
                if (didSanitize) {
                    *didSanitize = YES;
                }
                return;
            }
            id safeValue = MPJSONSafeObject(obj, stack, didSanitize);
            if (safeValue) {
                sanitized[key] = safeValue;
            }
        }];

        [stack removeObject:object];
        return [sanitized copy];
    }

    if ([object isKindOfClass:[NSArray class]]) {
        if ([stack containsObject:object]) {
            if (didSanitize) {
                *didSanitize = YES;
            }
            return nil;
        }
        [stack addObject:object];

        NSArray *array = nil;
        @try {
            array = [((NSArray *)object) copy];
        } @catch (NSException *exception) {
            if (didSanitize) {
                *didSanitize = YES;
            }
            [stack removeObject:object];
            return nil;
        }
        NSMutableArray *sanitized = [[NSMutableArray alloc] initWithCapacity:array.count];
        for (id item in array) {
            id safeItem = MPJSONSafeObject(item, stack, didSanitize);
            if (safeItem) {
                [sanitized addObject:safeItem];
            }
        }

        [stack removeObject:object];
        return [sanitized copy];
    }

    if ([object isKindOfClass:[NSSet class]]) {
        if (didSanitize) {
            *didSanitize = YES;
        }
        NSSet *setSnapshot = [((NSSet *)object) copy];
        return MPJSONSafeObject([setSnapshot allObjects], stack, didSanitize);
    }

    if ([object isKindOfClass:[NSDate class]]) {
        if (didSanitize) {
            *didSanitize = YES;
        }
        return @([(NSDate *)object timeIntervalSince1970] * 1000);
    }

    if ([object isKindOfClass:[NSURL class]]) {
        if (didSanitize) {
            *didSanitize = YES;
        }
        return [(NSURL *)object absoluteString];
    }

    if ([object isKindOfClass:[NSUUID class]]) {
        if (didSanitize) {
            *didSanitize = YES;
        }
        return [(NSUUID *)object UUIDString];
    }

    if (didSanitize) {
        *didSanitize = YES;
    }
    return nil;
}

static NSDictionary *MPJSONSafeDictionary(NSDictionary *dictionary, BOOL *didSanitize) {
    if (dictionary == nil || dictionary == (id)[NSNull null]) {
        if (didSanitize) {
            *didSanitize = YES;
        }
        return nil;
    }

    NSHashTable *stack = [NSHashTable hashTableWithOptions:NSHashTableObjectPointerPersonality];
    id safeObject = MPJSONSafeObject(dictionary, stack, didSanitize);
    if ([safeObject isKindOfClass:[NSDictionary class]]) {
        return (NSDictionary *)safeObject;
    }

    if (didSanitize) {
        *didSanitize = YES;
    }
    return nil;
}

@implementation MPUpload

- (instancetype)initWithSessionId:(NSNumber *)sessionId uploadDictionary:(NSDictionary *)uploadDictionary dataPlanId:(nullable NSString *)dataPlanId dataPlanVersion:(nullable NSNumber *)dataPlanVersion uploadSettings:(nonnull MPUploadSettings *)uploadSettings {
    BOOL didSanitize = NO;
    NSDictionary *safeDictionary = MPJSONSafeDictionary(uploadDictionary, &didSanitize);
    if (didSanitize) {
        MPILogWarning(@"Upload dictionary contained non-JSON-safe values or required normalization; sanitizing before serialization.");
    }

    NSError *error = nil;
    NSData *uploadData = nil;

    @try {
        uploadData = [NSJSONSerialization dataWithJSONObject:(safeDictionary ?: @{}) options:0 error:&error];
    } @catch (NSException *exception) {
        MPILogError(@"Exception serializing upload dictionary: %@", exception);
    }

    if (uploadData == nil || error != nil) {
        MPILogError(@"Failed to serialize upload dictionary: %@", error);
        uploadData = [NSJSONSerialization dataWithJSONObject:@{} options:0 error:nil];
    }
    NSDictionary *identifierSource = safeDictionary ?: uploadDictionary;
    return [self initWithSessionId:sessionId
                          uploadId:0
                              UUID:identifierSource[kMPMessageIdKey]
                        uploadData:uploadData
                         timestamp:[identifierSource[kMPTimestampKey] doubleValue]
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
