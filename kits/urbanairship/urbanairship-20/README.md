# mParticle Urban Airship Kit (Airship SDK 20.x)

This is the Urban Airship integration for the mParticle Apple SDK, built against the Airship SDK 20.x.

## Installation

### Swift Package Manager

Add the Urban Airship kit package dependency in Xcode or in your Package.swift. Swift Package Manager resolves the mParticle SDK automatically as a transitive dependency, so you do not need a separate .package entry for mparticle-apple-sdk.

```swift
let mParticleVersion: Version = "9.0.0"

.package(
    url: "https://github.com/mparticle-integrations/mparticle-apple-integration-urbanairship-20",
    .upToNextMajor(from: mParticleVersion)
),
```

Then add `mParticle-UrbanAirship` as a dependency of your target.

### CocoaPods

Add the kit dependency to your app's Podfile:

```ruby
pod 'mParticle-UrbanAirship', '~> 9'

## Verifying the Integration

After installing, rebuild and launch your app. With the mParticle log level set to Debug or higher, you should see the following in your Xcode console:

```text
Included kits: { UrbanAirship }
```

## Push Registration

Push registration is not handled by the Airship SDK when the passive registration setting is enabled. This prevents out-of-the-box categories from being registered automatically.

Registering out-of-the-box categories manually can be accomplished by accessing the defaultCategories class method on MPKitUrbanAirship and setting them on the UNNotificationCenter:

```swift
UNUserNotificationCenter.current().requestAuthorization(options: [UNAuthorizationOptions.alert]) { (success, err) in
    UNUserNotificationCenter.current().setNotificationCategories(MPKitUrbanAirship.defaultCategories())
}
```

## Tag-Based Segmentation

All mParticle user attributes are forwarded to Airship as [tags](https://docs.airship.com/platform/ios/segmentation/) which can be used to identify and segment your audience.

Most clients prefer for all tags to remain constant if set. But, a tag can be removed manually by invoking removeTag directly on the Airship SDK as shown below.

### Swift

```swift
private func removeTag(key: String) {
    if (!key.isEmpty) {
        Airship.channel.editTags { editor in
            editor.remove(key)
        }
        Airship.channel.updateRegistration()
    }
}
```

### Objective-C

```objective-c
- (void)removeTag:(nonnull NSString *)key {
    if (key && (NSNull *)key != [NSNull null] && ![key isEqualToString:@""]) {
        [[UAirship channel] editTags:^(UATagEditor * _Nonnull editor) {
            [editor removeTag:key];
            [editor apply];
        }];
        [[UAirship channel] updateRegistration];
    }
}
```

## Platform Support

| Platform | Minimum Version |
| -------- | --------------- |
| iOS      | 15.6            |
| tvOS     | 15.6            |

## Documentation

- [mParticle Urban Airship Integration Guide](https://docs.mparticle.com/integrations/airship/event/)
- [mParticle iOS SDK Documentation](https://docs.mparticle.com/developers/sdk/ios/)
- [Airship iOS SDK Documentation](https://docs.airship.com/platform/ios/)

## License

Apache License 2.0
