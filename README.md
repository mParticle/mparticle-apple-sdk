<img src="https://static.mparticle.com/sdk/mp_logo_black.svg" width="280">

# mParticle Apple SDK

A single SDK to collect analytics data and send it to 100+ marketing, analytics, and data platforms. Simplify your data integration with a single API.

This is the mParticle Apple SDK for iOS and tvOS.

At mParticle our mission is straightforward: make it really easy for apps and app services to connect and allow you to take ownership of your 1st party data.
Like most app owners, you end up implementing and maintaining numerous SDKs ranging from analytics, attribution, push notification, remarketing,
monetization, etc. However, embedding multiple 3rd party libraries creates a number of unintended consequences and hidden costs.

The mParticle platform addresses all these problems. We support an ever growing number of integrations with services and SDKs, including developer
tools, analytics, attribution, messaging, advertising, and more. mParticle has been designed to be the central hub connecting all these services –
read the [docs](https://docs.mparticle.com/developers/sdk/ios/) or contact us at <support@mparticle.com> to learn more.

## Overview

This document will help you:

- Install the mParticle SDK using [Swift Package Manager](https://github.com/apple/swift-package-manager) or [CocoaPods](https://cocoapods.org/?q=mparticle)
- Add any desired [kits](#currently-supported-kits)
- Initialize the mParticle SDK

## Get the SDK

The mParticle-Apple-SDK is available via [Swift Package Manager](https://github.com/apple/swift-package-manager) or [CocoaPods](https://cocoapods.org/?q=mparticle). Follow the instructions below based on your preference.

#### Swift Package Manager

To integrate the core SDK using Swift Package Manager, open your Xcode project, go to the "Package Dependencies" tab, click the "+" button, and add:

```text
https://github.com/mParticle/mparticle-apple-sdk
```

Choose the `mParticle-Apple-SDK` package and add the `mParticle-Apple-SDK` product to your app target.

If you'd like to add kits with Swift Package Manager, add each kit's version-tracked repository separately and select the product exported by that repository. For example:

```text
https://github.com/mparticle-integrations/mparticle-apple-integration-branchmetrics-3
https://github.com/mparticle-integrations/mparticle-apple-integration-braze-14
```

Then add the `mParticle-BranchMetrics` and `mParticle-Braze` products to your app target.

#### CocoaPods

To integrate the SDK using CocoaPods, specify it in your [Podfile](https://guides.cocoapods.org/syntax/podfile.html):

```ruby
target '<Your Target>' do
    pod 'mParticle-Apple-SDK', '~> 9'
end
```

Configuring your `Podfile` with the statement above will include only the _Core_ mParticle SDK.

> If your app targets iOS and tvOS in the same Xcode project, you need to configure the `Podfile` differently in order to use the SDK with multiple platforms. You can find an example of multi-platform configuration [here](https://github.com/mParticle/mparticle-apple-sdk/wiki/Multi-platform-Configuration).

If you'd like to add any kits, you can do so as follows:

```ruby
target '<Your Target>' do
    pod 'mParticle-Braze-14', '~> 9'
    pod 'mParticle-BranchMetrics-3', '~> 9'
    pod 'mParticle-Localytics-7', '~> 9'
end
```

In the case above, the _Braze 14_, _Branch Metrics 3_, and _Localytics 7_ kits would be integrated together with the core SDK.

#### Crash Reporter

For iOS only, you can also choose to install the crash reporter by including it as a separate pod:

```ruby
pod 'mParticle-CrashReporter', '~> 1.3'
```

You can read detailed instructions for including the Crash Reporter at its repository: [mParticle-CrashReporter](https://github.com/mParticle/mParticle-CrashReporter)

> Note you can't use the crash reporter at the same time as the Apteligent kit.

#### Currently Supported Kits

Several integrations require additional client-side add-on libraries called "kits." Some kits embed other SDKs, others just contain a bit of additional functionality. Kits are designed to feel just like server-side integrations; you enable, disable, filter, sample, and otherwise tweak kits completely from the mParticle platform UI. The Core SDK will detect kits at runtime, but you need to add them as dependencies to your app.

Each supported kit is released from this monorepo as a version-tracked mirror repository. Choose the track that matches the major version of the partner SDK you want to integrate.

| Kit Track                          | Repository                                                                                                                                                             | CocoaPods | Swift Package Manager |
| ---------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :-------: | :-------------------: |
| Adjust 5                           | [mparticle-apple-integration-adjust-5](https://github.com/mparticle-integrations/mparticle-apple-integration-adjust-5)                                                 |     ✓     |           ✓           |
| Adobe 5                            | [mparticle-apple-integration-adobe-5](https://github.com/mparticle-integrations/mparticle-apple-integration-adobe-5)                                                   |     ✓     |           ✓           |
| AppsFlyer 6                        | [mparticle-apple-integration-appsflyer-6](https://github.com/mparticle-integrations/mparticle-apple-integration-appsflyer-6)                                           |     ✓     |           ✓           |
| Apptentive 6                       | [mparticle-apple-integration-apptentive-6](https://github.com/mparticle-integrations/mparticle-apple-integration-apptentive-6)                                         |     ✓     |           ✓           |
| Apptimize 3                        | [mparticle-apple-integration-apptimize-3](https://github.com/mparticle-integrations/mparticle-apple-integration-apptimize-3)                                           |     ✓     |           ✓           |
| Branch Metrics 3                   | [mparticle-apple-integration-branchmetrics-3](https://github.com/mparticle-integrations/mparticle-apple-integration-branchmetrics-3)                                   |     ✓     |           ✓           |
| Braze 12                           | [mparticle-apple-integration-braze-12](https://github.com/mparticle-integrations/mparticle-apple-integration-braze-12)                                                 |     ✓     |           ✓           |
| Braze 13                           | [mparticle-apple-integration-braze-13](https://github.com/mparticle-integrations/mparticle-apple-integration-braze-13)                                                 |     ✓     |           ✓           |
| Braze 14                           | [mparticle-apple-integration-braze-14](https://github.com/mparticle-integrations/mparticle-apple-integration-braze-14)                                                 |     ✓     |           ✓           |
| CleverTap 7                        | [mparticle-apple-integration-clevertap-7](https://github.com/mparticle-integrations/mparticle-apple-integration-clevertap-7)                                           |     ✓     |           ✓           |
| comScore 6                         | [mparticle-apple-integration-comscore-6](https://github.com/mparticle-integrations/mparticle-apple-integration-comscore-6)                                             |     ✓     |           ✓           |
| Google Analytics for Firebase 11   | [mparticle-apple-integration-google-analytics-firebase-11](https://github.com/mparticle-integrations/mparticle-apple-integration-google-analytics-firebase-11)         |     ✓     |           ✓           |
| Google Analytics for Firebase 12   | [mparticle-apple-integration-google-analytics-firebase-12](https://github.com/mparticle-integrations/mparticle-apple-integration-google-analytics-firebase-12)         |     ✓     |           ✓           |
| Google Analytics 4 for Firebase 11 | [mparticle-apple-integration-google-analytics-firebase-ga4-11](https://github.com/mparticle-integrations/mparticle-apple-integration-google-analytics-firebase-ga4-11) |     ✓     |           ✓           |
| Google Analytics 4 for Firebase 12 | [mparticle-apple-integration-google-analytics-firebase-ga4-12](https://github.com/mparticle-integrations/mparticle-apple-integration-google-analytics-firebase-ga4-12) |     ✓     |           ✓           |
| Iterable 6                         | [mparticle-apple-integration-iterable-6](https://github.com/mparticle-integrations/mparticle-apple-integration-iterable-6)                                             |     ✓     |           ✓           |
| Kochava 9                          | [mparticle-apple-integration-kochava-9](https://github.com/mparticle-integrations/mparticle-apple-integration-kochava-9)                                               |           |           ✓           |
| Kochava No Tracking 9              | [mparticle-apple-integration-kochava-no-tracking-9](https://github.com/mparticle-integrations/mparticle-apple-integration-kochava-no-tracking-9)                       |           |           ✓           |
| Leanplum 6                         | [mparticle-apple-integration-leanplum-6](https://github.com/mparticle-integrations/mparticle-apple-integration-leanplum-6)                                             |     ✓     |           ✓           |
| Localytics 6                       | [mparticle-apple-integration-localytics-6](https://github.com/mparticle-integrations/mparticle-apple-integration-localytics-6)                                         |     ✓     |           ✓           |
| Localytics 7                       | [mparticle-apple-integration-localytics-7](https://github.com/mparticle-integrations/mparticle-apple-integration-localytics-7)                                         |     ✓     |           ✓           |
| OneTrust                           | [mp-apple-integration-onetrust](https://github.com/mparticle-integrations/mp-apple-integration-onetrust)                                                               |     ✓     |           ✓           |
| Optimizely 4                       | [mparticle-apple-integration-optimizely-4](https://github.com/mparticle-integrations/mparticle-apple-integration-optimizely-4)                                         |     ✓     |           ✓           |
| Optimizely 5                       | [mparticle-apple-integration-optimizely-5](https://github.com/mparticle-integrations/mparticle-apple-integration-optimizely-5)                                         |     ✓     |           ✓           |
| Radar 3                            | [mparticle-apple-integration-radar-3](https://github.com/mparticle-integrations/mparticle-apple-integration-radar-3)                                                   |     ✓     |           ✓           |
| Rokt                               | [mp-apple-integration-rokt](https://github.com/mparticle-integrations/mp-apple-integration-rokt)                                                                       |     ✓     |           ✓           |
| Singular 12                        | [mparticle-apple-integration-singular-12](https://github.com/mparticle-integrations/mparticle-apple-integration-singular-12)                                           |     ✓     |           ✓           |
| Urban Airship 19                   | [mparticle-apple-integration-urbanairship-19](https://github.com/mparticle-integrations/mparticle-apple-integration-urbanairship-19)                                   |     ✓     |           ✓           |
| Urban Airship 20                   | [mparticle-apple-integration-urbanairship-20](https://github.com/mparticle-integrations/mparticle-apple-integration-urbanairship-20)                                   |     ✓     |           ✓           |

For CocoaPods, use the pod name exposed by the kit track repository's podspec, such as `mParticle-Braze-14`, `mParticle-BranchMetrics-3`, or `mParticle-Rokt`. For Swift Package Manager, add the matching repository URL above and choose the library product it exports.

## Initialize the SDK

The mParticle SDK is initialized by calling the `startWithOptions` method within the `application:didFinishLaunchingWithOptions:` delegate call. Preferably the location of the initialization method call should be one of the last statements in the `application:didFinishLaunchingWithOptions:`. The `startWithOptions` method requires an options argument containing your key and secret and an initial Identity request.

> Note that it is imperative for the SDK to be initialized in the `application:didFinishLaunchingWithOptions:` method. Other parts of the SDK rely on the `UIApplicationDidBecomeActiveNotification` notification to function properly. Failing to start the SDK as indicated will impair it. Also, please do **not** use _GCD_'s `dispatch_async` to start the SDK.

#### Swift

```swift
import mParticle_Apple_SDK

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

       // Override point for customization after application launch.
        let mParticleOptions = MParticleOptions(key: "<<<App Key Here>>>", secret: "<<<App Secret Here>>>")

       //Please see the Identity page for more information on building this object
        let request = MPIdentityApiRequest()
        request.email = "email@example.com"
        mParticleOptions.identifyRequest = request
        mParticleOptions.onIdentifyComplete = { (apiResult, error) in
            NSLog("Identify complete. userId = %@ error = %@", apiResult?.user.userId.stringValue ?? "Null User ID", error?.localizedDescription ?? "No Error Available")
        }

       //Start the SDK
        MParticle.sharedInstance().start(with: mParticleOptions)

       return true
}
```

#### Objective-C

For apps supporting iOS 15.6+ and tvOS 15.6+, Apple recommends using the import syntax for **modules** or **semantic import**. However, if you prefer the traditional CocoaPods and static libraries delivery mechanism, that is fully supported as well.

If you are using mParticle as a framework, your import statement will be as follows:

```objective-c
@import mParticle_Apple_SDK;                // Apple recommended syntax, but requires "Enable Modules (C and Objective-C)" in pbxproj
#import <mParticle_Apple_SDK/mParticle.h>   // Works when modules are not enabled

```

Otherwise, for CocoaPods without `use_frameworks!`, you can use either of these statements:

```objective-c
#import <mParticle-Apple-SDK/mParticle.h>
#import "mParticle.h"
```

Next, you'll need to start the SDK:

```objective-c
- (BOOL)application:(UIApplication *)application
        didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    MParticleOptions *mParticleOptions = [MParticleOptions optionsWithKey:@"REPLACE ME"
                                                                   secret:@"REPLACE ME"];

    //Please see the Identity page for more information on building this object
    MPIdentityApiRequest *request = [MPIdentityApiRequest requestWithEmptyUser];
    request.email = @"email@example.com";
    mParticleOptions.identifyRequest = request;
    mParticleOptions.onIdentifyComplete = ^(MPIdentityApiResult * _Nullable apiResult, NSError * _Nullable error) {
        NSLog(@"Identify complete. userId = %@ error = %@", apiResult.user.userId, error);
    };

    [[MParticle sharedInstance] startWithOptions:mParticleOptions];

    return YES;
}
```

Please see [Identity](http://docs.mparticle.com/developers/sdk/ios/identity/) for more information on supplying an `MPIdentityApiRequest` object during SDK initialization.

## Example Project with Sample Code

A sample project is provided with the mParticle Apple SDK. It is a multi-platform video streaming app for both iOS and tvOS.

Clone the repository to your local machine

```bash
git clone https://github.com/mParticle/mparticle-apple-sdk.git
```

In order to run the sample app, first install the local CocoaPods dependencies.

1. Change to the `Example` directory
2. Run `pod install`
3. Open **mParticleExample.xcworkspace** in Xcode, select the **mParticleExample** scheme, build and run.

## Read More

Just by initializing the SDK you'll be set up to track user installs, engagement, and much more. Check out our doc site to learn how to add specific event tracking to your app.

- [SDK Documentation](http://docs.mparticle.com/#mobile-sdk-guide)

## Contributing

We welcome contributions! If you're interested in contributing to the mParticle Apple SDK, please read our [Contributing Guidelines](CONTRIBUTING.md).

## Support

Questions? Have an issue? Read the [docs](https://docs.mparticle.com/developers/sdk/ios/) or contact our **Customer Success** team at <support@mparticle.com>.

## License

[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0)
