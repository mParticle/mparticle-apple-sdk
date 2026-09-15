# Backend upload migration

## Baseline

This stack starts at `018a105d` on `workstation/swift-migration` (15 September
2026), after the persistence, consumer-information, and state-machine migrations.
The migration report on PR #990 measures the core at 75.75% of in-scope source
lines migrated, with 3,783 Objective-C source lines remaining. This is a code
composition metric, not an estimate of remaining effort.

`MPUploadBuilder.m` starts at 251 physical lines and `MPBackendController.m` at
2,068. The builder is internal: its header is outside `Include`, there is no ABI
baseline entry, and its only production caller is the backend. It has no archive,
dynamic lookup, kit, or public-overlay identity requirement.

## Stack

| Stage | Responsibility                                            | Status      |
| ----- | --------------------------------------------------------- | ----------- |
| 1     | Inject upload-builder context and enrichment persistence  | Implemented |
| 2     | Replace the Objective-C upload builder with Swift         | Pending     |
| 3     | Define networking, readiness, and scheduling dependencies | Pending     |
| 4     | Move batch preparation into the Swift coordinator         | Pending     |
| 5     | Move upload-cycle coordination into Swift                 | Pending     |

Each stage targets the previous branch; the first targets
`workstation/swift-migration`. Kit projection work is independent of this stack.

## Behavior contract

- Constructor seed values are captured at construction; header, ATT, consent,
  and customer-hook values are read during build. Providers resolve current
  SDK objects so resetting or starting the SDK does not retain stale dependencies.
- Sessionless uploads use fallback application/device information. Saved session
  information takes precedence, and fallback providers run only when needed.
- Upload settings retain their Objective-C archive identity and existing codec.
- Forward records are deleted at their existing build stage. Upload insertion
  and source-message deletion remain one persistence transaction.
- A customer hook returning nil suppresses builder completion. An equal
  replacement does not add the mutation marker. Ramped uploads retain their
  existing completion behavior, and skip-next-upload remains process-wide.
- The existing message queue, public entry points, wire keys, platform floors,
  and kit contracts remain unchanged.

## Validation

Every stage requires the ABI guard, Trunk, three-podspec lint, iOS/tvOS builds,
and both unit-test schemes. Builder and coordinator cutovers also require
SwiftPM/WireMock integration validation. Retain Objective-C behavior tests and
add direct Swift tests for migrated implementation.

Validation uses Xcode 26.6 locally. The tvOS 26.5 runtime was installed
during this stack. Native CI pins Xcode 16.4; integration CI pins Xcode 26.2. Record actual
validation results in each PR rather than treating a local build as coverage
of either CI toolchain.

## Remaining backend work

The backend remains an internal wrapper-removal candidate. After uploads, migrate
session/message lifecycle, event and user mutations, notification handling, and
startup/attribution coordination. Remove the backend only after its callers and
delegates migrate and the exported-declaration audit passes the ABI workflow.
`mParticle`, public events/users, and runtime-pinned upload settings remain the
required Objective-C boundary.

### Stage 1 results

- ABI guard, Trunk, iOS/tvOS builds, and all-three-podspec lint pass.
- iOS Swift: 920 tests pass. Objective-C: 924 iOS and 848 tvOS tests run;
  the existing `testInitStartsSessionSyncDisableAll` ordering flake passes
  independently on both platforms. Both new builder tests pass.
- tvOS Swift: 914 tests run; the unchanged date-format test expects `GMT`,
  while Foundation on tvOS 26.5 returns `GMT+0`. A tvOS 18.5 run is pending.
