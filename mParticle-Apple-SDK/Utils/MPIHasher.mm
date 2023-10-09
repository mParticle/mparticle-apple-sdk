#import "MPIHasher.h"
#include "MPHasher.h"

@implementation MPIHasher

+ (uint64_t)hashFNV1a:(NSData *)data {
    uint64_t dataHash = mParticle::Hasher::hashFNV1a((const char *)[data bytes], (int)[data length]);
    return dataHash;
}

+ (NSString *)hashString:(NSString *)stringToHash {
    NSString *result = [NSString stringWithCString:mParticle::Hasher::hashString([stringToHash cStringUsingEncoding:NSUTF8StringEncoding]).c_str() encoding:NSUTF8StringEncoding];
    return result;
}

+ (NSString *)hashStringUTF16:(NSString *)stringToHash {
    NSData *data = [stringToHash dataUsingEncoding:NSUTF16LittleEndianStringEncoding];
    int64_t hash = mParticle::Hasher::hashFNV1a((const char *)[data bytes], (int)[data length]);
    NSString *result = @(hash).stringValue;
    return result;
}

+ (NSString *)hashEventType:(MPEventType)eventType {
    return [NSString stringWithCString:mParticle::Hasher::hashString([[@(eventType) stringValue] UTF8String]).c_str() encoding:NSUTF8StringEncoding];
}

+ (MPEventType)eventTypeForHash:(NSString *)hashString {
    for (int i = 1; i <= MPEventTypeImpression; ++i) {
        if ([hashString isEqualToString: [MPIHasher hashEventType: (MPEventType)i]]) {
            return (MPEventType)i;
        }
    }
    
    return MPEventTypeOther;
}

+ (NSString *)hashEventName:(MPEventType)eventType eventName:(NSString *)eventName isLogScreen:(BOOL)isLogScreen {
    NSString *stringToBeHashed;
    if (isLogScreen) {
        stringToBeHashed = [NSString stringWithFormat:@"%@%@", @"0", [eventName lowercaseString]];

    } else {
        stringToBeHashed = [NSString stringWithFormat:@"%@%@", [@(eventType) stringValue], [eventName lowercaseString]];
    }
    return [NSString stringWithCString:mParticle::Hasher::hashString([stringToBeHashed cStringUsingEncoding:NSUTF8StringEncoding]).c_str() encoding:NSUTF8StringEncoding];
}

+ (NSString *)hashEventAttributeKey:(MPEventType)eventType eventName:(NSString *)eventName customAttributeName:(NSString *)customAttributeName isLogScreen:(BOOL)isLogScreen {
    NSString *stringToBeHashed;
    if (isLogScreen) {
        stringToBeHashed = [NSString stringWithFormat:@"%@%@%@", @"0", eventName, customAttributeName];

    } else {
        stringToBeHashed = [NSString stringWithFormat:@"%@%@%@", [@(eventType) stringValue], eventName, customAttributeName];
    }
    return [NSString stringWithCString:mParticle::Hasher::hashString([stringToBeHashed cStringUsingEncoding:NSUTF8StringEncoding]).c_str() encoding:NSUTF8StringEncoding];
}

+ (NSString *)hashUserAttributeKey:(NSString *)userAttributeKey {
    return [NSString stringWithCString:mParticle::Hasher::hashString([[userAttributeKey lowercaseString] cStringUsingEncoding:NSUTF8StringEncoding]).c_str() encoding:NSUTF8StringEncoding];
}

+ (NSString *)hashUserAttributeValue:(NSString *)userAttributeValue {
    return [NSString stringWithCString:mParticle::Hasher::hashString([[userAttributeValue lowercaseString] cStringUsingEncoding:NSUTF8StringEncoding]).c_str() encoding:NSUTF8StringEncoding];
}

    // User Identities are not actually hashed, this method is named this way to
    // be consistent with the filter class. UserIdentityType is also a number
+ (NSString *)hashUserIdentity:(MPUserIdentity)userIdentity {
    return [[NSString alloc] initWithFormat:@"%lu", (unsigned long)userIdentity];
}

+ (NSString *)hashConsentPurpose:(NSString *)regulationPrefix purpose:(NSString *)purpose {
    NSString *stringToBeHashed = [NSString stringWithFormat:@"%@%@", regulationPrefix, [purpose lowercaseString]];
    return [NSString stringWithCString:mParticle::Hasher::hashString([stringToBeHashed cStringUsingEncoding:NSUTF8StringEncoding]).c_str() encoding:NSUTF8StringEncoding];
}

+ (NSString *)hashCommerceEventAttribute:(MPEventType)commerceEventType key:(NSString *)key {
    NSString *stringToBeHashed = [NSString stringWithFormat:@"%@%@", [@(commerceEventType) stringValue], key];
    return [NSString stringWithCString:mParticle::Hasher::hashString([[stringToBeHashed lowercaseString] UTF8String]).c_str() encoding:NSUTF8StringEncoding];
}

@end
