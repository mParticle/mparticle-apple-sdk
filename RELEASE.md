# Release Process

## 1. Draft the release

1. Go to **Actions → Release – Draft** in GitHub
2. Select the bump type (`patch`, `minor`, or `major`) and run the workflow from `main`

This bumps versions across podspecs, `Package.swift`, constants files, and `CHANGELOG.md`, then opens a release PR against `main`.

## 2. Merge the release PR

Review and merge the PR. On merge, the **Release – Publish** workflow runs automatically:

- Builds xcframeworks for every kit
- Mirrors each kit subtree to its own repo under `mparticle-integrations/`
- Creates GitHub releases and tags (used by SPM consumers)

## 3. Publish to CocoaPods

> [!IMPORTANT]
> This is a **manual** step. Wait for the Release – Publish workflow to finish before running — kit mirror repos and GitHub tags must exist first.

```bash
# Register a trunk session if you don't have one (expires after ~3 days):
pod trunk register developers@mparticle.com 'mParticle Developers' --description='<your machine>'
# (confirm via email link)

# Publish everything:
./Scripts/pod_publish.sh
```

This pushes the Swift SDK and core SDK podspecs sequentially, then all kit podspecs in parallel.

## Post-release verification

- New `v<version>` tag exists on the main repo and all kit mirror repos
- New version is available on [CocoaPods](https://cocoapods.org/pods/mParticle-Apple-SDK)
- SPM resolves the new version
