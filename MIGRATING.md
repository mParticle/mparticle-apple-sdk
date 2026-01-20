# Migration Guides

This document provides migration guidance for breaking changes in the mParticle Apple SDK.

## Migrating from versions < 9.0.0

### Removed MPListenerController

The `MPListenerController` class has been removed. The SDK no longer invokes any listener callbacks.

### Direct Routing Enabled by Default

API requests now route directly to regional endpoints based on your API key prefix:

| API Key Format              | Endpoint Example               |
| --------------------------- | ------------------------------ |
| `us1-xxxxx`                 | `nativesdks.us1.mparticle.com` |
| `us2-xxxxx`                 | `nativesdks.us2.mparticle.com` |
| `eu1-xxxxx`                 | `nativesdks.eu1.mparticle.com` |
| `au1-xxxxx`                 | `nativesdks.au1.mparticle.com` |
| `xxxxx` (legacy, no prefix) | `nativesdks.us1.mparticle.com` |

Apps with network security policies should allow these regional subdomains. If you use App Transport Security with custom exceptions or allowlists, update them to permit the relevant hosts (for example, `*.us1.mparticle.com`, `*.eu1.mparticle.com`).

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
