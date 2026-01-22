# CheckAppSMP

Example iOS app using module A via Swift Package Manager (SPM).

## Structure

- `Project.swift` - Tuist project configuration with SPM dependency
- `Sources/` - Application source code

## Installation and Running

### 1. Generate Project via Tuist

```bash
cd checkAppSMP
tuist generate
```

### 2. Open Project

Open the generated Xcode project:

```bash
open CheckAppSMP.xcodeproj
```

### 3. Run

Select the `CheckAppSMP` scheme and run on simulator or device.

## Dependencies

- `A` - Local SPM package from `../check` folder

Dependency is configured in `Project.swift` via:

```swift
packages: [
    .package(path: "../check")
],
dependencies: [
    .package(product: "A", type: .runtime)
]
```

## What It Demonstrates

The app shows how to use Objective-C module A from Swift code via Swift Package Manager.

## Differences from checkAppPods

- **checkAppPods** - uses CocoaPods for dependency management
- **checkAppSMP** - uses Swift Package Manager (SPM) for dependency management

Both approaches allow using the same module A, but through different dependency management systems.
