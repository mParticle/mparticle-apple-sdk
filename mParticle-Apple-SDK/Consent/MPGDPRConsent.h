#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Record of consent under the GDPR.
 */
@interface MPGDPRConsent : NSObject

@property (nonatomic, assign) BOOL consented;
@property (nonatomic, nullable) NSString *document;
@property (nonatomic) NSDate *timestamp;
@property (nonatomic, nullable) NSString *location;
@property (nonatomic, nullable) NSString *hardwareId;

@end

NS_ASSUME_NONNULL_END
