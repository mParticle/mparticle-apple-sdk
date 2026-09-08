#import <Foundation/Foundation.h>

@class MPConsentState;

NS_ASSUME_NONNULL_BEGIN

@interface MPPersistenceUtilities : NSObject

+ (nonnull NSNumber *)mpId;
+ (void)setMpid:(nonnull NSNumber *)mpId;
+ (nullable MPConsentState *)consentStateForMpid:(nonnull NSNumber *)mpid;
+ (void)setConsentState:(nullable MPConsentState *)state forMpid:(nonnull NSNumber *)mpid;
+ (nullable MPConsentState *)deviceConsentState;
+ (void)setDeviceConsentState:(nullable MPConsentState *)state;
+ (nullable MPConsentState *)effectiveConsentStateForMpid:(nullable NSNumber *)mpid;
+ (NSInteger)maxBytesPerEvent:(nullable NSString *)messageType;
+ (NSInteger)maxBytesPerBatch:(nullable NSString *)messageType;

@end

NS_ASSUME_NONNULL_END
