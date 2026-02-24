# mParticle Iterable Kit (Iterable SDK 6.x)

This is the [Iterable](https://iterable.com) integration for the [mParticle Apple SDK](https://github.com/mParticle/mparticle-apple-sdk), built against the [Iterable iOS SDK 6.x](https://github.com/Iterable/swift-sdk).

## Installation

### Swift Package Manager

Add the Iterable kit package dependency in Xcode or in your `Package.swift`.
Swift Package Manager resolves the `mParticle` SDK automatically as a transitive dependency, so you do not need a separate `.package` entry for `mparticle-apple-sdk`.

```swift
let mParticleVersion: Version = "9.0.0"

.package(
    url: "https://github.com/mparticle-integrations/mparticle-apple-integration-iterable-6",
    .upToNextMajor(from: mParticleVersion)
),
```

Then add `mParticle-Iterable` as a dependency of your target.

### CocoaPods

Add the kit dependency to your app's Podfile:

```ruby
pod 'mParticle-Iterable', '~> 9.0'
```

## Configuration

### Custom Iterable Config

You can pass a custom `IterableConfig` before mParticle initialization:

```swift
import IterableSDK
import mParticle_Iterable

let config = IterableConfig()
config.autoPushRegistration = true
MPKitIterable.setCustomConfig(config)
```

### User ID Preference

By default, the kit identifies users by email. To prefer user ID instead:

```swift
MPKitIterable.setPrefersUserId(true)
```

## Verifying the Integration

After installing, rebuild and launch your app. With the mParticle log level set to Debug or higher, you should see the following in your Xcode console:

```bash
Included kits: { Iterable }
```

## Platform Support

| Platform | Minimum Version |
| -------- | --------------- |
| iOS      | 15.6            |
| tvOS     | 15.6            |

## Documentation

- [mParticle Iterable Integration Guide](https://docs.mparticle.com/integrations/iterable/event/)
- [mParticle iOS SDK Documentation](https://docs.mparticle.com/developers/sdk/ios/)
- [Iterable iOS SDK Documentation](https://support.iterable.com/hc/en-us/articles/360035018152-Iterable-s-iOS-SDK-)

## License

Apache License 2.0
