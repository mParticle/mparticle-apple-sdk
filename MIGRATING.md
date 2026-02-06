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

---

### Source-Based Distribution Changes

As part of the transition from binary (XCFramework) to source-based distribution, several public Swift classes have been converted to Objective-C. This improves compatibility with Swift Package Manager and reduces integration complexity, but may require code changes for Swift users who were referencing Swift-specific type hierarchies.

#### MPRoktEvent Classes Moved to Top-Level

The `MPRoktEvent` subclasses have been converted from Swift nested classes to Objective-C top-level classes. This changes how Swift users reference these types.

**Before (Swift):**

```swift
let initEvent = MPRoktEvent.MPRoktInitComplete(success: true)
let readyEvent = MPRoktEvent.MPRoktPlacementReady(placementId: "abc")
let purchaseEvent = MPRoktEvent.MPRoktCartItemInstantPurchase(...)
```

**After (Swift):**

```swift
let initEvent = MPRoktInitComplete(success: true)
let readyEvent = MPRoktPlacementReady(placementId: "abc")
let purchaseEvent = MPRoktCartItemInstantPurchase(...)
```

**Affected Classes:**

| Before (Swift)                              | After (Swift)                   |
| ------------------------------------------- | ------------------------------- |
| `MPRoktEvent.MPRoktInitComplete`            | `MPRoktInitComplete`            |
| `MPRoktEvent.MPRoktShowLoadingIndicator`    | `MPRoktShowLoadingIndicator`    |
| `MPRoktEvent.MPRoktHideLoadingIndicator`    | `MPRoktHideLoadingIndicator`    |
| `MPRoktEvent.MPRoktPlacementInteractive`    | `MPRoktPlacementInteractive`    |
| `MPRoktEvent.MPRoktPlacementReady`          | `MPRoktPlacementReady`          |
| `MPRoktEvent.MPRoktOfferEngagement`         | `MPRoktOfferEngagement`         |
| `MPRoktEvent.MPRoktOpenUrl`                 | `MPRoktOpenUrl`                 |
| `MPRoktEvent.MPRoktPositiveEngagement`      | `MPRoktPositiveEngagement`      |
| `MPRoktEvent.MPRoktPlacementClosed`         | `MPRoktPlacementClosed`         |
| `MPRoktEvent.MPRoktPlacementCompleted`      | `MPRoktPlacementCompleted`      |
| `MPRoktEvent.MPRoktPlacementFailure`        | `MPRoktPlacementFailure`        |
| `MPRoktEvent.MPRoktFirstPositiveEngagement` | `MPRoktFirstPositiveEngagement` |
| `MPRoktEvent.MPRoktCartItemInstantPurchase` | `MPRoktCartItemInstantPurchase` |

**Migration Steps:**

1. Find all usages of `MPRoktEvent.MPRokt*` in your Swift code
2. Remove the `MPRoktEvent.` prefix
3. Type checking with `is` remains unchanged since they still inherit from `MPRoktEvent`

**Notes:**

- Objective-C users are not affected by this change
- The `MPRoktEvent` base class still exists and can be used for type checking
- All initializers and properties remain the same

---

### Direct Routing Enabled by Default

API requests now route directly to regional endpoints based on your API key prefix:

**Before:**

- `nativesdks.mparticle.com`
- `tracking-nativesdks.mparticle.com`
- `identity.mparticle.com`
- `tracking-identity.mparticle.com`
- `config2.mparticle.com`

**After:**

- `nativesdks.[pod].mparticle.com`
- `tracking-nativesdks.[pod].mparticle.com`
- `identity.[pod].mparticle.com`
- `tracking-identity.[pod].mparticle.com`
- `config2.mparticle.com`

> [!NOTE]
> The `config2.mparticle.com` subdomain is used to fetch SDK configuration and will not change.

Examples:

