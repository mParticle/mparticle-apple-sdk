<img src="http://static.mparticle.com/sdk/logo.svg" width="280">

# mParticle Apple SDK

Hello! This is the unified mParticle Apple SDK. It currently supports iOS and tvOS, and we plan to continue adding support for more platforms in the future.

Your job is to build an awesome app that consumers love. You also need several tools and services to make data-driven decisions. Like most app owners, you end up implementing and maintaining numerous SDKs ranging from analytics, attribution, push notification, remarketing, monetization, etc. But embedding multiple 3rd party libraries creates a number of unintended consequences and hidden costs. From not being able to move as fast as you want, to bloating and destabilizing your app, to losing control and ownership of your 1st party data.

The mParticle platform addresses all these problems. We support an ever growing number of integrations with services and SDKs, including developer tools, analytics, attribution, messaging, advertising, and more. mParticle has been designed to be the central hub connecting all these services – check [our site](https://www.mparticle.com), or hit us at <dev@mparticle.com> to learn more.


## Overview

This document is a quick-start to:

* Obtaining the mParticle SDK via [CocoaPods](https://cocoapods.org/?q=mparticle) or via [Carthage](https://github.com/Carthage/Carthage)
* Extending the mParticle SDK with [*Kits*](https://github.com/mparticle-integrations)
* Initializing the mParticle SDK

The mParticle SDK is composed of the _Core_ library and a series of _kit_ libraries that depend on Core. With each integration with a partner we strive to implement as many features as possible in the server-to-server layer, however some times a deeper integration to work side-by-side with a 3rd party SDK comes with greater benefits to our clients. We use the term **Kit** to describe such integrations. The Core SDK takes care of initializing the kits depending on what you've configured in [your app's dashboard](https://app.mparticle.com), so you just have to decide which kits you may use prior to submission to the App Store. You can easily include all of the kits, none of the kits, or individual kits – the choice is yours.


## Get the SDK

The mParticle-Apple-SDK is available via [CocoaPods](https://cocoapods.org/?q=mparticle) or via [Carthage](https://github.com/Carthage/Carthage). Once you have picked your choice, follow the instructions below.

#### CocoaPods

To integrate mParticle into your Xcode project using CocoaPods, specify it in your [Podfile](https://guides.cocoapods.org/syntax/podfile.html):

```ruby
target '<Your Target>' do
    pod 'mParticle-Apple-SDK', '~> 6'
end
```

Configuring your `Podfile` with the statement above will include only the _Core_ mParticle SDK.

> If your app is targeting iOS and tvOS in the same Xcode project, you will need to configure the `Podfile` differently in order to use the SDK with multiple platforms. You can find multi-platform configuration [here](https://github.com/mParticle/mparticle-apple-sdk-private/wiki/Multi-platform-Configuration).

If you'd like to add any kits, you can do so as follows:

```ruby
target '<Your Target>' do
    pod 'mParticle-Appboy', '~> 6'
    pod 'mParticle-BranchMetrics', '~> 6'
    pod 'mParticle-Localytics', '~> 6'
end
```

In the cases above, the _Appboy_, _Branch Metrics_, and _Localytics_ kits would be integrated together with the core SDK.

For iOS only, you can also choose to install the crash reporter. You include it as a subspec:

```ruby
pod 'mParticle-Apple-SDK/CrashReporter', '~> 6'
```

> You can't use the crash reporter at the same time as the Apteligent/Crittercism kit.

#### Carthage

To integrate mParticle into your Xcode project using Carthage, specify it in your [Cartfile](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#cartfile):

```ogdl
github "mparticle/mparticle-apple-sdk" ~> 6.0
```

If you'd like to add any kits, you can do so as follows:

```ogdl
github "mparticle-integrations/mparticle-apple-integration-branchmetrics" ~> 6.0
```

In this case, only the _Branch Metrics_ kit would be integrated; all other kits would be left out.

> All kits are currently compatible with CocoaPods. For Carthage, look for this badge [![Carthage compatible](http://img.shields.io/badge/Carthage-compatible-brightgreen.png)](https://github.com/Carthage/Carthage) in the kit README to confirm availability.

#### Currently Supported Kits

* [Adjust](https://www.adjust.com)
* [Appboy](https://www.appboy.com)
* [AppsFlyer](https://www.appsflyer.com)
* [Apteligent](www.apteligent.com)
* [Branch Metrics](https://branch.io)
* [comScore](https://www.comscore.com)
* [Flurry](https://developer.yahoo.com)
* [Kahuna](https://www.kahuna.com)
* [Kochava](https://www.kochava.com)
* [Localytics](https://www.localytics.com)
* [Tune](https://www.tune.com)
* [Wootric](https://www.wootric.com)

Integration information can be found in each [kit repository](https://github.com/mparticle-integrations).


## Initialize the SDK

For apps supporting iOS 8 and above, the syntax for the import statement should be one for **modules** or **semantic import**.

The mParticle SDK is initialized by calling the `startWithKey` method within the `application:didFinishLaunchingWithOptions:` delegate call. The mParticle SDK must be initialized with your app key and secret prior to use. Preferably the location of the initialization method call should be one of the last statements in the `application:didFinishLaunchingWithOptions:`.

> Note that it is imperative that the SDK is initialized in the `application:didFinishLaunchingWithOptions:` method. Other parts of the SDK rely on the `UIApplicationDidBecomeActiveNotification` notification to function properly. Failing to start the SDK as indicated will impair it. Also, please do **not** use _GCD_'s `dispatch_async` to start the SDK.

#### Swift

```swift
import mParticle_Apple_SDK

func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    // Other code goes here, prior to initializing the mParticle SDK
    // ...

    MParticle.sharedInstance().startWithKey("<<<App Key Here>>>", secret:"<<<App Secret Here>>>")

    return true
}
```

#### Objective-C

```objective-c
@import mParticle_Apple_SDK;

- (BOOL)application:(UIApplication *)application
        didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Other code goes here, prior to initializing the mParticle SDK
    // ...

    [[MParticle sharedInstance] startWithKey:@"<<<App Key Here>>>"
                                      secret:@"<<<App Secret Here>>>"];

    return YES;
}
```

>If your app still needs to support iOS 7, please use:
>
>```objective-c
>#import <mParticle_Apple_SDK/mParticle.h>
>```

If you are migrating to the mParticle SDK 6 from a previous version (4 or 5), please consult the [Migration Guide](https://github.com/mParticle/mparticle-apple-sdk-private/wiki/Migration-Guide)


## Example Project with Sample Code

A sample project is provided with the mParticle Apple SDK. It is a multi-platform video streaming app for both iOS and tvOS.

Clone the repository to your local machine

```bash
git clone https://github.com/mParticle/mparticle-apple-sdk.git
```

In order to run either the iOS or tvOS examples you will first install the mParticle Apple SDK via [CocoaPods](https://guides.cocoapods.org/using/getting-started.html).

1. Change to the `Example` directory
2. Run `pod install`
3. Open **Example.xcworkspace** in Xcode, select either the **iOS_Example** or **tvOS_Example** scheme, build and run. (In case you want to run on iOS 7, please use the **iOS7_Example** scheme instead)


## Read More

Just by initializing the SDK you'll be set up to track user installs, engagement, and much more. Check out our doc site to learn how to add specific event tracking to your app.

* [SDK Documentation](http://docs.mparticle.com/#sdk-documentation)


## Support

Questions? Give us a shout at <support@mparticle.com>


## License

The mParticle-Apple-SDK is available under the [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0). See the LICENSE file for more info.
