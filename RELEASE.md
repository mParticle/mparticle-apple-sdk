# Release Process

This document outlines the process for creating a new release of the mParticle Apple SDK.

## Automated Release Process

We use GitHub Actions to automate our release process. Follow these steps to create a new release:

### Pre-release Checklist
- Ensure all commits are in the public main branch
- Review `sdk-release.yml` in the repo for specific workflow details
- The release job deploys the most current snapshot of main branch release tag to main branch

## Step 2: Release via GitHub Actions

### What the GitHub Release Job Does

1. **Initial Setup**
   - Verifies job is running from public repo and on main branch
   - Creates temporary `release/{run_number}` branch

2. **Testing Phase**
   - Runs unit tests for iOS and tvOS platforms
   - Validates CocoaPods spec
   - Validates Carthage build
   - Validates Swift Package Manager build
   - Updates kits and runs additional tests

3. **Version Management**
   - Runs semantic version action
     - Automatically bumps version based on commit messages
     - No version bump if no new commits (e.g., feat/fix)
     - Generates release notes automatically

4. **Artifact Publishing**
   - Publishes to package managers:
     - Pushes to CocoaPods trunk
     - Updates Carthage JSON spec
     - Updates Swift Package Manager
   - Creates GitHub release with artifacts



### How to Release

1. Navigate to the Actions tab in GitHub
2. Select "iOS SDK Release" workflow
3. Run the workflow from main branch with "true" first to perform a dry run
   > Important: Always start with a dry run to validate the release process. This will perform all steps up to semantic release without actually publishing, helping catch potential issues early.
4. If the dry run succeeds, run the workflow again with "false" option to perform the actual release
   > Note: Only proceed with the actual release after confirming a successful dry run

### Important Notes

- **Release Duration**: Expect ~30 minutes due to comprehensive test suite across platforms
- **Platform Requirements**: 
  - Tests run on macOS runners
  - Multiple Xcode versions may be tested
  - Both iOS and tvOS platforms are validated
- **Code Reusability**: 
  - Reusable GitHub Actions are defined in the [mparticle-workflows repo](https://github.com/mParticle/mparticle-workflows)
  - This enables other platforms to reuse similar jobs

## Post-Release Verification

After a successful build through GitHub Actions, verify:
1. Public repo has a new semantic release tag
2. New version is available on:
   - [CocoaPods](https://cocoapods.org/pods/mParticle-Apple-SDK)
   - [Carthage](https://github.com/mParticle/mparticle-apple-sdk/releases)
   - Swift Package Manager

## Troubleshooting

If you encounter issues during testing, check:
- Xcode version compatibility
- Platform-specific test failures (iOS vs tvOS)
- GitHub Actions logs for specific error messages
- CocoaPods trunk status
- Carthage binary framework validation
