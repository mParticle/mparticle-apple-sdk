# Tools/

Migration tooling for the Objective-C -> Swift conversion.

## abi-guard.sh

Snapshots the exported Objective-C header surface (class/protocol names,
selectors, property nullability, enum members) derived from
`mParticle-Apple-SDK/Include/*.h`. It is a focused migration guard, not a
complete binary-ABI verifier and not a declaration that every header token is
a supported customer or kit contract. It parses header text only — never
`eval`s or executes header contents.

```bash
Tools/abi-guard.sh snapshot [header-dir]  # print the current surface (default: Include/)
Tools/abi-guard.sh update                 # regenerate Tools/abi-baseline.txt from Include/
Tools/abi-guard.sh check [header-dir]     # diff header-dir's surface against the committed baseline
```

Run `Tools/abi-guard.sh check` on every conversion PR that touches
`Include/*.h`. Exit 0 means the exported snapshot matches the reviewed
baseline; a non-zero exit prints the diff for classification and review.

### Self-test

`Tools/abi-guard-selftest.sh` proves the guard actually catches breakage,
without touching the real tree:

```bash
Tools/abi-guard-selftest.sh
```

It asserts (1) the real, unmodified `Include/` passes `check`, and (2) a
mutated _copy_ of `Include/` (in a temp dir) fails `check`. Prints
`SELFTEST PASS` and exits 0 only if both hold.

### Baseline-update policy

`Tools/abi-baseline.txt` is committed. Updating it (`Tools/abi-guard.sh
update`) is legitimate only for one of these reviewed cases:

- a supported API addition that has completed normal API review; or
- removal of an accidentally exported internal declaration after auditing
  customer, kit, wrapper-SDK, and persisted/runtime-identity usage.

For an internal cleanup, the PR must show the pre-update diff, name the removed
symbols, explain why they are not a supported contract, regenerate the
baseline from the final tree, and finish with `abi-guard.sh check` passing.
Removal of a supported customer, kit, wrapper-SDK, or persisted/runtime
contract still requires explicit compatibility coordination. An unexplained
baseline diff is a **gate failure**, not something to fix by blindly running
`update`.

### CI wiring — deferred

Wiring `abi-guard.sh check` into CI (`.github/`) is a separate, explicitly
requested step and is **not** done here. Today it is run manually / locally
as part of the standing PR gate (see `docs/swift-migration/PR-GATE.md`).

## swift-migration-progress.sh

Builds the informational Swift migration report shown on pull requests. The
report compares two committed revisions without checking either one out in the
working tree:

```bash
Tools/swift-migration-progress.sh report \
  --repo . \
  --base origin/workstation/swift-migration \
  --head HEAD \
  --cloc /path/to/cloc-2.10.pl \
  --output /tmp/swift-migration-progress.md
```

