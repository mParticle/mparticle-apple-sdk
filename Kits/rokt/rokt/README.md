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

Then add `mParticle-Rokt` as a dependency of your target.

### CocoaPods

Add the kit dependency to your app's Podfile:

```ruby
pod 'mParticle-Rokt', '~> 9.0'
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

## Session management

Rokt sessions are managed automatically. Placements shown to the same user share one session, and **the kit ends the Rokt session whenever the mParticle user changes**:

| Identity transition | Rokt session |
|---|---|
| Anonymous user is identified (e.g. unknown on the payment page, known on the confirmation page) | **Kept** — same person, in-session state survives |
| A different user identifies or logs in | **Ended** — the next placement starts a new session |
| The current user logs out | **Ended** |

No integration code is needed for this behaviour.

### Self-service terminals (kiosks, shared devices)

Where a queue of unrelated customers uses one device, the recommended pattern is to **log the user out (or identify the next customer) between transactions** — the kit resets the Rokt session at that boundary, so each customer's placements and events land on their own session.

A manual reset is also available for explicit control:

```swift
MParticle.sharedInstance().rokt.clearSession()
```

Notes:

- The new session begins on the **next** `selectPlacements` call; `clearSession` only ends the current one.
- Calling `clearSession` with no active session is a no-op, and it is safe to combine with the automatic behaviour — both converge on the same idempotent reset.
- Avoid enabling Rokt experience caching on shared terminals: a cached experience belongs to the customer it was fetched for.

## Platform Support

| Platform | Minimum Version |
| -------- | --------------- |
| iOS      | 15.0            |
| tvOS     | 15.0            |

## Documentation

- [Rokt mParticle Integration](https://docs.rokt.com/developers/integration-guides/rokt-ads/customer-data-platforms/mparticle/)
- [mParticle Apple SDK Documentation](https://docs.mparticle.com/developers/sdk/ios/)

## Issues

Please report bugs and feature requests to the [mparticle-apple-sdk](https://github.com/mParticle/mparticle-apple-sdk/issues) repository. This mirror repository is not actively monitored for issues.

## License

[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0)
