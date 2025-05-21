#import "MPAppNotificationHandler.h"
#import "MParticleSwift.h"
#import "MPForwardRecord.h"
#import "MPPersistenceController.h"
#import "MPILogger.h"
#import "MPKitContainer.h"
#import "MPKitExecStatus.h"
#import <UIKit/UIKit.h>
#import "MPForwardQueueParameters.h"
#import "MPKitAPI.h"
#import "MPApplication.h"
#import "mParticle.h"

#if TARGET_OS_IOS == 1
    #import "MPNotificationController.h"
#endif

#if TARGET_OS_IOS == 1 && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
    #import <UserNotifications/UserNotifications.h>
#endif

@interface MParticle ()

@property (nonatomic, strong, readonly) MPBackendController_PRIVATE *backendController;
@property (nonatomic, strong, readonly) MPPersistenceController_PRIVATE *persistenceController;
@property (nonatomic, strong, readonly) MPStateMachine_PRIVATE *stateMachine;
+ (dispatch_queue_t)messageQueue;

@end

@interface MPKitAPI ()
- (id)initWithKitCode:(NSNumber *)integrationId;
@end

@interface MPForwardRecord ()
- (nonnull instancetype)initWithMessageType:(MPMessageType)messageType execStatus:(nonnull MPKitExecStatus *)execStatus;
@end

@implementation MPAppNotificationHandler

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    return self;
}

#pragma mark Public methods
#if TARGET_OS_IOS == 1
- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    if ([MParticle sharedInstance].stateMachine.optOut) {
        return;
    }
    
    if (![MPStateMachine_PRIVATE isAppExtension]) {
        [MPNotificationController_PRIVATE setDeviceToken:nil];
    }
    
    SEL failedRegistrationSelector = @selector(failedToRegisterForUserNotifications:);
    
    MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
    [queueParameters addParameter:error];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[MParticle sharedInstance].kitContainer_PRIVATE forwardSDKCall:failedRegistrationSelector
                                                          event:nil
                                                     parameters:queueParameters
                                                    messageType:MPMessageTypeUnknown
                                                       userInfo:nil
         ];
    });
}

- (BOOL)is9 {
    return [[[UIDevice currentDevice] systemVersion] floatValue] < 10.0;
}

- (BOOL)hasContentAvail:(NSDictionary *)dict {
    NSDictionary *aps = dict[@"aps"];
    NSString *contentAvail = aps[@"content-available"];
    return [contentAvail isEqual:@1];
}

- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    if ([MParticle sharedInstance].stateMachine.optOut) {
        return;
    }
    
    if (![MPStateMachine_PRIVATE isAppExtension]) {
        [MPNotificationController_PRIVATE setDeviceToken:deviceToken];
    }

    SEL deviceTokenSelector = @selector(setDeviceToken:);
    
    MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
    [queueParameters addParameter:deviceToken];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[MParticle sharedInstance].kitContainer_PRIVATE forwardSDKCall:deviceTokenSelector
                                                          event:nil
                                                     parameters:queueParameters
                                                    messageType:MPMessageTypePushRegistration
                                                       userInfo:@{@"state":@1}
         ];
    });
}

- (void)handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo {
    if ([MParticle sharedInstance].stateMachine.optOut) {
        return;
    }
    
    SEL handleActionWithIdentifierSelector = @selector(handleActionWithIdentifier:forRemoteNotification:);
    
    MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
    [queueParameters addParameter:identifier];
    [queueParameters addParameter:userInfo];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[MParticle sharedInstance].kitContainer_PRIVATE forwardSDKCall:handleActionWithIdentifierSelector
                                                          event:nil
                                                     parameters:queueParameters
                                                    messageType:MPMessageTypeUnknown
                                                       userInfo:nil
         ];
    });
}

- (void)handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo withResponseInfo:(NSDictionary *)responseInfo {
    if ([MParticle sharedInstance].stateMachine.optOut) {
        return;
    }
    
    SEL handleActionWithIdentifierSelector = @selector(handleActionWithIdentifier:forRemoteNotification:withResponseInfo:);
    
    MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
    [queueParameters addParameter:identifier];
    [queueParameters addParameter:userInfo];
    [queueParameters addParameter:responseInfo];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[MParticle sharedInstance].kitContainer_PRIVATE forwardSDKCall:handleActionWithIdentifierSelector
                                                          event:nil
                                                     parameters:queueParameters
                                                    messageType:MPMessageTypeUnknown
                                                       userInfo:nil
         ];
    });
}

