#import <Foundation/Foundation.h>

@class MPConsentKitFilter;
@class MPConsentStateSwift;

NS_ASSUME_NONNULL_BEGIN

@interface MPConsentSerialization : NSObject

+ (nullable NSString *)stringFromConsentState:(MPConsentStateSwift *)state;
+ (nullable MPConsentStateSwift *)consentStateFromString:(NSString *)string;
+ (nullable MPConsentKitFilter *)filterFromDictionary:(NSDictionary *)configDictionary;

@end

NS_ASSUME_NONNULL_END
