# mParticle Localytics Kit (Localytics SDK 6.x)

This is the [Localytics](https://www.localytics.com) integration for the [mParticle Apple SDK](https://github.com/mParticle/mparticle-apple-sdk), built against the [Localytics SDK 6.x](https://github.com/localytics/Localytics-swiftpm).

## Installation

### Swift Package Manager

Add the Localytics kit package dependency in Xcode or in your `Package.swift`. Swift Package Manager resolves the mParticle SDK automatically as a transitive dependency, so you do not need a separate `.package` entry for `mparticle-apple-sdk`.

```swift
.package(
    url: "https://github.com/mparticle-integrations/mparticle-apple-integration-localytics-6",
    .upToNextMajor(from: "9.0.0")
),
```

Then add `mParticle-Localytics` as a dependency of your target.

### CocoaPods

Add the kit dependency to your app's Podfile:

```ruby
pod 'mParticle-Localytics', '~> 9.0'
```

## Verifying the Integration

After installing, rebuild and launch your app. With the mParticle log level set to Debug or higher, you should see the following in your Xcode console:

```bash
Included kits: { Localytics }
```

## Platform Support

| Platform | Minimum Version |
| -------- | --------------- |
| iOS      | 15.6            |

## Documentation

- [mParticle Localytics Integration Guide](https://docs.mparticle.com/integrations/localytics/event/)
- [mParticle iOS SDK Documentation](https://docs.mparticle.com/developers/sdk/ios/)
- [Localytics iOS SDK Documentation](https://help.uplandsoftware.com/localytics/dev/ios.html)

## License

Apache License 2.0
