# mParticle CleverTap Kit (CleverTap SDK 7.x)

This is the [CleverTap](https://clevertap.com) integration for the [mParticle Apple SDK](https://github.com/mParticle/mparticle-apple-sdk), built against the [CleverTap SDK 7.x](https://github.com/CleverTap/clevertap-ios-sdk).

## Installation

### Swift Package Manager

Add the CleverTap kit package dependency in Xcode or in your `Package.swift`.
Swift Package Manager resolves the `mParticle` SDK automatically as a transitive dependency, so you do not need a separate `.package` entry for `mparticle-apple-sdk`.

```swift
let mParticleVersion: Version = "9.0.0"

.package(
    url: "https://github.com/mparticle-integrations/mparticle-apple-integration-clevertap-7",
    .upToNextMajor(from: mParticleVersion)
),
```

Then add `mParticle-CleverTap` as a dependency of your target.

### CocoaPods

Add the kit dependency to your app's Podfile:

```ruby
pod 'mParticle-CleverTap', '~> 9.0'
```

## Verifying the Integration

After installing, rebuild and launch your app. With the mParticle log level set to Debug or higher, you should see the following in your Xcode console:

```bash
Included kits: { CleverTap }
```

## Platform Support

| Platform | Minimum Version |
| -------- | --------------- |
| iOS      | 15.6            |

## Documentation

- [mParticle CleverTap Integration Guide](https://docs.mparticle.com/integrations/clevertap/event/)
- [mParticle iOS SDK Documentation](https://docs.mparticle.com/developers/sdk/ios/)
- [CleverTap iOS SDK Documentation](https://developer.clevertap.com/docs/ios-quickstart-guide)

## License

[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0)
