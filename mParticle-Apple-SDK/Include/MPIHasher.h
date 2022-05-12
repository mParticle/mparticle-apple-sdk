#import <Foundation/Foundation.h>
#import "MPEnums.h"

@interface MPIHasher : NSObject

+ (uint64_t)hashFNV1a:(NSData *)data;
+ (NSString *)hashString:(NSString *)stringToHash;
+ (NSString *)hashStringUTF16:(NSString *)stringToHash;
+ (NSString *)hashEventType:(MPEventType)eventType;
+ (MPEventType)eventTypeForHash:(NSString *)hashString;


@end
