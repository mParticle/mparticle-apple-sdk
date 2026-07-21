# Release Process

## 1. Refresh the CocoaPods trunk token

> [!IMPORTANT]
> The `COCOAPODS_TRUNK_TOKEN` secret in this repository expires after ~3 days. **Refresh it before every release.**

1. Generate a new session token:
   ```bash
   pod trunk register developers@mparticle.com 'mParticle Developers' --description='CI release'
   ```
   Confirm via the email link, then retrieve the token:
   ```bash
   grep -A2 'trunk.cocoapods.org' ~/.netrc | grep password | awk '{print $2}'
   ```
2. Update the `COCOAPODS_TRUNK_TOKEN` secret in **Settings → Secrets and variables → Actions** on this repository.

## 2. Draft the release

1. Go to **Actions → Release – Draft** in GitHub
2. Select the bump type (`patch`, `minor`, or `major`) and run the workflow from `main`

This bumps versions across podspecs, `Package.swift`, constants files, and `CHANGELOG.md`, then opens a release PR against `main`.

## 3. Merge the release PR

Review and merge the PR. On merge, the **Release – Publish** workflow runs automatically:

- Builds xcframeworks for every kit
- Mirrors each kit subtree to its own repo under `mparticle-integrations/` (and **RoktSDKPlus** to `ROKT/rokt-sdk-plus-ios`)
- Creates GitHub releases and tags (used by SPM consumers)
- Publishes the core SDK and all kit podspecs to CocoaPods trunk

> [!NOTE]
> The release GitHub App must be installed on **ROKT** with access to `rokt-sdk-plus-ios` for that mirror push to succeed (same app credentials as `mparticle-integrations` mirrors).

> [!NOTE]
> The Swift SDK podspec (`mParticle-Apple-SDK-Swift`) is not yet published automatically — push it manually before the core SDK if required:
>
> ```bash
> pod trunk push mParticle-Apple-SDK-Swift.podspec --allow-warnings
> ```

## Post-release verification

- New `v<version>` tag exists on the main repo and all kit mirror repos
- New version is available on [CocoaPods](https://cocoapods.org/pods/mParticle-Apple-SDK)
- SPM resolves the new version
