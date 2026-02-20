## Kochava Kit Integration

This repository contains the [Kochava](https://www.kochava.com) integration for the [mParticle Apple SDK](https://github.com/mParticle/mparticle-apple-sdk).

## Installation

Kochava's SDK, as of version 8.0.0, no longer supports CocoaPods. As this version is the minimum required for App Store submission due to the iOS 17 privacy manifest changes, the mParticle Kochava Kit by association no longer supports CocoaPods either.

In Xcode, see File > Swift Packages > Add Package Dependency ... > and enter the URL for this package repository.

The mParticle Kochava Kit contains two build targets: `mParticle-Kochava` and `mParticle-Kochava-NoTracking`. The `mParticle-Kochava` retains all of the same functionality of the previous version of Kochava, while the `mParticle-Kochava-NoTracking` removes the parts that Apple defines as "tracking".

Specifically this means, `mParticle-Kochava` depends on the `KochavaNetworking`, `KochavaMeasurement`, and `KochavaTracking` packages, while the `mParticle-Kochava-NoTracking` target only depends on the `KochavaNetworking` and `KochavaMeasurement` packages.

You can read more about that in Kochava's documentation here: https://support.kochava.com/sdk-integration/ios-sdk-integration/ios-migrating-to-v8/

### Adding the integration

1. Add this kit to your Xcode project using SPM, and choose either `mParticle-Kochava` or `mParticle-Kochava-NoTracking`

2. Follow the mParticle iOS SDK [quick-start](https://github.com/mParticle/mparticle-apple-sdk), then rebuild and launch your app, and verify that you see `"Included kits: { Kochava }"` in your Xcode console

> (This requires your mParticle log level to be at least Debug)

3. Reference mParticle's integration docs below to enable the integration.

### Deeplinking and attribution

Set the property `onAttributionComplete:` on `MParticleOptions` when initializing the mParticle SDK. A copy of your block will be invoked to provide the respective information:

```objective-c
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"<<Your app key>>" secret:@"<<Your app secret>>"];
    options.onAttributionComplete = ^void (MPAttributionResult *_Nullable attributionResult, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Attribution fetching for kitCode=%@ failed with error=%@", error.userInfo[mParticleKitInstanceKey], error);
            return;
        }

        if (attributionResult.linkInfo[MPKitKochavaEnhancedDeeplinkKey]) {
            // deeplinking result
            NSDictionary *deeplinkInfo = attributionResult.linkInfo[MPKitKochavaEnhancedDeeplinkKey];
            NSLog(@"Deeplink fetching for kitCode=%@ completed with destination: %@ raw: %@", attributionResult.kitCode, deeplinkInfo[MPKitKochavaEnhancedDeeplinkDestinationKey], deeplinkInfo[MPKitKochavaEnhancedDeeplinkRawKey]);
        } else {
            // attribution result
            NSLog(@"Attribution fetching for kitCode=%@ completed with linkInfo: %@", attributionResult.kitCode, attributionResult.linkInfo);
        }
    };
    [[MParticle sharedInstance] startWithOptions:options];

    return YES;
}
```

### Documentation

[Kochava integration](https://docs.mparticle.com/integrations/kochava/event/)

### License

[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0)
