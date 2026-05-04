# mParticle Rokt Kit

[Rokt](https://www.rokt.com) integration kit for the [mParticle Apple SDK](https://github.com/mParticle/mparticle-apple-sdk).

## Installation

### Swift Package Manager

Add the package dependency to your `Package.swift` or via Xcode:

```swift
.package(
    url: "https://github.com/mparticle-integrations/mp-apple-integration-rokt",
    .upToNextMajor(from: "9.0.0")
)
```

Then add a **product** to your target’s dependencies:

- **`mParticle-Rokt`** (default) — includes [`RoktPaymentExtension`](https://github.com/ROKT/rokt-payment-extension-ios) so Shoppable Ads works without declaring that package yourself. Imports stay the same (`mParticle_Rokt`, etc.).
- **`mParticle-Rokt-No-Payments`** — same kit **without** linking the payment extension (smaller dependency graph, no Stripe). Use this only if you do not need Shoppable Ads / `RoktPaymentExtension`, or you will add `rokt-payment-extension-ios` to your app separately.

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "mParticle-Rokt", package: "mp-apple-integration-rokt"),
        // …
    ]
)
```

No-payments example:

```swift
.product(name: "mParticle-Rokt-No-Payments", package: "mp-apple-integration-rokt"),
```

### CocoaPods

Default install includes the payment extension (for Shoppable Ads):

```ruby
pod 'mParticle-Rokt', '~> 9.0'
```

To use the kit **without** `RoktPaymentExtension` / Stripe:

```ruby
pod 'mParticle-Rokt/No-Payments', '~> 9.0'
```

## Verifying the Integration

After installing, rebuild and launch your app. With the mParticle log level set to Debug or higher, you should see the following in your Xcode console:

```bash
Included kits: { Rokt }
```

## Usage

### Placements

```swift
MParticle.sharedInstance().rokt.selectPlacements("checkout",
                                                  attributes: ["email": "user@example.com"],
                                                  embeddedViews: ["Location1": embeddedView],
                                                  config: nil) { event in
    if event is RoktEvent.PlacementReady {
        // Placement is ready
    }
}
```

### Shoppable Ads

Shoppable Ads enable in-placement purchases via Apple Pay (or another registered payment extension). Currently we support Stripe as a payment extension, however, if you need support for a different payment provider please reach out to your dedicated account team. The `stripePublishableKey` configured in the mParticle dashboard is automatically forwarded to Rokt — no manual key management needed in code.

**Step 1 — Register a payment extension once** (e.g., at app start):

```swift
MParticle.sharedInstance().rokt.registerPaymentExtension(stripeExtension)
```

```objective-c
[[MParticle sharedInstance].rokt registerPaymentExtension:stripeExtension];
```

**Step 2 — Display a Shoppable Ads placement:**

```swift
MParticle.sharedInstance().rokt.selectShoppableAds("ShopView",
                                                    attributes: ["email": "user@example.com"],
                                                    config: nil) { event in
    if event is RoktEvent.PlacementReady {
        // Placement is ready
    }
}
```

```objective-c
[[MParticle sharedInstance].rokt selectShoppableAds:@"ShopView"
                                          attributes:@{@"email": @"user@example.com"}
                                             config:nil
                                            onEvent:^(RoktEvent * _Nonnull event) {
    if ([event isKindOfClass:[RoktPlacementReady class]]) {
        // Placement is ready
    }
}];
```

For the full event type reference, see [MIGRATING.md](../../MIGRATING.md).

## Documentation

- [Rokt mParticle Integration](https://docs.rokt.com/developers/integration-guides/rokt-ads/customer-data-platforms/mparticle/)
- [mParticle Apple SDK Documentation](https://docs.mparticle.com/developers/sdk/ios/)

## Issues

Please report bugs and feature requests to the [mparticle-apple-sdk](https://github.com/mParticle/mparticle-apple-sdk/issues) repository. This mirror repository is not actively monitored for issues.

## License

[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0)
