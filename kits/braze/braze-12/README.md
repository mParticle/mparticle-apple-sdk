# mParticle Braze Kit (Braze Swift SDK 12.x)

This is the [Braze](https://www.braze.com) integration for the [mParticle Apple SDK](https://github.com/mParticle/mparticle-apple-sdk), built against the [Braze Swift SDK 12.x](https://github.com/braze-inc/braze-swift-sdk).

## Source Code

This repository is a **read-only mirror**. The source code is maintained in the [mParticle Apple SDK monorepo](https://github.com/mParticle/mparticle-apple-sdk) under `kits/braze/braze-12/` and is automatically published here via CI. To contribute or report issues, please open issues and pull requests against the [monorepo](https://github.com/mParticle/mparticle-apple-sdk).

## Installation

### Swift Package Manager

Add the package dependency in Xcode or in your `Package.swift`:

```swift
let mParticleVersion: Version = "9.0.0"

.package(
    url: "https://github.com/mparticle-integrations/mparticle-apple-integration-braze-12",
    .upToNextMajor(from: mParticleVersion)
),
.package(
    url: "https://github.com/mParticle/mparticle-apple-sdk",
    .upToNextMajor(from: mParticleVersion)
),
```

Then add `mParticle-Braze` as a dependency of your target.

> **Note:** Add the `-ObjC` flag to your target's **Other Linker Flags** build setting, per the [Braze documentation](https://www.braze.com/docs/developer_guide/platform_integration_guides/ios/initial_sdk_setup/installation_methods/swift_package_manager#step-2-configuring-your-project).

For iOS push-launch tracking, initialize Braze in `application(_:didFinishLaunchingWithOptions:)` **before** starting mParticle, then pass the instance to the kit:

```swift
import BrazeKit
import mParticle_Braze

let configuration = Braze.Configuration(
    apiKey: "[YOUR_BRAZE_API_KEY]",
    endpoint: "[YOUR_BRAZE_ENDPOINT]"
)
let braze = Braze(configuration: configuration)

MPKitBraze.setBrazeInstance(braze)
MPKitBraze.setShouldDisableNotificationHandling(true)
// Start mParticle after this.
```

Complete setup details (including required push delegate methods) are in the mParticle docs:

- [mParticle Braze iOS App Launch Tracking](https://docs.mparticle.com/integrations/braze/event/#ios-app-launch-tracking)

### Verifying the Integration

After installing, rebuild and launch your app. With the mParticle log level set to Debug or higher, you should see the following in your Xcode console:

```bash
Included kits: { Braze }
```

## Platform Support

| Platform | Minimum Version |
| -------- | --------------- |
| iOS      | 15.6            |
| tvOS     | 15.6            |

## Dependencies

| Dependency                                                              | Version                          |
| ----------------------------------------------------------------------- | -------------------------------- |
| [mParticle Apple SDK](https://github.com/mParticle/mparticle-apple-sdk) | Aligned with kit release version |
| [Braze Swift SDK](https://github.com/braze-inc/braze-swift-sdk)         | 12.0.0+                          |

## Documentation

- [mParticle Braze Integration Guide](https://docs.mparticle.com/integrations/braze/event/)
- [mParticle Apple SDK Quick Start](https://github.com/mParticle/mparticle-apple-sdk)
- [Braze Swift SDK Documentation](https://www.braze.com/docs/)

## License

[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0)
