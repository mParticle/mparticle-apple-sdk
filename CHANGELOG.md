# mParticle Apple SDK CHANGELOG

## 6.15.16

### Core SDK Updates

This release fixes an issue with setting user attributes concurrently from multiple threads.

### Kit Updates

- None

## 6.15.15

### Core SDK Updates

This release introduces a new API to kit developers. Kits can now delay the first upload of the Core SDK. This is to allow for necessary 3rd-party ID collection.

### Kit Updates

- Update Adobe kit to delay uploads prior to MCID collection

## 6.15.14

### Core SDK Updates

- Always forward didReceiveRemoteNotification API
- Fix main thread error

### Kit Updates

- Add Carthage support to Leanplum
- Update Apptentive SDK to 4.0.7
- Update BranchMetrics SDK to 0.20.2

## 6.15.13

### Core SDK Updates

- None

### Kit Updates

- Update UrbanAirship kit with named user support

## 6.15.12

### Core SDK Updates

- Disable code coverage settings
- Limit how often config requests can be sent

### Kit Updates

- Update Appboy kit with simplified endpoint logic
- Update ComScore SDK to 5.0

## 6.15.11

### Core SDK Updates

- Delay deeplinking call to kits if necessary

### Kit Updates

- Update AppsFlyer kit to support onAppOpenAttribution
- Update AppsFlyer SDK to 4.8.0
- Update Branch SDK to 0.18.8

## 6.15.10

### Core SDK Updates

- None

### Kit Updates

- Fix Localytics SDK version

## 6.15.9

### Core SDK Updates

- None

### Kit Updates

- Update Localytics SDK version

## 6.15.8

### Core SDK Updates

- Set transaction attributes on kit purchase events

### Kit Updates

- Add Adobe kit

## 6.15.7

### Core SDK Updates

- None

### Kit Updates

- Update AppsFlyer kit to support checking for deep links
- Update UrbanAirship kit to add transaction id to purchase events

## 6.15.6

### Core SDK Updates

- Prevent deprecation warnings for iOS 11 deployment target

### Kit Updates

- Update Singular and Apptentive kits to support Carthage

## 6.15.3

### Core SDK Updates

- Remove Git submodules from the repo to address https://github.com/mParticle/mparticle-apple-sdk/issues/49

### Kit Updates

- Update Singular kit with fixes from the Singular team: https://github.com/mparticle-integrations/mparticle-apple-integration-singular/pull/4

## 6.15.0

### Core SDK Updates

- All kits repos are now git submodules within the core repository

### Kit Updates

- mParticle now support Singular (formerly Apsalar) via both a Kit and server-side integration!
- This release introduces a class method to `MPKitAppsFlyer` such that implementing apps can set the AppsFlyer tracker delegate.
- Update Kochava SDK to 3.2.0
- Update Appboy SDK to 3.0.0
- Update Branch SDK to 0.17.6

## 6.14.5

* [FIX] Fixes for Xcode 9 / iOS 11 and main thread checker
* [NEW] Remove category on NSUserDefaults

## 6.14.4

* [FIX] Ensure all server-side configuration settings are reloaded on every app-launch

## 6.14.3

* [FIX] Revert main thread error fix

## 6.14.2

* [FIX] Fix main thread error
* [FIX] Fix clang pragma
* [FIX] Remove check for notification hash

## 6.14.1

* [FIX] Retry and increase timeout for search ads

## 6.14.0

* [NEW] Add support for Skyhook
* [NEW] Add support for Iterable

## 6.13.3

* [FIX] Capture user agent in start, never in background

## 6.13.2

* [FIX] Fix clang static analyzer warnings

## 6.13.1

