# mParticle Braze Kit (Braze Swift SDK 14.x)

This is the [Braze](https://www.braze.com) integration for the [mParticle Apple SDK](https://github.com/mParticle/mparticle-apple-sdk), built against the [Braze Swift SDK 14.x](https://github.com/braze-inc/braze-swift-sdk).

## Installation

### Swift Package Manager

Add the Braze kit package dependency in Xcode or in your `Package.swift`.
Swift Package Manager resolves the `mParticle` SDK automatically as a transitive dependency, so you do not need a separate `.package` entry for `mparticle-apple-sdk`.

```swift
let mParticleVersion: Version = "9.0.0"

.package(
    url: "https://github.com/mparticle-integrations/mparticle-apple-integration-braze-14",
    .upToNextMajor(from: mParticleVersion)
),
```

Then add `mParticle-Braze` as a dependency of your target.

> **Note:** Add the `-ObjC` flag to your target's **Other Linker Flags** build setting, per the [Braze documentation](https://www.braze.com/docs/developer_guide/platform_integration_guides/ios/initial_sdk_setup/installation_methods/swift_package_manager#step-2-configuring-your-project).

### CocoaPods

Add the kit dependency to your app's Podfile:

```ruby
pod 'mParticle-Braze-14', '~> 9.0'
```

For iOS push-launch tracking, initialize Braze in `application(_:didFinishLaunchingWithOptions:)` **before** starting mParticle, then pass the instance to the kit:

```swift
import BrazeKit
import mParticle_Braze

let configuration = Braze.Configuration(
    apiKey: "[YOUR_BRAZE_API_KEY]",
    endpoint: "[YOUR_BRAZE_ENDPOINT]"
)
let braze = Braze(configuration: configuration)

MPKitBraze.setBrazeInstance(braze)
MPKitBraze.setShouldDisableNotificationHandling(true)
// Start mParticle after this.
```

Complete setup details (including required push delegate methods) are in the mParticle docs:

- [mParticle Braze iOS App Launch Tracking](https://docs.mparticle.com/integrations/braze/event/#ios-app-launch-tracking)

### Verifying the Integration

After installing, rebuild and launch your app. With the mParticle log level set to Debug or higher, you should see the following in your Xcode console:

```bash
Included kits: { Braze }
```

## Platform Support

| Platform | Minimum Version |
| -------- | --------------- |
| iOS      | 15.0            |
| tvOS     | 15.0            |

## Privacy and consent

Enabling mParticle opt-out unsubscribes the current Braze user from email. Disabling
opt-out does not automatically resubscribe them. Use the explicit `email_subscribe`
user attribute to manage subsequent email subscription changes.

The kit forwards Google consent attributes only from consent supplied by the core
SDK, after device consent overrides and per-kit regulation/purpose filters. Missing
or filtered purposes do not update Braze attributes; an explicit denial sends `false`.
Update both the core SDK and this kit to receive the complete consent fix, including
replay when Braze starts or the current user changes. Older core versions remain
compatible but do not provide this startup replay.

The opt-out description in the external integration guide currently contradicts
this behavior and needs correction. The behavior above restores the Apple kit's
semantics before its [Swift SDK migration](https://github.com/mparticle-integrations/mparticle-apple-integration-appboy/pull/68).

## Documentation

- [mParticle Braze Integration Guide](https://docs.mparticle.com/integrations/braze/event/)
- [mParticle iOS SDK Documentation](https://docs.mparticle.com/developers/client-sdks/ios/)
- [Braze Swift SDK Documentation](https://www.braze.com/docs/)

## Issues

Please report bugs and feature requests to the [mparticle-apple-sdk](https://github.com/mParticle/mparticle-apple-sdk/issues) repository. This mirror repository is not actively monitored for issues.

## License

[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0)
