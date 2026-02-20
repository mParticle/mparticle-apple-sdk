# mParticle Kochava Kit (Kochava SDK 9.x)

This is the [Kochava](https://www.kochava.com) integration for the [mParticle Apple SDK](https://github.com/mParticle/mparticle-apple-sdk), built against [Kochava SDK 9.x](https://github.com/Kochava/Apple-SwiftPackage-KochavaTracking-XCFramework).

This package includes full Kochava functionality, including tracking (IDFA, etc.). For an alternative without tracking support, use [mParticle Kochava Kit No Tracking](https://github.com/mparticle-integrations/mparticle-apple-integration-kochava-no-tracking-9).

## Installation

### Swift Package Manager

Add the Kochava kit package dependency in Xcode or in your `Package.swift`. Swift Package Manager resolves the mParticle SDK automatically as a transitive dependency.

```swift
.package(
    url: "https://github.com/mparticle-integrations/mparticle-apple-integration-kochava-9",
    .upToNextMajor(from: "9.0.0")
),
```

Then add `mParticle-Kochava` as a dependency of your target.

## Verifying the Integration

With mParticle log level set to Debug or higher, you should see:

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