The workflow downloads
[`cloc` 2.10](https://github.com/AlDanial/cloc/releases/tag/v2.10) and verifies
its pinned SHA-256 before running the tool. For a local smoke test, download
that same release, make it executable, and run:

```bash
Tools/swift-migration-progress.sh selftest --cloc /path/to/cloc-2.10.pl
```

The self-test creates a temporary Git repository and verifies bucket
isolation, exclusions, code/comment/blank handling, percentage rounding,
zero-denominator handling, Objective-C++ counting, filenames with spaces,
renames, physical diff movement across divergent histories, flat changes, and
regressions. It also covers the retained manifest: comment/blank/whitespace
parsing, removal from the percentage denominator, retained thinning reported
without percentage movement, and rejection of stale, non-Objective-C,
out-of-bucket, and vendored entries.

### Metric definitions

The report has exactly two rows, because the migration has two horizons and
each horizon covers a different scope:

- **Short term — Core SDK and the Rokt kit, excluding the public API.**
  Swift SLOC / (Swift SLOC + in-scope Objective-C), counted only across Core
  SDK (including its kit infrastructure) and the Rokt kit. In-scope excludes
  the implementations listed in `Tools/swift-migration-retained-objc.txt` —
  the public/kit contract, runtime-identity, and boundary-glue files that stay
  Objective-C by design. **100% here is the end of this project for that
  scope**: every Objective-C implementation the migration intends to delete
  is gone. Every kit other than Rokt never counts here, no matter what the
  manifest says.
- **Long term — everything, including all kits and the public API.** Swift
  SLOC / (Swift SLOC + all Objective-C), summed across Core SDK, the Rokt
  kit, and every other standalone kit, with no manifest exclusion. **100%
  here means the public API itself becomes Swift and every kit converts**,
  which is a breaking change reserved for a future major release. It is kept
  so the goal stays measurable rather than being redefined away.

The retained public API surface is printed explicitly under the table (SLOC,
with a signed delta when it moved), but it is only part of the gap between
the two rows: it is the boundary within Core SDK and the Rokt kit. The rest
of the gap is every kit other than Rokt, which the short-term goal excludes
outright.

Retained wrappers keep their `@interface`, class name, selectors, and
nullability, but their logic still moves to Swift and the wrapper thins to
marshaling. That thinning moves the long-term row and the retained figure
while leaving the short-term row flat — the short-term goal tracks file
removal within its scope, the long-term goal tracks every Objective-C line
everywhere.

Both revisions are counted using the **head** revision's manifest. A PR that
edits the manifest therefore re-measures its own base under the new definition
instead of booking the redefinition as progress.

Path matching alone would misread a retained file that a PR **renames or
deletes**: its base-side path is absent from the head manifest, so the base
would count it as in-scope and the short-term row would rise on work nobody
did. The base count therefore also treats as retained any base-manifest entry
whose file no longer exists at head, which covers both cases. An entry dropped
from the manifest while its file survives is left alone on purpose — that is a
deliberate reclassification, and the head definition should apply to both
revisions.

The three production-code buckets do not overlap:

- **Core SDK:** Swift in `mParticle-Apple-SDK-Swift/Sources`, and Objective-C
  or Objective-C++ in `mParticle-Apple-SDK` (including each tree's SDK kit
  infrastructure — `mParticle-Apple-SDK/Kits` and the future
  `mParticle-Apple-SDK-Swift/Sources/Kits` subtree), excluding
  `mParticle-Apple-SDK/Libraries`. Shares the short-term goal.
- **Rokt kit:** Swift, Objective-C, and Objective-C++ only below
  `Kits/rokt/rokt/**/Sources`. Also shares the short-term goal.
- **Other kits:** every other standalone kit's Swift, Objective-C, and
  Objective-C++ below `Kits/**/Sources` (including `Kits/rokt-sdk-plus`).
  Counted only toward the long-term goal.

Current language composition is production SLOC reported by `cloc`, so blank
and comment lines do not count. Objective-C++ (`.mm`) is grouped with
Objective-C remaining. Tests, examples, headers, build outputs, vendored
libraries, and the customer-facing `MParticle/Sources` Swift overlay are
excluded.

The pull request movement table is a different metric, and it is **not**
filtered by the manifest — deleting lines from a retained wrapper is real work
and is counted. It reports physical Swift lines
added and Objective-C/Objective-C++ lines deleted according to
`git diff base...head --numstat -z`. The three-dot comparison measures changes
from the merge base through the pull request head, so commits present only on
an advanced base branch are not attributed to the pull request. These figures
can differ from the SLOC change because Git includes comments and blank lines.

### Retained Objective-C manifest

`Tools/swift-migration-retained-objc.txt` is the reviewed list of Objective-C
implementations this phase of the migration will not delete. It is the boundary
between the two goal rows, so it is committed and changed deliberately — never
edited to make a number look better.

```text
# one repository-relative path per line; `#` comments and blanks ignored
mParticle-Apple-SDK/Event/MPEvent.m
```

The report validates every entry and fails on any of these, rather than
silently counting the file as in-scope:

- a path that does not exist in the head revision (stale after a delete or
  rename — fix the manifest in the same PR);
- a path that is not a `.m`/`.mm` implementation; or
- a path outside the three counted buckets, including
  `mParticle-Apple-SDK/Libraries`.

Adding an entry requires the same evidence
`docs/swift-migration/CONVERSION-RECIPE.md` demands to classify a declaration
as a supported contract, runtime-identity-pinned, or boundary glue: name the
declaration, point at its `Tools/abi-baseline.txt` entry, and record the
customer/kit/wrapper-SDK audit in the PR. A file whose declaration is an
accidental export is **not** retained — it stays in scope and its wrapper gets
deleted.

Removing an entry is the normal end of classification 4: when a boundary is
redesigned and the glue is deleted, delete its line with it. A future major
release that takes the public API itself to Swift would empty the manifest,
which converges the short-term goal to 100% for its own scope — Core SDK and
the Rokt kit. The two rows themselves converge only once every other kit is
also fully Swift, since the long-term row keeps summing those in regardless of
the manifest.

The Rokt kit and every other standalone kit have no entries yet. Their
`MPKit*` classes are resolved by name at runtime, so any kit-side conversion
has to establish that contract before its implementation is listed here. An
entry for a kit other than Rokt would only ever move the long-term figure,
since the short-term goal never counts that kit regardless of the manifest.

### Workflow behavior and removal

`.github/workflows/swift-migration-progress.yml` runs the self-test and report
for every pull request and always publishes the Markdown to the job summary.
For same-repository pull requests it also replaces one comment identified by
`<!-- swift-migration-progress -->`. Fork pull requests only receive the job
summary because their `pull_request` token is read-only. Flat or negative
migration movement remains informational; installation, self-test, counting,
and same-repository comment failures fail the job.

When the migration is complete, remove:

- `.github/workflows/swift-migration-progress.yml`;
- the `swift-migration-progress` job and notification dependency in
  `.github/workflows/pull-request.yml`;
- `Tools/swift-migration-progress.sh`;
- `Tools/swift-migration-retained-objc.txt`; and
- this README section.

There is no stored baseline or external service to clean up.
