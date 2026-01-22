# Publishing MyModules to CocoaPods

## Preparation

### 1. Registration in CocoaPods Trunk

If you are not yet registered:

```bash
pod trunk register your.email@example.com 'Your Name'
```

Check registration:

```bash
pod trunk me
```

### 2. Git Repository Preparation

Make sure that:

- All changes are committed
- Version tag is created:
  ```bash
  git tag 1.0.0
  git push origin 1.0.0
  ```

### 3. Update Versions in podspec Files

Make sure versions in all three podspec files match:

- `MyModules-B.podspec`
- `MyModules-BObjC.podspec`
- `MyModules-A.podspec`

## Publishing

### Automatic Publishing (Recommended)

Use the `publish_pods.sh` script:

```bash
cd check
./publish_pods.sh 1.0.0
```

The script:

1. Checks for all podspec files
2. Checks versions (will offer to update if they don't match)
3. Checks CocoaPods registration
4. Performs lint check on all podspec files
5. Asks for confirmation before publishing
6. Publishes modules in correct order (B → BObjC → A)

### Dry-run Mode (Test Check)

For checking without publishing use `--dry-run`:

```bash
./publish_pods.sh 1.0.0 --dry-run
```

This will perform all checks but won't publish pods. Useful for testing before real publishing.

### Manual Publishing

If you prefer to publish manually:

```bash
cd check

# 1. Check podspec files
pod spec lint MyModules-B.podspec
pod spec lint MyModules-BObjC.podspec
pod spec lint MyModules-A.podspec

# 2. Publish in correct order
pod trunk push MyModules-B.podspec
pod trunk push MyModules-BObjC.podspec
pod trunk push MyModules-A.podspec
```

## Publishing Order

**IMPORTANT:** Publish modules strictly in this order:

1. **MyModules-B** - Base module without dependencies
2. **MyModules-BObjC** - Depends on B
3. **MyModules-A** - Depends on BObjC

If you try to publish in a different order, CocoaPods won't be able to resolve dependencies.

## Verification After Publishing

After publishing check:

```bash
# Search for published pod
pod search MyModules-A

# Check pod information
pod trunk info MyModules-A
```

## Usage After Publishing

After successful publishing in Podfile it's enough to specify:

```ruby
platform :ios, '14.0'
use_frameworks!

target 'YourApp' do
  pod 'MyModules-A', '~> 1.0.0'
end
```

CocoaPods will automatically pull dependencies `MyModules-BObjC` and `MyModules-B`.

## Version Update

To publish a new version:

1. Update version in all three podspec files
2. Create new Git tag:
   ```bash
   git tag 1.0.1
   git push origin 1.0.1
   ```
3. Run publishing script:
   ```bash
   ./publish_pods.sh 1.0.1
   ```

## Troubleshooting

### Error: "You need to register a session first"

Register in CocoaPods:

```bash
pod trunk register your.email@example.com 'Your Name'
```

### Error: "Unable to find a specification"

Make sure that:

- Modules are published in correct order
- Versions match in all podspec files
- Git tag is created and pushed

### Lint Error: "The source did not match any file"

Make sure that:

- File paths in podspec are correct
- All files are committed to Git
- Git tag points to correct commit

### Error: "Dependency not found"

Make sure dependent modules are published first:

- First B, then BObjC, then A
