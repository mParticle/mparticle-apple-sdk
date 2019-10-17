# mParticle Apple SDK CHANGELOG


## 7.12.3

- This release fixes a typo that caused `MPEvent` attributes to return nil if the deprecated `info` property was used. Due to our kits not yet having been updated to use the new property name, this was resulting in empty event attributes dictionaries being forwarded to kits.

## 7.12.2

- This release fixes Commerce events collected over the WKWebView bridge. Previously, the mapping of Web SDK-defined product-actions to Apple SDK product-actions was incorrect.

## 7.12.1

### Core

- This release rolls back a change to the `MPEventType` enum that caused problems with Swift compatibility and adds Swift unit tests to ensure this API remains stable going forward.

- Guard against potential crash if null product array is received from JS webview integration

### Kits

- None

## 7.12.0

## mParticle Media SDK

This release introduces support for the [mParticle Apple Media SDK](https://github.com/mParticle/mparticle-apple-media-sdk)!

Media tracking capabilities have been added by creating a separate module that you can add to your project in addition to the core SDK.

For more details, see the Media SDK repository: https://github.com/mParticle/mparticle-apple-media-sdk

### Other items

- You may notice that our main `MParticle#logEvent:` API has been changed to take a different type of parameter. This should not affect your code, except you can now pass commerce events to that method in addition to `MPEvent` objects.

- This release also includes a change to improve session management in cases where the background timer was not allowed to run by the OS.

## 7.11.0

## iOS 13 Official Support
### Push Registration
If you are collecting push registration tokens and using them for server-side integrations, this is a *critical update*. If you are only registering for push via kits (such as Braze), you can use iOS Braze kit 7.10.7 or later with iOS 13.

### UIWebView and User Agent Collection
Support for UIWebView has been removed. User agent collection has been disabled in this release. You may manually supply the user agent to the MParticleOptions object on SDK initialization if required.

## 7.10.5

## Core

- Ensure user attributes are filtered on FilteredMParticleUser
- Simplify APIs and options used to start the SDK

## Kits

- Braze - Update API usage for endpoint and location
- Firebase - Standardize custom attribute keys and values
- Adobe - Fix linker error if modules are disabled

## 7.10.4

## Critical Bug Fixes

This release fixes a critical bug in SDK versions 7.8.6 and later where uploads could be prematurely deleted if the network request failed due to the device being offline.

This release also fixes a crash while migrating the SDK's internal database. The crash occurs for apps that had opted into manual-session tracking in a previous version of the SDK, and then upgraded to the latest version of the SDK.

## Core

- Bugfix for upload response processing
- Fix session id migration for messages and uploads

## Kits

- Appboy - Update endpoint override logic

## 7.10.2

## Core

Note: To ensure proper validation, this release updates the userIdentities property of MPIdentityApiRequest to be an immutable dictionary.

If you happened to be modifying this dictionary directly, you will need to update your code to call setUserIdentity:identityType: instead.

- Don't allow direct mutation of request identities
- Guard against nil events

## Kits

- Button - Update kit to use Button Merchant Library

## 7.10.1

## Core

- Update for Xcode 11
- Respect max age expiration for configuration requests

## Kits

- Update Urban Airship import statements

## 7.10.0

This release introduces support for user alias requests.

Aliasing allows you to copy data from one user to another, typically for the purpose of building audiences that include actions a user may have taken before they logged in.

This release also adds properties to a user that indicate when this user was first or last seen by the SDK. Getting the list of all users known to the SDK now sorts by the last time each user was seen.

## Core

- Add support for sending user alias requests
- Move sessionTimeout to MParticleOptions
- Guard against unexpected radio technology values
- Implement Inspector protocol
- Reachability improvements

## Kits

- Apptentive - Add ability to delay Apptentive SDK initialization
- Radar - Minor tracking updates

Minor changes have been made across the kits to bring source indentation and license/readme/podspec files into consistency.

## 7.9.2

## Core

- Fix legacy openURL method forwarding to kits
- Fix static code analytics warnings

## Kits

- None

## 7.9.1

## Core

- None

## Kits

### Pilgrim kit

We've released an integration with Foursquare Pilgrim! Docs will be published soon--in the meantime you can check out the [source code here](https://github.com/mparticle-integrations/mparticle-apple-integration-pilgrim).

### OneTrust kit

We have also released an integration with OneTrust! Check out the [docs here](https://docs.mparticle.com/integrations/onetrust/event/) and the [source code here](https://github.com/mparticle-integrations/mparticle-apple-integration-onetrust).

- Leanplum - Add device id setting
- Optimizely - Update Optimizely SDK to 3.0

## 7.9.0

## Core

### Session tracking update

This release updates the mechanism whereby the SDK tracks user sessions.

Previously the SDK would start a session whenever an event was received, even if the event was triggered when processing a background push or location update.

The SDK now measures sessions based on user engagement i.e. when the app is in the foreground and visible to the user.

In the past the SDK would make special accommodations for apps that have long running background sessions due to use of location or background audio, in that sessions would continue even when the app remained in the background for an extended period of time. As of this release, this behavior has changed so that the session ends when the app is backgrounded even if, for example, background audio is still playing.

We have also introduced new APIs to manually begin and end sessions, so that you may customize this behavior if necessary.

Finally, this release also addresses an issue where session end messages may not have been created after the app was forcibly killed.

- Update kit configuration validation
- Update Modify API Response
- Cleanup unused macros and update setting for extensions

## Kits

- Appboy - Update configuration error checking
- Clevertap - Update CleverTap SDK to 3.4.1
- Iterable - Fix crash if no webpage URL from continueUserActivity
- UrbanAirship - Update UrbanAirship SDK to 10.1

## 7.8.6

## Core

- Add new webview bridge support
- Fix kit queue log messages when no kits included
- Fix potential crash when uploading a large backlog of messages

## Kits

- Optimizely - Update data file interval key

## 7.8.5

## Core

- None

## Kits

### Google Analytics for Firebase Kit

We've released an integration with Google Analytics for Firebase! Check out the [docs here](https://docs.mparticle.com/integrations/firebase/event/) and the [source code here](https://github.com/mparticle-integrations/mparticle-apple-integration-google-analytics-firebase).

## 7.8.4

## Core

This release helps make our AppDelegate proxy mechanism more transparent by allowing KVO/KVC messages to pass through to the original AppDelegate as expected. It also cleans up a few analyzer warnings that were introduced and removes some validation code that could interfere with partner kit development or certain customer use cases.

- Fix analyzer warnings
- Fix AppDelegate KVO when proxying is enabled
- Remove MPKitInstanceValidator

## Kits

- ComScore - Add tvOS support

## 7.8.3

## Core

- Add new and updated existing integration attribute APIs

    - Allow integration attributes to be set for any ID (not just known kit IDs)
    - Add a public query API for specific integration attributes by ID
    - Rename the private usages and APIs from kitCode to integrationId

- Fix a potential hang that could occur if Apple Search Ads timed out

## Kits

- None

## 7.8.2

## Core

- Fix kit identity forwarding

If the mpid did not change, we were not forwarding identity events to kits. This change ensures that we are always forwarding identity events to our kits by removing the early return and restructuring the code for clarity in the future.

## Kits

- Optimizely - Update for tvOS

## 7.8.1

## Core

- Updates retry logic for collecting Apple Search Ads and introduces an option to disable collection.

## Kits

### Responsys Kit

We've released an integration with Oracle Responsys! Check out the [docs here](https://docs.mparticle.com/integrations/oracle-responsys/event/) and the [source code here](https://github.com/mparticle-integrations/mparticle-apple-integration-responsys).

## Static Framework updates

We've marked several kits as static frameworks to make them usable with CocoaPods `use_frameworks!`:

- Appsee
- Apteligent/Crittercism
- Instabot
- Kahuna
- Kochava
- Radar
- Taplytics

## 7.8.0

## Core

- Introduced an API to query for the "Device Application Stamp": `MParticle.sharedInstance.identity.deviceApplicationStamp`
- Added Custom Flag support to `MPCommerceEvent`

## Kits

### Optimizely Kit

We've released an integration with Optimizely! Check out the [docs here](https://docs.mparticle.com/integrations/optimizely/event/) and the [source code here](https://github.com/mparticle-integrations/mparticle-apple-integration-optimizely).

## 7.7.5

## Critical Bug Fix

This release contains a bug fix for a regression present in SDK versions 7.7.3 and 7.7.4. The issue only affects customers using client-side "kit" integrations. For these customers, events are sent as duplicates to each integration. If your app is on an impacted SDK, you can use mParticle's server-side filtering features to prevent events from being sent until you can upgrade to SDK 7.7.5 or later.

## Core SDK Updates

### Carthage binary artifacts

In addition to directly attaching binary artifacts to GitHub releases,
we will be providing Carthage json manifest files in the root of each repo
that supports Carthage.

This helps support the use of some command line flags (like --no-use-binaries)
that may not otherwise work properly with certain kits (e.g. Braze/mParticle-Appboy)

Please note that due to the required sequence of steps for the release process,
the json files will be generated and published prior to the artifacts being
uploaded, so the links in the json files may be invalid for a short period of time
after initially being committed.

### Updated SDK limits

The SDK no longer limits the size of non-array event attribute values to 255 characters,
lengths of up to 4096 characters are now supported.

Some obsolete limits have been removed.

### New SDK limits

Add limits for message, batch size

This release results in messages larger than 100K being dropped.

If your log level is set to Error or higher, a message will be logged
when this occurs.

This release also limits the total message bytes and total number
of messages that can be packed into each batch.

However, these batch-level limits will not result in dropped data
since the SDK will enforce the limits by producing smaller batches.

### Disable kits for Anonymous Users

You can now control which kits are enabled and disabled based on a user's "logged in" state. A common use case would be to initialize a given kit for non-anonymous (logged in) users. Navigate to a kit's connection settings in your mParticle dashboard to give this a try.

- Mark user segments API deprecated
- Fix kit location forwarding

## Kit Updates

- Appboy - Bugfix for in app message delegate
- AppsFlyer - Mark as static_framework to support `use_frameworks!`
- Update Taplytics to 2.33.0

## 7.7.2

## Core SDK Updates

- Fix a bug where webview events with an encoded slash in the event info were being dropped
- Fix retain cycles in MPConnector

## Kit Updates

### Kochava
- Ensure log level from config is always respected, not overridden by environment
- Don't set Kochava delegate unless retrieveAttribution setting is turned on
- Remove use of undocumented isNewUser flag

## 7.7.1

## Core SDK Updates

- Fix Reachability bug where we were incorrectly reporting users as being on wifi when they were actually using mobile data

## Kit Updates

- Kochava - Add support for mParticle Attribution API

## 7.7.0

## Core SDK Updates

- We've cleaned up and addressed several bugs around automatic push-notification event tracking.
- Several new APIs have also been introduced to control the tracking of push notifications. You can now manually log that a push has been received or opened. You can also disable the automatic collection of those two events via the MParticleOptions "trackNotifications" property.
- We've also addressed an issue whereby NSNull is passed to the legacy, pre-IDSync kit APIs as several kits, such as Branch, were unable to handle NSNull.

## Kit Updates

### Taplytics Kit

The Taplytics kit has been released with much help from the Taplytics team!

## 7.6.0

## Core SDK Updates

- Updates for better iOS 12 and Xcode 10 support. We upgraded to NSSecureCoding and silenced other deprecation warnings to maintain support for older iOS versions.
- Code cleanup and additional unit tests for session notifications

## Kit Updates

- Update Radar kit
- Add Appsee kit

## 7.5.7

## Core SDK Updates

- Simplify backend attribute tests
- Update readme for Localytics Carthage support
- Prevent non-modular include error
- Fix potential crash if called with nil identity

## Kit Updates

- None

## 7.5.6

## Core SDK Updates

- Update JS snippet to initialize webview
- Enable undefined behavior sanitizer for unit tests
- Silence sanitizer for hashing
- Fix validation for set user tag
- Allow disabling location tracking using ifdef

## Kit Updates

- Branch: Fix mapping of events to Branch events

## 7.5.5

## Core SDK Updates

- Allow querying the SDK for session ID

## Kit Updates

- Branch: Handle deep links at app startup

## 7.5.4

## Core SDK Updates

- Update the order of forwarding identities to kits

## Kit Updates

- Braze (mParticle-Appboy): Implement modify and login MPKitProtocol methods. This ensures that users are assigned the correct email address when sharing the same device.

**Warning**: You must be using version 7.3.0 or later of the core SDK in order to use this version of the Braze kit.

## 7.5.3

## Core SDK Updates

- None

## Kit Updates

- AppsFlyer: Map MPCommerceEvent product SKUs to af_content_id
- Localytics: Add Carthage support

## 7.5.2

- This release updates the `mParticleSessionDidBeginNotification` and `mParticleSessionDidEndNotification` notifications to contain the session GUID rather than the SQLite autoincrement ID. This GUID will match the GUID that is communicated via mParticle's server-to-server integrations.
- This release also updates the UIApplication `openURL` signature exposed by the SDK to be more compatible with Swift.

## 7.5.1

- This release completely removes the SDK's primary UIApplication termination listener. Prior to this change, the SDK could prevent process termination while it was performing several cleanup activities.

## 7.5.0

### iOS 12 beta and iOS 12 support

This release updates the SDK to handle several changes present in the latest beta builds of Xcode 10 and iOS 12.

## 7.4.2

- This releases addresses several synchronization issues with internal SDK properties that could lead to crashes.  

## 7.4.1

- This releases updates the SDK's UIAppication termination handler to perform operations sychronously. This handler is used to capture the latest device state prior to app force-closes such that subsequent uploads are accurate. Doing this sychronously on the main thread is required to avoid undefined behavior due to iOS process destruction.

## 7.4.0

- This release is a follow up to version 7.3.11 and moves all kit APIs invocations to the main thread rather than the mParticle SDK's message queue.

## 7.3.13

- This release updates the timing of when user identities are set on the MParticleUser object. This makes it so that once an identity callback is returned, the provided MParticleUser object has the most up-to-date identities present and queryable.

## 7.3.12

- This release addresses a migration-crash for customers upgrading from version 6 of the SDK and who are using the SDK's crash-detection APIs.
- This release also adds an appledoc plist to source such that the Appledocs can be generated more easily. We also host the Appledocs on the mParticle documentation site: https://docs.mparticle.com/developers/sdk/ios/appledocs/index.html

## 7.3.11

- This release ensures that kits are always started on the main thread rather than the SDK's internal serial queue. Kits will still not be started sychronously when calling `MParticle.start`, but they will be initialized on the main thread on a later run-loop. 

## 7.3.10

- This release updates the SDK's app extension support. The `MPARTICLE_APP_EXTENSIONS` flag is no longer necessary and the SDK will determine if it's running in an app extension based off the `appex` suffix in the app bundle.

## 7.3.9

- This release addresses warnings due to the Xcode main thread checker and adds additional synchronization for internal properties that are accessed acrossed threads.

## 7.3.8

## Core SDK Updates

- This release fixes an issue where uploads could be delayed until app background

## Kit Updates

- Kochava: Fix user identity usage to conform to the latest `FilteredMParticleUser` APIs

## 7.3.7

### Core SDK Updates

#### GDPR Consent Management

The SDK can now dynamically enable and disable kits based on the current user's ConsentState, for GDPR and any other regulation. This lets you enable or disable individual kits only if a given Consent purpose or purposes have been granted or rejected by the user.

##### Additional Updates

- New NetworkOptions API letting you customize SSL pinning and SDK endpoints.
- Ability to query for all users that the SDK has tracked locally on the device.
- Bugfix to address simulator reachability issues

### Kit Updates

- Leanplum: Fix user identity query to conform to the latest `FilteredMParticleUser` APIs

## 7.3.6

- This release updates the SDK's SQLite connection to allow for full multi-threaded access. The SDK does not generally access SQLite outside of a single serial queue, but in certain situations it will and could have potentially caused a crash due to simultanous access.

## 7.3.5

- This release fixes potential SQLite crashes caused by multi-threaded SQLite access caused by the SDK's significant time-change listener.
- This release addresses a potential crash or error log caused by kits that implement the attribution API and return a nil attribution result.

## 7.3.4 

- This is a **critical** bug fix release. Prior to this, the SDK would upload duplicate kit forwarding statistics. These statistic do not impact forwarding - but they populate the mParticle Event Forwarding dashboard. This change is crucial for proper reporting as well as reducing the amount of SDK SQL storage and upload payload size.

## 7.3.3

- This release makes a change to the KitProtocol to remove the `onUserIdentified` API.

## 7.3.2

This release replaces the previous release 7.3.1, addressing a crash that can occur on startup when certain configuration settings are present.

The following changes from 7.3.1 are also included:

Addresses an issue where configuration could be purged by the OS on low disk space devices and cleans up some compiler warnings.

Updates the Branch kit with support for Branch's v2 event tracking APIs, collecting search ads attribution and various other improvements.

## 7.3.1

- This release moves kit configuration cache into NSUserDefaults to ensure it is not deleted on devices with low storage space.

## 7.3.0

- This release introduces a series of enhancements to the SDK to ensure that all database and filesystem operations are performed off of the main thread. The SDK's internal message queue is now relied on for all operations.

## 7.2.1

This release optimizes SDK startup time by deferring or avoiding expensive operations that otherwise were taking place during SDK start.

In addition, it introduces an option to start kits asynchronously.

Here are a few important notes about this release:

- If you are using the Adjust kit, you must update to version 7.2.1 of the kit in coordination with this update to the core SDK. Otherwise your Adjust environment will not be set properly.
- The SDK no longer automatically disables logging in production. The default log level is now set to "none". If you increase the log level for your development builds, please ensure that change does not get compiled into the release version of your app.
- App delegate proxying was incorrectly disabled by default. This has been fixed.
- The SDK now collects user agent by default

## 7.2.0

This is a *high priority* update for all users of SDK v7. This update:
- Ensures database migrations from v6 to v7 occur on a background thread.
- Reduces the amount of data that is migrated.
- Simplifies batch upload creation and session deletion logic to ensure the SDK's database is fully cleared when appropriate.

## 7.1.5

### Core SDK Updates

- Avoid blocking the main thread while migrating the database
- Clean up analyzer warnings

### Kit Updates

- None

## 7.1.4

### Core SDK Updates

- None

### Kit Updates

- Leanplum

#### Leanplum Email Campaigns

The Leanplum kit has been updated to set "email" as a user attribute on the Leanplum SDK to enable Leanplum email campaigns. If you would not like to send email to Leanplum, you may filter email to Leanplum via the mParticle Filters UI.

## 7.1.3

### Core SDK Updates

**This SDK release is a required update for all customers who are migrating from v6.**

It fixes an issue where migrated user identities were not being included when building the initial identity request.

### Kit Updates

- None

## 7.1.2

### Core SDK Updates

- Cache user agent until OS version changes
- Fix Nil User Identity Issue

This release optimizes the capture of user agent to only happen when the OS version changes.

### Kit Updates

- None

## 7.1.1

### Core SDK Updates

- Avoid requesting config before start

This release fixes a bug where the SDK could trigger a call to config before start was called.

### Kit Updates

- None

## 7.1.0

# IDSync

Version 7.1.0 is the first non-beta release of the new mParticle IDSync framework. It contains many new features as well as breaking changes:

- New Identity APIs allowing custom IDSync "strategies" per customer. 
- Included in the new APIs is a `MParticleUser` object, as well as the new APIs for `login`, `logout`, `modify`, and more! [You can read more about the new Identity APIs here](https://docs.mparticle.com/developers/sdk/ios/identity).
- `MParticleOptions` object for explicit SDK configuration.
- New "Attribution" API, which replaces the former "deferred deeplink" API.

## Migrating from SDK v6

Prior to upgrading to version 7, your mParticle org **must** be provisioned with an Identity Strategy. Please contact the mParticle Customer Success team at support@mparticle.com. 

The new SDK contains multiple breaking API changes. To learn how to migrate your existing code, please [reference the iOS migration guide](https://docs.mparticle.com/developers/sdk/ios/getting-started#upgrade-to-version-7-of-the-sdk).

## 7.0.9

### Core SDK Updates

This release updates MPIdentityApiRequest by removing the copyUserAttributes setting, and adding an optional onUserAlias block. By setting this block on your request, you can copy user attributes per your business logic from one user to the next. You can also copy object from the user's cart.

### Kit Updates

- Update AppsFlyer with new attribution API
- Update BranchMetrics with new attribution API
- Update Button with new attribution API
- Update Iterable with new attribution API
- Update Singular with new attribution API
- Update Tune with new attribution API
- Update BranchMetrics SDK to 0.20.2
- Update UrbanAirship kit with named user support

## 7.0.8

* [NEW] Introduce new deeplinking API

## 7.0.7

* [FIX] Allow concurrent internal modify requests

## 7.0.6

* [FIX] Ensure Identifying flag is flipped on API timeout

## 7.0.5

* [FIX] Fixes and enhancements to Identity API error callbacks

## 7.0.4

* [FIX] Remove MPUtils.h/m

## 7.0.3

* [FIX] Ensure the correct mpid is used in batches
* [FIX] Fix device application stamp

## 7.0.2

* [FIX] Propagate Identity API errors to original caller

## 7.0.0

* [NEW] New identity APIs

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
