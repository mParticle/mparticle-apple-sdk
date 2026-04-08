#import <Foundation/Foundation.h>
#import <mParticle_Apple_SDK_ObjC/mParticle.h>

@interface MPKitApptentive : NSObject <MPKitProtocol>

@property (nonatomic, strong, nonnull) NSDictionary *configuration;
@property (nonatomic, strong, nullable) NSDictionary *launchOptions;
@property (nonatomic, unsafe_unretained, readonly) BOOL started;
@property (nonatomic, strong, nullable) NSDictionary<NSString *, id> *userAttributes;
@property (nonatomic, strong, nullable) NSArray<NSDictionary<NSString *, id> *> *userIdentities;


/**
 Begins Apptentive SDK initialization. Does nothing if the SDK is already initialized.
 
 @return YES if SDK initialization was successful. NO - if the SDK was already initialized or failed to initialize.
 */
+ (BOOL)registerSDK;

@end