- (void) didReceiveRemoteNotification:(NSDictionary *)userInfo {
    if ([MParticle sharedInstance].stateMachine.optOut || !userInfo) {
        return;
    }
    
    if ([MParticle sharedInstance].trackNotifications) {
        if ([self is9]) {
            UIApplicationState state = [MPApplication_PRIVATE sharedUIApplication].applicationState;
            if (state != UIApplicationStateActive || ![self hasContentAvail:userInfo]) {
                [[MParticle sharedInstance] logNotificationOpenedWithUserInfo:userInfo andActionIdentifier:nil];
            }else {
                [[MParticle sharedInstance] logNotificationReceivedWithUserInfo:userInfo];
            }
        } else {
            if ([self hasContentAvail:userInfo]) {
                [[MParticle sharedInstance] logNotificationReceivedWithUserInfo:userInfo];
            }
        }
    }

    SEL receivedNotificationSelector = @selector(receivedUserNotification:);
    
    MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
    [queueParameters addParameter:userInfo];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[MParticle sharedInstance].kitContainer_PRIVATE forwardSDKCall:receivedNotificationSelector
                                                          event:nil
                                                     parameters:queueParameters
                                                    messageType:MPMessageTypePushNotification
                                                       userInfo:userInfo
         ];
    });
}

- (void)didUpdateUserActivity:(nonnull NSUserActivity *)userActivity {
    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
    if (stateMachine.optOut) {
        return;
    }
    
    SEL didUpdateUserActivitySelector = @selector(didUpdateUserActivity:);
    
    MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
    [queueParameters addParameter:userActivity];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[MParticle sharedInstance].kitContainer_PRIVATE forwardSDKCall:didUpdateUserActivitySelector
                                                          event:nil
                                             parameters:queueParameters
                                            messageType:MPMessageTypeUnknown
                                                       userInfo:nil
         ];
    });
}
#endif

#if TARGET_OS_IOS == 1 && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
- (void)userNotificationCenter:(nonnull UNUserNotificationCenter *)center willPresentNotification:(nonnull UNNotification *)notification {
    if ([MParticle sharedInstance].stateMachine.optOut || !notification.request.content.userInfo) {
        return;
    }
    
    if ([MParticle sharedInstance].trackNotifications && ![self hasContentAvail:notification.request.content.userInfo]) {
        [[MParticle sharedInstance] logNotificationReceivedWithUserInfo:notification.request.content.userInfo];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        SEL userNotificationCenterWillPresentNotification = @selector(userNotificationCenter:willPresentNotification:);
        NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [[MParticle sharedInstance].kitContainer_PRIVATE activeKitsRegistry];
        
        for (id<MPExtensionKitProtocol> kitRegister in activeKitsRegistry) {
            if ([kitRegister.wrapperInstance respondsToSelector:userNotificationCenterWillPresentNotification]) {
                MPKitExecStatus *execStatus = [kitRegister.wrapperInstance userNotificationCenter:center willPresentNotification:notification];
                
                if (execStatus.success) {
                    MPForwardRecord *forwardRecord = [[MPForwardRecord alloc] initWithMessageType:MPMessageTypePushNotification execStatus:execStatus];
                    
                    dispatch_async([MParticle messageQueue], ^{
                        [[MParticle sharedInstance].persistenceController saveForwardRecord:forwardRecord];
                    });
                    
                    MPILogDebug(@"Forwarded user notifications call to kit: %@", kitRegister.name);
                }
            }
        }
    });
}

