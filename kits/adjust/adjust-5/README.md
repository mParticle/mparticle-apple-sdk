# mParticle Adjust Kit (Adjust SDK 5.x)

This is the [Adjust](https://www.adjust.com) integration for the [mParticle Apple SDK](https://github.com/mParticle/mparticle-apple-sdk), built against the [Adjust SDK 5.x](https://github.com/adjust/ios_sdk).

## Installation

### Swift Package Manager

Add the Adjust kit package dependency in Xcode or in your `Package.swift`.
Swift Package Manager resolves the `mParticle` SDK automatically as a transitive dependency, so you do not need a separate `.package` entry for `mparticle-apple-sdk`.

```swift
let mParticleVersion: Version = "9.0.0"

.package(
    url: "https://github.com/mparticle-integrations/mparticle-apple-integration-adjust-5",
    .upToNextMajor(from: mParticleVersion)
),
```

Then add `mParticle-Adjust` as a dependency of your target.

### CocoaPods

Add the kit dependency to your app's Podfile:

```ruby
pod 'mParticle-Adjust', '~> 9.0'
```

## Verifying the Integration

After installing, rebuild and launch your app. With the mParticle log level set to Debug or higher, you should see the following in your Xcode console:

```bash
Included kits: { Adjust }
```

## Platform Support

| Platform | Minimum Version |
| -------- | --------------- |
| iOS      | 15.6            |
| tvOS     | 15.6            |

## Documentation

- [mParticle Adjust Integration Guide](https://docs.mparticle.com/integrations/adjust/event/)
- [mParticle iOS SDK Documentation](https://docs.mparticle.com/developers/sdk/ios/)
- [Adjust iOS SDK Documentation](https://help.adjust.com/en/sdk/ios)

## License

Apache License 2.0
