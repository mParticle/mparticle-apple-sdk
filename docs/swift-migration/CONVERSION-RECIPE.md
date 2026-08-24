# Conversion Recipe

How to move one Objective-C type's implementation to Swift without breaking the
public ObjC API or the kit integration contract. Follow this end-to-end for any
type on the tracking sheet — no clarifying questions should be needed.

## Two-stage wrapper model

Every conversion is two stages, and which stage-2 you get depends on whether the
type is public (see "Public vs internal" below):

1. **Move logic → Swift, keep the ObjC wrapper.** Add a Foundation-only Swift type
   in `mParticle-Apple-SDK-Swift/Sources/`. The ObjC class stays the type identity —
   its `.m` constructs/holds the Swift object and marshals values across the
   boundary. This pattern is already proven in-repo: 31 `.m` files `@import
mParticle_Apple_SDK_Swift` today (e.g. `mParticle-Apple-SDK/Ecommerce/MPProduct.m`,
   `mParticle-Apple-SDK/Identity/MParticleUser.m`).
2. **Remove the wrapper — internal types only.** Once a type's logic is fully in
   Swift and no ObjC caller needs the class, delete the internal `.h`/`.m` wrapper
   and have callers use the Swift type directly. Public and kit types skip this
   stage permanently.

## Per-type recipe steps

1. Add a Foundation-only Swift type in `mParticle-Apple-SDK-Swift/Sources/` with
   the same behavior, operating on Foundation types (`[String: Any]`, `Data`,
   `Date`, `NSNumber`). Mirror existing keys exactly (e.g. `MessageKeys`) — do not
   rename or restructure them.
2. Leave the ObjC `@interface`, class name, selectors, and nullability annotations
   untouched. The public/kit surface does not move.
3. Change the `.m` to own/forward to the Swift object. Marshal SDK types
   (`MPEvent`, `MParticleUser`, kit types) to/from Foundation values at the
   boundary — the Swift side never sees an SDK type directly. Properties stay on
   the ObjC class so KVC, `NSCopying`, and kit code keep working unchanged.
4. Keep `+Dictionary` categories and `MPDataModelProtocol` conformance on the ObjC
   type. Swift produces the dictionary; ObjC vends it.
5. Preserve private class extensions (e.g. `@interface MParticle ()`) on the ObjC
   type — a Swift helper cannot legally extend an ObjC class. Pass any extra state
   the extension held as arguments into the Swift call instead.
6. Add tests per the dual-test convention (below).
7. **Internal type**: once fully Swift and all callers migrated, delete the
   `.h`/`.m` wrapper. **Public or kit type**: the wrapper stays — see next section.

## Public vs internal

**Decision rule: a type is public iff it has a header in
`mParticle-Apple-SDK/Include/`.**

- **Internal** (no `Include/` header): once the logic is fully in Swift and no
  caller needs the ObjC class anymore, delete the `.h`/`.m` wrapper. Callers move
  to the Swift type directly.
- **Public or kit-protocol type**: the thin ObjC wrapper stays **permanently**.
  Deleting it turns the class into a Swift `@objc` class — an ABI/module-identity
  change that can break partner kits and mixed-language apps even with an
  identical class name. This is never done for a public or kit type in this
  project.

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
- Add a mirroring Swift test in `UnitTests/SwiftTests/` for each extracted slice
  (round-trip JSON, consent blobs, identity DTO fields, etc.) that exercises the
  new Swift type directly.
- Retire the ObjC duplicate only after sustained confidence in the Swift
  mirror — not automatically on merge.
- **This convention has no pilot in Phase 1.** `MPBracket` is being converted in
  parallel by a teammate and is out of scope here, so Foundation does not convert
  any type behind a wrapper. The dual-test convention is first demonstrated on
  **the first Phase 2 conversion**.

## Worked example

Existing forward-to-Swift wrappers to read before your first conversion:

- `mParticle-Apple-SDK/Ecommerce/MPProduct.m` — `@import mParticle_Apple_SDK_Swift`
- `mParticle-Apple-SDK/Identity/MParticleUser.m` — `@import mParticle_Apple_SDK_Swift`

Existing Foundation-only Swift helper pattern to mirror:

- `mParticle-Apple-SDK-Swift/Sources/Utils/MPIHasher.swift`
- `mParticle-Apple-SDK-Swift/Sources/Utils/MPUserDefaults.swift`
