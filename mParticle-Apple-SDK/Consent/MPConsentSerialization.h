#import <Foundation/Foundation.h>

@class MPConsentKitFilter;
@class MPConsentStateSwift;

NS_ASSUME_NONNULL_BEGIN

@interface MPConsentSerialization : NSObject

+ (nullable MPConsentStateSwift *)consentStateFromString:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
