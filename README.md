<img src="http://static.mparticle.com/sdk/logo.svg" width="280">

# mParticle iOS SDK

<!---
[![CI Status](http://img.shields.io/travis/Dalmo Cirne/mParticle-iOS-SDK.svg?style=flat)](https://travis-ci.org/Dalmo Cirne/mParticle-iOS-SDK)
[![Version](https://img.shields.io/cocoapods/v/mParticle-iOS-SDK.svg?style=flat)](http://cocoapods.org/pods/mParticle-iOS-SDK)
[![License](https://img.shields.io/cocoapods/l/mParticle-iOS-SDK.svg?style=flat)](http://cocoapods.org/pods/mParticle-iOS-SDK)
[![Platform](https://img.shields.io/cocoapods/p/mParticle-iOS-SDK.svg?style=flat)](http://cocoapods.org/pods/mParticle-iOS-SDK)
-->

Hello! This is the initial open source release of the mParticle SDK. For the past 2 years we have been working tirelessly on developing each component of our platform; initially we deployed this SDK as an iOS framework, however we are at a different stage now, and we could not be more excited to be able to share it with you.

Your job is to build an awesome app experience that consumers love. You also need several tools and services to make data-driven decisions. Like most app owners, you end up implementing and maintaining numerous SDKs ranging from analytics, attribution, push notification, remarketing, monetization, etc. But embedding multiple 3rd party libraries creates a number of unintended consequences and hidden costs. From not being able to move as fast as you want, to bloating and destabilizing your app, to losing control and ownership of your 1st party data.

[mParticle](http://mparticle.com) solves all these problems with one lightweight SDK. Implement new partners without changing code or waiting for app store approval. Improve stability and security within your app. We enable our clients to spend more time innovating and less time integrating.

## Installation

#### All Kits

mParticle-iOS-SDK is available through [CocoaPods](https://cocoapods.org/?q=mparticle). To install it, simply add the following statement to your Podfile:

```ruby
target '<Your Target>' do
    pod 'mParticle-iOS-SDK', '~> 5'
end
```

> Configuring you Podfile with the statement above will include _all_ integrations defined in the default subspecs. (See note in [Crash Reporter](#crash-reporter)). You can choose to integrate only a subset of kits by specifying which ones in your Podfile using the pattern `pod 'mParticle-iOS-SDK/<kit>'`, as we can see in the sample configuration below:

#### Pick and Choose Kits

```ruby
pod 'mParticle-iOS-SDK/Appboy', '~> 5'
pod 'mParticle-iOS-SDK/BranchMetrics', '~> 5'
pod 'mParticle-iOS-SDK/Localytics', '~> 5'
```

In the case above, only the Appboy, Branch Metrics, and Localytics kits would be integrated, all other kits would be left out.

If you do not need to build the mParticle SDK with any kit 3rd party kits, and utilize only the server-to-server integrations, you can do it by configuring your Podfile with the following statement:

#### mParticle SDK Only

```ruby
pod 'mParticle-iOS-SDK/mParticle', '~> 5'
```

#### Crash Reporter

The crash reporter feature has been implemented as an optional subspec. It is installed by default, however, if you are fine tuning your installation, you can choose to install it or not in your Podfile.

```ruby
pod 'mParticle-iOS-SDK/CrashReporter', '~> 5'
```

> CrashReporter and Crittercism are mutually exclusive subspecs. If your app needs to use the Crittercism kit, it must _not_ include the CrashReporter subspec in your Podfile.


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

The mParticle SDK is initialized by calling the `startWithKey` method within the `application:didFinishLaunchingWithOptions:` delegate call. The mParticle SDK must be initialized with your app key and secret prior to use. Preferably the location of the initialization method call should be one of the last statements in the `application:didFinishLaunchingWithOptions:`

#### Swift

```swift
func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    // Other code goes here, prior to initializing the mParticle SDK
    // ...

    MParticle.sharedInstance().startWithKey("<<<App Key Here>>>", secret:"<<<App Secret Here>>>")

    return true
}
```

#### Objective-C

```objective-c
#import <mParticle.h>

- (BOOL)application:(UIApplication *)application
        didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Other code goes here, prior to initializing the mParticle SDK
    // ...

    [[MParticle sharedInstance] startWithKey:@"<<<App Key Here>>>"
                                      secret:@"<<<App Secret Here>>>"];

    return YES;
}
```


## Dynamically Loaded and Static Libraries

If you are using a dynamically loaded library installed via CocoaPods, you have probably uncommented `use_frameworks!` in your Podfile. In order to have the mParticle SDK to work is such situation you will need to add the following pre and post statements to your Podfile:

The `pre_install` statement should be added right after `use_frameworks!`, but before any of the targets.

```ruby
use_frameworks!

pre_install do |pre_i|
    def pre_i.verify_no_static_framework_transitive_dependencies; end
end

target 'your_project' do
...
```

The `post_install` statement should be added after the last target.

```ruby
target 'your_project_last_target' do
...
end

post_install do |pi|
    pi.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            if target.name == "mParticle-iOS-SDK"
                config.build_settings["OTHER_LDFLAGS"]  = '$(inherited) "-ObjC"'
            end
        end
    end
end
```


## Migrating From Version 4.x to Version 5.x

Remove the statement from your Podfile

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
#import <mParticle.h>
```

In case you had the need to directly call methods from a 3rd party provider kit through the mParticle SDK, you no longer need to indirectly import their headers. You can just import them directly as indicated in the provider respective documentation. For example, if you were using:

```objective-c
#import <mParticle/Appboy/AppboyKit.h>
```

You will now use:

```objective-c
#import <AppboyKit.h>
```


## Documentation

Detailed documentation and other information about the mParticle SDK can be found at: [http://docs.mparticle.com](http://docs.mparticle.com)

## Author

mParticle, Inc.

## Support

<support@mparticle.com>

## Usage

Clone the repository to your local machine

```bash
git clone git@github.com:mParticle/mParticle-iOS-SDK.git
```

Running the iOS sample app is as simple as selecting the **mParticle-iOS-SDK-Example** scheme, build and run.


## License

mParticle-iOS-SDK is available under the Apache license. See the LICENSE file for more info.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
