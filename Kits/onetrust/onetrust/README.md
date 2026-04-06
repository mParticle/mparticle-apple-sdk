# mParticle OneTrust Kit

This is the [OneTrust](https://www.onetrust.com) integration for the [mParticle Apple SDK](https://github.com/mParticle/mparticle-apple-sdk), built against the [OTPublishersHeadlessSDK](https://github.com/Zentrust/OTPublishersHeadlessSDK) (iOS) and [OTPublishersHeadlessSDKtvOS](https://github.com/Zentrust/OTPublishersHeadlessSDKtvOS) (tvOS).

## OneTrust SDK Version

OneTrust uses a constrained versioning model defined in [app.onetrust.com](https://app.onetrust.com). **Partners must specify the OneTrust SDK version they require** in their app's dependency configuration; the kit does not pin a specific version by default.

- **Source-based distribution (SPM, CocoaPods)**: Add `OTPublishersHeadlessSDK` and `OTPublishersHeadlessSDKtvOS` as direct dependencies with the version that matches your OneTrust configuration.
- **Binary distribution (XCFramework, vendored frameworks)**: Pre-built binaries are built with a specific OneTrust SDK version baked in at build time. Binary releases use the latest OneTrust SDK version available when the kit was built. If you need a different version, use source-based distribution and pin the version yourself.

## Installation

### Swift Package Manager

Add the OneTrust kit package dependency in Xcode or in your `Package.swift`.
Swift Package Manager resolves the mParticle SDK automatically as a transitive dependency, so you do not need a separate `.package` entry for `mparticle-apple-sdk`.

Add the OneTrust SDK as a direct dependency with the version from your OneTrust configuration:

```swift
let mParticleVersion: Version = "9.0.0"

.package(
    url: "https://github.com/mparticle-integrations/mparticle-apple-integration-onetrust",
    .upToNextMajor(from: mParticleVersion)
),
.package(
    url: "https://github.com/Zentrust/OTPublishersHeadlessSDK",
    .exact("202502.1.0")  // Use the version from your OneTrust UI
),
.package(
    url: "https://github.com/Zentrust/OTPublishersHeadlessSDKtvOS",
    .exact("202502.1.0")  // Must match your iOS SDK version
),
```

Then add `mParticle-OneTrust` and the OneTrust SDK products as dependencies of your target.

### CocoaPods

Add the kit and pin the OneTrust SDK to the version from your OneTrust configuration:

```ruby
pod 'mParticle-OneTrust', '~> 9.0'
pod 'OTPublishersHeadlessSDK', '202502.1.0'  # Use the version from your OneTrust UI
```

## Verifying the Integration

After installing, rebuild and launch your app. With the mParticle log level set to Debug or higher, you should see the following in your Xcode console:

```bash
Included kits: { OneTrust }
```

## Platform Support

| Platform | Minimum Version |
| -------- | --------------- |
| iOS      | 15.6            |
| tvOS     | 15.6            |

## Documentation

- [mParticle OneTrust Integration Guide](https://docs.mparticle.com/integrations/onetrust/event/)
- [mParticle iOS SDK Documentation](https://docs.mparticle.com/developers/sdk/ios/)
- [OneTrust Developer Portal: iOS SDK](https://developer.onetrust.com/onetrust/docs/add-sdk-to-app-ios-tvos)

## License

[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0)
