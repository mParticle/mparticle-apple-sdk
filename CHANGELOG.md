# mParticle iOS SDK CHANGELOG

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
