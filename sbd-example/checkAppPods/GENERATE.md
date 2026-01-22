# Generating CheckAppPods Project

## Requirements

- Tuist installed: `brew install tuist` or follow [instructions](https://docs.tuist.io/getting-started/installation)
- CocoaPods installed: `sudo gem install cocoapods`

## Generation Steps

### 1. Generate Xcode Project via Tuist

```bash
cd checkAppPods
tuist generate
```

This command will create:

- `CheckAppPods.xcodeproj` - Xcode project
- `CheckAppPods.xcworkspace` - Workspace (will be created after pod install)

### 2. Install CocoaPods Dependencies

```bash
pod install
```

This command:

- Will install dependencies from Podfile
- Will create/update `CheckAppPods.xcworkspace`
- Will add Pods project to workspace

### 3. Open Project

**IMPORTANT:** Open `.xcworkspace`, not `.xcodeproj`!

```bash
open CheckAppPods.xcworkspace
```

Or via Xcode:

- File → Open...
- Select `CheckAppPods.xcworkspace`

### 4. Run

1. Select `CheckAppPods` scheme
2. Select simulator or device
3. Press Run (⌘R)

## Regenerating Project

If you changed `Project.swift` or `Podfile`:

```bash
tuist generate
pod install
```

## Troubleshooting

### Error: "No such module 'A'"

Make sure that:

1. You ran `pod install`
2. Opened `.xcworkspace`, not `.xcodeproj`
3. Path to module A in Podfile is correct (`../check`)

### Error During Tuist Generation

Check Tuist version:

```bash
tuist version
```

Should be version 4.x or higher.

### Error During pod install: "Unable to find a specification for MyModules-BObjC"

This error occurs when CocoaPods cannot find dependencies of module A.

**Solution:** Make sure all three modules are specified explicitly in Podfile:

```ruby
pod 'MyModules-B', :path => '../check'
pod 'MyModules-BObjC', :path => '../check'
pod 'MyModules-A', :path => '../check'
```

CocoaPods requires explicit specification of all local dependencies in Podfile, even if they are already specified in podspec files.

### Error During pod install (General)

Check that:

1. Podfile is in correct folder
2. Path `../check` exists and contains all three podspec files:
   - `MyModules-A.podspec`
   - `MyModules-BObjC.podspec`
   - `MyModules-B.podspec`
3. Run `pod repo update` if needed
4. Make sure all three modules are specified in Podfile (see above)
