# Apple SDK 8 Migration Guide

This guide contains an overview of the changes Apple is introducing with iOS 14 and includes an API migration guide so that you can easily upgrade to the latest mParticle SDK.

## What's Changing?

- Apple's iOS 14, tvOS 14, iPadOS 14, and Xcode 12 were released September 16th, 2020
- mParticle has released Apple SDK 8.0.1 with critical changes for Xcode 12 and iOS 14
- mParticle is removing the query of IDFA from the Apple SDK. See the migration guide below for API changes and other details.
- mParticle is continually working to release updates for any kits to their respective SDK versions for iOS 14

## Preparing for iOS 14 

The iOS 14, iPadOS 14, and tvOS 14 betas originally introduced several critical API changes as well as new Apple App Store submission guidelines. Apple has since reverted these changes, but mParticle has updated the Apple SDK and the broader mParticle platform to adhere to and follow the spirit of these changes which are to be reintroduced early next year.

## Developer Migration Guide

#### Removal of IDFA and Updated Identity API

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

*Note*: Starting in 2021, to collect the IDFA with Apple SDK 8 you will need to [follow Apple's guidelines](https://developer.apple.com/documentation/apptrackingtransparency) to implement the AppTrackingTransparancy framework. If the user consents to tracking, providing the IDFA proceeds as already described. If they do not or the AppTrackingTransparancy framework is not implemented, ASIdentifierManager's `advertisingIdentifier` API will return a nil, all-zero IDFA.

#### Common IDFA Use-cases

The following are some common use-cases and best practices:
1. If you are looking to collect IDFA, you should *always* provide it to the mParticle SDK when creating an identity request
2. On first launch of your app, the mParticle SDK will make an initial identify request. If the user has never consented to IDFA collection, IDFA will be unavailable to you, and as such you will not be able to provide it on your initial identity request. If and when the IDFA is made available to your app, you should perform an `identify` request or a `modify` request, supplying all known IDs of the current user as well as the newly known IDFA.
3. When a user logs out of your application, be sure to provide IDFA to the identity `logout` API - it will *NOT* automatically be passed from one user to the next. You must provide it for *every identity request*.

[See the example application](https://github.com/mParticle/mparticle-apple-sdk/tree/master/Example) in the Apple SDK repository for a full implementation of the AppTrackingTransparency framework.

**Other device IDs such as the IDFV as still automatically collected, though you can also provide them with this new API if you would like to override the Apple SDK's collection.**

## App Clips

Apple SDK 8 is compatible with App Clips. The SDK is designed to be light-weight and has few dependencies on outside frameworks, and as such functions without issue within the limited capacity of an App Clip. [See Apple's guidelines here](https://developer.apple.com/documentation/app_clips/developing_a_great_app_clip) for the frameworks and identifers available in an App Clip. 

**Notably, IDFV is not available in an App Clip, so you cannot rely on this identifier for App Clip data collected via mParticle.**

## Approximate Location

**The mParticle Apple SDK never automatically gathers location, it has always been and continues to be an opt-in API.**

Starting with iOS 14, app developers can request "approximate" location for use-cases that do not require "precise" location. Specifically, [the `CLLocationAccuracy` enum has been modified](https://developer.apple.com/documentation/corelocation/cllocationaccuracy) to add a new `kCLLocationAccuracyReduced` option.

The mParticle Apple SDK's API is unchanged, but you can now provide this reduced accuracy option if you choose:

```objective-c
[[MParticle sharedInstance] beginLocationTracking:kCLLocationAccuracyReduced
                                      minDistance:1000];
```

## Kit Dependencies

Historically mParticle has centrally managed and released most kits. This allowed us to rapidly improve the APIs exposed to kits, while also providing app developers with a consistent experience. Specifically, with SDK version 7 and earlier, the mParticle engineering team would release *matching* versions of all kits. So for example, your Podfile (or Cartfile) should have looked something like this, with *all versions matching*:

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

The above Podfile may eventually resolve to different versions of each kit. However, mParticle has committed to making *no breaking API changes to kit APIs prior to the next major version, 9.0*. This means that it's always in your best interest to update to the latest versions of all kits as well as the Core SDK, and you do not need to worry about matching versions across your kit dependencies.
