<!-- markdownlint-disable MD024 -->

# Migration Guides

This document provides migration guidance for breaking changes in the mParticle Apple SDK.

## Migrating from versions < 9.0.0

### Removed AppDelegateProxy

The `AppDelegateProxy` feature has been removed from the SDK. This feature previously allowed the SDK to automatically intercept `UIApplicationDelegate` messages to handle push notifications, URL opening, and user activity events without requiring explicit calls from your app delegate.

#### What Has Changed

- The `proxyAppDelegate` property has been removed from `MParticleOptions`
- The `proxiedAppDelegate` property has been removed from `MParticle`
- The `MPAppDelegateProxy` and `MPSurrogateAppDelegate` classes have been removed

#### Migration Steps

If you were using `proxyAppDelegate = YES` (which was the default), you must now explicitly forward app delegate events to the SDK.

##### Push Notifications

**After (Objective-C):**

```objective-c
// In AppDelegate
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [[MParticle sharedInstance] didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    [[MParticle sharedInstance] didFailToRegisterForRemoteNotificationsWithError:error];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [[MParticle sharedInstance] didReceiveRemoteNotification:userInfo];
    completionHandler(UIBackgroundFetchResultNewData);
}
```

**After (Swift):**

```swift
// In AppDelegate
func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    MParticle.sharedInstance().didRegisterForRemoteNotifications(withDeviceToken: deviceToken)
}

func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    MParticle.sharedInstance().didFailToRegisterForRemoteNotificationsWithError(error)
}

func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    MParticle.sharedInstance().didReceiveRemoteNotification(userInfo)
    completionHandler(.newData)
}
```

##### URL Handling and User Activity

For URL handling and user activity (universal links), use the `UIScene` lifecycle methods as described in the "Removed Deprecated UIApplicationDelegate Methods" section below.

#### Notes

- If you were already using `proxyAppDelegate = NO`, no changes are required
- Remove any references to `proxyAppDelegate` from your `MParticleOptions` configuration
- Remove any references to `proxiedAppDelegate` property checks

---

### Removed Legacy Database Migration Support

Support for migrating from SDK versions prior to **SDK 8.27.0** (internal database version < 30) has been removed. Only migration from the immediately preceding database version (v30 → v31) is now supported.

#### What This Means

- Apps upgrading from **SDK 8.26.x or earlier** to SDK 9.x will start with a fresh local database
- Any pending (unsent) events from the old SDK version will be lost during this upgrade
- User identity and session data will be re-established after the upgrade

#### Affected Users

This change only affects users who:

1. Are upgrading directly from mParticle SDK versions **before 8.27.0** (released August 2024)
2. Have pending events that have not yet been uploaded to mParticle

---

### Removed MPListenerController

The `MPListenerController` class has been removed. The SDK no longer invokes any listener callbacks.

### Removed Deprecated UIApplicationDelegate Methods

Apple has deprecated several `UIApplicationDelegate` protocol methods in favor of the modern `UIScene` lifecycle introduced in iOS 13. The mParticle SDK previously provided wrapper methods for these deprecated delegate methods, but these have been removed as they are scheduled for removal by Apple in iOS 27.

#### What Has Changed

The following methods have been removed from the `MParticle` class:

- `openURL:sourceApplication:annotation:`
- `openURL:options:`
- `continueUserActivity:restorationHandler:`

#### Migration Steps

##### URL Handling

**Before (Objective-C):**

```objective-c
// In AppDelegate
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    [[MParticle sharedInstance] openURL:url options:options];
    return YES;
}
```

**After (Objective-C):**

```objective-c
// In SceneDelegate
- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts {
    for (UIOpenURLContext *urlContext in URLContexts) {
        [[MParticle sharedInstance] handleURLContext:urlContext];
    }
}
```

**Before (Swift):**

```swift
// In AppDelegate
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    MParticle.sharedInstance().open(url, options: options)
    return true
}
```

**After (Swift):**

```swift
// In SceneDelegate
func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    for urlContext in URLContexts {
        MParticle.sharedInstance().handleURLContext(urlContext)
    }
}
```

##### User Activity Handling (Universal Links, Handoff, etc.)

**Before (Objective-C):**

```objective-c
// In AppDelegate
- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> *restorableObjects))restorationHandler {
    [[MParticle sharedInstance] continueUserActivity:userActivity restorationHandler:restorationHandler];
    return YES;
}
```

**After (Objective-C):**

```objective-c
// In SceneDelegate
- (void)scene:(UIScene *)scene continueUserActivity:(NSUserActivity *)userActivity {
    [[MParticle sharedInstance] handleUserActivity:userActivity];
}
```

**Before (Swift):**

```swift
// In AppDelegate
func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    MParticle.sharedInstance().continue(userActivity, restorationHandler: restorationHandler)
    return true
}
```

**After (Swift):**

```swift
// In SceneDelegate
func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    MParticle.sharedInstance().handleUserActivity(userActivity)
}
```

#### Notes

- The new methods `handleURLContext:` and `handleUserActivity:` are designed to work with the `UIScene` lifecycle
- `handleURLContext:` is available on iOS 13.0 and above
- If you are still using the `UIApplicationDelegate` lifecycle without scenes, consider migrating to the `UIScene` lifecycle as Apple continues to deprecate the older approach
- For apps that must support iOS versions below 13, you may need to maintain both code paths with appropriate availability checks

---

## Migrating from versions < 8.0.0

For migration guidance from SDK 7.x to SDK 8.x, please see [migration-guide-v8.md](migration-guide-v8.md).
