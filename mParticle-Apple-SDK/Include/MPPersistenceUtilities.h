#import <Foundation/Foundation.h>

@class MPConsentState;

NS_ASSUME_NONNULL_BEGIN

@interface MPPersistenceUtilities : NSObject

+ (NSNumber *)mpId;
+ (void)setMpid:(NSNumber *)mpId;
+ (nullable MPConsentState *)consentStateForMpid:(NSNumber *)mpid;
+ (void)setConsentState:(nullable MPConsentState *)state forMpid:(NSNumber *)mpid;
+ (nullable MPConsentState *)deviceConsentState;
+ (void)setDeviceConsentState:(nullable MPConsentState *)state;
+ (nullable MPConsentState *)effectiveConsentStateForMpid:(nullable NSNumber *)mpid;
+ (NSInteger)maxBytesPerEvent:(nullable NSString *)messageType;
+ (NSInteger)maxBytesPerBatch:(nullable NSString *)messageType;

@end

NS_ASSUME_NONNULL_END
