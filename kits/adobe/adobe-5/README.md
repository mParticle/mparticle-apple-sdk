# mParticle Adobe Kit (Adobe Experience Platform SDK 5.x)

This is the [Adobe](https://www.adobe.com) integration for the [mParticle Apple SDK](https://github.com/mParticle/mparticle-apple-sdk).

Two library products are available:

- **mParticle-Adobe** — Base Adobe integration that handles Marketing Cloud ID synchronization via the Demdex endpoint. No external Adobe SDK dependency.
- **mParticle-AdobeMedia** — Full Adobe Experience Platform media tracking integration (AEPCore, AEPMedia, AEPAnalytics, AEPUserProfile, AEPIdentity, AEPLifecycle, AEPSignal).

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

Then add `mParticle-Adobe` or `mParticle-AdobeMedia` as a dependency of your target.

### CocoaPods

Add the kit dependency to your app's Podfile:

```ruby
pod 'mParticle-Adobe', '~> 9.0'
```

To send media data to Adobe, use the AdobeMedia subspec:

```ruby
pod 'mParticle-Adobe/AdobeMedia', '~> 9.0'
```

## Verifying the Integration

After installing, rebuild and launch your app. With the mParticle log level set to Debug or higher, you should see the following in your Xcode console:

```bash
Included kits: { Adobe }
```

or for the media integration:

```bash
Included kits: { AdobeMedia }
```

## Platform Support

| Platform | Minimum Version |
| -------- | --------------- |
| iOS      | 15.6            |

## Documentation

- [mParticle Adobe Integration Guide](https://docs.mparticle.com/integrations/adobe/event/)
- [mParticle iOS SDK Documentation](https://docs.mparticle.com/developers/sdk/ios/)
- [Adobe Experience Platform SDK Documentation](https://developer.adobe.com/client-sdks/)

## License

[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0)
