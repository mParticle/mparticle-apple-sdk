<img src="https://static.mparticle.com/sdk/mp_logo_black.svg" width="280">

# mParticle Apple SDK

This is the mParticle Apple SDK for iOS and tvOS.

At mParticle our mission is straightforward: make it really easy for apps and app services to connect and allow you to take ownership of your 1st party data.
Like most app owners, you end up implementing and maintaining numerous SDKs ranging from analytics, attribution, push notification, remarketing,
monetization, etc. However, embedding multiple 3rd party libraries creates a number of unintended consequences and hidden costs.

The mParticle platform addresses all these problems. We support an ever growing number of integrations with services and SDKs, including developer
tools, analytics, attribution, messaging, advertising, and more. mParticle has been designed to be the central hub connecting all these services –
read the [docs](https://docs.mparticle.com/developers/sdk/ios/) or contact us at <support@mparticle.com> to learn more.

## Overview

This document will help you:

* Install the mParticle SDK using [CocoaPods](https://cocoapods.org/?q=mparticle) or [Carthage](https://github.com/Carthage/Carthage)
* Add any desired [kits](#currently-supported-kits)
* Initialize the mParticle SDK

## Get the SDK

The mParticle-Apple-SDK is available via [CocoaPods](https://cocoapods.org/?q=mparticle), [Carthage](https://github.com/Carthage/Carthage) or [Swift Package Manager](https://github.com/apple/swift-package-manager). Follow the instructions below based on your preference.

#### CocoaPods

To integrate the SDK using CocoaPods, specify it in your [Podfile](https://guides.cocoapods.org/syntax/podfile.html):

```ruby
target '<Your Target>' do
    pod 'mParticle-Apple-SDK', '~> 8'
    
    # If you'd like to use a version of the SDK that doesn't include any location tracking nor links the CoreLocation framework, use this subspec:
    # pod 'mParticle-Apple-SDK/mParticleNoLocation', '~> 8'
end
```

Configuring your `Podfile` with the statement above will include only the _Core_ mParticle SDK.

> If your app targets iOS and tvOS in the same Xcode project, you need to configure the `Podfile` differently in order to use the SDK with multiple platforms. You can find an example of multi-platform configuration [here](https://github.com/mParticle/mparticle-apple-sdk/wiki/Multi-platform-Configuration).

If you'd like to add any kits, you can do so as follows:

```ruby
target '<Your Target>' do
    pod 'mParticle-Appboy', '~> 8'
    pod 'mParticle-BranchMetrics', '~> 8'
    pod 'mParticle-Localytics', '~> 8'
end
```

In the cases above, the _Appboy_, _Branch Metrics_, and _Localytics_ kits would be integrated together with the core SDK.

#### Crash Reporter

For iOS only, you can also choose to install the crash reporter by including it as a separate pod:

```ruby
pod 'mParticle-CrashReporter', '~> 1.3'
```

You can read detailed instructions for including the Crash Reporter at its repository: [mParticle-CrashReporter](https://github.com/mParticle/mParticle-CrashReporter)

> Note you can't use the crash reporter at the same time as the Apteligent kit.

#### Carthage

To integrate the SDK using Carthage, specify it in your [Cartfile](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#cartfile):

```ogdl

binary "https://raw.githubusercontent.com/mParticle/mparticle-apple-sdk/main/mParticle_Apple_SDK.json" ~> 8.0
```

If you'd like to add any kits, you can do so as follows:

```ogdl
github "mparticle-integrations/mparticle-apple-integration-branchmetrics" ~> 8.0
```

In this case, only the _Branch Metrics_ kit would be integrated; all other kits would be left out.

#### Swift Package Manager

To integrate the SDK using Swift Package Manager, open your Xcode project and click on your project in the file list on the left, click on your Project name in the middle of the window, click on the "Package Dependencies" tab, and click the "+" button underneath the Packages list.

Enter the repository URL `https://github.com/mParticle/mparticle-apple-sdk` in the search box on the top right, choose `mparticle-apple-sdk` from the list of pacakges, and change "Dependency Rule" to "Up to Next Major Version". Then click the "Add Package" button on the bottom right.

Then choose either the "Package Product" called `mParticle-Apple-SDK`, or if you'd like to use a version of the SDK that doesn't include any location tracking nor links the CoreLocation framework choose `mParticle-Apple-SDK-NoLocation`.

**IMPORTANT:** If you choose the `mParticle-Apple-SDK-NoLocation` package product, you will need to import the SDK using `import mParticle_Apple_SDK_NoLocation` instead of `import mParticle_Apple_SDK` as shown in the rest of the documentation and this README. 

#### Currently Supported Kits

Several integrations require additional client-side add-on libraries called "kits." Some kits embed other SDKs, others just contain a bit of additional functionality. Kits are designed to feel just like server-side integrations; you enable, disable, filter, sample, and otherwise tweak kits completely from the mParticle platform UI. The Core SDK will detect kits at runtime, but you need to add them as dependencies to your app.

Kit | CocoaPods | Carthage | Swift Package Manager |
----|:---------:|:-------:|:-------:|
[Adjust](https://github.com/mparticle-integrations/mparticle-apple-integration-adjust)                                            | ✓  | ✓  | ✓  
[Appboy](https://github.com/mparticle-integrations/mparticle-apple-integration-appboy)                                            | ✓  | ✓  | ✓  
[Adobe](https://github.com/mparticle-integrations/mparticle-apple-integration-adobe)                                              | ✓  | ✓  | ✓   
[AppsFlyer](https://github.com/mparticle-integrations/mparticle-apple-integration-appsflyer)                                      | ✓  | ✓  | ✓  
[Appsee](https://github.com/mparticle-integrations/mparticle-apple-integration-appsee)                                            | ✓  |    |    
[Apptentive](https://github.com/mparticle-integrations/mparticle-apple-integration-apptentive)                                    | ✓  | ✓  | ✓   
[Apptimize](https://github.com/mparticle-integrations/mparticle-apple-integration-apptimize)                                      | ✓  | ✓  | ✓   
[Apteligent](https://github.com/mparticle-integrations/mparticle-apple-integration-apteligent)                                    | ✓  |    |    
[Blueshift](https://github.com/blueshift-labs/mparticle-apple-integration-blueshift)                                              | ✓  | ✓  |    
[Branch Metrics](https://github.com/mparticle-integrations/mparticle-apple-integration-branchmetrics)                             | ✓  | ✓  | ✓   
[Button](https://github.com/mparticle-integrations/mparticle-apple-integration-button)                                            | ✓  | ✓  | ✓  
[CleverTap](https://github.com/mparticle-integrations/mparticle-apple-integration-clevertap)                                      | ✓  | ✓  | ✓  
[comScore](https://github.com/mparticle-integrations/mparticle-apple-integration-comscore)                                        | ✓  |    | ✓  
[Flurry](https://github.com/mparticle-integrations/mparticle-apple-integration-flurry)                                            | ✓  |    |    
[Foresee](https://github.com/mparticle-integrations/mparticle-apple-integration-foresee)                                          | ✓  |    | ✓  
[Google Analytics for Firebase](https://github.com/mparticle-integrations/mparticle-apple-integration-google-analytics-firebase)  | ✓  | ✓  | ✓  
[Google Analytics 4 for Firebase](https://github.com/mparticle-integrations/mparticle-apple-integration-google-analytics-firebase-ga4)                                        | ✓  | ✓  | ✓  
[Instabot](https://github.com/mparticle-integrations/mparticle-apple-integration-instabot)                                        | ✓  |    |    
[Iterable](https://github.com/mparticle-integrations/mparticle-apple-integration-iterable)                                        | ✓  | ✓  | ✓  
[Kochava](https://github.com/mparticle-integrations/mparticle-apple-integration-kochava)                                          |    |    | ✓  
[Leanplum](https://github.com/mparticle-integrations/mparticle-apple-integration-leanplum)                                        | ✓  | ✓  | ✓  
[Localytics](https://github.com/mparticle-integrations/mparticle-apple-integration-localytics)                                    | ✓  | ✓  | ✓  
[Optimizely](https://github.com/mparticle-integrations/mparticle-apple-integration-optimizely)                                    | ✓  | ✓  | ✓  
[OneTrust](https://github.com/mparticle-integrations/mparticle-apple-integration-onetrust)                                        | ✓  | ✓  | ✓  
[Pilgrim](https://github.com/mparticle-integrations/mparticle-apple-integration-pilgrim)                                          | ✓  | ✓  |    
[Primer](https://github.com/mparticle-integrations/mparticle-apple-integration-primer)                                            | ✓  | ✓  |    
[Radar](https://github.com/mparticle-integrations/mparticle-apple-integration-radar)                                              | ✓  | ✓  | ✓  
[Responsys](https://github.com/mparticle-integrations/mparticle-apple-integration-responsys)                                      | ✓  |    |    
[Reveal Mobile](https://github.com/mparticle-integrations/mparticle-apple-integration-revealmobile)                               | ✓  |    |    
[Singular](https://github.com/mparticle-integrations/mparticle-apple-integration-singular)                                        | ✓  |    | ✓  
[Skyhook](https://github.com/mparticle-integrations/mparticle-apple-integration-skyhook)                                          | ✓  |    |    
[Taplytics](https://github.com/mparticle-integrations/mparticle-apple-integration-taplytics)                                      | ✓  |    | ✓  
[Tune](https://github.com/mparticle-integrations/mparticle-apple-integration-tune)                                                | ✓  | ✓  |    
[Urban Airship](https://github.com/mparticle-integrations/mparticle-apple-integration-urbanairship)                               | ✓  |    | ✓  
[UserLeap](https://github.com/UserLeap/userleap-mparticle-ios-kit)                                                                | ✓  | ✓  |    
[Wootric](https://github.com/mparticle-integrations/mparticle-apple-integration-wootric)                                          | ✓  |    |    


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

For apps supporting iOS 8 and above, Apple recommends using the import syntax for **modules** or **semantic import**. However, if you prefer the traditional CocoaPods and static libraries delivery mechanism, that is fully supported as well.

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

In order to run either the iOS or tvOS examples, first install the mParticle Apple SDK via [CocoaPods](https://guides.cocoapods.org/using/getting-started.html).

1. Change to the `Examples/CocoaPodsExample` directory
2. Run `pod install`
3. Open **Example.xcworkspace** in Xcode, select either the **iOS_Example** or **tvOS_Example** scheme, build and run.


## Read More

Just by initializing the SDK you'll be set up to track user installs, engagement, and much more. Check out our doc site to learn how to add specific event tracking to your app.

* [SDK Documentation](http://docs.mparticle.com/#mobile-sdk-guide)


## Support

Questions? Have an issue? Read the [docs](https://docs.mparticle.com/developers/sdk/ios/) or contact our **Customer Success** team at <support@mparticle.com>.

## License

Apache 2.0
