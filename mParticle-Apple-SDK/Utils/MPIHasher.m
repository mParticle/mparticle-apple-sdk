#import "MPIHasher.h"

@implementation MPIHasher

+ (uint64_t)hashFNV1a:(NSData *)data {
    // FNV-1a hashing
    uint64_t rampHash = 0xcbf29ce484222325;
    const char *bytes = (const char *)data.bytes;
    NSUInteger length = data.length;
    
    for (int i = 0; i < length; i++) {
        rampHash = (rampHash ^ bytes[i]) * 0x100000001B3;
    }
    return rampHash;
}

+ (NSString *)hashString:(NSString *)stringToHash {
    if (stringToHash.length == 0) {
        return @"";
    }
    
    NSString *lowercaseStringToHash = stringToHash.lowercaseString;
    NSData *dataToHash = [lowercaseStringToHash dataUsingEncoding:NSUTF8StringEncoding];
    const char *bytes = (const char *)dataToHash.bytes;
    NSUInteger length = dataToHash.length;
    
    int32_t hash = 0;
    for (int i = 0; i < length; i++) {
        uint8_t character = bytes[i];
        hash = ((hash << 5) - hash) + character;
    }
    
    return [NSString stringWithFormat:@"%d", hash];
}

+ (NSString *)hashStringUTF16:(NSString *)stringToHash {
    NSData *data = [stringToHash dataUsingEncoding:NSUTF16LittleEndianStringEncoding];
    int64_t hash = [self hashFNV1a:data];
    NSString *result = @(hash).stringValue;
    return result;
}

+ (NSString *)hashEventType:(MPEventType)eventType {
    return [self hashString:[@(eventType) stringValue]];
}

+ (MPEventType)eventTypeForHash:(NSString *)hashString {
    for (int i = 1; i <= MPEventTypeImpression; ++i) {
        if ([hashString isEqualToString: [MPIHasher hashEventType: (MPEventType)i]]) {
            return (MPEventType)i;
        }
    }
    
    return MPEventTypeOther;
}

+ (NSString *)hashEventType:(MPEventType)eventType eventName:(NSString *)eventName isLogScreen:(BOOL)isLogScreen {
    NSString *stringToBeHashed;
    if (isLogScreen) {
        stringToBeHashed = [NSString stringWithFormat:@"%@%@", @"0", [eventName lowercaseString]];

    } else {
        stringToBeHashed = [NSString stringWithFormat:@"%@%@", [@(eventType) stringValue], [eventName lowercaseString]];
    }
    
    return [self hashString:stringToBeHashed];
}

+ (NSString *)hashEventAttributeKey:(MPEventType)eventType eventName:(NSString *)eventName customAttributeName:(NSString *)customAttributeName isLogScreen:(BOOL)isLogScreen {
    NSString *stringToBeHashed;
    if (isLogScreen) {
        stringToBeHashed = [NSString stringWithFormat:@"%@%@%@", @"0", eventName, customAttributeName];
        
    } else {
        stringToBeHashed = [NSString stringWithFormat:@"%@%@%@", [@(eventType) stringValue], eventName, customAttributeName];
    }
    return [self hashString:stringToBeHashed];
}

+ (NSString *)hashUserAttributeKey:(NSString *)userAttributeKey {
    return [self hashString:userAttributeKey.lowercaseString];
}

+ (NSString *)hashUserAttributeValue:(NSString *)userAttributeValue {
    return[self hashString:userAttributeValue.lowercaseString];
}

    // User Identities are not actually hashed, this method is named this way to
    // be consistent with the filter class. UserIdentityType is also a number
+ (NSString *)hashUserIdentity:(MPUserIdentity)userIdentity {
    return [[NSString alloc] initWithFormat:@"%lu", (unsigned long)userIdentity];
}

+ (NSString *)hashConsentPurpose:(NSString *)regulationPrefix purpose:(NSString *)purpose {
    NSString *stringToBeHashed = [NSString stringWithFormat:@"%@%@", regulationPrefix, [purpose lowercaseString]];
    return [self hashString:stringToBeHashed];
}

+ (NSString *)hashCommerceEventAttribute:(MPEventType)commerceEventType key:(NSString *)key {
    NSString *stringToBeHashed = [NSString stringWithFormat:@"%@%@", [@(commerceEventType) stringValue], key];
    return [self hashString:stringToBeHashed];
}

+ (NSString *)hashTriggerEventName:(NSString *)eventName eventType:(NSString *)eventType {
    NSString *stringToBeHashed = [NSString stringWithFormat:@"%@%@", eventName, eventType];
    return [self hashString:stringToBeHashed];
}

@end
