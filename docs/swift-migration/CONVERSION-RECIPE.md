# Conversion Recipe

How to move one Objective-C type's implementation to Swift without breaking the
public ObjC API or the kit integration contract. Follow this end-to-end for any
type on the tracking sheet — no clarifying questions should be needed.

## Classify the compatibility contract first

A header under `mParticle-Apple-SDK/Include/` proves that a declaration is
exported today; it does not by itself prove that the declaration is a supported
customer or kit contract. Choose the conversion end state from the declaration's
real compatibility obligations:

1. **Supported customer, kit, or wrapper-SDK contract.** Keep the ObjC interface
   and runtime identity. Move implementation to Swift behind a thin ObjC wrapper.
2. **Internal with no runtime-identity obligation.** Move callers to the Swift
   type and delete the ObjC wrapper. If the declaration was accidentally
   exported, remove it from the umbrella/header surface and update the ABI
   baseline through `PR-GATE.md`'s reviewed workflow.
3. **Internal but runtime-identity pinned.** The header may be privatized, but
   keep the ObjC class when archives, `NSClassFromString`, nib/storyboard lookup,
   or another persisted/dynamic mechanism depends on its class identity.
4. **Internal ObjC boundary glue.** The declaration may leave the public surface
   even when a small ObjC implementation remains to bridge an unavoidable module
   or framework boundary.

Before classifying a declaration as internal, audit all of the following:

- customer documentation, examples, and the public Swift overlay;
- standalone kits and the kit protocols/types they implement;
- wrapper-SDK integration points;
- repository-wide ObjC and Swift callers, categories, KVC, and subclassing;
- archived class names, secure-coding mappings, dynamic class lookup, and
  nib/storyboard references; and
- recent migration PRs and review decisions that established compatibility
  requirements.

Record the evidence in any PR that removes an exported declaration. If the
audit finds a supported external dependency, classify the declaration as a
contract and keep its wrapper.

Classifications 1, 3, and 4 keep an Objective-C implementation permanently, so
they are also the migration's scope boundary. When a conversion settles one of
those classifications, add the implementation path to
`Tools/swift-migration-retained-objc.txt` with the audit evidence in the PR;
that file is what makes the progress report's 100% reachable, and
`PR-GATE.md`'s "What \"done\" means" section governs it. Classification 2 files
stay out of the manifest — they are the work the percentage measures.

## Two-stage wrapper model

1. **Move logic → Swift; keep the boundary that is still required.** Add a
   Foundation-only Swift type in `mParticle-Apple-SDK-Swift/Sources/`. When an
   ObjC wrapper is required, its `.m` constructs/holds the Swift object and
   marshals values across the boundary.
2. **Apply the classified end state.** Keep contract or runtime-pinned wrappers;
   privatize ObjC-only boundary glue; delete internal wrappers once all callers
   can use the Swift type directly.

## Per-type recipe steps

1. Add a Foundation-only Swift type in `mParticle-Apple-SDK-Swift/Sources/` with
   the same behavior, operating on Foundation types (`[String: Any]`, `Data`,
   `Date`, `NSNumber`). Mirror existing keys exactly (e.g. `MessageKeys`) — do not
   rename or restructure them.
2. For a supported customer, kit, or wrapper-SDK contract, leave the ObjC
   `@interface`, class name, selectors, and nullability annotations untouched.
   For an audited accidental export, remove it only through the baseline-update
   workflow in `PR-GATE.md`.
3. When a wrapper remains, change the `.m` to own/forward to the Swift object.
   Marshal SDK types (`MPEvent`, `MParticleUser`, kit types) to/from Foundation
   values at the boundary — the Swift side never sees an SDK type directly.
   Keep properties on the ObjC class when KVC, `NSCopying`, or external callers
   require them.
4. Keep `+Dictionary` categories and `MPDataModelProtocol` conformance on the ObjC
   type. Swift produces the dictionary; ObjC vends it.
5. Preserve private class extensions (e.g. `@interface MParticle ()`) on the ObjC
   type — a Swift helper cannot legally extend an ObjC class. Pass any extra state
   the extension held as arguments into the Swift call instead.
6. Add tests per the dual-test convention (below).
7. Apply the classified end state: keep a contract/runtime wrapper, privatize
   boundary glue, or delete the internal `.h`/`.m` wrapper after callers migrate.

