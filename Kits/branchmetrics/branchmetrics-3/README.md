# mParticle Branch Metrics Kit (Branch SDK 3.x)

This is the [Branch](https://branch.io) integration for the [mParticle Apple SDK](https://github.com/mParticle/mparticle-apple-sdk), built against the [Branch SDK 3.x](https://github.com/BranchMetrics/ios-branch-sdk-spm).

## Installation

### Swift Package Manager

Add the Branch Metrics kit package dependency in Xcode or in your `Package.swift`.
Swift Package Manager resolves the `mParticle` SDK automatically as a transitive dependency, so you do not need a separate `.package` entry for `mparticle-apple-sdk`.

```swift
let mParticleVersion: Version = "9.0.0"

.package(
    url: "https://github.com/mparticle-integrations/mparticle-apple-integration-branchmetrics-3",
    .upToNextMajor(from: mParticleVersion)
),
```

Then add `mParticle-BranchMetrics` as a dependency of your target.

### CocoaPods

Add the kit dependency to your app's Podfile:

```ruby
pod 'mParticle-BranchMetrics', '~> 9.0'
```

## Verifying the Integration

After installing, rebuild and launch your app. With the mParticle log level set to Debug or higher, you should see the following in your Xcode console:

```bash
Included kits: { BranchMetrics }
```

## Platform Support

| Platform | Minimum Version |
| -------- | --------------- |
| iOS      | 15.6            |

## Documentation

- [mParticle Branch Integration Guide](https://docs.mparticle.com/integrations/branch-metrics/event/)
- [mParticle iOS SDK Documentation](https://docs.mparticle.com/developers/sdk/ios/)
- [Branch iOS SDK Documentation](https://help.branch.io/developers-hub/docs/ios-sdk-overview)

## License

[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0)
