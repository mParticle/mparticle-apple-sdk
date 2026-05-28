# Migration Guide

This document provides guidance on migrating to newer versions of the Rokt Payment Extension for iOS.

## Ecosystem versioning (mParticle monorepo)

When consumed from the [mParticle Apple SDK monorepo](https://github.com/mParticle/mparticle-apple-sdk) or its mirror **[ROKT/rokt-payment-extension-ios](https://github.com/ROKT/rokt-payment-extension-ios)**, **RoktPaymentExtension** uses the **same semver as mParticle-Apple-SDK** (for example `9.2.1`), not the legacy **2.x** release line. Update SPM pins and CocoaPods to that ecosystem version; tags are **`v<version>`** (for example `v9.2.1`).

## Migrating from 1.x to 2.0.0

Version 2.0 replaces the `returnURL:` init parameter with `urlScheme:`. Partners now pass only the bare URL scheme — the SDK builds the full redirect URL (`<scheme>://rokt-payment-return`) internally and verifies the scheme is registered under `CFBundleURLSchemes` in the host app's `Info.plist` at init time.

### Init parameter rename

**Before (1.x):**

```swift
guard let paymentExtension = RoktPaymentExtension(
    applePayMerchantId: "merchant.com.example",
    returnURL: "myapp://stripe-redirect"
) else { return }
```

**After (2.0):**

```swift
guard let paymentExtension = RoktPaymentExtension(
    applePayMerchantId: "merchant.com.example",
    urlScheme: "myapp"
) else { return }
```

Your `Info.plist` `CFBundleURLSchemes` entry does not need to change — keep the same scheme you already declared.

### New init-time validation

`init?` now returns `nil` when the supplied `urlScheme` is not registered under `CFBundleURLSchemes` in the host app's `Info.plist`.

- **DEBUG builds** also fire an `assertionFailure` with a copy-paste `Info.plist` snippet.
- **Release builds** log the same message via `os_log` at `.error` level.

If your `guard let` starts returning `nil`, double-check that the scheme you pass to `urlScheme:` exactly matches an entry in your `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array><string>myapp</string></array>
  </dict>
</array>
```

### `handleURLCallback(with:)` now filters URLs

`handleURLCallback(with:)` now filters incoming URLs to the configured `<scheme>://rokt-payment-return` pattern and returns `false` for any URL that doesn't match. If your app forwards every redirect URL to every registered payment extension, URLs owned by your own code are no longer accidentally consumed by the Rokt extension.

### Afterpay-not-configured error message

The error message raised when Afterpay is triggered without an init-time `urlScheme` now reads:

> `Afterpay not configured. Provide a urlScheme at init.`

(Previously: `... Provide a returnURL at init.`)

---

## Migrating from `RoktStripePaymentExtension` (0.x) to 1.0.0

Version 1.0 renames the package and class. To migrate:

1. Replace `import RoktStripePaymentExtension` with `import RoktPaymentExtension`.
2. Replace the class name `RoktStripePaymentExtension` with `RoktPaymentExtension`.
3. Update your `Package.swift` URL to `https://github.com/ROKT/rokt-payment-extension-ios.git` (old URL auto-redirects via GitHub).
4. Update your `Podfile`: `pod 'RoktPaymentExtension'`.
5. Optional: the initializer now accepts an optional `applePayMerchantId`. To support only Afterpay, drop it and pass `urlScheme` instead (see [Migrating from 1.x to 2.0.0](#migrating-from-1x-to-200) above for the current Afterpay init parameter).
