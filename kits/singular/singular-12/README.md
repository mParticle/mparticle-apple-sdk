# mParticle Singular Kit (Singular SDK 12.x)

This is the [Singular](https://www.singular.net) integration for the [mParticle Apple SDK](https://github.com/mParticle/mparticle-apple-sdk), built against the [Singular SDK 12.x](https://github.com/singular-labs/Singular-iOS-SDK).

## Installation

### Swift Package Manager

Add the Singular kit package dependency in Xcode or in your `Package.swift`:

```swift
.package(
    url: "https://github.com/mparticle-integrations/mparticle-apple-integration-singular-12",
    .upToNextMajor(from: "9.0.0")
)
```

Then add `mParticle-Singular` as a dependency of your target.

### CocoaPods

Add the kit dependency to your app's Podfile:

```ruby
pod 'mParticle-Singular', '~> 9.0'
```

## Verifying the Integration

After installing, rebuild and launch your app. With the mParticle log level set to Debug or higher, you should see the following in your Xcode console:

```bash
Included kits: { Singular }
```

## Documentation

- [Singular mParticle Integration](https://support.singular.net/)
- [mParticle Apple SDK Documentation](https://docs.mparticle.com/developers/sdk/ios/)

## License

[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0)
