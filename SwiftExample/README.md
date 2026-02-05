# mParticle Swift Example App

A SwiftUI-based example app demonstrating the mParticle Apple SDK using Swift Package Manager (SPM) for dependency management.

## Features

This example app demonstrates:

- **SDK Initialization** - Configure and start the mParticle SDK with identity request
- **Events** - Log simple events, custom events, screen views, commerce events, timed events, errors, and exceptions
- **User Attributes** - Set and increment user attributes
- **Session Attributes** - Set and increment session attributes
- **Identity** - Login, logout, and modify identity (IDFA)
- **Consent** - Toggle CCPA and GDPR consent states
- **Push Notifications** - Register for remote notifications
- **Audiences** - Get user audiences
- **ATT** - Request App Tracking Transparency authorization
- **Rokt Integration** - Display overlay and embedded Rokt placements

## Requirements

- iOS 14.0+
- Xcode 15.0+
- Swift 5.0+

## Setup

1. Open `mParticleSwiftExample.xcodeproj` in Xcode
2. The project uses a local SPM reference to the mParticle SDK (`../..`) (_Note_ currently this does not use the local version of the SDK. Source Based Distribution is required for this)
3. Replace `REPLACE_WITH_APP_KEY` and `REPLACE_WITH_APP_SECRET` in `mParticleSwiftExampleApp.swift` with your mParticle credentials
4. Build and run on a simulator or device

## SPM Dependency

This project uses Swift Package Manager with a **local package reference** to the mParticle SDK in the parent repository. This allows testing local SDK changes immediately.

To use the published SDK instead, you can modify the package reference in Xcode:

1. Select the project in the navigator
2. Go to "Package Dependencies"
3. Remove the local reference
4. Add a new package with URL: `https://github.com/mParticle/mparticle-apple-sdk`

## Alternate Setup (Framework)

If you prefer to use the pre-built XCFramework instead of SPM, follow these steps:

### 1. Build the XCFramework

From the repository root, run:

```bash
# Make the build scripts executable
chmod +x ./Scripts/make_artifacts.sh
chmod +x ./Scripts/carthage.sh
chmod +x ./Scripts/xcframework.sh

# Build the frameworks
./Scripts/make_artifacts.sh
```

This will generate:

- `mParticle_Apple_SDK.xcframework.zip`
- `mParticle_Apple_SDK_NoLocation.xcframework.zip`

### 2. Extract the XCFramework

```bash
unzip mParticle_Apple_SDK.xcframework.zip -d ./Frameworks
```

### 3. Configure the Xcode Project

1. **Remove SPM dependency:**
   - Select the project in Xcode
   - Go to "Package Dependencies" tab
   - Remove the mParticle-Apple-SDK package

2. **Add the XCFramework:**
   - Drag `Frameworks/mParticle_Apple_SDK.xcframework` into your project
   - In the dialog, ensure "Copy items if needed" is checked
   - Select "Embed & Sign" for the framework in Target > General > Frameworks, Libraries, and Embedded Content

3. **Update Build Settings (if needed):**
   - Set **Framework Search Paths** to include `$(PROJECT_DIR)/Frameworks`
   - Ensure **Enable Modules** is set to `YES`

### 4. Update Import Statement

The import statement remains the same:

```swift
import mParticle_Apple_SDK
```

### Using NoLocation Variant

If your app doesn't require location services, use `mParticle_Apple_SDK_NoLocation.xcframework` instead. This variant excludes CoreLocation dependencies.

## Project Structure

```text
SwiftExample/
├── README.md
├── mParticleSwiftExample/
│   ├── mParticleSwiftExampleApp.swift  # App entry point & SDK initialization
│   ├── ContentView.swift               # Main UI with all SDK actions
│   ├── Info.plist
│   ├── mParticleSwiftExample.entitlements
│   └── Assets.xcassets/
└── mParticleSwiftExample.xcodeproj/
```

## Comparison to ObjC Example

This Swift example mirrors the functionality of the Objective-C example in `../Example/`, but uses:

- **SwiftUI** instead of UIKit/Storyboards
- **SPM** instead of CocoaPods for dependency management
- **Pure Swift** instead of Objective-C

## Notes

- The Rokt features require additional setup and will not function without proper Rokt credentials
- ATT (App Tracking Transparency) prompts only appear on physical devices, not simulators
- Push notifications require proper entitlements and certificates for full functionality
