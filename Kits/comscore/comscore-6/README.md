# mParticle ComScore Kit (ComScore SDK 6.x)

This is the [ComScore](https://www.comscore.com) integration for the [mParticle Apple SDK](https://github.com/mParticle/mparticle-apple-sdk), built against the [ComScore SDK 6.x](https://github.com/comScore/Comscore-Swift-Package-Manager).

## Installation

### Swift Package Manager

Add the ComScore kit package dependency in Xcode or in your `Package.swift`.
Swift Package Manager resolves the `mParticle` SDK automatically as a transitive dependency, so you do not need a separate `.package` entry for `mparticle-apple-sdk`.

```swift
let mParticleVersion: Version = "9.0.0"

.package(
    url: "https://github.com/mparticle-integrations/mparticle-apple-integration-comscore-6",
    .upToNextMajor(from: mParticleVersion)
),
```

Then add `mParticle-ComScore` as a dependency of your target.

## Verifying the Integration

After installing, rebuild and launch your app. With the mParticle log level set to Debug or higher, you should see the following in your Xcode console:

```bash
Included kits: { ComScore }
```

## Platform Support

| Platform | Minimum Version |
| -------- | --------------- |
| iOS      | 15.6            |
| tvOS     | 15.6            |

## Documentation

- [mParticle ComScore Integration Guide](https://docs.mparticle.com/integrations/comscore/event/)
- [mParticle iOS SDK Documentation](https://docs.mparticle.com/developers/sdk/ios/)
- [ComScore SDK Documentation](https://github.com/comScore/Comscore-Swift-Package-Manager)

## License

[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0)
