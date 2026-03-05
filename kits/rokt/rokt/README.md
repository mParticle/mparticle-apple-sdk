# mParticle Rokt Kit

[Rokt](https://www.rokt.com) integration kit for the [mParticle Apple SDK](https://github.com/mParticle/mparticle-apple-sdk).

## Installation

### Swift Package Manager

Add the package dependency to your `Package.swift` or via Xcode:

```swift
.package(
    url: "https://github.com/mparticle-integrations/mparticle-apple-integration-rokt",
    .upToNextMajor(from: "9.0.0")
)
```

Then add `mParticle-Rokt` as a dependency of your target.

### CocoaPods

Add the kit dependency to your app's Podfile:

```ruby
pod 'mParticle-Rokt', '~> 9.0'
```

## Verifying the Integration

After installing, rebuild and launch your app. With the mParticle log level set to Debug or higher, you should see the following in your Xcode console:

```bash
Included kits: { Rokt }
```

## Documentation

- [Rokt mParticle Integration](https://docs.rokt.com/developers/integration-guides/rokt-ads/customer-data-platforms/mparticle/)
- [mParticle Apple SDK Documentation](https://docs.mparticle.com/developers/sdk/ios/)

## License

[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0)
