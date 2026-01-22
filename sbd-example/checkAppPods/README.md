# CheckAppPods

Example iOS app using module A via CocoaPods.

## Structure

- `Project.swift` - Tuist project configuration
- `Podfile` - CocoaPods dependencies
- `Sources/` - Application source code

## Installation and Running

### 1. Generate Project via Tuist

```bash
cd checkAppPods
tuist generate
```

### 2. Install CocoaPods Dependencies

```bash
pod install
```

### 3. Open Project

Open `CheckAppPods.xcworkspace` (not .xcodeproj!)

```bash
open CheckAppPods.xcworkspace
```

### 4. Run

Select the `CheckAppPods` scheme and run on simulator or device.

## Dependencies

All modules are connected as local pods from the `../check` folder:

- `MyModules-B` - Base Swift module
- `MyModules-BObjC` - Swift bridge module (depends on B)
- `MyModules-A` - Objective-C module (depends on BObjC)

**Important:** All three modules must be explicitly specified in Podfile so CocoaPods can resolve dependencies between them.

## What It Demonstrates

The app shows how to use Objective-C module A from Swift code via CocoaPods.