| API Key Format              | Events Endpoint                | Events Tracking Endpoint                | Identity Endpoint            | Identity Tracking Endpoint            |
| --------------------------- | ------------------------------ | --------------------------------------- | ---------------------------- | ------------------------------------- |
| `xxxxx` (legacy, no prefix) | `nativesdks.us1.mparticle.com` | `tracking-nativesdks.us1.mparticle.com` | `identity.us1.mparticle.com` | `tracking-identity.us1.mparticle.com` |
| `us1-xxxxx`                 | `nativesdks.us1.mparticle.com` | `tracking-nativesdks.us1.mparticle.com` | `identity.us1.mparticle.com` | `tracking-identity.us1.mparticle.com` |
| `us2-xxxxx`                 | `nativesdks.us2.mparticle.com` | `tracking-nativesdks.us2.mparticle.com` | `identity.us2.mparticle.com` | `tracking-identity.us2.mparticle.com` |
| `eu1-xxxxx`                 | `nativesdks.eu1.mparticle.com` | `tracking-nativesdks.eu1.mparticle.com` | `identity.eu1.mparticle.com` | `tracking-identity.eu1.mparticle.com` |
| `au1-xxxxx`                 | `nativesdks.au1.mparticle.com` | `tracking-nativesdks.au1.mparticle.com` | `identity.au1.mparticle.com` | `tracking-identity.au1.mparticle.com` |

> [!NOTE]
> If your app has strict App Transport Security (ATS) settings, you may need to add `NSIncludesSubdomains` set to `YES` for the `mparticle.com` domain in your Info.plist to allow connections to regional subdomains.

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

### Removed Location Support

In version 9.0.0, Location support has been removed from the SDK. This change simplifies the SDK distribution and affects the available build targets.

#### What Has Changed

- Location-related functionality has been removed
- The SDK now provides a single target without Location support
- The target name has been simplified to match the base target name (the Location suffix has been removed)

#### Migration Steps

If you were previously using a target with Location support, you should:

1. Update your project configuration to use the standard target (without Location suffix)
2. Remove any Location-related dependencies or imports
3. Update any build scripts or CI/CD configurations that reference the Location-specific target name

**If you were using the `NoLocation` variant** (e.g., `mParticle-Apple-SDK-NoLocation`), you should:

1. Replace the `NoLocation` import/product with the standard import/product name (`mParticle-Apple-SDK`)
2. The standard target now provides the same functionality as the previous `NoLocation` variant (no location support)
3. Update your `Package.swift` or `Podfile` to use the standard target name instead of the `-NoLocation` suffix

**Example - Swift Package Manager:**

Before (using `NoLocation` variant):

```swift
.target(
    name: "MyTarget",
    dependencies: [
        .product(name: "mParticle-Apple-SDK-NoLocation", package: "mParticle-Apple-SDK")
    ]
)
```

After (using standard target):

```swift
.target(
    name: "MyTarget",
    dependencies: [
        .product(name: "mParticle-Apple-SDK", package: "mParticle-Apple-SDK")
    ]
)
```

**Example - Direct dependency:**

Before:

```swift
dependencies: [
    .package(url: "https://github.com/mParticle/mparticle-apple-sdk", from: "8.0.0")
],
targets: [
    .target(
        name: "MyApp",
        dependencies: [
            .product(name: "mParticle-Apple-SDK-NoLocation", package: "mParticle-Apple-SDK")
        ]
    )
]
```

After:

```swift
dependencies: [
    .package(url: "https://github.com/mParticle/mparticle-apple-sdk", from: "9.0.0")
],
targets: [
    .target(
        name: "MyApp",
        dependencies: [
            .product(name: "mParticle-Apple-SDK", package: "mParticle-Apple-SDK")
        ]
    )
]
```

#### Notes

- The simplified target name now matches the base SDK target name
- All core SDK functionality remains available through the standard target
- Location-related features are no longer available in the SDK

---

## Migrating from versions < 8.0.0

For migration guidance from SDK 7.x to SDK 8.x, please see [migration-guide-v8.md](migration-guide-v8.md).
