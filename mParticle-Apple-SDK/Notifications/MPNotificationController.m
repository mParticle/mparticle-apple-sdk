#import "MPNotificationController.h"
#import "MPIConstants.h"
#import "MPPersistenceController.h"
#import "mParticle.h"
#import "MPNetworkCommunication.h"
#import "MParticleSwift.h"

@interface MPNotificationController_PRIVATE() {
}

@end

@interface MParticle ()

+ (dispatch_queue_t)messageQueue;
@property (nonatomic, strong, readonly) MPStateMachine_PRIVATE *stateMachine;
@property (nonatomic, strong, nonnull) MPBackendController_PRIVATE *backendController;

@end

#if TARGET_OS_IOS == 1
static NSData *deviceToken = nil;
#endif

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
+ (NSData *)deviceToken {
#ifndef MP_UNIT_TESTING
    MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
    deviceToken = userDefaults[kMPDeviceTokenKey];
#else
    deviceToken = [@"<000000000000000000000000000000>" dataUsingEncoding:NSUTF8StringEncoding];
#endif
    
    return deviceToken;
}

+ (void)setDeviceToken:(NSData *)devToken {
    if ([MPNotificationController_PRIVATE deviceToken] && [[MPNotificationController_PRIVATE deviceToken] isEqualToData:devToken]) {
        return;
    }
    
    NSData *newDeviceToken = [devToken copy];
    NSData *oldDeviceToken = [deviceToken copy];
    
    deviceToken = devToken;

    dispatch_async([MParticle messageQueue], ^{
        NSMutableDictionary *deviceTokenDictionary = [[NSMutableDictionary alloc] initWithCapacity:2];
        NSString *newTokenString = nil;
        NSString *oldTokenString = nil;
        if (newDeviceToken) {
            deviceTokenDictionary[kMPRemoteNotificationDeviceTokenKey] = newDeviceToken;
            newTokenString = [MPUserDefaults stringFromDeviceToken:newDeviceToken];
        }
        
        if (oldDeviceToken) {
            deviceTokenDictionary[kMPRemoteNotificationOldDeviceTokenKey] = oldDeviceToken;
            oldTokenString = [MPUserDefaults stringFromDeviceToken:oldDeviceToken];
        }

        [[NSNotificationCenter defaultCenter] postNotificationName:kMPRemoteNotificationDeviceTokenNotification
                                                            object:nil
                                                          userInfo:deviceTokenDictionary];
        
        if (oldTokenString && newTokenString) {
            [[MParticle sharedInstance].backendController.networkCommunication modifyDeviceID:@"push_token"
                                                                                        value:newTokenString
                                                                                     oldValue:oldTokenString];
        }
        
#ifndef MP_UNIT_TESTING
        MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
        userDefaults[kMPDeviceTokenKey] = deviceToken;
        [userDefaults synchronize];
#endif
    });
}

#endif

@end
