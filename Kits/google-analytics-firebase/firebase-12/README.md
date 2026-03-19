# mParticle Firebase Kit (Firebase SDK 12.x)

This kit integrates [Firebase Analytics](https://firebase.google.com/docs/analytics) with the [mParticle Apple SDK](https://github.com/mParticle/mparticle-apple-sdk). It targets Firebase SDK major version 12.x.

## Installation

### Swift Package Manager

Add the `mParticle-Firebase` product from this package to your Xcode project or `Package.swift`:

```swift
.package(url: "https://github.com/mParticle/mparticle-apple-integration-google-analytics-firebase-12", .upToNextMajor(from: "9.0.0"))
```

Then add `mParticle-Firebase` as a dependency of your target.

## Verifying the Integration

After installing, rebuild and launch your app. With the mParticle log level set to Debug or higher, you should see the following in your Xcode console:

```bash
Included kits: { Firebase }
```

## Platform Support

| Platform | Minimum Version |
| -------- | --------------- |
| iOS      | 15.6            |
| tvOS     | 15.6            |

## Documentation

- [mParticle Google Analytics for Firebase Integration Guide](https://docs.mparticle.com/integrations/google-analytics-firebase/event/)
- [mParticle iOS SDK Documentation](https://docs.mparticle.com/developers/sdk/ios/)
- [Firebase iOS SDK Documentation](https://github.com/firebase/firebase-ios-sdk)

## License

[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0)
