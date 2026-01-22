# How to Run ClientAppExample

## Method 1: Via Command Line (Swift Package Manager)

```bash
cd check
swift run ClientAppExample
```

## Method 2: Via Xcode

1. Open project in Xcode:

   ```bash
   cd check
   xed .
   ```

2. In Xcode:
   - Select `ClientAppExample` scheme in top bar
   - Press Run (⌘R) or select Product → Run

## Method 3: Build and Run Manually

```bash
cd check
swift build
.build/debug/ClientAppExample
```

## Expected Output

On successful run you should see:

```
=== ClientAppExample ===
Demonstration of using module A

Created AThing object
Calling method demo():

Price = 40
Formatted: Price: 40

=== Done ===
```

## What Happens When Running

1. **ClientAppExample** (Swift) imports module **A**
2. Object `AThing` is created from module **A** (Objective-C)
3. Method `demo()` is called, which:
   - Uses `BPricingEngineObjC` from module **BObjC** (Swift bridge)
   - Which in turn uses `PricingEngine` from module **B** (pure Swift)
4. Result is printed to console

## Troubleshooting

### Error: "No such module 'A'"

Make sure that:

- You are in `check` folder
- Run `swift package resolve`
- Rebuild project: `swift build`

### Compilation Error

Try:

```bash
swift package clean
swift package resolve
swift build
```

### Error When Running in Xcode

1. Select correct scheme: `ClientAppExample`
2. Select correct platform: macOS or iOS Simulator
3. Clean Build Folder: Product → Clean Build Folder (⌘⇧K)
