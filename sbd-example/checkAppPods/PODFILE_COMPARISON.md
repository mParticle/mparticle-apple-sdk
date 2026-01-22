# Podfile Comparison: Local Development vs Published Pods

## Local Development (`:path`)

When using local pods via `:path`, **you need to specify all dependencies explicitly**:

```ruby
target 'CheckAppPods' do
  # All three modules must be specified explicitly
  pod 'MyModules-B', :path => '../check'
  pod 'MyModules-BObjC', :path => '../check'
  pod 'MyModules-A', :path => '../check'
end
```

**Why?** CocoaPods cannot automatically resolve local dependencies from podspec files when using `:path`.

## Published Pods (CocoaPods Trunk or Git)

When modules are published to CocoaPods repository, **it's enough to specify only MyModules-A**:

```ruby
target 'CheckAppPods' do
  # Only MyModules-A - dependencies will resolve automatically
  pod 'MyModules-A', '~> 1.0.0'
end
```

**Why does this work?** CocoaPods reads podspec files from repository and automatically resolves dependencies:

- `MyModules-A` → depends on `MyModules-BObjC` (from podspec)
- `MyModules-BObjC` → depends on `MyModules-B` (from podspec)
- CocoaPods automatically pulls all dependencies

## Comparison Table

| Aspect                      | Local Development (`:path`) | Published Pods           |
| --------------------------- | --------------------------- | ------------------------ |
| **Specifying Dependencies** | All modules explicitly      | Only MyModules-A         |
| **Dependency Resolution**   | Manual (in Podfile)         | Automatic (from podspec) |
| **Podfile**                 | 3 pod lines                 | 1 pod line               |
| **Usage**                   | Development                 | Production               |

## Examples

### Current Podfile (Local Development)

See `Podfile` - used for local development.

### Podfile for Published Pods

See `Podfile.published` - example for use after publishing to CocoaPods.

## Migration

When ready to publish pods:

1. Publish all three modules to CocoaPods (in correct order: B → BObjC → A)
2. Replace `Podfile` with contents from `Podfile.published`
3. Run `pod install`

After that Podfile will have only one line with `MyModules-A`!
