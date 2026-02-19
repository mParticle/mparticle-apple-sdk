# mParticle AppsFlyer Kit (AppsFlyer SDK 6.x)

This is the [AppsFlyer](https://www.appsflyer.com) integration for the [mParticle Apple SDK](https://github.com/mParticle/mparticle-apple-sdk), built against the [AppsFlyer SDK 6.x](https://github.com/AppsFlyerSDK/AppsFlyerFramework-Static).

## Installation

### Swift Package Manager

Add the AppsFlyer kit package dependency in Xcode or in your `Package.swift`.
Swift Package Manager resolves the `mParticle` SDK automatically as a transitive dependency, so you do not need a separate `.package` entry for `mparticle-apple-sdk`.

```swift
let mParticleVersion: Version = "9.0.0"

.package(
    url: "https://github.com/mparticle-integrations/mparticle-apple-integration-appsflyer-6",
    .upToNextMajor(from: mParticleVersion)
),
```

Then add `mParticle-AppsFlyer` as a dependency of your target.

### CocoaPods

Add the kit dependency to your app's Podfile:

```ruby
pod 'mParticle-AppsFlyer', '~> 9.0'
```

## Verifying the Integration

After installing, rebuild and launch your app. With the mParticle log level set to Debug or higher, you should see the following in your Xcode console:

```bash
Included kits: { AppsFlyer }
```

## Platform Support

| Platform | Minimum Version |
| -------- | --------------- |
| iOS      | 15.6            |
| tvOS     | 15.6            |

## Documentation

- [mParticle AppsFlyer Integration Guide](https://docs.mparticle.com/integrations/appsflyer/event/)
- [mParticle iOS SDK Documentation](https://docs.mparticle.com/developers/sdk/ios/)
- [AppsFlyer iOS SDK Documentation](https://dev.appsflyer.com/hc/docs/integrate-ios-sdk)

## License

Apache License 2.0
