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
@end
