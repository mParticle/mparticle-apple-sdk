# Integration Tests

Integration tests for mParticle Apple SDK with WireMock.

## Overview

This project uses Tuist for project generation and links directly to a locally-built xcframework of the mParticle SDK. This approach allows testing the SDK from source code without CocoaPods/SPM compatibility issues.

## How It Works

1. **Project Generation**: `Project.swift` defines a simple iOS app that depends on a local xcframework
2. **Build Script**: `run_clean_integration_tests.sh` orchestrates the entire process:
   - Builds mParticle SDK xcframework from source
   - Places it in `temp_artifacts/` directory
   - Regenerates Xcode project via Tuist
   - Builds and runs the integration test app

## Running Tests

Simply run the script:

```bash
./run_clean_integration_tests.sh
```

The script will:
- Build the SDK xcframework from source (iOS + Simulator)
- Generate the Xcode project
- Clean simulators
- Build the test app
- Install and launch it on the simulator

## Project Structure

- `Project.swift` - Tuist project definition
- `Sources/main.swift` - Test application code
- `run_clean_integration_tests.sh` - Main test execution script
- `temp_artifacts/` - Temporary directory for built xcframework (gitignored)

## Benefits of This Approach

- ✅ Uses SDK source code directly (not pre-built binaries)
- ✅ No CocoaPods/SPM compatibility issues with Xcode 16
- ✅ Fast iteration during development
- ✅ Clean separation between project definition and dependencies
- ✅ Suitable for CI/CD pipelines

## CI/CD Integration

In CI, this approach mimics the release process where binaries are built first, then used by dependent projects. The script ensures a clean build from source every time.

