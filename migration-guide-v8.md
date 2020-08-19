# Apple SDK 8 Migration Guide

This is an evolving document, please keep checking back as the release of iOS 14 approaches.

This guide contains an overview of the changes Apple is introducing with iOS 14 and includes an API migration guide so that you can easily upgrade to the latest mParticle SDK.

## What's Changing?

- Apple's iOS 14, tvOS 14, iPadOS 14, and Xcode 12 are in beta and will be released in late September or early October 2020.
- mParticle has released a beta SDK updated with critical changes such that you can test your apps ahead of the Xcode 12 release.
- mParticle is removing the query of IDFA from the Apple SDK. See the migration guide below for API changes and other details.
- mParticle is working to release updates for any kits to their respective SDK versions for iOS 14

**mParticle recommends that all customers upgrade to Apple SDK version 8.0.0 or later in order to provide end users with the best experience, avoid disruption in data collection, and to follow the spirit of Apple's privacy focus in iOS 14.**

## When will the SDK be released?

After the beta SDKs, mParticle will release the official SDK no later than the *same week* as the Xcode 12 "Gold Master" release. This typically occurs in late September or early October. During that week, also expect to see multiple releases of kit dependencies as respective partners also update their SDKs.

## Preparing for iOS 14 

iOS 14, iPadOS 14, and tvOS 14 introduce several critical API changes as well as new Apple App Store submission guidelines, and mParticle has updated the Apple SDK and the broader mParticle platform to adhere to and follow the spirit of these changes.

This guide enumerates some of the high-level changes introduced by Apple and how to upgrade your app and mParticle configuration to be compatible with them.

### AppTrackingTransparency framework

