<img src="http://static.mparticle.com/sdk/logo.svg" width="280">

# mParticle Apple SDK

### <span style="color:red">This is an alpha release</span>

<!---
[![CI Status](http://img.shields.io/travis/Dalmo Cirne/mParticle-Apple-SDK.svg?style=flat)](https://travis-ci.org/Dalmo Cirne/mParticle-Apple-SDK)
[![Version](https://img.shields.io/cocoapods/v/mParticle-Apple-SDK.svg?style=flat)](http://cocoapods.org/pods/mParticle-Apple-SDK)
[![License](https://img.shields.io/cocoapods/l/mParticle-Apple-SDK.svg?style=flat)](http://cocoapods.org/pods/mParticle-Apple-SDK)
[![Platform](https://img.shields.io/cocoapods/p/mParticle-Apple-SDK.svg?style=flat)](http://cocoapods.org/pods/mParticle-Apple-SDK)
-->

Hello! This is the unified mParticle Apple SDK. It currently supports iOS and tvOS, however we plan to continue adding support for more platforms in the future. For the past 3 years we have been working tirelessly on developing each component of our platform; initially we deployed this SDK as iOS only, however we are at a different stage now, and we could not be more excited to be able to share it with you.

Your job is to build an awesome app experience that consumers love. You also need several tools and services to make data-driven decisions. Like most app owners, you end up implementing and maintaining numerous SDKs ranging from analytics, attribution, push notification, remarketing, monetization, etc. But embedding multiple 3rd party libraries creates a number of unintended consequences and hidden costs. From not being able to move as fast as you want, to bloating and destabilizing your app, to losing control and ownership of your 1st party data.

[mParticle](http://mparticle.com) solves all these problems with one lightweight SDK. Implement new partners without changing code or waiting for app store approval. Improve stability and security within your app. We enable our clients to spend more time innovating and less time integrating.

## Installation

mParticle-Apple-SDK is available via [CocoaPods](https://cocoapods.org/?q=mparticle).

#### mParticle SDK Only

```ruby
target '<Your Target>' do
    pod 'mParticle-Apple-SDK', :git => 'https://github.com/mParticle/mParticle-iOS-SDK.git', :branch => 'extensions'
end
```

> Configuring you Podfile with the statement above will include only the core mParticle SDK.

#### Multi-platform Projects

If your app is targeting iOS and tvOS in the same Xcode project, you will need to configure the `Podfile` differently in order to use the SDK with multiple platforms.

Below you can find a multi-platform sample `Podfile` configuration targeting iOS and tvOS.

```ruby
source 'https://github.com/CocoaPods/Specs.git'
inhibit_all_warnings!

# Replace with the name of your Xcode project name
xcodeproj '<Your Xcode Project Name>'

# Contains a list of all pods which are common among the platforms
def include_common_pods
    pod 'mParticle-Apple-SDK', :git => 'https://github.com/mParticle/mParticle-iOS-SDK.git', :branch => 'extensions'
end

# iOS app
target :phoneApp do
    # Replace with the name of the iOS target in your Xcode project
    link_with '<Your iOS Target>'
    use_frameworks!
    platform :ios, '8.0'
    include_common_pods
end

# tvOS app
target :tvApp do
    # Replace with the name of the tvOS target in your Xcode project
    link_with '<Your tvOS Target>'
    use_frameworks!
    platform :tvos, '9.0'
    include_common_pods
end
```

#### Pick and Choose Kits

If you need or choose to integrate with 3rd party kits embedded in our SDK, you may select a set of kits in your Podfile using the pattern `pod 'mParticle-Apple-SDK/<kit>'`, as we can see in the sample configuration below:

```ruby
pod 'mParticle-Apple-SDK/Appboy', :git => 'https://github.com/mParticle/mParticle-iOS-SDK.git', :branch => 'extensions'
pod 'mParticle-Apple-SDK/BranchMetrics', :git => 'https://github.com/mParticle/mParticle-iOS-SDK.git', :branch => 'extensions'
pod 'mParticle-Apple-SDK/Localytics', :git => 'https://github.com/mParticle/mParticle-iOS-SDK.git', :branch => 'extensions'
```

In the case above, only the Appboy, Branch Metrics, and Localytics kits would be integrated, all other kits would be left out.

#### Crash Reporter (iOS Only)

The crash reporter feature has been implemented as an optional subspec. It is installed by default, however, if you are fine tuning your installation, you can choose to install it or not in your Podfile.

```ruby
pod 'mParticle-Apple-SDK/CrashReporter', :git => 'https://github.com/mParticle/mParticle-iOS-SDK.git', :branch => 'extensions'
```

> CrashReporter and Crittercism are mutually exclusive subspecs. If your app needs to use the Crittercism kit, it must _**not**_ include the CrashReporter subspec in your Podfile.

### Kits

With each integration with a partner we strive to implement as many features as possible in the server-to-server layer, however some times a deeper integration to work side-by-side with a 3rd party SDK comes with greater benefits to our clients. We use the term **Kit** to describe such integrations.

#### Here is the List of All Currently Supported Kits

* [Adjust](https://www.adjust.com)
* [Appboy](https://www.appboy.com)
* [AppsFlyer](https://www.appsflyer.com)
* [Branch Metrics](https://branch.io)
* [comScore](https://www.comscore.com)
* [Crittercism](http://www.crittercism.com)
* [Flurry](https://developer.yahoo.com)
* [Kahuna](https://www.kahuna.com)
* [Kochava](https://www.kochava.com)
* [Localytics](https://www.localytics.com)
* [Tune](https://www.tune.com)
* [Wootric](https://www.wootric.com)

## Initialize the SDK

The syntax for the import statement to use the mParticle SDK needs to be one for **modules** or **semantic import**.

```objective-c
@import mParticle_Apple_SDK;
```

The mParticle SDK is initialized by calling the `startWithKey` method within the `application:didFinishLaunchingWithOptions:` delegate call. The mParticle SDK must be initialized with your app key and secret prior to use. Preferably the location of the initialization method call should be one of the last statements in the `application:didFinishLaunchingWithOptions:`

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


## Migrating From Version 4.x to Version 5.x (iOS Only)

Remove the statement from your `Podfile`

```ruby
pod 'mParticle', '~> 4'
```

and replace it with one of the options described above.

The `#import` statements are now simpler, instead of:

```objective-c
#import <mParticle/mParticle.h>
```

use:

```objective-c
@import mParticle_Apple_SDK;
```

In case you had the need to directly call methods from a 3rd party provider kit through the mParticle SDK, you no longer need to indirectly import their headers. You can just import them directly as indicated in the provider respective documentation. For example, if you were using:

```objective-c
#import <mParticle/Appboy/AppboyKit.h>
```

You will now use:

```objective-c
#import <AppboyKit.h>
```

Or whichever other way is recommended by the 3rd party provider.


## Example Project with Sample Code

A sample project is provided with the mParticle Apple SDK. A multi-platform video streaming app for both iOS and tvOS.

Clone the repository to your local machine

```bash
git clone https://github.com/mParticle/mParticle-iOS-SDK.git
```

In order to run either the iOS or tvOS examples you will first install the mParticle Apple SDK via CocoaPods.

1. Change to the `Example` directory
2. Run `pod install`
3. Open **Example.xcworkspace** in Xcode, select either the **iOS_Example** or **tvOS_Example** scheme, build and run. (In case you want to run on iOS 7, please use the **iOS7_Example** scheme instead)

> You can read a great blog post about developing a multi-platform app using the mParticle Apple SDK  [here](http://blog.mparticle.com/unified-mparticle-apple-sdk/)

## Documentation

Detailed documentation and other information about the mParticle SDK can be found at: [http://docs.mparticle.com](http://docs.mparticle.com)


## Author

mParticle, Inc.


## Support

<support@mparticle.com>


## License

mParticle-Apple-SDK is available under the Apache license. See the LICENSE file for more info.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
