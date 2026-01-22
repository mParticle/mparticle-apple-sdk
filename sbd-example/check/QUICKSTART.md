# Quick Start

## Build Check

```bash
cd check
swift build
```

## Run Tests

```bash
swift test
```

## Usage in Xcode Project

### 1. Add Package

1. Open Xcode project
2. File → Add Packages...
3. Select "Add Local..."
4. Specify path to `check` folder
5. Press "Add Package"

### 2. Add Dependency to Target

1. Select your target in project
2. Go to "General" tab
3. In "Frameworks, Libraries, and Embedded Content" section
4. Press "+" and select `MyModules` → `A`

### 3. Use in Code

#### Swift

```swift
import A

let thing = AThing()
thing.demo()
```

#### Objective-C

```objc
@import A;

AThing *thing = [[AThing alloc] init];
[thing demo];
```

## File Structure

```
check/
├── Package.swift              # SPM package configuration
├── README.md                  # Main documentation
├── ARCHITECTURE.md            # Architecture description
├── QUICKSTART.md              # This file
├── Sources/
│   ├── A/                     # Objective-C module
│   │   ├── include/
│   │   │   └── AThing.h       # Public header
│   │   └── AThing.m           # Implementation
│   ├── B/                     # Pure Swift module
│   │   └── PricingEngine.swift
│   └── BObjC/                 # Swift bridge for ObjC
│       └── BPricingEngineObjC.swift
└── Tests/
    └── MyModulesTests/
        └── MyModulesTests.swift
```

## What Happens During Build

1. Module **B** compiles (Swift)
2. Module **BObjC** compiles (Swift with @objc)
   - `BObjC-Swift.h` is generated automatically
3. Module **A** compiles (Objective-C)
   - Imports `BObjC` via `@import BObjC;`
4. All modules are linked together

## Troubleshooting

### Error: "No such module 'BObjC'"

Make sure that:

- Module BObjC is correctly specified in dependencies of module A
- All files are in correct folders
- Run `swift package clean` and `swift build` again

### Error: "Cannot find 'BPricingEngineObjC' in scope"

Make sure that:

- Class is marked as `@objcMembers` or `@objc`
- Class inherits from `NSObject`
- Methods are marked as `@objc` (if not using `@objcMembers`)

### Objective-C Compilation Error

Make sure that:

- Using `@import BObjC;` instead of `#import`
- Public headers are in `include/` folder
- `publicHeadersPath: "include"` is specified in Package.swift
