# Module Architecture

## Dependency Diagram

```
┌─────────────────┐
│   Client App    │
│  (Swift/ObjC)   │
└────────┬────────┘
         │
         │ import A / @import A
         │
         ▼
┌─────────────────┐
│   Module A      │
│  (Objective-C)  │
└────────┬────────┘
         │
         │ @import BObjC
         │
         ▼
┌─────────────────┐
│   Module BObjC  │
│  (Swift Bridge) │
│  @objc + NSObject│
└────────┬────────┘
         │
         │ import B
         │
         ▼
┌─────────────────┐
│   Module B      │
│  (Pure Swift)   │
│  struct, generics│
└─────────────────┘
```

## Data Flow

1. **Client App** calls API of module **A**
2. **A** (ObjC) calls methods from **BObjC** via `@import BObjC`
3. **BObjC** (Swift bridge) calls pure Swift code from **B**
4. Result is returned back through the chain

## Key Principles

### Module Isolation

- **B** doesn't know about existence of **A** or **BObjC**
- **BObjC** doesn't know about existence of **A**
- **A** doesn't know about existence of **B** (knows only about **BObjC**)

### ObjC Compatibility

Module **BObjC** provides ObjC compatibility through:

- `@objcMembers` - all public methods are accessible from ObjC
- `NSObject` - base class for ObjC compatibility
- ObjC-compatible types:
  - `NSNumber` instead of `Int`
  - `NSString` instead of `String`
  - `NSArray` instead of `Array` (if needed)

### Header Generation

SPM automatically generates Objective-C headers:

- `BObjC-Swift.h` - for module BObjC
- Available via `@import BObjC;` in Objective-C code
- Don't need to import directly

## Usage Examples

### From Swift Client App

```swift
import A

let thing = AThing()
thing.demo()  // Inside uses BObjC → B
```

### From Objective-C Client App

```objc
@import A;

AThing *thing = [[AThing alloc] init];
[thing demo];  // Inside uses BObjC → B
```

### Direct Usage of BObjC from Swift

```swift
import BObjC

let engine = BPricingEngineObjC()
let price = engine.price(forUserId: "test")
```

### Direct Usage of B from Swift

```swift
import B

let engine = PricingEngine()
let price = engine.price(for: "test")
```

## Advantages of This Architecture

1. **Pure Swift code** in module B - can use all Swift features
2. **Isolation** - ObjC code doesn't depend directly on Swift-only API
3. **Flexibility** - can use B directly from Swift, or through BObjC from ObjC
4. **Testability** - each module can be tested independently
5. **Migration** - can gradually migrate from ObjC to Swift
