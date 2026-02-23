## OneTrust Kit Integration

This repository contains the [OneTrust](https://www.onetrust.com/) integration for the [mParticle Apple SDK](https://github.com/mParticle/mparticle-apple-sdk).

### Adding the integration

1. Add the kit dependencies to your app's Podfile or using SPM:

   ```
   pod 'mParticle-OneTrust', '~> 8.0'
   ```

   OR

   ```
   Open your project and navigate to the project's settings. Select the tab named Swift Packages and click on the add button (+) at the bottom left. then, enter the URL of OneTrust Kit GitHub repository - https://github.com/mparticle-integrations/mparticle-apple-integration-onetrust and click Next.
   ```

   _Note: OneTrust does not support Carthage at this moment_

2. Add the OneTrust SDK following their [documentation](https://developer.onetrust.com/onetrust/docs/add-sdk-to-app-ios-tvos) and ensure you pin to the correct version of the OneTrust SDK as you specified in the OneTrust UI on app.onetrust.com.

   _Note: OneTrust is unique in their versioning and in that you must specify your version used from a constrained list in their UI. This necessitates that we cannot pin the version of the OneTrust SDK in this kit. Therefore you must pin the correct version in the podspec or package.swift of your application_

3. Follow the mParticle iOS SDK [quick-start](https://github.com/mParticle/mparticle-apple-sdk), then rebuild and launch your app, and verify that you see `"Included kits: { OneTrust }"` in your Xcode console

- (This requires your mParticle log level to be at least Debug)

3. Reference mParticle's integration docs below to enable the integration.

### Documentation

[mParticle Docs: OneTrust integration](https://docs.mparticle.com/integrations/onetrust/event/)

[OneTrust Developer SDK Portal: Getting Started with Native SDK (iOS)](https://developer.onetrust.com/sdk/mobile-apps/ios/getting-started)

### License

[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0)
