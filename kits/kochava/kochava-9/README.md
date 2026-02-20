# mParticle Kochava Kit (Kochava SDK 9.x)

This is the [Kochava](https://www.kochava.com) integration for the [mParticle Apple SDK](https://github.com/mParticle/mparticle-apple-sdk), built against the [Kochava SDK 9.x](https://github.com/Kochava/Apple-SwiftPackage-KochavaTracking-XCFramework).

## Installation

### Swift Package Manager

Add the Kochava kit package dependency in Xcode or in your `Package.swift`.
Swift Package Manager resolves the `mParticle` SDK automatically as a transitive dependency, so you do not need a separate `.package` entry for `mparticle-apple-sdk`.

```swift
let mParticleVersion: Version = "9.0.0"

.package(
    url: "https://github.com/mparticle-integrations/mparticle-apple-integration-kochava-9",
    .upToNextMajor(from: mParticleVersion)
),
```

Then add `mParticle-Kochava` as a dependency of your target.

**Note:** The mParticle Kochava Kit contains two build targets: `mParticle-Kochava` and `mParticle-Kochava-NoTracking`. The `mParticle-Kochava` retains all of the same functionality, while the `mParticle-Kochava-NoTracking` removes the parts that Apple defines as "tracking". Specifically, `mParticle-Kochava` depends on the `KochavaNetworking`, `KochavaMeasurement`, and `KochavaTracking` packages, while the `mParticle-Kochava-NoTracking` target only depends on the `KochavaNetworking` and `KochavaMeasurement` packages.

## Verifying the Integration

After installing, rebuild and launch your app. With the mParticle log level set to Debug or higher, you should see the following in your Xcode console:

```bash
Included kits: { Kochava }
```

## Platform Support

| Platform | Minimum Version |
| -------- | --------------- |
| iOS      | 15.6            |
| tvOS     | 15.6            |

## Documentation

- [mParticle Kochava Integration Guide](https://docs.mparticle.com/integrations/kochava/event/)
- [mParticle iOS SDK Documentation](https://docs.mparticle.com/developers/sdk/ios/)
- [Kochava iOS SDK Documentation](https://support.kochava.com/sdk-integration/ios-sdk-integration/)

## License

Apache License 2.0