One of the more impactful changes relates to the collection of user identifiers, and specifically the Advertising Identifier (IDFA). From [Apple's documentation](https://developer.apple.com/app-store/user-privacy-and-data-use/):

> With iOS 14, iPadOS 14, and tvOS 14, you will need to receive the user’s permission through the AppTrackingTransparency framework to track them or access their device’s advertising identifier. Tracking refers to the act of linking user or device data collected from your app with user or device data collected from other companies’ apps, websites, or offline properties for targeted advertising or advertising measurement purposes. Tracking also refers to sharing user or device data with data brokers.

What this means in practice for developers is:

- The advertising identifier (IDFA) will not be available unless you specifically request user consent via the `AppTrackingTransparency` framework.
- If you have multiple apps, this must happen for any app that wishes to query the IDFA
- Users can revoke this consent at any time via the settings app.
- The consent is otherwise maintained until the app is uninstalled.
- The "Limit ad tracking" boolean has been deprecated - it will always return false

> Note that this is for *all* users that upgrade to iOS 14. Whether your app is upgraded to target iOS 14 or not, the IDFA will stop being available as soon as your users upgrade.

### What does this mean for the mParticle platform?

First, mParticle has no strict dependency on the IDFA. mParticle does not ever co-mingle your data with other customers data or perform any cross-customer identity resolution. From the mParticle platform's perspective, the IDFA is just another identifier. The data that you send to mParticle is opt-in, and if you decide to request access to and collect IDFA, you may continue to include it API calls to the mParticle Events API. However, there are several critical ways in which your mParticle integrations may be using IDFA today which may be affected by its unavailability.

mParticle is working with all partners to update their respective integrations as needed. For many integrations, in particular analytics and data warehouses, the transition will be seamless as they rely only on either no ID at all, or first-party IDs (IDFV, Customer IDs, first-party cookies, etc) for accurate user and device segmentation. For other integrations such as "attribution," audience-based advertising, and event-based ad integrations, the absense of IDFA is expected to have a larger impact and mParticle is working with each of them to ensure the best experience for their respective platform, via mParticle.

### What does this mean for the mParticle Apple SDK?

mParticle's Apple SDK v7 and earlier automatically query for the IDFA on app startup. Starting with Apple SDK 8.0, all IDFA-querying code has been entirely removed from the SDK. 

**If you wish to collect the IDFA, you must specifically provide it to the SDK's Identity API methods, see below for details.**

### What happens if I don't upgrade to the latest SDK?

The previous SDKs will continue to function largely without issue, however:

- IDFA collection may be disrupted. The previous SDKs immediately query for the IDFA on app startup, which is likely prior to when the user has consented to IDFA (if you choose to prompt them at all)
- Since the previous SDKs contain symbols relating to the IDFA, it is expect that you will need to justify during app submission and to your users why you collect IDFA, even if you don't intend to. 
- Previous Kit versions may use outdated partner SDKs, which may also have critical iOS 14 changes 

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
```

#### Apple SDK 8

```objective-c

MPIdentityApiRequest *identityRequest = [MPIdentityApiRequest requestWithUser:currentUser];
[identityRequest setIdentity:@"123456" identityType:MPIdentityCustomerId];
```

#### Supplying the IDFA in Apple SDK 8

If you would like to collect the IDFA with Apple SDK 8, you must [follow Apple's guidelines](https://developer.apple.com/documentation/apptrackingtransparency) to implement the AppTrackingTransparancy framework. If the user consents to tracking, you can provide the ID to the identity API just as with any other ID:

```objective-c
MParticleUser *currentUser = [[MParticle sharedInstance] identity].currentUser;
MPIdentityApiRequest *identityRequest = [MPIdentityApiRequest requestWithUser:currentUser];
[identityRequest setIdentity:advertiserID identityType:MPIdentityIOSAdvertiserId];
```

#### Common IDFA Use-cases

The following are some common use-cases and best practices:
1. If you are looking to collect IDFA, you should *always* provide it to the mParticle SDK when creating an identity request
2. On first launch of your app, the mParticle SDK will make an initial identify request. If the user has never consented to IDFA collection, IDFA will be unavailable to you, and as such you will not be able to provide it on your initial identity request. If and when the IDFA is made available to your app, you should perform an `identify` request or a `modify` request, supplying all known IDs of the current user as well as the newly known IDFA.
3. When a user logs out of your application, be sure to provide IDFA to the identity `logout` API - it will *NOT* automatically be passed from one user to the next. You must provide it for *every identity request*.

[See the example application](https://github.com/mParticle/mparticle-apple-sdk/tree/master/Example) in the Apple SDK repository for a full implementation of the AppTrackingTransparency framework.

**Other device IDs such as the IDFV as still automatically collected, though you can also provide them with this new API if you would like to override the Apple SDK's collection.**

## App Clips

Apple SDK 8 is compatible with App Clips and more documentation and samples will be provided prior to the official release of iOS 14. The SDK is designed to be light-weight and has few dependencies on outside frameworks, and as such functions without issue within the limited capacity of an App Clip. [See Apple's guidelines here](https://developer.apple.com/documentation/app_clips/developing_a_great_app_clip) for the frameworks and identifers available in an App Clip. 

**Notably, IDFV is not available in an App Clip, so you cannot rely on this identifier for App Clip data collected via mParticle.**

## Approximate Location

**The mParticle Apple SDK never automatically gathers location, it has always been and continues to be an opt-in API.**

Starting with iOS 14, app developers can request "approximate" location for use-cases that do not require "precise" location. Specifically, [the `CLLocationAccuracy` enum has been modified](https://developer.apple.com/documentation/corelocation/cllocationaccuracy) to add a new `kCLLocationAccuracyReduced` option.

The mParticle Apple SDK's API is unchanged, but you can now provide this reduced accuracy option if you choose:

```objective-c
[[MParticle sharedInstance] beginLocationTracking:kCLLocationAccuracyReduced
                                      minDistance:1000];
```

# Additional Changes in SDK v8

## Kit Dependencies

Historically mParticle has centrally managed and released most kits. This allowed us to rapidly improve the APIs exposed to kits, while also providing app developers with a consistent experience. Specifically, with SDK version 7 and earlier, the mParticle engineering team would release *matching* versions of all kits. So for example, your Podfile (or Cartfile) should have looked something like this, with *all versions matching*:

```ruby
pod 'mParticle-Apple-SDK', '7.16.2'
pod 'mParticle-Appboy', '7.16.2'
pod 'mParticle-BranchMetrics', '7.16.2'
```

Starting with SDK 8, this paradigm is changing. As more partners develop their own kits, and in order to release kits (and the core SDK) SDK more rapidly, we are decoupling kit versions from the core SDK version.

**For the release of SDK 8 all existing kits will be updated to 8.0.0**, and will begin to diverge depending on the pace of development of each kit.

For SDK version 8, we recommend updating the above Podfile as follows:

```ruby
pod 'mParticle-Apple-SDK', '~> 8.0'
pod 'mParticle-Appboy', '~> 8.0'
pod 'mParticle-BranchMetrics','~> 8.0'
```

The above Podfile may eventually resolve to different versions of each kit. However, mParticle has committed to making *no breaking API changes to kit APIs prior to the next major version, 9.0*. This means that it's always in your best interest to update to the latest versions of all kits as well as the Core SDK, and you do not need to worry about matching versions across your kit dependencies.
