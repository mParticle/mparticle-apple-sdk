# mParticle Radar Kit

This is the [Radar](https://radar.com) integration for the [mParticle Apple SDK](https://github.com/mParticle/mparticle-apple-sdk), built against the [Radar iOS SDK 3.x](https://github.com/radarlabs/radar-sdk-ios).

## Installation

### Swift Package Manager

Add the Radar kit package dependency in Xcode or in your `Package.swift`.
Swift Package Manager resolves the `mParticle` SDK automatically as a transitive dependency, so you do not need a separate `.package` entry for `mparticle-apple-sdk`.

```swift
let mParticleVersion: Version = "9.0.0"

.package(
    url: "https://github.com/mparticle-integrations/mparticle-apple-integration-radar",
    .upToNextMajor(from: mParticleVersion)
),
```

Then add `mParticle-Radar` as a dependency of your target.

### CocoaPods

Add the kit dependency to your app's Podfile:

```ruby
pod 'mParticle-Radar', '~> 9.0'
```

## Verifying the Integration

After installing, rebuild and launch your app. With the mParticle log level set to Debug or higher, you should see the following in your Xcode console:

```bash
Included kits: { Radar }
```

## Platform Support

| Platform | Minimum Version |
| -------- | --------------- |
| iOS      | 15.6            |

## Documentation

- [mParticle Radar Integration Guide](https://docs.mparticle.com/integrations/radar/event/)
- [mParticle iOS SDK Documentation](https://docs.mparticle.com/developers/sdk/ios/)
- [Radar iOS SDK Documentation](https://radar.com/documentation/sdk/ios)

## License

Apache License 2.0
