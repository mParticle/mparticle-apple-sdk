#import "MPNotificationController.h"
#import "MPIConstants.h"
#import "MPPersistenceController.h"
#import "mParticle.h"
#import "MPNetworkCommunication.h"
#import "MPUserDefaultsConnector.h"
@import mParticle_Apple_SDK_Swift;

@interface MParticle ()

+ (dispatch_queue_t)messageQueue;
@property (nonatomic, strong, readonly) MPStateMachine_PRIVATE *stateMachine;
@property (nonatomic, strong, nonnull) MPBackendController_PRIVATE *backendController;

@end

@implementation MPNotificationController_PRIVATE

#if TARGET_OS_IOS == 1

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    return self;
}

#pragma mark Public static methods

// Non-extractable: MPUserDefaults is reached through MPUserDefaultsConnector, an ObjC type
// the Swift module cannot import, so persistence stays here. The store owns the token itself.
- (NSData *)deviceToken {
#ifndef MP_UNIT_TESTING
    MPUserDefaults *userDefaults = MPUserDefaultsConnector.userDefaults;
    NSData *persistedToken = userDefaults[kMPDeviceTokenKey];
#else
    NSData *persistedToken = [@"<000000000000000000000000000000>" dataUsingEncoding:NSUTF8StringEncoding];
#endif

    return [MPDeviceTokenStore.shared adoptPersistedToken:persistedToken];
}

- (void)setDeviceToken:(NSData *)devToken {
    MPDeviceTokenChange *change = [MPDeviceTokenStore.shared changeToToken:devToken];
    if (!change) {
        return;
    }

    dispatch_async([MParticle messageQueue], ^{
        [MPDeviceTokenStore.shared postChange:change];

        // Non-extractable: MPNetworkCommunication is an ObjC type reached through MParticle's
        // private backendController extension above.
        if (change.shouldModifyDeviceID) {
            [[MParticle sharedInstance].backendController.networkCommunication modifyDeviceID:@"push_token"
                                                                                        value:change.newTokenString
                                                                                     oldValue:change.oldTokenString];
        }

#ifndef MP_UNIT_TESTING
        MPUserDefaults *userDefaults = MPUserDefaultsConnector.userDefaults;
        userDefaults[kMPDeviceTokenKey] = MPDeviceTokenStore.shared.currentToken;
        [userDefaults synchronize];
#endif
    });
}

#endif

@end
