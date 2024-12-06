#import "MPSurrogateAppDelegate.h"
#import "MPAppDelegateProxy.h"
#import "MPNotificationController.h"
#import "MPAppNotificationHandler.h"
#import "mParticle.h"

@interface MParticle ()

@property (nonatomic, strong, readonly) MPStateMachine_PRIVATE *stateMachine;
@property (nonatomic, strong, readonly) MPAppNotificationHandler *appNotificationHandler;

@end

@interface MPSurrogateAppDelegate () {
    SEL applicationOpenURLOptionsSelector;
    NSArray *selectorArray;
}
@end

@implementation MPSurrogateAppDelegate

- (instancetype)init
{
    self = [super init];
    if (self) {
        applicationOpenURLOptionsSelector = @selector(application:openURL:options:);
        selectorArray = @[
                          [NSValue valueWithPointer:applicationOpenURLOptionsSelector]
#if TARGET_OS_IOS == 1
                          ,
                          [NSValue valueWithPointer:@selector(application:openURL:sourceApplication:annotation:)],
                          [NSValue valueWithPointer:@selector(application:didFailToRegisterForRemoteNotificationsWithError:)],
                          [NSValue valueWithPointer:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)],
                          [NSValue valueWithPointer:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:)],
                          [NSValue valueWithPointer:@selector(application:continueUserActivity:restorationHandler:)],
                          [NSValue valueWithPointer:@selector(application:didUpdateUserActivity:)]
#endif
                          ];
    }
    return self;
}

- (BOOL)implementsSelector:(SEL)aSelector {
    if (![selectorArray containsObject:[NSValue valueWithPointer:aSelector]]) {
        return NO;
    }
    
    if (aSelector == applicationOpenURLOptionsSelector && [[[UIDevice currentDevice] systemVersion] floatValue] < 9.0) {
        return NO;
    }
    
    return YES;
}

#pragma mark UIApplicationDelegate
#if TARGET_OS_IOS == 1

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    MPAppNotificationHandler *appNotificationHandler = [MParticle sharedInstance].appNotificationHandler;
    [appNotificationHandler didReceiveRemoteNotification:userInfo];
    
    if ([_appDelegateProxy.originalAppDelegate respondsToSelector:_cmd]) {
        [_appDelegateProxy.originalAppDelegate application:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
    } else {
        completionHandler(UIBackgroundFetchResultNewData);
    }
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [[MParticle sharedInstance].appNotificationHandler didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    
    if ([_appDelegateProxy.originalAppDelegate respondsToSelector:_cmd]) {
        [_appDelegateProxy.originalAppDelegate application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    }
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    [[MParticle sharedInstance].appNotificationHandler didFailToRegisterForRemoteNotificationsWithError:error];
    
    if ([_appDelegateProxy.originalAppDelegate respondsToSelector:_cmd]) {
        [_appDelegateProxy.originalAppDelegate application:application didFailToRegisterForRemoteNotificationsWithError:error];
    }
}


- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    [[MParticle sharedInstance].appNotificationHandler openURL:url sourceApplication:sourceApplication annotation:annotation];
    
    id<UIApplicationDelegate> originalAppDelegate = _appDelegateProxy.originalAppDelegate;
    if ([originalAppDelegate respondsToSelector:_cmd]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        return [originalAppDelegate application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
#pragma clang diagnostic pop
    }
    
    return NO;
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void(^ _Nonnull)(NSArray<id<UIUserActivityRestoring>> *restorableObjects))restorationHandler {
    [[MParticle sharedInstance].appNotificationHandler continueUserActivity:userActivity restorationHandler:restorationHandler];
    
    id<UIApplicationDelegate> originalAppDelegate = _appDelegateProxy.originalAppDelegate;
    if ([originalAppDelegate respondsToSelector:_cmd]) {
        return [originalAppDelegate application:application continueUserActivity:userActivity restorationHandler:restorationHandler];
    }
    
    return NO;
}

- (void)application:(UIApplication *)application didUpdateUserActivity:(NSUserActivity *)userActivity {
    [[MParticle sharedInstance].appNotificationHandler didUpdateUserActivity:userActivity];
    
    id<UIApplicationDelegate> originalAppDelegate = _appDelegateProxy.originalAppDelegate;
    if ([originalAppDelegate respondsToSelector:_cmd]) {
        [originalAppDelegate application:application didUpdateUserActivity:userActivity];
    }
}

#endif

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *, id> *)options {
    [[MParticle sharedInstance].appNotificationHandler openURL:url options:options];
    
    id<UIApplicationDelegate> originalAppDelegate = _appDelegateProxy.originalAppDelegate;
    if ([originalAppDelegate respondsToSelector:_cmd]) {
        return [originalAppDelegate application:app openURL:url options:options];
    }
    
    return NO;
}

@end
