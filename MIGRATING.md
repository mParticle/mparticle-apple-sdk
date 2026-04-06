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

### MPRokt API Changes

The `MPRokt` interface has been updated to align with the Rokt SDK 5.0.x API. These changes consolidate multiple callback parameters into a unified event-based callback pattern and standardize parameter naming.

#### What Has Changed

- The `MPRoktEventCallback` class has been removed; the `selectPlacements:` method's `callbacks:` parameter has been replaced with `onEvent:`
- `MPRoktEvent` and all its subclasses have been removed; event types are now provided by the `RoktContracts` library (`rokt-contracts-apple`) and are shared with the Rokt iOS SDK
- The `purchaseFinalized:` method's `placementId:` parameter has been renamed to `identifier:`
- A new `globalEvents:` method has been added for subscribing to global Rokt events
- New `registerPaymentExtension:` and `selectShoppableAds:` methods have been added for Shoppable Ads support

#### Import Changes

Since event types now come from the `RoktContracts` library instead of the SDK itself, the import requirements have changed:

**Objective-C:**

Objective-C callers must add `@import RoktContracts;` to access `RoktEvent` types (e.g., `RoktPlacementReady`, `RoktShowLoadingIndicator`) used in the `onEvent:` callbacks:

```objective-c
@import mParticle_Apple_SDK_ObjC;
@import RoktContracts;
```

**Swift:**

A single import provides access to all `MPRokt` methods and `RoktEvent` types — no additional imports are needed:

```swift
import mParticle_Apple_SDK
```

> **Note:** In previous betas, Swift callers needed a second `import mParticle_Rokt_Swift` to access MPRokt APIs that use `RoktContracts` types. This is no longer required.

#### Migration Steps

##### selectPlacements Method

**Before (Objective-C):**

```objective-c
MPRoktEventCallback *callbacks = [[MPRoktEventCallback alloc] init];
callbacks.onLoad = ^{
    // Handle load
};
callbacks.onUnLoad = ^{
    // Handle unload
};
callbacks.onShouldShowLoadingIndicator = ^{
    // Show loading indicator
};
callbacks.onShouldHideLoadingIndicator = ^{
    // Hide loading indicator
};
callbacks.onEmbeddedSizeChange = ^(NSString *placementId, CGFloat height) {
    // Handle size change
};

[[MParticle sharedInstance].rokt selectPlacements:@"checkout"
                                       attributes:attributes
                                    embeddedViews:embeddedViews
                                           config:config
                                        callbacks:callbacks];
```

**After (Objective-C):**

```objective-c
[[MParticle sharedInstance].rokt selectPlacements:@"checkout"
                                       attributes:attributes
                                    embeddedViews:embeddedViews
                                           config:config
                                          onEvent:^(RoktEvent * _Nonnull event) {
    if ([event isKindOfClass:[RoktShowLoadingIndicator class]]) {
        // Show loading indicator
    } else if ([event isKindOfClass:[RoktHideLoadingIndicator class]]) {
        // Hide loading indicator
    } else if ([event isKindOfClass:[RoktPlacementReady class]]) {
        // Handle load/ready
    } else if ([event isKindOfClass:[RoktPlacementClosed class]]) {
        // Handle unload/closed
    } else if ([event isKindOfClass:[RoktEmbeddedSizeChanged class]]) {
        RoktEmbeddedSizeChanged *sizeEvent = (RoktEmbeddedSizeChanged *)event;
        // Handle size change with sizeEvent.identifier and sizeEvent.updatedHeight
    }
}];
```

**Before (Swift):**

```swift
let callbacks = MPRoktEventCallback()
callbacks.onLoad = {
    // Handle load
}
callbacks.onUnLoad = {
    // Handle unload
}
callbacks.onShouldShowLoadingIndicator = {
    // Show loading indicator
}
callbacks.onShouldHideLoadingIndicator = {
    // Hide loading indicator
}
callbacks.onEmbeddedSizeChange = { placementId, height in
    // Handle size change
}

MParticle.sharedInstance().rokt.selectPlacements("checkout",
                                                  attributes: attributes,
                                                  embeddedViews: embeddedViews,
                                                  config: config,
                                                  callbacks: callbacks)
```

