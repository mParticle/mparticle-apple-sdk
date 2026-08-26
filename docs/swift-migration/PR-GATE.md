# PR Gate

The standing gate every migration PR must pass, unchanged, for the duration of
this project. Established in Phase 1; applies to every conversion PR in every
phase after it without exception.

## The five items

1. **No unreviewed Objective-C contract diff.** Run:

   ```bash
   bash Tools/abi-guard.sh check
   ```

   The guard snapshots the exported ObjC header surface derived from
   `Include/*.h` (class names, selectors, nullability, enum cases) and diffs
   the current tree against the committed baseline. It is a review alarm, not
   the authority on whether every exported declaration is a supported contract.

   An ordinary migration leaves the baseline unchanged and this command must
   exit 0. A migration may update the baseline only when it intentionally
   removes an accidentally exported internal declaration. That PR must:
   - audit customer, kit, wrapper-SDK, and runtime/persistence usage;
   - show that the pre-update diff contains only the audited internal symbols;
   - name those symbols and summarize the compatibility evidence in the PR;
   - regenerate the baseline from the final tree; and
   - rerun this command and get exit 0.

   Do not refresh the baseline to conceal removal of a supported customer, kit,
   wrapper-SDK, or persisted/runtime-identity contract. Supported API additions
   require normal API review and an intentional baseline update outside a
   behavior-preserving migration.

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

## What "done" means

The migration does not end at zero Objective-C. The public customer API, the
kit and wrapper-SDK contract surface, runtime-identity-pinned classes, and the
boundary glue in `CONVERSION-RECIPE.md`'s classifications 1, 3, and 4 stay
Objective-C by design — that is the intended end state, not unfinished work.

The migration is complete when every **in-scope** Objective-C implementation is
gone: the classification 2 wrappers and the internal types behind them. The
retained boundary is enumerated in `Tools/swift-migration-retained-objc.txt`,
and the progress report on each PR excludes it from the percentage so 100%
is reachable and means what it says.

Two consequences for a conversion PR:

- Classifying a declaration as a retained contract means adding its
  implementation to the manifest, with the audit evidence
  `CONVERSION-RECIPE.md` requires recorded in the PR. Item 1's baseline-update
  policy governs the other direction: an accidental export that gets removed is
  **not** retained.
- Deleting or renaming a retained implementation means updating the manifest in
  the same PR. The report fails on a stale entry.

Retaining a wrapper does not freeze it. A contract wrapper keeps its
`@interface`, class name, selectors, and nullability while its logic moves to
Swift, so the report tracks its remaining Objective-C SLOC in a separate
retained column rather than in the percentage.

## Scope note

This gate applies to every migration PR and is not re-specified per phase.
The ABI item was refined after the first conversion series demonstrated that
some internal implementation types had been accidentally exported through
`Include/`. Wiring the guard into CI (`.github/`) remains a separate,
explicitly-requested step; until then, run the five items locally before
opening or updating a PR.

Source for the validation sequence: `AGENTS.md` ("Code style, quality, and
validation" — strict post-change validation rule).
