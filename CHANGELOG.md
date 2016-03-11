# mParticle Apple SDK CHANGELOG

>Upgrade suggestion levels:
>* **LOW**: An upgrade is not needed unless there are new features you want to use
>* **MODERATE**: An upgrade is recommended, but it's not urgent
>* **HIGH**: There is a bug that may affect a subset of users. Upgrade!
>* **CRITICAL**: There is a critical bug affecting _most users_. Upgrade ASAP!


## 6.0.0

>Upgrade suggestion: **MODERATE**.

* [NEW] We are introducing the ability to implement extensions for the mParticle SDK. Kits have been the first component to take advantage of this new and more powerful architecture

## 5.5.0

>Upgrade suggestion: **LOW**. Upgrade if you are planning to release a multi-platform app supporting iOS and tvOS

* [NEW] Unification of the SDKs. Now the iOS and tvOS SDKs are combined into one single SDK. Support for more platforms will be coming in the future
* [NEW] Updated Kahuna kit

## 5.4.2

>Upgrade suggestion: **LOW**

* [NEW] Validating the data type in event custom flags. Making sure that the array of flags is an array and that it only contains string items in it
* [FIX] Do not forward push information to Kahuna if the app was launched as a result of a user tapping on a push notification, since their SDK is already capturing the contents of the notification. There is no impact on data forwarding/counting/reporting, this just prevents a Kahuna delegate method from being called twice

## 5.4.1

>Upgrade suggestion: **HIGH**. If you are using Appboy, Branch Metrics, Localytics, or Impressions in commerce events

* [NEW] Expanded the Branch Metrics kit to handle `openURL` and `continueUserActivity`
* [NEW] Custom mapping between mParticle and Appboy user attributes
* [FIX] Fixed duplicate forwarding of a push notification when launching an app by tapping on a remote notification
* [FIX] Fixed the representation of custom attributes in commerce event product impressions
* [FIX] Fixed the predicate filtering active kits
* [FIX] Fixed the formatting of event attributes in `logError`
* [FIX] Correct the expected data type for configuring custom dimensions in Localytics

## 5.4.0

* Support for [Tune](https://www.tune.com/) as a kit
* Verifying whether obtained 3rd party custom module values are a supported data type

## 5.3.2

* Updated the nullability notation for handleActionWithIdentifier
* Deferring the execution of the code in the ApplicationDidFinishLaunching to the next run-loop as a workaround to a bug in the Sqlite implementation

## 5.3.1

* Determining whether to forward an app delegate call to the old deep-linking method
* Forwarding event attributes as user attributes to Appboy

## 5.3.0

* Support for [AppsFlyer](https://www.appsflyer.com) as a kit
* Implementation of filter by event attribute value
* Preventing session history batch being sent when data is ramped

## 5.2.3

* Indirect instantiation of Kochava to allow it to work in the mParticle SDK with dynamically linked frameworks, `use_frameworks!`, bitcode, and static libraries

## 5.2.2

* Updated the podspec and README to allow for the utilization of `use_frameworks!` and the mParticle SDK
* Fixed an overloaded start method that was overriding the running environment parameter

## 5.2.1

* Fixing the location of the Wootric subspec

## 5.2.0

* Support for [Wootric](https://www.wootric.com) as a kit
* Broadcast of the session start notification may incur a delay if the SDK is being started
* Renamed MPConstants to MPIConstants

## 5.1.6

* Verifying the boundaries of eCommerce currency values to avoid numbers represented using scientific notation
* Early detection of kit configuration change when migrating from SDK 4.x to 5.x
* Reporting the app key in the request header

## 5.1.5

* Replaced NSTimer with dispatch_source_t with positive results minimizing the use of energy
* Refactored class files adding the MP prefix

## 5.1.4

* Adopted Lightweight Generics
* Fixed a bug reporting active kits
* Enforcing the data type of eCommerce numeric values

## 5.1.3

* Adopted the Objective-C Nullability syntax
* Serializing kit configurations rather than kit instances
* Defined default subspecs
* New and updated unit tests

## 5.1.2

* Using asynchronous validation for authenticity of certificates

## 5.1.1

* Each commerce event action is dealt with in an action-by-action basis for Kahuna
* Fixed a bug expanding and forwarding events to kits with no support to eCommerce events

## 5.1.0

* Support for [Crittercism](http://www.crittercism.com) as a kit
* Crash reporter has been implemented as an optional subspec
* Validating the authenticity of network requests by alternative means to avoid errors raised by 3rd party SDKs mutating and proxying mParticle's original object performing the request
* Removed legacy semaphores from network connections
* Fixed a bug referencing commerce event names

## 5.0.2

* Fixed a bug about events with no attributes not being forwarded to kits

## 5.0.1

* Migrated Unit Tests from SDK version 4.x to 5.x
* Added support to the new iOS 9 application:openURL:options: app delegate method
* Fixed a bug migrating data when the database structure changes