**After (Swift):**

```swift
MParticle.sharedInstance().rokt.selectPlacements("checkout",
                                                  attributes: attributes,
                                                  embeddedViews: embeddedViews,
                                                  config: config) { event in
    switch event {
    case is RoktEvent.ShowLoadingIndicator:
        // Show loading indicator
    case is RoktEvent.HideLoadingIndicator:
        // Hide loading indicator
    case is RoktEvent.PlacementReady:
        // Handle load/ready
    case is RoktEvent.PlacementClosed:
        // Handle unload/closed
    case let sizeEvent as RoktEvent.EmbeddedSizeChanged:
        // Handle size change with sizeEvent.identifier and sizeEvent.updatedHeight
    default:
        break
    }
}
```

##### purchaseFinalized Method

**(Objective-C):**

```objective-c
[[MParticle sharedInstance].rokt purchaseFinalized:@"checkout"
                                     catalogItemId:@"item123"
                                           success:YES];
```

Note: The method signature remains the same, but the parameter name has changed from `placementId:` to `identifier:`. If you're using named parameters, update accordingly.

##### events Method

The `events:onEvent:` method name is unchanged, but the callback parameter type has changed from `MPRoktEvent` to `RoktEvent` (from the `RoktContracts` library). This aligns with the same event types used by `selectPlacements:onEvent:` and the Rokt SDK directly.

**Before (Objective-C):**

```objective-c
[[MParticle sharedInstance].rokt events:@"checkout" onEvent:^(MPRoktEvent * _Nonnull event) {
    // Handle event
}];
```

**After (Objective-C):**

```objective-c
[[MParticle sharedInstance].rokt events:@"checkout" onEvent:^(RoktEvent * _Nonnull event) {
    if ([event isKindOfClass:[RoktPlacementReady class]]) {
        // Handle placement ready
    } else if ([event isKindOfClass:[RoktPlacementClosed class]]) {
        // Handle placement closed
    }
}];
```

**Before (Swift):**

```swift
MParticle.sharedInstance().rokt.events("checkout") { (event: MPRoktEvent) in
    // Handle event
}
```

**After (Swift):**

```swift
MParticle.sharedInstance().rokt.events("checkout") { event in
    switch event {
    case is RoktEvent.PlacementReady:
        // Handle placement ready
    case is RoktEvent.PlacementClosed:
        // Handle placement closed
    default:
        break
    }
}
```

##### New globalEvents Method

The new `globalEvents:` method allows you to subscribe to global Rokt events from all sources, including events not associated with a specific view (such as `InitComplete`).

**Objective-C:**

```objective-c
[[MParticle sharedInstance].rokt globalEvents:^(RoktEvent * _Nonnull event) {
    if ([event isKindOfClass:[RoktInitComplete class]]) {
        RoktInitComplete *initEvent = (RoktInitComplete *)event;
        if (initEvent.success) {
            // Rokt SDK initialized successfully
        }
    }
}];
```

**Swift:**

```swift
MParticle.sharedInstance().rokt.globalEvents { event in
    if let initEvent = event as? RoktEvent.InitComplete {
        if initEvent.success {
            // Rokt SDK initialized successfully
        }
    }
}
```

##### New Shoppable Ads APIs

