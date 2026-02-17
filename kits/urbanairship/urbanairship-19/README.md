## UrbanAirship Kit Integration

This repository contains the [Airship](https://www.airship.com) integration for the [mParticle Apple SDK](https://github.com/mParticle/mparticle-apple-sdk).

### Adding the integration

1. Add the kit dependency to your app's Podfile:

   ```
   pod 'mParticle-UrbanAirship', '~> 8'
   ```

2. Follow the mParticle iOS SDK [quick-start](https://github.com/mParticle/mparticle-apple-sdk), then rebuild and launch your app, and verify that you see `"Included kits: { UrbanAirship }"` in your Xcode console

> (This requires your mParticle log level to be at least Debug)

3. Reference mParticle's integration docs below to enable the integration.

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

Most clients prefer for all tags to remain constant if set. But, a tag can be removed manually by invoking removeTag directly on the Airship SDK as shown bellow.

#### Swift

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

#### Objective-C

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

### Documentation

[Airship integration](https://docs.mparticle.com/integrations/airship/event/)

### License

[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0)
