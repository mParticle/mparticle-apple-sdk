import Foundation

/// Entry point for **Rokt SDK+** (SwiftPM product and CocoaPods pod: **RoktSDKPlus**).
///
/// This module links the [mParticle Apple SDK](https://github.com/mParticle/mparticle-apple-sdk),
/// the [mParticle Rokt](https://github.com/mparticle-integrations/mp-apple-integration-rokt) kit, and
/// [Rokt Payment Extension](https://github.com/ROKT/rokt-payment-extension-ios). Import the
/// upstream modules you use alongside `RoktSDKPlus` as needed.
public enum RoktSDKPlus {
    /// Umbrella package version for **Rokt SDK+** (module `RoktSDKPlus`), aligned with the mParticle Apple SDK ecosystem.
    public static let version = "9.1.0"
}
