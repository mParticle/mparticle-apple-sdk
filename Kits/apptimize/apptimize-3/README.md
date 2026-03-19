# mParticle Apptimize Kit (Apptimize SDK 3.x)

This is the [Apptimize](https://www.apptimize.com) integration for the [mParticle Apple SDK](https://github.com/mParticle/mparticle-apple-sdk), built against the [Apptimize SDK 3.x](https://sdk.apptimize.com).

## Installation

### Swift Package Manager

Add the Apptimize kit package dependency in Xcode or in your `Package.swift`:

```swift
.package(
    url: "https://github.com/mparticle-integrations/mparticle-apple-integration-apptimize-3",
    .upToNextMajor(from: "9.0.0")
)
```

Then add `mParticle-Apptimize` as a dependency of your target.

### CocoaPods

Add the kit dependency to your app's Podfile:

```ruby
pod 'mParticle-Apptimize', '~> 9.0'
```

## Verifying the Integration

After installing, rebuild and launch your app. With the mParticle log level set to Debug or higher, you should see the following in your Xcode console:

```bash
Included kits: { Apptimize }
```

## Documentation

- [mParticle Apptimize Integration Guide](https://docs.mparticle.com/integrations/apptimize/event/)
- [mParticle Apple SDK Documentation](https://docs.mparticle.com/developers/sdk/ios/)

## License

[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0)
