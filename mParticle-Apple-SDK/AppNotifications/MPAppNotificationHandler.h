#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#if TARGET_OS_IOS == 1
    #import "MParticleUserNotification.h"
#endif

#if TARGET_OS_IOS == 1 && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
    @class UNUserNotificationCenter;
    @class UNNotification;
    @class UNNotificationResponse;
#endif

NS_ASSUME_NONNULL_BEGIN

@protocol MPAppNotificationHandlerProtocol

#if TARGET_OS_IOS == 1

- (void)didFailToRegisterForRemoteNotificationsWithError:(nullable NSError *)error;
- (void)didRegisterForRemoteNotificationsWithDeviceToken:(nonnull NSData *)deviceToken;
- (void)handleActionWithIdentifier:(nullable NSString *)identifier
             forRemoteNotification:(nullable NSDictionary *)userInfo;
- (void)handleActionWithIdentifier:(nullable NSString *)identifier
             forRemoteNotification:(nullable NSDictionary *)userInfo
                  withResponseInfo:(nullable NSDictionary *)responseInfo;
- (void)didReceiveRemoteNotification:(nonnull NSDictionary *)userInfo;
#endif

#if TARGET_OS_IOS == 1 && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
- (void)userNotificationCenter:(nonnull UNUserNotificationCenter *)center
      willPresentNotification:(nonnull UNNotification *)notification NS_AVAILABLE_IOS(10.0);

- (void)userNotificationCenter:(nonnull UNUserNotificationCenter *)center
   didReceiveNotificationResponse:(nonnull UNNotificationResponse *)response NS_AVAILABLE_IOS(10.0);
#endif

- (BOOL)continueUserActivity:(nonnull NSUserActivity *)userActivity
          restorationHandler:(void(^ _Nonnull)(NSArray<id<UIUserActivityRestoring>> * __nullable restorableObjects))restorationHandler;

- (void)openURL:(nonnull NSURL *)url options:(nullable NSDictionary<NSString *, id> *)options;

@end

NS_ASSUME_NONNULL_END

@interface MPAppNotificationHandler : NSObject<MPAppNotificationHandlerProtocol>
@end
