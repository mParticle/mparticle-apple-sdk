# Apple SDK 8 Migration Guide

Apple’s new App Tracking Transparency (ATT) framework and the respective App Store review guidelines introduce industry-shifting, privacy-focused changes. Under the latest guidelines, device data must only be used for "cross-application tracking" after the device has opted-in via the new ATT framework. mParticle acts an extension of your data infrastructure, and it's your responsibility to adhere to Apple's guidelines and respect user privacy by auditing the integrations you use and where end-user data is sent.

The mParticle platform has been adapting to these changes and we've made several critical API and SDK updates to ensure the best development experience and allow for conditional data-flows based on an end user's ATT authorization. This guide contains a quick overview of the changes Apple is introducing with iOS 14 and includes an SDK migration guide so that you can easily upgrade to the latest mParticle SDK.

## What's Changing?

- Apple's iOS 14, tvOS 14, iPadOS 14, and Xcode 12 were released September 16th, 2020. This introduced the new ATT framework, but did not include the enforcement of its usage.
- mParticle released Apple SDK 8.0.1 in September 2020, removing the automatic-query of the IDFA from the SDK and other changes detailed below
- mParticle released Apple SDK 8.2.0 in February 2021, in anticipation of the iOS 14.5 release. Version 8.2.0 exposes a new API to collect the device's App Tracking Transparency authorization status
- mParticle is continually releasing updates for both server-side integrations and client-side kit integrations, as the respective partner APIs and SDKs adapt

## Preparing for iOS 14 

Under these new privacy guidelines each app must ensure that all user data processing obeys user consent elections and ultimately protects them from breaching App Store Review guidelines.

Please reference the following two Apple documents for the latest compliance requirements:

- [User Privacy and Data Use Overview](https://developer.apple.com/app-store/user-privacy-and-data-use/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

## Developer Migration Guide

Please see below for Apple-SDK specific guidance, and [reference the mParticle iOS 14 guide](https://docs.mparticle.com/developers/sdk/ios/ios14) to understand how this fits into the broader platform.

### App Tracking Transparency Framework Support

The App Tracking Transparency framework replaces the [original `advertisingTrackingEnabled` boolean flag](https://developer.apple.com/documentation/adsupport/asidentifiermanager/1614148-advertisingtrackingenabled) with the new `ATTrackingManagerAuthorizationStatus` enumeration. With mParticle, you can now associate any device data with this new enumeration such that you can control the flow of data based on the end-user's wishes.

The mParticle Apple SDK automatically collects the publisher-sandboxed IDFV, but does not automatically collect any user identifers or the IDFA and it does not automatically prompt the user for tracking authorization. It is up to you to determine if your downstream mParticle integrations require ATT authorization for cross-application tracking, and if they require the IDFA.

[Please see Apple’s App Tracking Transparency guide](https://developer.apple.com/documentation/apptrackingtransparency) for how to request user authorization for tracking and collect their ATT authorization status.

#### ATT API Overview

- mParticle has introduced a new `att_authorization_status` field to [our data model](https://docs.mparticle.com/developers/server/json-reference/), which surfaces the same values as Apple's [`ATTrackingManagerAuthorizationStatus` enumeration](https://developer.apple.com/documentation/apptrackingtransparency/attrackingmanagerauthorizationstatus)
- mParticle has also introduced an optional `att_timestamp_unixtime_ms` field representing the time when the user responded to the ATT prompt or their status was otherwise updated
- The Apple SDK lets you set these two fields, and the `MPATTAuthorizationStatus` enumeration maps directly to Apple’s `ATTrackingManagerAuthorizationStatus` enumeration.
- All customers implementing the Apple SDK or sending iOS data server-to-server are encouraged to begin collecting and sending the status field. 
- **At a future date, this field will become required when providing mParticle with an IDFA**


### Collecting ATT Status with Apple SDK 8.2.0+

Once provided to the SDK, the ATT status will be stored by the SDK on the device and continually included with all future uploads, for all MPIDs for the device. If not provided, the timestamp will be set to the current time. The SDK will ignore API calls to change the ATT status, if the ATT status hasn’t changed from the previous API call. This allows the SDK to keep track of the originally provided timestamp.

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
