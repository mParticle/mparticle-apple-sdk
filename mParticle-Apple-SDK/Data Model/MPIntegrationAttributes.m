#import "MPIntegrationAttributes.h"
@import mParticle_Apple_SDK_Swift;

@interface MPIntegrationAttributes ()
@property (nonatomic, strong) MPIntegrationAttributesPRIVATE *implementation;
@end

@implementation MPIntegrationAttributes

- (instancetype)initWithIntegrationId:(NSNumber *)integrationId attributes:(NSDictionary<NSString *, NSString *> *)attributes {
    MPIntegrationAttributesPRIVATE *implementation = [[MPIntegrationAttributesPRIVATE alloc] initWithIntegrationId:integrationId attributes:attributes];
    if (!implementation) {
        return nil;
    }

    self = [super init];
    if (self) {
        _implementation = implementation;
    }
    return self;
}

- (instancetype)initWithIntegrationId:(NSNumber *)integrationId attributesData:(NSData *)attributesData {
    MPIntegrationAttributesPRIVATE *implementation = [[MPIntegrationAttributesPRIVATE alloc] initWithIntegrationId:integrationId attributesData:attributesData];
    if (!implementation) {
        return nil;
    }

    self = [super init];
    if (self) {
        _implementation = implementation;
    }
    return self;
}

- (NSNumber *)integrationId {
    return self.implementation.integrationId;
}

- (void)setIntegrationId:(NSNumber *)integrationId {
    self.implementation.integrationId = integrationId;
}

- (NSDictionary<NSString *, NSString *> *)attributes {
    return (NSDictionary<NSString *, NSString *> *)self.implementation.attributes;
}

- (void)setAttributes:(NSDictionary<NSString *, NSString *> *)attributes {
    self.implementation.attributes = attributes;
}

- (NSDictionary *)dictionaryRepresentation {
    return [self.implementation dictionaryRepresentation];
}

- (NSString *)serializedString {
    return [self.implementation serializedString];
}

@end