- (void)userNotificationCenter:(nonnull UNUserNotificationCenter *)center didReceiveNotificationResponse:(nonnull UNNotificationResponse *)response {
    if ([MParticle sharedInstance].stateMachine.optOut) {
        return;
    }
    
    if (!response.notification.request.content.userInfo) {
        return;
    }
    
    if ([MParticle sharedInstance].trackNotifications && ![response.actionIdentifier isEqual:UNNotificationDismissActionIdentifier]) {
        [[MParticle sharedInstance] logNotificationOpenedWithUserInfo:response.notification.request.content.userInfo andActionIdentifier:response.actionIdentifier];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        SEL userNotificationCenterDidReceiveNotificationResponse = @selector(userNotificationCenter:didReceiveNotificationResponse:);
        NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [[MParticle sharedInstance].kitContainer_PRIVATE activeKitsRegistry];

        for (id<MPExtensionKitProtocol> kitRegister in activeKitsRegistry) {
            if ([kitRegister.wrapperInstance respondsToSelector:userNotificationCenterDidReceiveNotificationResponse]) {
                MPKitExecStatus *execStatus = [kitRegister.wrapperInstance userNotificationCenter:center didReceiveNotificationResponse:response];
                
                if (execStatus.success) {
                    MPForwardRecord *forwardRecord = [[MPForwardRecord alloc] initWithMessageType:MPMessageTypePushNotificationInteraction execStatus:execStatus];
                    
                    dispatch_async([MParticle messageQueue], ^{
                        [[MParticle sharedInstance].persistenceController saveForwardRecord:forwardRecord];
                    });
                    
                    MPILogDebug(@"Forwarded user notifications response call to kit: %@", kitRegister.name);
                }
            }
        }
    });
}
#endif

- (BOOL)continueUserActivity:(nonnull NSUserActivity *)userActivity restorationHandler:(void(^ _Nonnull)(NSArray<id<UIUserActivityRestoring>> * __nullable restorableObjects))restorationHandler {
    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
    if (stateMachine.optOut) {
        return NO;
    }
    
    if (userActivity.webpageURL != nil) {
        stateMachine.launchInfo = [[MPLaunchInfo alloc] initWithURL:userActivity.webpageURL options:nil];
    } else {
        NSURL *defaultURL = [[NSURL alloc] initWithString:@""];
        stateMachine.launchInfo = [[MPLaunchInfo alloc] initWithURL:defaultURL options:nil];
    }
    
    SEL continueUserActivitySelector = @selector(continueUserActivity:restorationHandler:);
    
    MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
    [queueParameters addParameter:userActivity];
    [queueParameters addParameter:restorationHandler];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[MParticle sharedInstance].kitContainer_PRIVATE forwardSDKCall:continueUserActivitySelector
                                                          event:nil
                                                     parameters:queueParameters
                                                    messageType:MPMessageTypeUnknown
                                                       userInfo:nil
         ];
    });
    
    NSSet<id<MPExtensionKitProtocol>> *registeredKitsRegistry = [MPKitContainer_PRIVATE registeredKits];
    BOOL handlingActivity = NO;
    for (id<MPExtensionKitProtocol> kitRegister in registeredKitsRegistry) {
        if ([kitRegister.wrapperInstance respondsToSelector:continueUserActivitySelector]) {
            handlingActivity = YES;
            break;
        }
    }
    
    return handlingActivity;
}

- (void)openURL:(NSURL *)url options:(NSDictionary<NSString *, id> *)options {
    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
    if (stateMachine.optOut) {
        return;
    }
    
    stateMachine.launchInfo = [[MPLaunchInfo alloc] initWithURL:url options:options];
    
    SEL openURLOptionsSelector = @selector(openURL:options:);
    
    MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
    [queueParameters addParameter:url];
    [queueParameters addParameter:options];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[MParticle sharedInstance].kitContainer_PRIVATE forwardSDKCall:openURLOptionsSelector
                                                          event:nil
                                                     parameters:queueParameters
                                                    messageType:MPMessageTypeUnknown
                                                       userInfo:nil
         ];
    });
}

- (void)openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
    if (stateMachine.optOut) {
        return;
    }
    
    stateMachine.launchInfo = [[MPLaunchInfo alloc] initWithURL:url
                                              sourceApplication:sourceApplication
                                                     annotation:annotation];
    
    SEL openURLSourceAppAnnotationSelector = @selector(openURL:sourceApplication:annotation:);
    
    MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
    [queueParameters addParameter:url];
    [queueParameters addParameter:sourceApplication];
    [queueParameters addParameter:annotation];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[MParticle sharedInstance].kitContainer_PRIVATE forwardSDKCall:openURLSourceAppAnnotationSelector
                                                          event:nil
                                                     parameters:queueParameters
                                                    messageType:MPMessageTypeUnknown
                                                       userInfo:nil
         ];
    });
}

@end
