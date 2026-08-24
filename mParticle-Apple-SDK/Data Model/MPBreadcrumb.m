#import "MPBreadcrumb.h"
#import "MPIConstants.h"
@import mParticle_Apple_SDK_Swift;

@interface MPBreadcrumb()
@property (nonatomic, strong) MPBreadcrumbPRIVATE *implementation;
@end

@implementation MPBreadcrumb

- (instancetype)initWithSessionUUID:(NSString *)sessionUUID breadcrumbId:(int64_t)breadcrumbId UUID:(NSString *)uuid breadcrumbData:(NSData *)breadcrumbData timestamp:(NSTimeInterval)timestamp {
    self = [super init];
    if (self) {
        _implementation = [[MPBreadcrumbPRIVATE alloc] initWithSessionUUID:sessionUUID
                                                              breadcrumbId:breadcrumbId
                                                                      UUID:uuid
                                                            breadcrumbData:breadcrumbData ?: [NSData data]
                                                                 timestamp:timestamp];
        _uuid = uuid;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Breadcrumb\n UUID: %@\n Content: %@\n timestamp: %.0f\n", self.uuid, self.implementation.content, self.timestamp];
}

- (BOOL)isEqual:(MPBreadcrumb *)object {
    if (MPIsNull(object) || ![object isKindOfClass:[MPBreadcrumb class]]) {
        return NO;
    }
    return [self.implementation isEqualToBreadcrumb:object.implementation];
}

- (NSUInteger)hash {
    return (NSUInteger)self.implementation.hash;
}

- (id)copyWithZone:(NSZone *)zone {
    MPBreadcrumbPRIVATE *copyImpl = [self.implementation copyBreadcrumb];
    return [[MPBreadcrumb alloc] initWithSessionUUID:copyImpl.sessionUUID
                                        breadcrumbId:copyImpl.breadcrumbId
                                                UUID:copyImpl.uuid
                                      breadcrumbData:copyImpl.breadcrumbData
                                           timestamp:copyImpl.timestamp];
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.sessionUUID forKey:@"sessionUUID"];
    [coder encodeInt64:self.breadcrumbId forKey:@"breadcrumbId"];
    [coder encodeObject:self.uuid forKey:@"uuid"];
    [coder encodeObject:self.implementation.content forKey:@"content"];
    [coder encodeObject:self.breadcrumbData forKey:@"breadcrumbData"];
    [coder encodeDouble:self.timestamp forKey:@"timestamp"];
}

- (id)initWithCoder:(NSCoder *)coder {
    NSString *content = [coder decodeObjectForKey:@"content"];
    NSData *breadcrumbData = [content dataUsingEncoding:NSUTF8StringEncoding];
    return [self initWithSessionUUID:[coder decodeObjectOfClass:[NSString class] forKey:@"sessionUUID"]
                        breadcrumbId:[coder decodeInt64ForKey:@"breadcrumbId"]
                                UUID:[coder decodeObjectOfClass:[NSString class] forKey:@"uuid"]
                      breadcrumbData:breadcrumbData
                           timestamp:[coder decodeDoubleForKey:@"timestamp"]];
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (NSString *)sessionUUID { return self.implementation.sessionUUID; }
- (void)setSessionUUID:(NSString *)sessionUUID { self.implementation.sessionUUID = sessionUUID; }
- (int64_t)breadcrumbId { return self.implementation.breadcrumbId; }
- (void)setBreadcrumbId:(int64_t)breadcrumbId { self.implementation.breadcrumbId = breadcrumbId; }
- (NSString *)uuid { return self.implementation.uuid; }
- (void)setUuid:(NSString *)uuid { self.implementation.uuid = uuid; _uuid = uuid; }
- (NSData *)breadcrumbData { return self.implementation.breadcrumbData; }
- (void)setBreadcrumbData:(NSData *)breadcrumbData { self.implementation.breadcrumbData = breadcrumbData; }
- (NSTimeInterval)timestamp { return self.implementation.timestamp; }
- (void)setTimestamp:(NSTimeInterval)timestamp { self.implementation.timestamp = timestamp; }

- (NSDictionary *)dictionaryRepresentation {
    return [self.implementation dictionaryRepresentation];
}

- (NSString *)serializedString {
    return [self.implementation serializedString];
}

@end
