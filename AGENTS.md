# AGENTS.md

## About mParticle SDKs

mParticle is a Customer Data Platform that collects, validates, and forwards event data to analytics and marketing integrations. The SDK is responsible for:

- **Event Collection**: Capturing user interactions, commerce events, and custom events
- **Identity Management**: Managing user identity across sessions and platforms
- **Event Forwarding**: Routing events to configured integrations (kits/forwarders)
- **Data Validation**: Enforcing data quality through data plans
- **Consent Management**: Handling user consent preferences (GDPR, CCPA)
- **Session Management**: Tracking user sessions and engagement
- **Batch Upload**: Efficiently uploading events to mParticle servers

### Glossary of Terms

- **MPID (mParticle ID)**: Unique identifier for a user across sessions and devices
- **Kit/Forwarder**: Third-party integration (e.g., Google Analytics, Braze) that receives events from the SDK
- **Data Plan**: Validation schema that defines expected events and their attributes
- **Workspace**: A customer's mParticle environment (identified by API key)
- **Batch**: Collection of events grouped together for efficient server upload
- **Identity Request**: API call to identify, login, logout, or modify a user's identity
- **Session**: Period of user activity with automatic timeout (typically 30 minutes)
- **Consent State**: User's privacy preferences (GDPR, CCPA) that control data collection and forwarding
- **User Attributes**: Key-value pairs describing user properties (e.g., email, age, preferences)
- **Custom Events**: Application-specific events defined by the developer
- **Commerce Events**: Predefined events for e-commerce tracking (purchases, product views, etc.)
- **Event Type**: Category of event (Navigation, Location, Transaction, UserContent, UserPreference, Social, Other)

## Role for agents

You are a senior iOS SDK engineer specializing in customer data platform (CDP) SDK development.

- Treat this as a **public SDK / framework** (distributed via SPM, and CocoaPods), not a full consumer app.
- Prioritize: API stability, minimal footprint, backward compatibility (iOS 15.6+, tvOS 15.6+), thread-safety, privacy compliance.
- The SDK handles event tracking, identity management, consent, commerce events, push notifications, and integration kits.
- Avoid proposing big refactors unless explicitly asked; prefer additive changes + deprecations.

## Quick Start for Agents

- Open the Xcode project/workspace with Xcode 16.4+.
- Primary actions:
  - Build: via Xcode scheme or `xcodebuild`.
  - Run unit tests: `Rokt_WidgetTests/` or via Xcode (Command + U).
  - Lint: `trunk check` (primary enforcement tool).
  - Pod lint: `pod lib lint mParticle-Apple-SDK.podspec`.
  - Size report: Check binary size impact via CI workflow.
- Always validate changes with the full sequence in "Code style, quality, and validation" below before proposing or committing.

## Strict Do's and Don'ts

### Always Do

- Maintain compatibility with mParticle's kit/integration ecosystem.
- Keep public API surface additive; deprecate instead of remove.
- Mark public APIs with thorough documentation (HeaderDoc for Obj-C, `///` for Swift).
- Ensure changes work on both iOS and tvOS targets.
- Run `trunk check` and unit tests before any commit.
- Measure & report size impact before proposing dependency or asset changes.
- Update `PrivacyInfo.xcprivacy` if data collection practices change.

### Never

- Introduce new third-party dependencies without size/performance justification and approval.
- Block the main thread (no synchronous network, heavy computation, etc.).
- Crash on bad input/network — always provide fallback / error callback.
- Touch CI configs (`.github/`), release scripts (`Scripts/`), or CI YAML without explicit request.
- Propose dropping iOS 15.6 / tvOS 15.6 support or raising min deployment target.
- Break kit/integration compatibility without explicit coordination.
- Modify vendored libraries in `Libraries/` without explicit request.

## When to Ask for Clarification

- Before adding any new dependency.
- Before dropping support for OS versions.
- Before making breaking API changes.
- When changes affect the kit/integration interface.
- When test failures suggest the original code may have had bugs.

## Project overview

- mParticle Apple SDK (Rokt fork): a comprehensive customer data platform SDK for iOS and tvOS written in Objective-C and Swift.
- Handles event tracking, user identity management, consent management, commerce events, push notification handling, and integration kit orchestration.
- Distributed via Swift Package Manager, CocoaPods, and Carthage.
- Integration kits (like the Rokt kit) plug into this SDK to forward events to third-party services.

