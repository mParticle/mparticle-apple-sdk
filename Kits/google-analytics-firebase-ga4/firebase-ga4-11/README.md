# mParticle Firebase GA4 Kit (Firebase SDK 11.x)

This kit integrates [Firebase Analytics (GA4)](https://firebase.google.com/docs/analytics) with the [mParticle Apple SDK](https://github.com/mParticle/mparticle-apple-sdk). It targets Firebase SDK major version 11.x.

## Installation

### Swift Package Manager

Add the `mParticle-FirebaseGA4` product from this package to your Xcode project or `Package.swift`:

```swift
.package(url: "https://github.com/mParticle/mparticle-apple-integration-google-analytics-firebase-ga4-11", .upToNextMajor(from: "9.0.0"))
```

Then add `mParticle-FirebaseGA4` as a dependency of your target.

## Verifying the Integration

After installing, rebuild and launch your app. With the mParticle log level set to Debug or higher, you should see the following in your Xcode console:

```bash
Included kits: { FirebaseGA4 }
```

## Platform Support

| Platform | Minimum Version |
| -------- | --------------- |
| iOS      | 15.6            |
| tvOS     | 15.6            |

## Documentation

- [mParticle Google Analytics 4 for Firebase Integration Guide](https://docs.mparticle.com/integrations/google-analytics-firebase-ga4/event/)
- [mParticle iOS SDK Documentation](https://docs.mparticle.com/developers/sdk/ios/)
- [Firebase iOS SDK Documentation](https://github.com/firebase/firebase-ios-sdk)

## Issues

Please report bugs and feature requests to the [mparticle-apple-sdk](https://github.com/mParticle/mparticle-apple-sdk/issues) repository. This mirror repository is not actively monitored for issues.

## License

[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0)
