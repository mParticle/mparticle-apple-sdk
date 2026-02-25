# mParticle Leanplum Kit (Leanplum SDK 6.x)

This is the [Leanplum](https://www.leanplum.com) integration for the [mParticle Apple SDK](https://github.com/mParticle/mparticle-apple-sdk), built against [Leanplum SDK 6.x](https://github.com/leanplum/leanplum-ios-sdk).

## Installation

### Swift Package Manager

Add the Leanplum kit package dependency in Xcode or in your `Package.swift`. Swift Package Manager resolves the mParticle SDK automatically as a transitive dependency, so you do not need a separate `.package` entry for `mparticle-apple-sdk`.

```swift
.package(
    url: "https://github.com/mparticle-integrations/mparticle-apple-integration-leanplum-6",
    .upToNextMajor(from: "9.0.0")
),
```

Then add `mParticle-Leanplum` as a dependency of your target.

### CocoaPods

Add the kit dependency to your app's Podfile:

```ruby
pod 'mParticle-Leanplum', '~> 9.0'
```

## Verifying the Integration

After installing, rebuild and launch your app. With the mParticle log level set to Debug or higher, you should see the following in your Xcode console:

```bash
Included kits: { Leanplum }
```

## Platform Support

| Platform | Minimum Version |
| -------- | --------------- |
| iOS      | 15.6            |

## Documentation

- [mParticle Leanplum Integration Guide](https://docs.mparticle.com/integrations/leanplum/event/)
- [mParticle iOS SDK Documentation](https://docs.mparticle.com/developers/sdk/ios/)
- [Leanplum iOS SDK Documentation](https://docs.leanplum.com/docs/ios-sdk)

## License

Apache License 2.0
