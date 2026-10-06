# mParticle AppsFlyer Kit (AppsFlyer SDK 6.x)

This is the [AppsFlyer](https://www.appsflyer.com) integration for the [mParticle Apple SDK](https://github.com/mParticle/mparticle-apple-sdk), built against the [AppsFlyer SDK 6.x](https://github.com/AppsFlyerSDK/AppsFlyerFramework-Static).

## Installation

### Swift Package Manager

Add the AppsFlyer kit package dependency in Xcode or in your `Package.swift`.
Swift Package Manager resolves the `mParticle` SDK automatically as a transitive dependency, so you do not need a separate `.package` entry for `mparticle-apple-sdk`.

```swift
let mParticleVersion: Version = "9.0.0"

.package(
    url: "https://github.com/mparticle-integrations/mparticle-apple-integration-appsflyer-6",
    .upToNextMajor(from: mParticleVersion)
),
```

Then add `mParticle-AppsFlyer` as a dependency of your target.

### CocoaPods

Add the kit dependency to your app's Podfile:

```ruby
pod 'mParticle-AppsFlyer-6', '~> 9.0'
```

### Prebuilt xcframework

Each release attaches `mParticle_AppsFlyer.xcframework.zip`. The kit links its dependencies dynamically, so embed all four frameworks in your app target:

| Framework                               | Source                                                                                                                                 |
| --------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| `mParticle_AppsFlyer.xcframework`       | This repository's releases                                                                                                             |
| `mParticle_Apple_SDK.xcframework`       | [mparticle-apple-sdk releases](https://github.com/mParticle/mparticle-apple-sdk/releases), matching version                            |
| `mParticle_Apple_SDK_Swift.xcframework` | [mparticle-apple-sdk releases](https://github.com/mParticle/mparticle-apple-sdk/releases), matching version                            |
| `AppsFlyerLib.xcframework`              | `AppsFlyerLib-Dynamic.xcframework.zip` from [AppsFlyerFramework releases](https://github.com/AppsFlyerSDK/AppsFlyerFramework/releases) |

Set all four to **Embed & Sign**. Core SDK releases up to and including 9.7.0 have no `mParticle_Apple_SDK_Swift.xcframework.zip`; see [MIGRATING.md](https://github.com/mParticle/mparticle-apple-sdk/blob/main/MIGRATING.md). Use the dynamic `AppsFlyerLib-Dynamic.xcframework.zip` rather than the static build; the static variant does not provide the dynamic library the kit loads at runtime.

Prefer Swift Package Manager or CocoaPods unless your build requires prebuilt binaries — those integrations resolve these dependencies for you.

## Verifying the Integration

After installing, rebuild and launch your app. With the mParticle log level set to Debug or higher, you should see the following in your Xcode console:

```bash
Included kits: { AppsFlyer }
```

## Manual Start

If this kit's "Require Manual Start" connection setting is enabled, AppsFlyer does not start automatically — attribution and event forwarding stay paused until your app tells it to go (for example, once a user accepts a consent prompt). Resume it by calling `startAppsFlyer`, which always operates on the same AppsFlyer instance this kit configured:

```swift
import mParticle_AppsFlyer

MPKitAppsFlyer.startAppsFlyer()
```

```objc
#import <mParticle_AppsFlyer/mParticle_AppsFlyer.h>

[MPKitAppsFlyer startAppsFlyer];
```

Don't call `AppsFlyerLib.shared().start()` directly: if your app links the AppsFlyer SDK anywhere else, that call can resolve a different, unconfigured instance and fail with "No dev key".

## Platform Support

| Platform | Minimum Version |
| -------- | --------------- |
| iOS      | 15.0            |
| tvOS     | 15.0            |

## Documentation

- [mParticle AppsFlyer Integration Guide](https://docs.mparticle.com/integrations/appsflyer/event/)
- [mParticle iOS SDK Documentation](https://docs.mparticle.com/developers/sdk/ios/)
- [AppsFlyer iOS SDK Documentation](https://dev.appsflyer.com/hc/docs/integrate-ios-sdk)

## Issues

Please report bugs and feature requests to the [mparticle-apple-sdk](https://github.com/mParticle/mparticle-apple-sdk/issues) repository. This mirror repository is not actively monitored for issues.

## License

[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0)
