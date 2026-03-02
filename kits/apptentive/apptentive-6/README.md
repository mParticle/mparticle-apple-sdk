# mParticle Apptentive Kit (Apptentive SDK 6.x)

This is the [Apptentive](https://www.apptentive.com) integration for the [mParticle Apple SDK](https://github.com/mParticle/mparticle-apple-sdk), built against the [Apptentive SDK 6.x](https://github.com/apptentive/apptentive-kit-ios).

## Installation

### Swift Package Manager

Add the Apptentive kit package dependency in Xcode or in your `Package.swift`.
Swift Package Manager resolves the `mParticle` SDK automatically as a transitive dependency, so you do not need a separate `.package` entry for `mparticle-apple-sdk`.

```swift
let mParticleVersion: Version = "9.0.0"

.package(
    url: "https://github.com/mparticle-integrations/mparticle-apple-integration-apptentive-6",
    .upToNextMajor(from: mParticleVersion)
),
```

Then add `mParticle-Apptentive` as a dependency of your target.

### CocoaPods

Add the kit dependency to your app's Podfile:

```ruby
pod 'mParticle-Apptentive', '~> 9.0'
```

## Verifying the Integration

After installing, rebuild and launch your app. With the mParticle log level set to Debug or higher, you should see the following in your Xcode console:

```bash
Included kits: { Apptentive }
```

## Platform Support

| Platform | Minimum Version |
| -------- | --------------- |
| iOS      | 15.6            |

## Documentation

- [mParticle Apptentive Integration Guide](https://docs.mparticle.com/integrations/apptentive/event/)
- [mParticle iOS SDK Documentation](https://docs.mparticle.com/developers/sdk/ios/)
- [Apptentive iOS SDK Documentation](https://github.com/apptentive/apptentive-kit-ios)

## License

Apache License 2.0
