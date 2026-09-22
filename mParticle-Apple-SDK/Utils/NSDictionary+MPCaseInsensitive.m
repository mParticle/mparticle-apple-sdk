#import "NSDictionary+MPCaseInsensitive.h"
#import "MPILogger.h"
#import "mParticle.h"
@import mParticle_Apple_SDK_Swift;

@implementation NSDictionary(MPCaseInsensitive)

- (NSString *)caseInsensitiveKey:(NSString *)key {
    @try {
        NSString *localKey = [self mpCaseInsensitiveKey:key];
        if (localKey) {
            return localKey;
        }
    } @catch (NSException *exception) {
        MPILogError(@"Exception retrieving case insentitive key: %@", [exception reason]);
    }

    return key;
}

- (id)valueForCaseInsensitiveKey:(NSString *)key {
    @try {
        return [self mpValueForCaseInsensitiveKey:key];
    } @catch (NSException *exception) {
        MPILogError(@"Exception retrieving case insentitive value: %@", [exception reason]);
    }

    return nil;
}

- (NSDictionary<NSString *, id> *)transformValuesToString {
    NSMutableDictionary<NSString *, id> *transformedDictionary = [[NSMutableDictionary alloc] initWithCapacity:self.count];

    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (![MPAttributeValueTransformer isSupportedAttributeValue:obj]) {
            MPILogError(@"Data type is not supported as an attribute value: %@ - %@", obj, [[obj class] description]);
            return;
        }

        transformedDictionary[key] = [MPAttributeValueTransformer transformedValueForAttribute:obj];
    }];

    return transformedDictionary;
}

@end
