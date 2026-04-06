# mParticle Kochava Kit No Tracking (Kochava SDK 9.x)

This is the [Kochava](https://www.kochava.com) integration for the [mParticle Apple SDK](https://github.com/mParticle/mparticle-apple-sdk), built against [Kochava SDK 9.x](https://github.com/Kochava/Apple-SwiftPackage-KochavaMeasurement-XCFramework), **without tracking support**. It provides the same `mParticle-Kochava` target and API as the full kit, but excludes the `KochavaTracking` package—removing the parts that Apple defines as "tracking" (e.g., IDFA). Use this package when you need Kochava integration without tracking capabilities.

## Installation

### Swift Package Manager

Add the Kochava No Tracking kit package dependency in Xcode or in your `Package.swift`.
Swift Package Manager resolves the `mParticle` SDK automatically as a transitive dependency, so you do not need a separate `.package` entry for `mparticle-apple-sdk`.

```swift
let mParticleVersion: Version = "9.0.0"

.package(
    url: "https://github.com/mparticle-integrations/mparticle-apple-integration-kochava-no-tracking-9",
    .upToNextMajor(from: mParticleVersion)
),
```

Then add `mParticle-Kochava` as a dependency of your target. The target name is the same as the full Kochava kit; this package is a drop-in alternative that omits tracking.

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

[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0)
