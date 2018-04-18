#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Record of consent under the GDPR.
 */
@interface MPGDPRConsent : NSObject

@property (nonatomic, assign) BOOL consented;
@property (nonatomic) NSString *document;
@property (nonatomic) NSDate *timestamp;
@property (nonatomic) NSString *location;
@property (nonatomic) NSString *hardwareId;

@end

NS_ASSUME_NONNULL_END