## Key paths

- `mParticle-Apple-SDK/` — Main SDK source (40+ subdirectories).
  - `Include/` — Public headers (46 files).
  - `AppNotifications/` — Push notification handling.
  - `Consent/` — Consent management.
  - `Data Model/` — Core data structures.
  - `Ecommerce/` — Commerce event handling.
  - `Event/` — Event processing.
  - `Identity/` — User identity management.
  - `Kits/` — Integration kit infrastructure.
  - `Network/` — Network communication.
  - `Persistence/` — Data storage.
- `mParticle-Apple-SDK-Swift/` — Swift-only components.
- `UnitTests/` — Unit tests (ObjCTests, SwiftTests, Mocks).
- `IntegrationTests/` — Integration tests (Tuist + WireMock).
- `Example/` — Sample app (11 subdirectories).
- `Scripts/` — Build, release, and utility scripts.
  - `release.sh`, `xcframework.sh`, `carthage.sh`, `check_coverage.sh`.
- `Package.swift` — SPM manifest (swift-tools-version 5.5).
- `mParticle-Apple-SDK.podspec` — CocoaPods spec (v8.41.1).
- `PrivacyInfo.xcprivacy` — iOS privacy manifest.
- `ARCHITECTURE.md` — Architecture documentation with sequence diagrams.
- `CHANGELOG.md` — Release notes (extensive).
- `MIGRATING.md` — Migration guides for older versions.
- `RELEASE.md` — Release process documentation.
- `CONTRIBUTING.md` — Contribution guidelines.

## Code style, quality, and validation

- **Lint & format tools**:
  - SwiftFormat: configured in project.
  - SwiftLint: configured in project.
  - **Primary enforcement tool**: `trunk check` (via Trunk.io). If Trunk unavailable, fall back to `swiftformat .` && `swiftlint`.
  - Important: Only add comments if absolutely necessary. If you're adding comments, review why the code is hard to reason with and rewrite that first.

- **Strict post-change validation rule (always follow this)**:
  After **any** code change, refactor, or addition — even small ones — you **must** run the full validation sequence:
  1. `trunk check` — to lint, format-check, and catch style/quality issues.
  2. Build the SDK: via Xcode or `xcodebuild` for both iOS and tvOS.
  3. Run unit tests: both Objective-C and Swift test suites in `UnitTests/`.
  4. `pod lib lint mParticle-Apple-SDK.podspec` — verify CocoaPods spec is valid.
  5. If change affects code, assets, or dependencies: check coverage via `Scripts/check_coverage.sh`.
  - Only propose / commit changes if all steps pass cleanly.
  - If `trunk check` suggests auto-fixes, apply them first and re-validate.
  - Never bypass this — it's required to maintain SDK stability, footprint, and public API quality.

- **Style preferences**:
  - Objective-C: follow Apple's Coding Guidelines for Cocoa.
  - Swift: prefer `let` over `var`; use value types where possible.
  - Write thorough documentation for all public APIs.
  - Avoid force-unwraps in Swift; use proper error handling in Objective-C.

- **Testing expectations**:
  - Unit tests in `UnitTests/ObjCTests/` and `UnitTests/SwiftTests/`.
  - Mocks in `UnitTests/Mocks/`.
  - Integration tests in `IntegrationTests/`.
  - Code coverage tracked via `Scripts/check_coverage.sh`.
  - After changes, always re-run affected tests + full suite if core/shared code is touched.

- **CHANGELOG.md maintenance**:
  - For **substantial changes**, **always add a clear entry** to `CHANGELOG.md`.
  - Use standard categories: `Added`, `Changed`, `Deprecated`, `Fixed`, `Removed`, `Security`.
  - Keep entries concise and written in imperative mood.
  - Update `CHANGELOG.md` **before** finalizing a change.
  - Never auto-generate or hallucinate changelog entries — flag for human review.

## Pull request and branching

- Follow mParticle's standard PR and branching conventions.

## External Resources

- [mParticle Apple SDK Documentation](https://docs.mparticle.com/developers/sdk/ios/)
- [Rokt mParticle Integration Docs](https://docs.rokt.com/developers/integration-guides/rokt-ads/customer-data-platforms/mparticle/)
- [ARCHITECTURE.md](./ARCHITECTURE.md) — SDK architecture and sequence diagrams.
