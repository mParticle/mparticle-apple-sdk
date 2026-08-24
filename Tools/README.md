# Tools/

Migration tooling for the Objective-C -> Swift conversion. Additive only:
nothing here modifies `.github/`, `Scripts/`, or the CI YAML.

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
