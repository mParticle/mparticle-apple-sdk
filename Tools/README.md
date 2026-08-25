# Tools/

Migration tooling for the Objective-C -> Swift conversion.

## abi-guard.sh

Proves the public Objective-C ABI (class/protocol names, selectors, property
nullability, enum members) derived from `mParticle-Apple-SDK/Include/*.h` has
not changed. Parses header text only — never `eval`s or executes header
contents.

```bash
Tools/abi-guard.sh snapshot [header-dir]  # print the current surface (default: Include/)
Tools/abi-guard.sh update                 # regenerate Tools/abi-baseline.txt from Include/
Tools/abi-guard.sh check [header-dir]     # diff header-dir's surface against the committed baseline
```

Run `Tools/abi-guard.sh check` on every conversion PR that touches
`Include/*.h`. Exit 0 means the public surface is unchanged; a non-zero exit
prints the diff.

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
update`) is only legitimate for an intentional, reviewed public-ABI change —
per `.planning/PROJECT.md`, that means a major-version / partner-coordination
event. An unexplained baseline diff in a PR is a **gate failure**, not
something to fix by re-running `update`.

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
regressions.

### Metric definitions

The three production-code buckets do not overlap:

- **Core SDK:** Swift in `mParticle-Apple-SDK-Swift/Sources`, and Objective-C
  or Objective-C++ in `mParticle-Apple-SDK`, excluding each tree's kit
  infrastructure and excluding `mParticle-Apple-SDK/Libraries`.
- **SDK kit infrastructure:** sources in `mParticle-Apple-SDK/Kits` and the
  future `mParticle-Apple-SDK-Swift/Sources/Kits` subtree.
- **Standalone kits:** Swift, Objective-C, and Objective-C++ only below
  `Kits/**/Sources`.

Current language composition is production SLOC reported by `cloc`, so blank
and comment lines do not count. Objective-C++ (`.mm`) is grouped with
Objective-C remaining. Tests, examples, headers, build outputs, vendored
libraries, and the customer-facing `MParticle/Sources` Swift overlay are
excluded.

The pull request movement table is a different metric: physical Swift lines
added and Objective-C/Objective-C++ lines deleted according to
`git diff base...head --numstat -z`. The three-dot comparison measures changes
from the merge base through the pull request head, so commits present only on
an advanced base branch are not attributed to the pull request. These figures
can differ from the SLOC change because Git includes comments and blank lines.

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
- `Tools/swift-migration-progress.sh`; and
- this README section.

There is no stored baseline or external service to clean up.
