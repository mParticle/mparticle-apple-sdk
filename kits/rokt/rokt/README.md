# mParticle-Rokt

Rokt integration kit for the [mParticle Apple SDK](https://github.com/mParticle/mparticle-apple-sdk).

## Installation

### Swift Package Manager

Add the package dependency to your `Package.swift` or via Xcode:

```swift
.package(
    url: "https://github.com/mparticle-integrations/mparticle-apple-integration-rokt",
    .upToNextMajor(from: "9.0.0")
)
```

### CocoaPods

```ruby
pod 'mParticle-Rokt', '~> 9.0'
```

## Usage

Follow the [mParticle iOS SDK quick-start](https://github.com/mParticle/mparticle-apple-sdk), then rebuild and launch your app. Verify you see `"Included kits: { Rokt }"` in the Xcode console (requires Debug log level).

## Documentation

- [Rokt mParticle Integration](https://docs.rokt.com/developers/integration-guides/rokt-ads/customer-data-platforms/mparticle/)
- [mParticle Apple SDK Docs](https://docs.mparticle.com/developers/sdk/ios/)

## License

[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0)
