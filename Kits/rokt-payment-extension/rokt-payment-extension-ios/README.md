# Rokt Payment Extension (iOS)

Developed in the [mParticle Apple SDK monorepo](https://github.com/mParticle/mparticle-apple-sdk) under `Kits/rokt-payment-extension/rokt-payment-extension-ios` and mirrored to **[ROKT/rokt-payment-extension-ios](https://github.com/ROKT/rokt-payment-extension-ios)**. **RoktPaymentExtension** is versioned with the mParticle Apple SDK ecosystem (`VERSION` in the monorepo); SPM/CocoaPods tags use that semver (not the legacy 2.x line).

Optional payment integration for the Rokt iOS SDK ecosystem. Currently provides
Apple Pay, card, and Afterpay/Clearpay support via Stripe for
[Shoppable Ads](https://docs.rokt.com) placements. Designed to host additional
providers (e.g. PayPal, Klarna) over time.

This package depends only on [RoktContracts](https://github.com/ROKT/rokt-contracts-apple) — not the full Rokt SDK — keeping payment-provider SDKs isolated and the integration lightweight.

## Requirements

- iOS 15.6+
- Swift 5.9+
- Xcode 15.0+
- Stripe account with Apple Pay enabled (for Apple Pay / card)
- For Afterpay / Clearpay: a Stripe account with the method enabled and a custom
  URL scheme registered in the host app's `Info.plist` under `CFBundleURLSchemes`
  (you pass the same scheme to the extension via `urlScheme:`)

## Installation

### Swift Package Manager

In Xcode: **File > Add Packages**, enter:

```text
https://github.com/ROKT/rokt-payment-extension-ios.git
```

Or add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/ROKT/rokt-payment-extension-ios.git", from: "9.2.1")
]
```

### CocoaPods

```ruby
pod 'RoktPaymentExtension'
```

## Usage

The extension accepts optional init params — you enable only the methods you
want to support. At least one of `applePayMerchantId` or `urlScheme` must be
provided; otherwise the initializer returns `nil`.

| Init parameters           | Enables                   |
| ------------------------- | ------------------------- |
| `applePayMerchantId` only | Apple Pay, card           |
| `urlScheme` only          | Afterpay / Clearpay       |
| Both                      | Apple Pay, card, Afterpay |

### Direct Rokt SDK Integration

When using the Rokt SDK directly, the partner provides the Stripe publishable key
explicitly at registration time:

```swift
import Rokt_Widget
import RoktPaymentExtension

// 1. Initialize Rokt
Rokt.initWith(roktTagId: "your-tag-id")

// 2. Create the payment extension.
//    Supply `applePayMerchantId` for Apple Pay, `urlScheme` for Afterpay, or both.
guard let paymentExtension = RoktPaymentExtension(
    applePayMerchantId: "merchant.com.example",
    urlScheme: "myapp" // bare scheme — omit to keep the extension Apple-Pay-only
) else { return }

// 3. Register with the Rokt SDK — pass your Stripe publishable key
Rokt.registerPaymentExtension(paymentExtension, config: [
    "stripeKey": "pk_live_abc123"
])

// 4. Show Shoppable Ads (always overlay)
Rokt.selectShoppableAds(
    identifier: "ConfirmationPage",
    attributes: [
        "email": "user@example.com",
        "firstname": "John",
        "lastname": "Doe",
        "confirmationref": "ORDER-12345"
    ],
    onEvent: { event in
        switch event {
        case let e as RoktEvent.CartItemInstantPurchase:
            print("Purchase: \(e.catalogItemId)")
        case let e as RoktEvent.CartItemInstantPurchaseFailure:
            print("Failed: \(e.error ?? "unknown")")
        default:
            break
        }
    }
)
```

### SDK+ Integration

When using the mParticle SDK, the Stripe publishable key is **automatically provided
from the mParticle dashboard configuration**. The partner only needs to create the
extension and register it — the Kit injects the `stripeKey` before forwarding to the
Rokt SDK:

```swift
import mParticle_Apple_SDK
import RoktPaymentExtension

// 1. mParticle init handles Rokt.initialize via Kit (tagId from dashboard)

// 2. Create and register the payment extension — no stripeKey needed.
guard let paymentExtension = RoktPaymentExtension(
    applePayMerchantId: "merchant.com.example",
    urlScheme: "myapp" // bare scheme — omit to keep the extension Apple-Pay-only
) else { return }
MParticle.sharedInstance().rokt.registerPaymentExtension(paymentExtension)
// Kit automatically injects stripeKey from dashboard config

// 3. Show Shoppable Ads
MParticle.sharedInstance().rokt.shoppableAds(
    "ConfirmationPage",
    attributes: [
        "email": "user@example.com",
        "firstname": "John",
        "lastname": "Doe"
    ]
)
```

### Enabling Afterpay / Clearpay

Afterpay/Clearpay is a redirect-based payment method: Stripe opens a web page for
authentication and redirects back to your app via a custom URL scheme.

1. **Declare the URL scheme** in your host app's `Info.plist` under
   `CFBundleURLTypes` (e.g. `myapp`).
2. **Pass the matching `urlScheme`** when creating the extension
   (e.g. `"myapp"`). The SDK builds the full return URL internally — you
   never need to type the path. The initializer returns `nil` if the scheme
   isn't registered in `Info.plist` (and raises an `assertionFailure` in
   DEBUG builds). Omit `urlScheme` entirely and the extension stays
   Apple-Pay-only.
3. **Forward redirect URLs** to the Rokt SDK from your `SceneDelegate` /
   `AppDelegate`. The SDK dispatches the URL to every registered
   `PaymentExtension` via the optional `handleURLCallback(with:)` hook, which
   this extension implements by calling `StripeAPI.handleURLCallback(with:)`.

   ```swift
   // SceneDelegate
   func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
       for ctx in URLContexts {
           Rokt.handleURLCallback(with: ctx.url)
       }
   }
   ```

### What Partners Need for Each Scenario

| Scenario                     | Packages                           | Stripe Key Source             | Code                                                                 |
| ---------------------------- | ---------------------------------- | ----------------------------- | -------------------------------------------------------------------- |
| Standard placements (SDK+)   | mParticle SDK + Rokt Kit           | —                             | `rokt.selectPlacements(...)`                                         |
| Shoppable Ads (SDK+)         | Above + RoktPaymentExtension       | Dashboard config (automatic)  | `registerPaymentExtension(ext)` + `shoppableAds(...)`                |
| Standard placements (Direct) | Rokt-Widget                        | —                             | `Rokt.selectPlacements(...)`                                         |
| Shoppable Ads (Direct)       | Rokt-Widget + RoktPaymentExtension | Partner passes in config dict | `registerPaymentExtension(ext, config:)` + `selectShoppableAds(...)` |

For Apple Pay, the extension now uses the backend preparation response to show
shipping, tax, and final total line items in the PassKit sheet whenever those
amounts are supplied.

## Architecture

```text
RoktPaymentExtension (public facade)
  ├── StripeApplePayManager (Apple Pay / card)       ← built if applePayMerchantId provided
  │    ├── STPApplePayContext (Stripe SDK)
  │    └── ContactAddressMapping (PKContact → ContactAddress)
  ├── StripeAfterpayManager (Afterpay / Clearpay)    ← built if urlScheme provided
  │    ├── STPPaymentHandler (Stripe SDK)
  │    └── BillingDetailsMapping (ContactAddress → Stripe billing/shipping)
  └── handleURLCallback(with:) → StripeAPI.handleURLCallback
```

- **RoktPaymentExtension**: Implements `PaymentExtension` protocol from RoktContracts; routes each `PaymentMethodType` to the matching internal manager. `supportedMethods` is computed from the configured managers.
- **StripeApplePayManager**: Manages Apple Pay / card flows via Stripe's `STPApplePayContext`, including line-item totals from the backend payment preparation response.
- **StripeAfterpayManager**: Manages redirect-based Afterpay / Clearpay flows via `STPPaymentHandler`; validates `PaymentContext.billingAddress` and confirms the PaymentIntent with a Rokt-owned return URL built from the partner's `urlScheme`.
- **ContactAddressMapping**: Converts Apple Pay `PKContact` to `ContactAddress`.
- **BillingDetailsMapping**: Converts `ContactAddress` to `STPPaymentMethodBillingDetails` and `STPPaymentIntentShippingDetailsParams`.

## Migration

See [MIGRATING.md](MIGRATING.md) for migration guidance between major versions.

## License

Copyright 2024 Rokt Pte Ltd. Licensed under the [Rokt SDK Terms of Use 2.0](https://rokt.com/sdk-license-2-0/).

## Security

Please report vulnerabilities via our [disclosure form](https://www.rokt.com/vulnerability-disclosure/). Do not use GitHub issues.
