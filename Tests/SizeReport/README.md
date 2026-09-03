# SDK Size Report

## Overview

Measures the mParticle SDK's impact on app size by comparing a baseline app (no SDK) against one with the SDK integrated.

![SDK Size Monitoring Diagram](diagram-mparticle-ios-sdk-size-monitoring.jpg)

## How It Works

1. `measure_size.sh` builds the SDK **from source** into an xcframework
2. Builds two test apps: baseline and with-SDK
3. Reports the size delta
4. `analyze_binary.sh` attributes those bytes to segments, sections and modules

## Usage

```bash
./measure_size.sh          # Human-readable output
./measure_size.sh --json   # JSON output for CI

# Attribute the bytes in a built framework
./analyze_binary.sh build/mParticle_Apple_SDK.xcframework/ios-arm64/mParticle_Apple_SDK.framework
./analyze_binary.sh <framework> --json     # aggregates only, for CI
./analyze_binary.sh <framework> --top 50   # 50 largest symbols per image
```

## Reading the numbers

**`App Bundle Impact` is the number that matters.** The SDK ships as a dynamic framework
that the app embeds, so the app's own executable grows by under a kilobyte
(`Executable Impact`) while the framework is carried whole. Nothing in the SDK is
dead-stripped at app link time, which is why this metric tracks compiled code almost 1:1.

**Ignore the XCFramework total.** `xcodebuild -create-xcframework` folds the dSYM in
beside the framework, and Release builds with `dwarf-with-dsym`, so roughly 60% of that
number is debug symbols that never reach a device. `framework_size_kb` is the shipped
part; `dsym_size_kb` is not.

**Consumers who take the SDK as source pay less.** SwiftPM and CocoaPods compile from
source and link statically into the app, where dead-stripping does apply. This harness
measures the binary-xcframework path, which is the worst case.

## Size budget

The migration from Objective-C to Swift raised the SDK's app-bundle impact from
**1,852 KB on `main` to 2,496 KB on `workstation/swift-migration`** (+652 KB, +35%).

Target: **app-bundle impact must not exceed `main`'s 1,852 KB once the migration is
complete.** Until then, treat every increase as debt that has to be paid down before the
migration branch merges.

`size-report.yml` fails when a PR adds more than `SIZE_DELTA_THRESHOLD_KB` (50 KB) to the
app-bundle impact. Two things to know about that gate:

- The target-branch measurement is `continue-on-error`. When it fails the delta is `N/A`,
  which means "could not verify", not "passed" - the job warns instead of passing quietly.
- The ruleset covering `main` and `workstation/*` requires no status checks, so this gate
  only blocks a merge once someone marks the check required.

## What drives the size

Attribution of the +652 KB regression, from `analyze_binary.sh`:

| Component             | Share | What moves it                                                           |
| --------------------- | ----- | ----------------------------------------------------------------------- |
| `__text` (code)       | 57%   | Amount of compiled code; `SWIFT_OPTIMIZATION_LEVEL`                     |
| `__LINKEDIT`          | 22%   | Number of exported symbols - Swift `public` symbols are `no_dead_strip` |
| `__objc_*` metadata   | 14%   | Every `@objc` declaration, including those on Swift types               |
| `__swift5_*` metadata | 3%    | Type metadata and reflection                                            |

The framework ships as **two** Mach-O images: `mParticle_Apple_SDK.framework` and, nested
inside it, `mParticle_Apple_SDK_Swift.framework`. The second one exists because SwiftPM
cannot mix Objective-C and Swift in one target; it costs a second set of symbol tables and
prevents dead-stripping across the boundary. It collapses on its own once the migration
removes the last `.m` file.

## CI Integration

The `.github/workflows/size-report.yml` workflow runs on PRs to report size changes.
