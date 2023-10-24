#import <Foundation/Foundation.h>
#import "MPEnums.h"

@interface MPIHasher : NSObject

+ (uint64_t)hashFNV1a:(NSData *)data;
+ (NSString *)hashString:(NSString *)stringToHash;
+ (NSString *)hashStringUTF16:(NSString *)stringToHash;
+ (NSString *)hashEventType:(MPEventType)eventType;
+ (MPEventType)eventTypeForHash:(NSString *)hashString;
+ (NSString *)hashEventType:(MPEventType)eventType eventName:(NSString *)eventName isLogScreen:(BOOL)isLogScreen;
+ (NSString *)hashEventAttributeKey:(MPEventType)eventType eventName:(NSString *)eventName customAttributeName:(NSString *)customAttributeName isLogScreen:(BOOL)isLogScreen;
+ (NSString *)hashUserAttributeKey:(NSString *)userAttributeKey;
+ (NSString *)hashUserAttributeValue:(NSString *)userAttributeValue;
+ (NSString *)hashUserIdentity:(MPUserIdentity)userIdentity;
+ (NSString *)hashConsentPurpose:(NSString *)regulationPrefix purpose:(NSString *)purpose;
+ (NSString *)hashCommerceEventAttribute:(MPEventType)commerceEventType key:(NSString *)key;
+ (NSString *)hashTriggerEventName:(NSString *)eventName eventType:(NSString *)eventType;

@end