## Compatibility inventory

This inventory captures the current audit. Recheck usage in the conversion PR
because downstream code can change.

| Classification                       | Declarations                                                                                                                                                                                                                                                                                                     | Required end state                                                                                                             |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| Internal, wrapper-removal candidates | `MPApplication_PRIVATE`; `MPBackendController_PRIVATE`, `MPKitContainer_PRIVATE`, `MPNetworkCommunication_PRIVATE`, `MPNotificationController_PRIVATE`, `MPPersistenceController_PRIVATE`, `MPStateMachine_PRIVATE`, and their internal protocols/delegates; `SceneDelegateHandler` and `OpenURLHandlerProtocol` | Remove exported headers/baseline entries with the conversion; delete wrappers after internal callers migrate.                  |
| Internal ObjC boundary glue          | `MPUserDefaultsConnector`                                                                                                                                                                                                                                                                                        | Remove accidental public exposure when callers permit, but retain the ObjC bridge until its dependency boundary is redesigned. |
| Internal, runtime-identity pinned    | `MPUploadSettings`                                                                                                                                                                                                                                                                                               | Its header may become internal, but retain the ObjC class, secure-coding conformance, and legacy archive class-name mappings.  |
| Internal members on a supported type | `MParticle.kitContainer_PRIVATE`, `MParticle.deferredKitConfiguration_PRIVATE`, `+[MParticle isOlderThanConfigMaxAgeSeconds]`                                                                                                                                                                                    | Move into private declarations through separate reviewed migrations, then remove their baseline entries.                       |
| Supported kit/wrapper contracts      | `MPKitProtocol`, `MPKitAPI`, `MPKitExecStatus`, filtered identity/user types, commerce dictionary helpers, `MPCommerceEventInstruction`, `MPForwardRecord`, `+[MParticle _setWrapperSdk_internal:version:]`                                                                                                      | Preserve the ObjC interface and runtime identity.                                                                              |

Customer-facing event, identity, consent, commerce, location, options, and Rokt
APIs remain supported contracts even when their implementations move to Swift.
Their Objective-C declaration sites are enumerated in
`Tools/swift-migration-retained-objc.txt`.

## Hard constraint: the Swift module cannot import ObjC

`mParticle-Apple-SDK-Swift` is Foundation/UIKit-only and **cannot import** the
ObjC module (`mParticle_Apple_SDK_ObjC`) — that would be a dependency cycle,
since the ObjC module already imports the Swift module. This means:

- The Swift helper only ever operates on Foundation/UIKit types.
- All marshaling of SDK types (`MPEvent`, `MParticleUser`, kit types, etc.) to
  and from Foundation values happens in the ObjC `.m`, not in Swift.
- If a conversion seems to need the Swift side to know about an SDK type, that's
  a sign the boundary is drawn wrong — push the marshaling back into the `.m`.

## Dual-test convention (FOUND-03)

- Keep the existing ObjC test in `UnitTests/ObjCTests/` as the behavior contract
  — it does not get deleted just because logic moved to Swift.
- Add a mirroring Swift test in `mParticle-Apple-SDK-Swift/Test/Utils/` for each extracted slice
  (round-trip JSON, consent blobs, identity DTO fields, etc.) that exercises the
  new Swift type directly.
- Retire the ObjC duplicate only after sustained confidence in the Swift
  mirror — not automatically on merge.

## Worked example

Existing contract wrappers to read before a conversion:

- `mParticle-Apple-SDK/Ecommerce/MPProduct.m` — `@import mParticle_Apple_SDK_Swift`
- `mParticle-Apple-SDK/Identity/MParticleUser.m` — `@import mParticle_Apple_SDK_Swift`
- `mParticle-Apple-SDK/Utils/MPUploadSettings.m` — internal but archive-identity pinned

Existing direct/internal migrations to read before deleting a wrapper:

- `mParticle-Apple-SDK-Swift/Sources/Utils/MPApplication.swift`
- `mParticle-Apple-SDK-Swift/Sources/Utils/MPConsentKitFilter.swift`

Existing Foundation-only Swift helper pattern to mirror:

- `mParticle-Apple-SDK-Swift/Sources/Utils/MPIHasher.swift`
- `mParticle-Apple-SDK-Swift/Sources/Utils/MPUserDefaults.swift`
