# Generating CheckAppSMP Project

## Requirements

- Tuist installed: `brew install tuist` or follow [instructions](https://docs.tuist.io/getting-started/installation)

## Generation Steps

### 1. Generate Xcode Project via Tuist

```bash
cd checkAppSMP
tuist generate
```

This command will create:

- `CheckAppSMP.xcodeproj` - Xcode project
- SPM dependencies will be automatically resolved

### 2. Open Project

```bash
open CheckAppSMP.xcodeproj
```

Or via Xcode:

- File → Open...
- Select `CheckAppSMP.xcodeproj`

### 3. Run

1. Select `CheckAppSMP` scheme
2. Select simulator or device
3. Press Run (⌘R)

## Regenerating Project

If you changed `Project.swift`:

```bash
tuist generate
```

SPM dependencies will be automatically updated on next build.

## Troubleshooting

### Error: "No such module 'A'"

Make sure that:

1. Path to module A in `Project.swift` is correct (`../check`)
2. Folder `../check` exists and contains `Package.swift`
3. Run Clean Build Folder (⌘⇧K) and rebuild

### Error During Tuist Generation

Check Tuist version:

```bash
tuist version
```

Should be version 4.x or higher.

### SPM Dependency Resolution Error

In Xcode:

1. File → Packages → Reset Package Caches
2. File → Packages → Resolve Package Versions
3. Clean Build Folder (⌘⇧K)
4. Rebuild project

### Changes in Local Package Not Applied

If you changed code in `../check`:

1. In Xcode: File → Packages → Update to Latest Package Versions
2. Or Clean Build Folder and rebuild