* [FIX] Support for [Radar](https://www.onradar.com) as a kit
* [FIX] Support for forcing SDK Environment on start-up

## 6.13.0

* [NEW] Handle eCommerce events from embedded js sdk
* [NEW] Optimize user identity and user attribute change messages
* [NEW] Sync user attributes and identities only once per kit

## 6.12.6

* [FIX] Force refresh the config cache when a kit configuration is absent

## 6.12.5

* [NEW] Use mutable copy of string when setting a user attribute key

## 6.12.4

* [NEW] Include latitude and longitude in session start events
* [NEW] Allow for environment override even for prod apps
* [FIX] Reporting of commerce events when originated from a custom mapping

## 6.12.3

* [FIX] Execute projection when the commerce event has no mapped attributes

## 6.12.2

* [NEW] Remove eTag when app version or build changes
* [FIX] Enumeration to generate upload batches is done non-concurrently

## 6.12.1

* [FIX] A try/catch block added to serialization of MPMessage. Moreover, further conditions were added to assure the values being handled by the MPUploadBuilder are valid

## 6.12.0

* [NEW] Support for [Radar](https://www.onradar.com) as a kit
* [NEW] Retrieve kit instance asynchronously with a block. Use `- (void)kitInstance:(NSNumber *)kitCode completionHandler:(void (^)(id _Nullable kitInstance))completionHandler;` to retrieve a kit instance. The block will be called immediately if the kit is already initialized, or will be called asynchronously as soon as the kit becomes initialized
* [NEW] Lighter SDK. New Year, new resolution, the core SDK has gone on a diet. Stay tuned, more to come
* [FIX] Fix location getter and nullability notation

## 6.11.2

* [NEW] Set location without the need to call `beginLocationTracking`
* [FIX] Upload data immediately on first application launch

## 6.11.1

* [NEW] Queue launch parameters. The app notification handler now takes advantage of the forwarding queue mechanism. If kits have not been initialized yet (config not received from server), the data will be held in a queue and once the configuration has been received and kits initialized, the queued items are replayed to kits

## 6.11.0

* [NEW] Support for [Reveal Mobile](http://www.revealmobile.com/) as a kit
* [NEW] Wrap the capture of the user-agent in a try/catch
* [FIX] Adjust CommerceEvent property serialization: currency, screen name, and non-interactive are now located at the root of serialized CommerceEvent messages
* [FIX] Simplify session management when app becomes active

## 6.10.5

* [FIX] Increment user attribute when not set previously
* [FIX] Runtime iOS 10 verification of push notifications

## 6.10.4

* [FIX] Fix potential race condition beginning sessions
* [FIX] End background task when batches are finished

## 6.10.3

* [FIX] Fix crash when an app is being force quit.

## 6.10.2

* [FIX] Remove the use of generics from the `checkForDeferredDeepLinkWithCompletionHandler:` method. The received parameter signature is now `NSDictionary`, previously it was `NSDictionary<NSString *, NSString *>`

## 6.10.0

* [NEW] Collect attribute details from search ads
* [FIX] Compare custom mapping keys in a case insensitive manner
* [FIX] Convert event attributes to <string, string> prior to matching custom mappings
* [FIX] Generate the upload batch when the app is terminated by the user or OS. This way app version and build will always be correctly attributed to app events

## 6.9.0

* [NEW] Support for [Apptimize](https://apptimize.com) as a kit
* [NEW] Collect whether Daylight Savings Time is enabled
* [NEW] Add notification for when the SDK has finished initializing. Add a flag property indicating whether the SDK has been initialized (KVO compatible)

## 6.8.0

* [NEW] Support for [Leanplum](https://www.leanplum.com) as a kit
* [NEW] When a user identity changes a new type of message is added to the batch to be uploaded to the server. This allows for greater control to inform partners about which user identities were set/present at the moment an app event is logged

> You will need for this SDK update:
> * Xcode 8 or later
> * CocoaPods 1.1.0.rc.2 or later

## 6.7.2

* [FIX] When a user attribute changes (new, update, or delete) a new type of message is added to the batch to be uploaded to the server. This allows for greater control to inform partners about which user attributes were set/present at the moment an app event is logged

## 6.7.1

* [FIX] Timing of logged events: Events (both app events and commerce events) now have a timestamp property, which gets populated automatically by the SDK, when an event is logged prior to the SDK being fully initialized. If set, this property will override the timestamp of messages when they are about to be persisted

## 6.7.0

* [NEW] Custom mappings now support more advanced matching schemes
* [NEW] Support for [Urban Airship](https://www.urbanairship.com) as a kit

## 6.6.1

* [FIX] A newly introduced class was missing from the tvOS Xcode target

## 6.6.0

* [NEW] Kits can now pass integration attributes back to the core SDK

## 6.5.0

* [NEW] Support for [Primer](https://goprimer.com) as a kit

## 6.4.0

* [NEW] Support for [Apptentive](http://www.apptentive.com) as a kit
* [NEW] MParticleConfig.plist option to opt in/out of automatic silent notification registration. See [mParticle Docs](http://docs.mparticle.com/#apple) for details

## 6.3.0

* [NEW] Add the customerId user identity as an event attribute when forwarding to AppsFlyer
* [NEW] Add new methods to the kit protocol to forward user notification related info to kits
* [NEW] Config optional flag to send the session history batch (reducing the amount of data sent over to mParticle)
* [NEW] Opt-in to always try to collect the IDFA
* [NEW] Add continueUserActivity to the public SDK API (Pull Request submitted by twobitlabs)
* [FIX] Guarantee that launch options in AST messages to contain only string parameters

## 6.2.0

* [NEW] Support for [Button](https://www.usebutton.com) as a kit
* [FIX] Server configuration override of crash report initialization is restored

## 6.1.0

* [NEW] User attributes can now take arrays as values. The array of values is associated with a user attribute key. The list of all user attributes can be retrieved using the new `userAttributes` property

## 6.0.7

* [FIX] Filter transaction attributes in commerce events
* [FIX] Expand the scope of MPAppDelegateProxy to handle protocol conformance and class hierarchy matching
* [FIX] Fix static analysis flags
* [FIX] Add clang pragmas to remove warnings

## 6.0.6

* [FIX] Using a string constant (iOS 9 or above) or a string literal (iOS 8 or below) to log a deep-linking event

## 6.0.5

* [FIX] Add additional checks for iOS 9 symbols

## 6.0.4

* [FIX] More consistent handling of kit initialization and sampling

## 6.0.3

* [FIX] Expose some files for use by kits
* [FIX] Add nil check and prevent modifying while enumerating

## 6.0.2

* [FIX] Set the kits initialized flag only if persisted kits have been initialized

## 6.0.1

* [FIX] Correct a condition determining whether variables were valid

## 6.0.0

* [NEW] We are introducing the ability to implement extensions for the mParticle SDK. Kits have been the first component to take advantage of this new and more powerful architecture
* [NEW] A queue was added to hold events to be forwarded to kits until the first configuration is received from the server and kits are initialized
* [NEW] Added support for Carthage
* [NEW] Maximum user attribute value length has been extended to 4096 characters
* [FIX] Restored unit tests for each of the platforms

## 5.5.2

* [NEW] Stripping `$` from event attributes when forwarding to Appboy
* [FIX] Updated the `podspec` to include paths and flags required to build kits

## 5.5.1

* [NEW] Added Branch Metrics support for received push notifications
* [NEW] Renamed the `MPLogLevel` enum to `MPILogLevel`. The renamed values are: `MPILogLevelNone`, `MPILogLevelError`, `MPILogLevelWarning`, `MPILogLevelDebug`, and `MPILogLevelVerbose`

## 5.5.0

* [NEW] Unification of the SDKs. Now the iOS and tvOS SDKs are combined into one single SDK. Support for more platforms will be coming in the future
* [NEW] Updated Kahuna kit
* [NEW] Conforming to the RFC 6585 HTTP status code 429, `Retry-After` response header

## 5.4.2

* [NEW] Validating the data type in event custom flags. Making sure that the array of flags is an array and that it only contains string items in it
* [FIX] Do not forward push information to Kahuna if the app was launched as a result of a user tapping on a push notification, since their SDK is already capturing the contents of the notification. There is no impact on data forwarding/counting/reporting, this just prevents a Kahuna delegate method from being called twice

## 5.4.1

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
