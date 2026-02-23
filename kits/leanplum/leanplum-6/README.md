## Leanplum Kit Integration

This repository contains the [Leanplum](https://www.leanplum.com) integration for the [mParticle Apple SDK](https://github.com/mParticle/mparticle-apple-sdk).

### Adding the integration

1. Add the kit dependency via SPM or add to your app's Podfile or Cartfile:

   ```
   pod 'mParticle-Leanplum', '~> 8.0'
   ```

   OR

   ```
   github "mparticle-integrations/mparticle-apple-integration-leanplum" ~> 8.0
   ```

2. Follow the mParticle iOS SDK [quick-start](https://github.com/mParticle/mparticle-apple-sdk), then rebuild and launch your app, and verify that you see `"Included kits: { Leanplum }"` in your Xcode console

> (This requires your mParticle log level to be at least Debug)

3. Reference mParticle's integration docs below to enable the integration.

### Documentation

[Leanplum integration](https://docs.mparticle.com/integrations/leanplum/event/)

### License

[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0)
