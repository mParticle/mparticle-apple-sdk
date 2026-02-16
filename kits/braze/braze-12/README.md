# Braze (formerly Appboy) Kit Integration

This repository contains the [Braze](https://www.braze.com) integration for the [mParticle Apple SDK](https://github.com/mParticle/mparticle-apple-sdk) using the latest [Braze Swift SDK](https://github.com/braze-inc/braze-swift-sdk/).

## Adding the integration

1. Add the kit dependency using SPM or add it to your app's Podfile or Cartfile:

   ```ruby
   pod 'mParticle-Appboy', '~> 8.0'
   ```

   OR

   ```swift
   github "mparticle-integrations/mparticle-apple-integration-appboy" ~> 8.0
   ```

2. If using SPM, make sure to add the `-ObjC` flag to the target's `Other Linker Flags` setting in Xcode, according to the [Braze documentation](https://www.braze.com/docs/developer_guide/platform_integration_guides/ios/initial_sdk_setup/installation_methods/swift_package_manager#step-2-configuring-your-project).

3. Follow the mParticle iOS SDK [quick-start](https://github.com/mParticle/mparticle-apple-sdk), then rebuild and launch your app, and verify that you see `"Included kits: { Appboy }"` in your Xcode console

> (This requires your mParticle log level to be at least Debug)

4. Reference mParticle's integration docs below to enable the integration.

## Documentation

[Braze integration](https://docs.mparticle.com/integrations/braze/event/)

## License

[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0)
