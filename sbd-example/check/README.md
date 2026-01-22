# SPM Package Example: Swift → ObjC Bridge

This example demonstrates an architecture with three modules:

- **B** - Pure Swift module (struct, generics, Swift-only features)
- **BObjC** - Swift bridge, exporting ObjC-compatible API
- **A** - Objective-C module using BObjC

## Structure

```
check/
├── Package.swift
└── Sources/
    ├── B/                    # Swift core
    │   └── PricingEngine.swift
    ├── BObjC/               # Swift bridge for ObjC
    │   └── BPricingEngineObjC.swift
    └── A/                    # Objective-C module
        ├── include/          # Public headers
        │   ├── A.h          # Umbrella header
        │   └── AThing.h
        └── AThing.m         # Implementation
```

## Dependencies

```
A → BObjC → B
```

- Module A (ObjC) depends only on BObjC
- Module BObjC (Swift bridge) depends on B
- Module B (Swift) has no dependencies

## Usage in Client App

### Option 1: Swift Client App

```swift
import A

let thing = AThing()
thing.demo()
```

### Option 2: Objective-C Client App

```objc
@import A;

AThing *thing = [[AThing alloc] init];
[thing demo];
```

## Key Points

1. **B** - Pure Swift, not directly visible from ObjC
2. **BObjC** - Uses `@objcMembers` and `NSObject` for ObjC compatibility
3. **A** - Imports only `BObjC`, doesn't know about `B`
4. SPM automatically generates Objective-C header for `BObjC`

## Testing

```bash
cd check
swift build
swift test  # if there are tests
```

## Integration into Xcode Project

### Step 1: Add Package to Xcode Project

1. Open your Xcode project
2. File → Add Packages...
3. Add local path: `/path/to/check` or Git URL
4. Select needed products (A, B, BObjC) depending on what's needed

### Step 2: Usage in Swift Client App

In your Swift file:

```swift
import A

class MyViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let thing = AThing()
        thing.demo()
    }
}
```

### Step 3: Usage in Objective-C Client App

In your `.m` file:

```objc
@import A;

@implementation MyViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    AThing *thing = [[AThing alloc] init];
    [thing demo];
}

@end
```

In your `.h` file (if needed):

```objc
@import A;
```

## How It Works Under the Hood

1. **Module B** compiles as a pure Swift module
2. **Module BObjC** compiles as a Swift module, but with `@objc` annotations
   - SPM automatically generates `BObjC-Swift.h` header
   - This header is available through `@import BObjC;` in Objective-C
3. **Module A** compiles as an Objective-C module
   - Imports `BObjC` through `@import BObjC;`
   - Doesn't know about the existence of module `B`
4. **Client App** connects only needed products
   - Dependencies are pulled automatically
   - If connecting `A`, `BObjC` and `B` will be automatically pulled

## Important Notes

- **Don't use `#import "BObjC-Swift.h"` directly** - use `@import BObjC;`
- **Module B is not visible from Objective-C** - only through BObjC
- **All public APIs in BObjC must be `@objc`** - otherwise they won't be visible from ObjC
- **Return ObjC-compatible types** - `NSNumber` instead of `Int`, `NSString` instead of `String`, etc.
