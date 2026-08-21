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

Rokt sessions are managed automatically: placements shown to the same user share one session, and the session survives app restarts. No session code is needed for a normal single-user app.

The kit does **not** end the Rokt session when the mParticle user changes. A login or logout is not a reliable signal that a different person is present — a single customer's MPID can move mid-journey, for example anonymous on the payment page and known on the confirmation page — and acting on it would split sessions for every partner on this kit rather than only shared-device ones.

### Self-service terminals (kiosks, shared devices)

Where a queue of unrelated customers uses one device, each transaction should be its own session. Call `clearSession` at the transaction boundary so the next customer starts fresh:

```swift
// The customer has finished at the terminal; the next person starts fresh.
MParticle.sharedInstance().rokt.clearSession()
```

The kit forwards this straight to the Rokt SDK. Because there is no automatic reset, this call is what separates one customer from the next — logging the user out or identifying the next customer does not do it on its own.

Notes:

- **When to call it:** at the boundary between customers, not between screens within one customer's journey. Two placements shown to the same customer are meant to share a session.
- **When the new session begins:** on the next `selectPlacements` call. `clearSession` only ends the current session.
- **Buffered events are not lost:** queued analytics events are flushed before the session is dropped, so the departing customer's activity stays attributed to them.
- **Calling it is always safe:** repeated calls are idempotent, and with no active session there is no session state to clear.
- **Session hand-off:** this also clears the id returned by `getSessionId`, so a WebView hand-off must be re-established afterwards.
- **Experience caching:** avoid enabling Rokt experience caching on shared terminals — a cached experience belongs to the customer it was fetched for.

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