SDK 9.0.0 adds `registerPaymentExtension:` and `selectShoppableAds:` to `MPRokt`. For integration details and code examples, see the [Rokt Integration section in the README](README.md#rokt-integration).

#### Event Mapping Reference

In Objective-C, use the flat class name; in Swift, use the nested form `RoktEvent.<Name>`.

| Old Callback                   | ObjC Class                 | Swift Type                       |
| ------------------------------ | -------------------------- | -------------------------------- |
| `onLoad`                       | `RoktPlacementReady`       | `RoktEvent.PlacementReady`       |
| `onUnLoad`                     | `RoktPlacementClosed`      | `RoktEvent.PlacementClosed`      |
| `onShouldShowLoadingIndicator` | `RoktShowLoadingIndicator` | `RoktEvent.ShowLoadingIndicator` |
| `onShouldHideLoadingIndicator` | `RoktHideLoadingIndicator` | `RoktEvent.HideLoadingIndicator` |
| `onEmbeddedSizeChange`         | `RoktEmbeddedSizeChanged`  | `RoktEvent.EmbeddedSizeChanged`  |

#### Notes

- The `onEvent` callback receives all event types; use type checking to handle specific events
- `RoktEmbeddedSizeChanged` provides `identifier` and `updatedHeight` properties
- Shoppable Ads placements emit additional events: `RoktEvent.CartItemInstantPurchase`, `RoktEvent.CartItemInstantPurchaseFailure`, `RoktEvent.InstantPurchaseDismissal`, and `RoktEvent.CartItemDevicePay`
- Remove any references to `MPRoktEventCallback` and `MPRoktEvent` subclasses from your code
- All `MPRokt` methods are directly accessible in both Objective-C and Swift — no separate interop import needed
- Calling `selectShoppableAds` automatically logs a `selectShoppableAds` custom event to mParticle

## Migrating from versions < 8.0.0

Apple's new App Tracking Transparency (ATT) framework and the respective App Store review guidelines introduce industry-shifting, privacy-focused changes. Under the latest guidelines, device data must only be used for "cross-application tracking" after the device has opted-in via the new ATT framework. mParticle acts an extension of your data infrastructure, and it's your responsibility to adhere to Apple's guidelines and respect user privacy by auditing the integrations you use and where end-user data is sent.

The mParticle platform has been adapting to these changes and we've made several critical API and SDK updates to ensure the best development experience and allow for conditional data-flows based on an end user's ATT authorization. This guide contains a quick overview of the changes Apple is introducing with iOS 14 and includes an SDK migration guide so that you can easily upgrade to the latest mParticle SDK.

### What's Changing?

- Apple's iOS 14, tvOS 14, iPadOS 14, and Xcode 12 were released September 16th, 2020. This introduced the new ATT framework, but did not include the enforcement of its usage.
- mParticle released Apple SDK 8.0.1 in September 2020, removing the automatic-query of the IDFA from the SDK and other changes detailed below
- mParticle released Apple SDK 8.2.0 in February 2021, in anticipation of the iOS 14.5 release. Version 8.2.0 exposes a new API to collect the device's App Tracking Transparency authorization status
- mParticle is continually releasing updates for both server-side integrations and client-side kit integrations, as the respective partner APIs and SDKs adapt

### Preparing for iOS 14

Under these new privacy guidelines each app must ensure that all user data processing obeys user consent elections and ultimately protects them from breaching App Store Review guidelines.

Please reference the following two Apple documents for the latest compliance requirements:

- [User Privacy and Data Use Overview](https://developer.apple.com/app-store/user-privacy-and-data-use/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

### App Tracking Transparency Framework Support

The App Tracking Transparency framework replaces the [original `advertisingTrackingEnabled` boolean flag](https://developer.apple.com/documentation/adsupport/asidentifiermanager/1614148-advertisingtrackingenabled) with the new `ATTrackingManagerAuthorizationStatus` enumeration. With mParticle, you can now associate any device data with this new enumeration such that you can control the flow of data based on the end-user's wishes.

The mParticle Apple SDK automatically collects the publisher-sandboxed IDFV, but does not automatically collect any user identifers or the IDFA and it does not automatically prompt the user for tracking authorization. It is up to you to determine if your downstream mParticle integrations require ATT authorization for cross-application tracking, and if they require the IDFA.

[Please see Apple's App Tracking Transparency guide](https://developer.apple.com/documentation/apptrackingtransparency) for how to request user authorization for tracking and collect their ATT authorization status.

#### ATT API Overview

- mParticle has introduced a new `att_authorization_status` field to [our data model](https://docs.mparticle.com/developers/server/json-reference/), which surfaces the same values as Apple's [`ATTrackingManagerAuthorizationStatus` enumeration](https://developer.apple.com/documentation/apptrackingtransparency/attrackingmanagerauthorizationstatus)
- mParticle has also introduced an optional `att_timestamp_unixtime_ms` field representing the time when the user responded to the ATT prompt or their status was otherwise updated
- The Apple SDK lets you set these two fields, and the `MPATTAuthorizationStatus` enumeration maps directly to Apple's `ATTrackingManagerAuthorizationStatus` enumeration.
- All customers implementing the Apple SDK or sending iOS data server-to-server are encouraged to begin collecting and sending the status field.
- **At a future date, this field will become required when providing mParticle with an IDFA**

### Collecting ATT Status with Apple SDK 8.2.0+

Once provided to the SDK, the ATT status will be stored by the SDK on the device and continually included with all future uploads, for all MPIDs for the device. If not provided, the timestamp will be set to the current time. The SDK will ignore API calls to change the ATT status, if the ATT status hasn't changed from the previous API call. This allows the SDK to keep track of the originally provided timestamp.

There are two locations where you should provide the ATT status:

#### 1. On SDK Initialization

```swift
let options = MParticleOptions(key: "REPLACE WITH APP KEY", secret: "REPLACE WITH APP SECRET")
options.attStatus = NSNumber.init(value: ATTrackingManager.trackingAuthorizationStatus.rawValue)
MParticle.sharedInstance().start(with: options)
```

#### 2. After the user responds to the ATT prompt

The code below shows the following:

- On response to the user, map the `ATTrackingManagerAuthorizationStatus` enum to the mParticle `MPATTAuthorizationStatus` enum
- If desired, provide the IDFA to the mParticle Identity API when available

```swift
ATTrackingManager.requestTrackingAuthorization { status in
    switch status {
    case .authorized:
        MParticle.sharedInstance().setATTStatus((MPATTAuthorizationStatus)status, withTimestampMillis: nil)

        // Now that we are authorized we can get the IDFA, supply to mParticle Identity API as needed
        var identityRequest = MPIdentityApiRequest.withEmptyUser()
        identityRequest.setIdentity(ASIdentifierManager.shared().advertisingIdentifier.uuidString, identityType: MPIdentity.iosAdvertiserId)
        MParticle.sharedInstance().identity.modify(identityRequest, completion: identityCallback)
    case .denied:
        MParticle.sharedInstance().setATTStatus((MPATTAuthorizationStatus)status, withTimestampMillis: nil)
    case .notDetermined:
        MParticle.sharedInstance().setATTStatus((MPATTAuthorizationStatus)status, withTimestampMillis: nil)
    case .restricted:
        MParticle.sharedInstance().setATTStatus((MPATTAuthorizationStatus)status, withTimestampMillis: nil)
    @unknown default:
        MParticle.sharedInstance().setATTStatus((MPATTAuthorizationStatus)status, withTimestampMillis: nil)
    }
}
```

### Removal of IDFA and Updated Identity API

Apple SDK v8 no longer queries for the IDFA.

To account for this change, the SDK's `MPIdentityAPIRequest` object has been updated to accept device identities in addition to "user" identities:

- A new `MPIdentity` enum has been surfaced which includes both user (eg Customer ID) and device IDs (eg IDFA)
- The `setUserIdentity` API has been replaced with the `setIdentity` API, which accepts this new enum.

#### Apple SDK 7

```objective-c

MPIdentityApiRequest *identityRequest = [MPIdentityApiRequest requestWithUser:currentUser];
[identityRequest setUserIdentity:@"123456" identityType:MPUserIdentityCustomerId];
[[[MParticle sharedInstance] identity] modify:identityRequest completion:identityCallback];
```

#### Apple SDK 8

```objective-c

MPIdentityApiRequest *identityRequest = [MPIdentityApiRequest requestWithUser:currentUser];
[identityRequest setIdentity:@"123456" identityType:MPIdentityCustomerId];
[[[MParticle sharedInstance] identity] modify:identityRequest completion:identityCallback];
```

#### Supplying the IDFA in Apple SDK 8

If you would like to collect the IDFA with Apple SDK 8, you must query ASIdentifierManager, and provide it with all identity requests. The SDK will not cache this value, so it must be provided whenever making a call to the Identity API.

```objective-c
MParticleUser *currentUser = [[MParticle sharedInstance] identity].currentUser;
MPIdentityApiRequest *identityRequest = [MPIdentityApiRequest requestWithUser:currentUser];
[identityRequest setIdentity: [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString] identityType:MPIdentityIOSAdvertiserId];
[[[MParticle sharedInstance] identity] modify:identityRequest completion:identityCallback];
```

_Note_: Starting in 2021, to collect the IDFA with Apple SDK 8 you will need to [follow Apple's guidelines](https://developer.apple.com/documentation/apptrackingtransparency) to implement the AppTrackingTransparancy framework. If the user consents to tracking, providing the IDFA proceeds as already described. If they do not or the AppTrackingTransparancy framework is not implemented, ASIdentifierManager's `advertisingIdentifier` API will return a nil, all-zero IDFA.

#### Common IDFA Use-cases

The following are some common use-cases and best practices:

1. If you are looking to collect IDFA, you should _always_ provide it to the mParticle SDK when creating an identity request
2. On first launch of your app, the mParticle SDK will make an initial identify request. If the user has never consented to IDFA collection, IDFA will be unavailable to you, and as such you will not be able to provide it on your initial identity request. If and when the IDFA is made available to your app, you should perform an `identify` request or a `modify` request, supplying all known IDs of the current user as well as the newly known IDFA.
3. When a user logs out of your application, be sure to provide IDFA to the identity `logout` API - it will _NOT_ automatically be passed from one user to the next. You must provide it for _every identity request_.

[See the example application](https://github.com/mParticle/mparticle-apple-sdk/tree/master/Example) in the Apple SDK repository for a full implementation of the AppTrackingTransparency framework.

**Other device IDs such as the IDFV as still automatically collected, though you can also provide them with this new API if you would like to override the Apple SDK's collection.**

### App Clips

Apple SDK 8 is compatible with App Clips. The SDK is designed to be light-weight and has few dependencies on outside frameworks, and as such functions without issue within the limited capacity of an App Clip. [See Apple's guidelines here](https://developer.apple.com/documentation/app_clips/developing_a_great_app_clip) for the frameworks and identifers available in an App Clip.

**Notably, IDFV is not available in an App Clip, so you cannot rely on this identifier for App Clip data collected via mParticle.**

### Approximate Location

**The mParticle Apple SDK never automatically gathers location, it has always been and continues to be an opt-in API.**

Starting with iOS 14, app developers can request "approximate" location for use-cases that do not require "precise" location. Specifically, [the `CLLocationAccuracy` enum has been modified](https://developer.apple.com/documentation/corelocation/cllocationaccuracy) to add a new `kCLLocationAccuracyReduced` option.

The mParticle Apple SDK's API is unchanged, but you can now provide this reduced accuracy option if you choose:

```objective-c
[[MParticle sharedInstance] beginLocationTracking:kCLLocationAccuracyReduced
                                      minDistance:1000];
```

### Kit Dependencies

Historically mParticle has centrally managed and released most kits. This allowed us to rapidly improve the APIs exposed to kits, while also providing app developers with a consistent experience. Specifically, with SDK version 7 and earlier, the mParticle engineering team would release _matching_ versions of all kits. So for example, your Podfile (or Cartfile) should have looked something like this, with _all versions matching_:

```ruby
pod 'mParticle-Apple-SDK', '7.16.2'
pod 'mParticle-Appboy', '7.16.2'
pod 'mParticle-BranchMetrics', '7.16.2'
```

Starting with SDK 8, this paradigm is changing. As more partners develop their own kits, and in order to release kits (and the core SDK) SDK more rapidly, we are decoupling kit versions from the core SDK version.

**For the release of SDK 8 all existing kits have be updated to 8.0.1**, and will begin to diverge depending on the pace of development of each kit.

For SDK version 8, we recommend updating the above Podfile as follows:

```ruby
pod 'mParticle-Apple-SDK', '~> 8.0'
pod 'mParticle-Appboy', '~> 8.0'
pod 'mParticle-BranchMetrics','~> 8.0'
```

The above Podfile may eventually resolve to different versions of each kit. However, mParticle has committed to making _no breaking API changes to kit APIs prior to the next major version, 9.0_. This means that it's always in your best interest to update to the latest versions of all kits as well as the Core SDK, and you do not need to worry about matching versions across your kit dependencies.
