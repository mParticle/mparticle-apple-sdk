# mParticle Apple SDK — Integration Kits

Kits forward events from the mParticle Apple SDK to partner services. To use a partner integration, add mParticle core plus the kit that matches the partner SDK major version you use.

## How to Choose a Kit

Kits are versioned by the partner SDK major:

- `braze-12` → Braze Swift SDK 12.x
- `braze-14` → Braze Swift SDK 14.x

Pick the kit that matches the partner SDK major you want in your app.

## Important Note (Monorepo Paths)

The `kits/<provider>/<provider>-<major>/` paths are how kits are organized in this repository. For your app, use the **Standalone Repository** link below (or the kit's README) to install via your dependency manager.

## Setup Instructions

Each kit has its own README with installation and configuration steps.

## Available Kits

| Kit                       | Standalone Repository                                                                                                                                                    | Partner SDK                                                                     |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------- |
| Adobe 5                   | [`mparticle-apple-integration-adobe-5`](https://github.com/mparticle-integrations/mparticle-apple-integration-adobe-5)                                                   | [Adobe Experience Platform SDK 5.x](https://github.com/adobe/aepsdk-core-ios)   |
| Adjust 5                  | [`mparticle-apple-integration-adjust-5`](https://github.com/mparticle-integrations/mparticle-apple-integration-adjust-5)                                                 | [Adjust SDK 5.x](https://github.com/adjust/ios_sdk)                             |
| AppsFlyer 6               | [`mparticle-apple-integration-appsflyer-6`](https://github.com/mparticle-integrations/mparticle-apple-integration-appsflyer-6)                                           | [AppsFlyer SDK 6.x](https://github.com/AppsFlyerSDK/AppsFlyerFramework)         |
| Apptimize 3               | [`mparticle-apple-integration-apptimize-3`](https://github.com/mparticle-integrations/mparticle-apple-integration-apptimize-3)                                           | [Apptimize SDK 3.x](https://sdk.apptimize.com)                                  |
| Branch Metrics 3          | [`mparticle-apple-integration-branchmetrics-3`](https://github.com/mparticle-integrations/mparticle-apple-integration-branchmetrics-3)                                   | [Branch SDK 3.x](https://github.com/BranchMetrics/ios-branch-sdk-spm)           |
| Braze 12                  | [`mparticle-apple-integration-braze-12`](https://github.com/mparticle-integrations/mparticle-apple-integration-braze-12)                                                 | [Braze Swift SDK 12.x](https://github.com/braze-inc/braze-swift-sdk)            |
| Braze 13                  | [`mparticle-apple-integration-braze-13`](https://github.com/mparticle-integrations/mparticle-apple-integration-braze-13)                                                 | [Braze Swift SDK 13.x](https://github.com/braze-inc/braze-swift-sdk)            |
| Braze 14                  | [`mparticle-apple-integration-braze-14`](https://github.com/mparticle-integrations/mparticle-apple-integration-braze-14)                                                 | [Braze Swift SDK 14.x](https://github.com/braze-inc/braze-swift-sdk)            |
| CleverTap 7               | [`mparticle-apple-integration-clevertap-7`](https://github.com/mparticle-integrations/mparticle-apple-integration-clevertap-7)                                           | [CleverTap SDK 7.x](https://github.com/CleverTap/clevertap-ios-sdk)             |
| Firebase Analytics 11     | [`mparticle-apple-integration-google-analytics-firebase-11`](https://github.com/mparticle-integrations/mparticle-apple-integration-google-analytics-firebase-11)         | [Firebase 11.x](https://github.com/firebase/firebase-ios-sdk)                   |
| Firebase Analytics 12     | [`mparticle-apple-integration-google-analytics-firebase-12`](https://github.com/mparticle-integrations/mparticle-apple-integration-google-analytics-firebase-12)         | [Firebase 12.x](https://github.com/firebase/firebase-ios-sdk)                   |
| Firebase Analytics GA4 11 | [`mparticle-apple-integration-google-analytics-firebase-ga4-11`](https://github.com/mparticle-integrations/mparticle-apple-integration-google-analytics-firebase-ga4-11) | [Firebase 11.x (GA4)](https://github.com/firebase/firebase-ios-sdk)             |
| Firebase Analytics GA4 12 | [`mparticle-apple-integration-google-analytics-firebase-ga4-12`](https://github.com/mparticle-integrations/mparticle-apple-integration-google-analytics-firebase-ga4-12) | [Firebase 12.x (GA4)](https://github.com/firebase/firebase-ios-sdk)             |
| Iterable 6                | [`mparticle-apple-integration-iterable-6`](https://github.com/mparticle-integrations/mparticle-apple-integration-iterable-6)                                             | [Iterable iOS SDK 6.x](https://github.com/Iterable/swift-sdk)                   |
| Kochava 9                 | [`mparticle-apple-integration-kochava-9`](https://github.com/mparticle-integrations/mparticle-apple-integration-kochava-9)                                               | [Kochava SDK 9.x](https://github.com/Kochava/Apple-SwiftPackage-KochavaTracker) |
| Kochava (No Tracking) 9   | [`mparticle-apple-integration-kochava-no-tracking-9`](https://github.com/mparticle-integrations/mparticle-apple-integration-kochava-no-tracking-9)                       | [Kochava SDK 9.x](https://github.com/Kochava/Apple-SwiftPackage-KochavaTracker) |
| Leanplum 6                | [`mparticle-apple-integration-leanplum-6`](https://github.com/mparticle-integrations/mparticle-apple-integration-leanplum-6)                                             | [Leanplum SDK 6.x](https://github.com/Leanplum/Leanplum-iOS-SDK)                |
| Optimizely 4              | [`mparticle-apple-integration-optimizely-4`](https://github.com/mparticle-integrations/mparticle-apple-integration-optimizely-4)                                         | [Optimizely Swift SDK 4.x](https://github.com/optimizely/swift-sdk)             |
| Optimizely 5              | [`mparticle-apple-integration-optimizely-5`](https://github.com/mparticle-integrations/mparticle-apple-integration-optimizely-5)                                         | [Optimizely Swift SDK 5.x](https://github.com/optimizely/swift-sdk)             |
| Rokt                      | [`mparticle-apple-integration-rokt`](https://github.com/mparticle-integrations/mparticle-apple-integration-rokt)                                                         | [Rokt Widget SDK](https://github.com/ROKT/rokt-sdk-ios)                         |
| Urban Airship 20          | [`mparticle-apple-integration-urbanairship-20`](https://github.com/mparticle-integrations/mparticle-apple-integration-urbanairship-20)                                   | [Airship SDK 20.x](https://github.com/urbanairship/ios-library)                 |
