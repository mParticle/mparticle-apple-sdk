# mParticle Optimizely Kit (Optimizely Swift SDK 4.x)

This is the [Optimizely](https://www.optimizely.com) integration for the [mParticle Apple SDK](https://github.com/mParticle/mparticle-apple-sdk), built against the [Optimizely Swift SDK 4.x](https://github.com/optimizely/swift-sdk).

## Installation

### Swift Package Manager

Add the Optimizely kit package dependency in Xcode or in your `Package.swift`:

```swift
.package(
    url: "https://github.com/mparticle-integrations/mparticle-apple-integration-optimizely-4",
    .upToNextMajor(from: "9.0.0")
),
```

Then add `mParticle-Optimizely` as a dependency of your target.

## Verifying the Integration

After installing, rebuild and launch your app. With the mParticle log level set to Debug or higher, you should see the following in your Xcode console:

```bash
Included kits: { Optimizely }
```

## Platform Support

| Platform | Minimum Version |
| -------- | --------------- |
| iOS      | 15.0            |
| tvOS     | 15.0            |

## Documentation

- [mParticle Optimizely Integration Guide](https://docs.mparticle.com/integrations/optimizely/event/)
- [mParticle iOS SDK Documentation](https://docs.mparticle.com/developers/client-sdks/ios/)
- [Optimizely Swift SDK Documentation](https://docs.developers.optimizely.com/full-stack/docs/swift-sdk)

## Issues

Please report bugs and feature requests to the [mparticle-apple-sdk](https://github.com/mParticle/mparticle-apple-sdk/issues) repository. This mirror repository is not actively monitored for issues.

## License

[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0)
