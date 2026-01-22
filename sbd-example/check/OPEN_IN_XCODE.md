# How to Open Project in Xcode

## Method 1: Open Package.swift Directly

1. In Finder find `Package.swift` file in `check` folder
2. Double click or right click → "Open With" → Xcode
3. Xcode should automatically create project and show all files

## Method 2: Open via Xcode

1. Launch Xcode
2. File → Open...
3. Select `check` folder (not Package.swift file, but the folder)
4. Xcode will automatically find Package.swift and open project

## Method 3: Via Command Line

```bash
cd check
open Package.swift
```

or

```bash
cd check
xed .
```

## If Project is Empty

If after opening Package.swift project is empty, try:

1. **Clear Xcode Cache:**

   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/*
   ```

2. **Rebuild Project:**

   ```bash
   cd check
   swift package clean
   swift package resolve
   ```

3. **Open Again:**

   ```bash
   open Package.swift
   ```

4. **Check File Structure:**
   Make sure files are in correct places:
   - `Sources/B/PricingEngine.swift`
   - `Sources/BObjC/BPricingEngineObjC.swift`
   - `Sources/A/AThing.h`
   - `Sources/A/AThing.m`

## Verification in Xcode

After opening project you should see in navigator:

```
MyModules
├── Sources
│   ├── A
│   │   ├── A.h
│   │   ├── AThing.h
│   │   └── AThing.m
│   ├── B
│   │   └── PricingEngine.swift
│   └── BObjC
│       └── BPricingEngineObjC.swift
└── Tests
    └── MyModulesTests
        └── MyModulesTests.swift
```

If structure is not displayed, try:

- File → Packages → Reset Package Caches
- Product → Clean Build Folder (Cmd+Shift+K)
