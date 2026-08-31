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
  `mParticle-Apple-SDK-Swift`, which release does not publish automatically (see `RELEASE.md`).
- `mParticle-Apple-SDK.xcodeproj` is the Xcode framework build, and the one CI compiles in the
  build, analyze and unit-test jobs.

## Commands

- Lint and format: `trunk check`
- Build for iOS:
  `xcodebuild -project mParticle-Apple-SDK.xcodeproj -scheme mParticle-Apple-SDK -destination 'generic/platform=iOS' build`
- Objective-C unit tests:
  `xcodebuild -project mParticle-Apple-SDK.xcodeproj -scheme mParticle-Apple-SDK -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test`
- Swift unit tests: the same, with `-scheme mParticle-Apple-SDK-Swift`
- Podspec lint:
  `pod lib lint mParticle-Apple-SDK.podspec --include-podspecs="{mParticle-Apple-SDK-Swift.podspec,mParticle-Apple-SDK-ObjC.podspec,mParticle-Apple-SDK.podspec}"`
- Integration tests: see `IntegrationTests/README.md` - needs Tuist, Java and WireMock

### Command traps

1. **There are two test schemes, and each has exactly one testable.** `-scheme mParticle-Apple-SDK`
   runs only `mParticle-Apple-SDKTests` (`UnitTests/ObjCTests`); the Swift suite is reachable only
   through `-scheme mParticle-Apple-SDK-Swift`. Run one and you have tested half the SDK. CI runs
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
6. **`CONTRIBUTING.md`'s test command does not work.** It names an `.xcworkspace` and an
   `mParticle-Apple-SDK-iOS` scheme, neither of which exists. Use the commands above.

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

## Kits

`Kits/<vendor>/<vendor>-<major>/` is a self-contained package: its own `Package.swift`, podspec,
`.xcodeproj`, `CHANGELOG.md` and example apps. `Kits/matrix.json` is the registry, mapping each kit
to its `local_path`, `podspec`, build `schemes` and the `dest_repo` it is mirrored out to on
release. **A kit missing from `matrix.json` is not built, not pod-linted and not released** -
nothing else discovers it.

## Pull requests

- Base off `main`. `workstation/*` are long-lived integration branches covered by the same ruleset,
  and stacks of migration PRs often target one of them instead - check what the work you are
  following up on is based on rather than assuming `main`.
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
6. **The workflow list and the tree disagree, in both directions.** `cross-platform-tests.yml` is in
   the tree but `disabled_manually` in repository settings, so it never runs; and
   `gh workflow list --all` reports a `release-ecosystem-from-main.yml` whose file is not on `main`
   at all, only on unmerged branches. Separately, `RNExample` is not built on PRs because
   `build-secondary-platforms` is commented out of `.github/workflows/pull-request.yml`. Neither the
   tree nor the workflow list is sufficient alone; check the caller too.
7. `ARCHITECTURE.md` is two diagram images and no prose. There is no written architecture document.
