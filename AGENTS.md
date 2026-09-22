# mParticle Apple SDK - Agent Instructions

Loaded into every agent session, so it holds only what you cannot get by reading the repository.
Anything a config file already states is deliberately absent: read the config, which cannot go
stale, rather than this file, which can. For the rest see `README.md` (install and public API),
`CONTRIBUTING.md` (commit and PR conventions), `RELEASE.md`, `Kits/README.md`,
`IntegrationTests/README.md`, and the
[public SDK docs](https://docs.mparticle.com/developers/sdk/ios/).

## Working rules

Objective-C and Swift customer-data-platform SDK for iOS and tvOS. Treat it as a public framework,
not an app: keep the public API additive, deprecate rather than remove, never break the kit
interface, never block the main thread, never crash on bad input or a failed request, and prefer
additive changes to refactors unless a refactor was asked for. Do not raise the deployment-target
floor - it is pinned in `Package.swift` and all three podspecs. Do not edit `.github/`, `Scripts/`
or `.trunk/` unless the task is about them. Update `PrivacyInfo.xcprivacy` if data-collection
behaviour changes; the single root copy is what both SwiftPM and CocoaPods ship. Ask first before
adding a dependency, dropping an OS version, making a breaking API change, or touching the kit
interface.

## Names that collide

Several unrelated things here answer to "mParticle-Apple-SDK", and confusing them is the easiest
mistake to make.

- `mParticle-Apple-SDK/` (the directory) is the Objective-C core: SwiftPM target
  `mParticle_Apple_SDK_ObjC`, pod `mParticle-Apple-SDK-ObjC`.
- `MParticle/Sources/` is the small Swift umbrella that _is_ the consumer-facing SwiftPM product and
  the pod named `mParticle-Apple-SDK`.
- `mParticle-Apple-SDK-Swift/Sources/` is internal Swift components: pod
  `mParticle-Apple-SDK-Swift`. Release publishes it before the Objective-C core and Swift umbrella
  pods so their exact-version dependencies can resolve (see `RELEASE.md`).
- `mParticle-Apple-SDK.xcodeproj` is the Xcode framework build, and the one CI compiles in the
  build, analyze and unit-test jobs.

## Commands

- Lint and format: `trunk check`
- Build for iOS:
  `xcodebuild -project mParticle-Apple-SDK.xcodeproj -scheme mParticle-Apple-SDK -destination 'generic/platform=iOS' build`
- Before running tests, list destinations with
  `xcodebuild -project mParticle-Apple-SDK.xcodeproj -scheme mParticle-Apple-SDK -showdestinations`
  and set `SIMULATOR_UDID` to an available iOS or tvOS simulator ID. Builds can use a generic
  destination; tests need a runnable simulator instance, with no specific model required.
- Objective-C unit tests:
  `xcodebuild -project mParticle-Apple-SDK.xcodeproj -scheme mParticle-Apple-SDK -destination "id=$SIMULATOR_UDID" test`
- Swift unit tests: the same, with `-scheme mParticle-Apple-SDK-Swift`
- Podspec lint:
  `pod lib lint mParticle-Apple-SDK.podspec --include-podspecs="{mParticle-Apple-SDK-Swift.podspec,mParticle-Apple-SDK-ObjC.podspec,mParticle-Apple-SDK.podspec}"`
- Integration tests: see `IntegrationTests/README.md` - needs Tuist, Java and WireMock

### Command traps

1. **There are two test schemes, and each has exactly one testable.** `-scheme mParticle-Apple-SDK`
   runs only `mParticle-Apple-SDKTests`; the internal Swift suite in
   `mParticle-Apple-SDK-Swift/Test/` is reachable only through `-scheme mParticle-Apple-SDK-Swift`.
   Run one and you have tested half the SDK. CI runs
   both schemes against both iOS and tvOS (`.github/workflows/native-tests.yml`).
2. **The lint configs are not at the repo root.** `.swiftlint.yml` and `.swiftformat` live in
   `.trunk/configs/`, where a bare `swiftlint` or `swiftformat .` invoked from the root will not
   find them - those runs silently apply the tools' own defaults instead of this repo's rules. Use
   `trunk check`; there is no fallback that reproduces it.
3. **`pod lib lint` needs all three podspecs.** They depend on each other by exact version
   (`s.dependency 'mParticle-Apple-SDK-ObjC', s.version.to_s`), so the umbrella cannot resolve
   without `--include-podspecs`.
4. **`Scripts/check_coverage.sh` cannot fail.** `Scripts/check_coverage.py` appends to
   `failed_files` and then never exits non-zero, and the shell wrapper ends on `rm -rf venv`. No
   workflow invokes it. It prints per-file coverage and nothing more. It also only works with
   `Scripts/` as the working directory, since both the project path and the Python call inside it
   are relative.
5. **Xcode is pinned to two different versions, so "the CI Xcode" is ambiguous.** `build-and-lint`,
   `native-tests` and `size-report` pin one; `integration-tests`, `build-kits` and
   `verify-kit-xcframework-import` pin a newer one. Read `XCODE_VERSION` (or `xcode-version`) in the
   workflow you care about rather than assuming a single toolchain covers the repo.

## Conventions that no config enforces

- **Three consumers decide header publicness separately, and it takes two actions.** Moving a header
  into `mParticle-Apple-SDK/Include/` covers SwiftPM (`publicHeadersPath`) and CocoaPods (the
  podspec's `public_header_files` glob); the Xcode framework target keeps its own list, so the file
  also needs `ATTRIBUTES = (Public, )` there. Skip the second action and the header is public to
  SwiftPM and CocoaPods consumers but missing from the built framework.
- **SwiftLint never sees test code** - `.trunk/configs/.swiftlint.yml` excludes `UnitTests`.
- **Never hand-edit a version string.** The Release - Draft workflow rewrites `VERSION`,
  `Framework/Info.plist`, every core and kit podspec, `MPIConstants.m` and a handful of kit sources
  in one pass. Introducing a new place a version lives means teaching
  `.github/workflows/release-draft.yml` about it, or it goes stale silently.
- **Never hand-write `CHANGELOG.md`.** Release sections are generated from conventional-commit PR
  titles at release time (same workflow, `exclude-types: chore,ci,test,build`) and inserted below
  the `## [Unreleased]` heading, which is not itself consumed - so a hand-written entry there is
  never folded into a release. Your PR title is the changelog entry.
- Objective-C follows Apple's Cocoa coding guidelines. Swift prefers `let` and value types and
  avoids force-unwraps. Public API needs HeaderDoc (Objective-C) or `///` (Swift). Add a comment
  only where the code cannot be made clear instead.
- **Swift conversions can increase binary size even as Objective-C shrinks.** The historical
  comparison of `13f53dcf` with `656d3349`, measured 2026-09-21, removed 11,151 lines of ObjC and
  saved 411 KB in the Objective-C image, while 16,263 added Swift lines cost 1,409 KB in the Swift
  image. Source volume grew 18 %, and shipped size grew 54 %. These are historical snapshots,
  not measurements of current `main`. `Tests/SizeReport/README.md` records the breakdown and
  1,840 KB recovery target; run `Tests/SizeReport/analyze_binary.sh` for fresh attribution.
  Four rules follow:
  - **Delete eligible internal ObjC leaf wrappers in the same PR as their Swift replacement** once
    callers have migrated. Keep the public, kit, runtime-identity, and module boundaries required
    by `docs/swift-migration/CONVERSION-RECIPE.md`, moving their logic into Swift where possible.
    Base classes may need a staged conversion because ObjC cannot subclass Swift; explain any
    remaining wrapper and its compatibility or dependency constraint in the PR.
  - **`@objc` per member, never `@objcMembers` per type, and delete the annotation with its last ObjC
    caller when no compatibility or runtime requirement remains.** In the measured snapshot,
    1,489 Swift annotations generated 226 KB of Objective-C metadata, alongside 233 KB from the
    Objective-C image itself.
  - **`internal` and `final` by default.** In the measured snapshot, 236 of 306 Swift types were
    `public` or `open`, mostly for access from the ObjC module. The Swift image exported 4,730
    symbols, up from 720 at `13f53dcf`; symbol tables accounted for 19 % of the size increase.
    Cross-module access can require `public`, but it is a size decision as well as an API decision.
  - **Don't introduce `Codable`, generic helpers, `Mirror`, or Swift Concurrency into the core without
    measuring.** The measured snapshot used none of them and had only 55 KB of Swift metadata.
    Adding runtime reflection can also constrain future reflection-metadata build settings.
- **Test code can reach the shipped framework through the synchronized group.** The
  `mParticle-Apple-SDK-Swift` target draws its files from a `PBXFileSystemSynchronizedRootGroup` over
  the whole `mParticle-Apple-SDK-Swift/` directory, which holds `Sources/` _and_ `Test/`. Test code is
  excluded by hand-enumerated `membershipExceptions`, historically only `*Tests.swift`/`*Tests.m`, so
  a mock under `Test/Mocks/` shipped to customers until it was noticed in a symbol dump. Any new file
  under `Test/` that is not named `*Tests.*` must be added to both exception sets. SwiftPM and
  CocoaPods scope to `Sources/**` and are unaffected, so this is invisible outside the Xcode build.

## Kits

`Kits/<vendor>/<vendor>-<major>/` is a self-contained package: its own `Package.swift`, podspec,
`.xcodeproj`, `CHANGELOG.md` and example apps. `Kits/matrix.json` is the registry, mapping each kit
to its `local_path`, `podspec`, build `schemes` and the `dest_repo` it is mirrored out to on
release. **A kit missing from `matrix.json` is not built, not pod-linted and not released** -
nothing else discovers it.

## Pull requests

- Base ongoing Swift migration work off `main` and target conversion PRs there. The integration
  branch has merged; the migration continues on `main`. `workstation/*` branches still support
  maintenance releases and other integration work; use one only when that is the task's target.
- Branch name _and_ PR title are both checked against the semantic-commit convention by
  `.github/workflows/reusable-workflows.yml`; the allowed types are listed in `CONTRIBUTING.md`.
- **CI is not the merge gate.** The ruleset covering `main` and `workstation/*` requires no status
  checks at all - re-check that before treating a green run as a gate. What it does require: one
  CODEOWNERS approval (`* @mParticle/sdk-team`), every review thread resolved, and an extra approval
  for commits not attributed to a GitHub account, so commit with an email tied to your account. Any
  push dismisses existing approvals, and only squash and merge commits are allowed, never rebase.
- **A fork PR cannot go green, whatever it changes.** `size-report` finishes by writing a PR
  comment, and a `pull_request` event from a fork gets a read-only token whatever the workflow's
  `permissions:` block asks for. Judge a fork PR on the jobs that _can_ run, and on the merge state
  rather than the check list.
- **Place a red or `cancelled` check before debugging it.** `build-kits / Pod Lint <kit>` resolves
  third-party pods through the CocoaPods CDN, so those jobs fail as a batch, retries exhausted, when
  that CDN errors. A `cancelled` job is normally a `timeout-minutes` expiry in `native-tests` or a
  superseded push, since `pull-request.yml` sets `concurrency: cancel-in-progress` keyed on the PR -
  neither is a test result. Compare the same job on `main` before reading a red one as yours.

## Gotchas

1. **The analyzer job fails on any new clang warning.** `run-analyzer` filters four known warning
   strings out of the `xcodebuild analyze` log and fails if any `: warning:` line survives
   (`.github/workflows/build-and-lint.yml`). A warning you would normally ignore breaks the build.
2. **The custom `mparticle-api-key-check` trunk linter over-matches.** Its pattern
   `[a-z]{2}[0-9]*-[0-9a-f]{32}` runs against every file and also matches `md5-…` and `sha256-…`
   digests, so a lockfile integrity hash or a hex test fixture fails `trunk check` as a suspected
   API key.
3. **A clean `size-report` is not proof of no size change.** The base-branch measurement is
   `continue-on-error`, and a base build that fails is reported as `N/A (new baseline)` rather than
   failing the job.
4. **The root `Package.swift` is compiled by exactly one PR job.** `integration-tests` pulls it in
   through Tuist (`.package(path: "../")`); nothing else builds the SwiftPM graph, so an SPM-only
   break survives every other check.
5. Integration tests fail on an unmatched request but only _warn_ on a recorded WireMock mapping
   the app never calls (`IntegrationTests/run_integration_tests_ci.sh`).
6. **Check workflow settings and callers as well as the tree.** `cross-platform-tests.yml` is in
   the tree but disabled in repository settings, and GitHub may list workflows whose files are
   absent from the checkout. The PR workflow calls `build-secondary-platforms`, which builds
   `RNExample`; the disabled cross-platform workflow does not imply those builds are disabled.
7. `ARCHITECTURE.md` is two diagram images and no prose. There is no written architecture document.
