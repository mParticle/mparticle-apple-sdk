#import <Foundation/Foundation.h>
@import mParticle_Apple_SDK_ObjC;

@interface MPKitUrbanAirship : NSObject <MPKitProtocol>

@property (nonatomic, strong, nonnull) NSDictionary *configuration;
@property (nonatomic, strong, nullable) NSDictionary *launchOptions;
@property (nonatomic, unsafe_unretained, readonly) BOOL started;

/**
 * Default out-of-the-box categories.
 *
 * @note These notification categories need to be set on the current notification center to retain
 * out-of-the-box categories functionality.
 */
+ (NSSet<UNNotificationCategory *> *_Nonnull)defaultCategories;

@end
