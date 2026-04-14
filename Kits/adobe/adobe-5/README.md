# mParticle Adobe Kit (Adobe Experience Platform SDK 5.x)

This is the [Adobe](https://www.adobe.com) integration for the [mParticle Apple SDK](https://github.com/mParticle/mparticle-apple-sdk).

The **mParticle-Adobe** library handles Marketing Cloud ID synchronization via the Demdex endpoint. No external Adobe SDK dependency.

## Installation

### Swift Package Manager

Add the Adobe kit package dependency in Xcode or in your `Package.swift`.
Swift Package Manager resolves the `mParticle` SDK automatically as a transitive dependency, so you do not need a separate `.package` entry for `mparticle-apple-sdk`.

```swift
let mParticleVersion: Version = "9.0.0"

.package(
    url: "https://github.com/mparticle-integrations/mparticle-apple-integration-adobe-5",
    .upToNextMajor(from: mParticleVersion)
),
```

Then add `mParticle-Adobe` as a dependency of your target.

### CocoaPods

Add the kit dependency to your app's Podfile:

```ruby
pod 'mParticle-Adobe-5', '~> 9.0'
```

## Verifying the Integration

After installing, rebuild and launch your app. With the mParticle log level set to Debug or higher, you should see the following in your Xcode console:

```bash
Included kits: { Adobe }
```

## Platform Support

| Platform | Minimum Version |
| -------- | --------------- |
| iOS      | 15.6            |

## Documentation

- [mParticle Adobe Integration Guide](https://docs.mparticle.com/integrations/adobe/event/)
- [mParticle iOS SDK Documentation](https://docs.mparticle.com/developers/sdk/ios/)
- [Adobe Experience Platform SDK Documentation](https://developer.adobe.com/client-sdks/)

## Issues

Please report bugs and feature requests to the [mparticle-apple-sdk](https://github.com/mParticle/mparticle-apple-sdk/issues) repository. This mirror repository is not actively monitored for issues.

## License

[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0)
