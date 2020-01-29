#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Record of consent under the CCPA.
 */
@interface MPCCPAConsent : NSObject <NSCopying>

/**
* Whether the user consented to data collection
 This should be set to false if the user has opted out of data sharing under the CCPA.
*/
@property (nonatomic, assign) BOOL consented;
/**
* The data collection document to which the user consented or did not consent
*/
@property (nonatomic, copy, nullable) NSString *document;
/**
* Timestamp when the user was prompted for consent
*/
@property (nonatomic, copy) NSDate *timestamp;
/**
* Where the consent prompt took place. This can be a physical or digital location (e.g. URL)
*/
@property (nonatomic, copy, nullable) NSString *location;
/**
* The device ID associated with this consent record
*/
@property (nonatomic, copy, nullable) NSString *hardwareId;

@end

NS_ASSUME_NONNULL_END
