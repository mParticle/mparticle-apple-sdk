# mParticle-Apptimize

[Apptimize](https://www.apptimize.com) integration for the [mParticle Apple SDK](https://github.com/mParticle/mparticle-apple-sdk).

## Installation

### Swift Package Manager

Add the package dependency to your `Package.swift` or via Xcode:

```swift
.package(
    url: "https://github.com/mparticle-integrations/mparticle-apple-integration-apptimize-3",
    .upToNextMajor(from: "9.0.0")
)
```

### CocoaPods

```ruby
pod 'mParticle-Apptimize', '~> 9'
```

## Usage

Follow the [mParticle iOS SDK quick-start](https://github.com/mParticle/mparticle-apple-sdk), then rebuild and launch your app. Verify you see `"Included kits: { Apptimize }"` in the Xcode console (requires Debug log level).

## Documentation

- [Apptimize integration](https://docs.mparticle.com/integrations/apptimize/event/)
- [mParticle Apple SDK Docs](https://docs.mparticle.com/developers/sdk/ios/)

## License

[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0)
