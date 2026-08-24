# PR Gate

The standing gate every migration PR must pass, unchanged, for the duration of
this project. Established in Phase 1; applies to every conversion PR in every
phase after it without exception.

## The five items

1. **Zero public-ABI diff.** Run:

   ```bash
   bash Tools/abi-guard.sh check
   ```

   Must exit 0. The guard snapshots the public ObjC surface derived from
   `Include/*.h` (class names, selectors, nullability, enum cases) and diffs
   the current tree against the committed baseline. The guard script itself is
   defined in `Tools/` (see plan 01-02).

2. **`pod lib lint` clean on all 3 podspecs.** Run:

   ```bash
   pod lib lint mParticle-Apple-SDK.podspec --include-podspecs="{mParticle-Apple-SDK-Swift.podspec,mParticle-Apple-SDK-ObjC.podspec,mParticle-Apple-SDK.podspec}"
   ```

3. **Build green on iOS + tvOS.** Both platform targets must build without
   errors or new warnings introduced by the change.

4. **`trunk check` clean.** The primary lint/format enforcement tool must pass
   with no outstanding issues.

5. **ObjC + Swift unit test suites green.** Both `UnitTests/ObjCTests/` and
   `UnitTests/SwiftTests/` must pass. Any conversion PR that extracts logic to
   Swift must add a Swift mirror test for that extracted logic (see
   `CONVERSION-RECIPE.md`'s dual-test convention).

## Scope note

This gate is established in Phase 1 and applies unchanged to every migration
PR from here forward — it is not re-specified per phase. Wiring it into CI
(`.github/`) is a separate, explicitly-requested step and is **not** done as
part of establishing the gate; until that happens, run the five items locally
before opening a PR.

Source for the validation sequence: `AGENTS.md` ("Code style, quality, and
validation" — strict post-change validation rule).
