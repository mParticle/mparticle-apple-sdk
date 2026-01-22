# Using CocoaPods podspec

## Podspec File Structure

Three podspec files are created for each module:

- `MyModules-A.podspec` - Objective-C module (depends on BObjC)
- `MyModules-BObjC.podspec` - Swift bridge (depends on B)
- `MyModules-B.podspec` - Pure Swift module

## Installation via CocoaPods

### Option 1: Local Installation (for development)

**⚠️ IMPORTANT:** When developing locally with `:path` you need to specify all dependencies explicitly!

Create `Podfile` in your project:

```ruby
platform :ios, '14.0'

target 'YourApp' do
  use_frameworks!

  # For local development you need to specify all modules explicitly
  pod 'MyModules-B', :path => '../check'
  pod 'MyModules-BObjC', :path => '../check'
  pod 'MyModules-A', :path => '../check'
end
```

Then run:

```bash
pod install
```

**Why do you need to specify all modules?**
CocoaPods cannot automatically resolve local dependencies from podspec files when using `:path`. Therefore all dependencies must be specified explicitly in Podfile.

### Option 2: From Git Repository

```ruby
platform :ios, '14.0'

target 'YourApp' do
  use_frameworks!

  # It's enough to specify only MyModules-A
  # CocoaPods will automatically pull dependencies (BObjC and B) from podspec files
  pod 'MyModules-A', :git => 'https://github.com/example/MyModules.git', :tag => '1.0.0'
end
```

### Option 2a: From Published CocoaPods Repository

```ruby
platform :ios, '14.0'

target 'YourApp' do
  use_frameworks!

  # If modules are published to CocoaPods, it's enough to specify only MyModules-A
  # CocoaPods will automatically resolve dependencies from podspec files
  pod 'MyModules-A', '~> 1.0.0'
end
```

**✅ Advantage:** No need to specify dependencies explicitly - CocoaPods will automatically pull `MyModules-BObjC` and `MyModules-B` from podspec files.

### Option 3: Using Individual Modules

If you need to use only specific modules:

```ruby
platform :ios, '14.0'

target 'YourApp' do
  use_frameworks!

  # Use only Swift module B
  pod 'MyModules-B', :path => '../check'

  # Or use Swift bridge BObjC
  pod 'MyModules-BObjC', :path => '../check'

  # Or use Objective-C module A (will automatically pull BObjC and B)
  pod 'MyModules-A', :path => '../check'
end
```

## Usage in Code

### Swift

```swift
import A

let thing = AThing()
thing.demo()
```

### Objective-C

```objc
@import A;

AThing *thing = [[AThing alloc] init];
[thing demo];
```

## Checking podspec

Check podspec file correctness:

```bash
pod spec lint MyModules-A.podspec
```

For local podspec (without checking remote repository):

```bash
pod spec lint MyModules-A.podspec --local
```

## Publishing to CocoaPods

1. Create tag in Git:

   ```bash
   git tag 1.0.0
   git push origin 1.0.0
   ```

2. Register pod (first time only):

   ```bash
   pod trunk register your.email@example.com 'Your Name'
   ```

3. Publish pod:
   ```bash
   pod trunk push MyModules-A.podspec
   pod trunk push MyModules-BObjC.podspec
   pod trunk push MyModules-B.podspec
   ```

## Important Notes

1. **Dependency Order**: When publishing, first publish `B`, then `BObjC`, then `A`

2. **Versions**: All three podspecs must have the same version for dependencies to work correctly

3. **Public Headers**: In module A public headers are in `Sources/A/include/` and specified in `public_header_files`

4. **Swift Versions**: Make sure Swift version is compatible with your project

## Troubleshooting

### Error: "Unable to find a specification"

Make sure that:

- Path to podspec is correct
- You ran `pod repo update`
- For local development use `:path =>`

### Swift Module Compilation Error

Make sure that:

- `use_frameworks!` is specified in Podfile
- Swift version is compatible (`swift_versions` in podspec)

### Header Error

Make sure that:

- `public_header_files` points to correct folder
- Headers are in specified folder
