# mParticle Apple SDK — Integration Kits

This directory contains the source code for all mParticle integration kits (forwarders) that are part of the Apple SDK monorepo.

## Monorepo Structure

Each kit lives under a provider/version directory:

```bash
kits/
└── <provider>/
    └── <provider>-<major_version>/
        ├── Package.swift          # SPM manifest
        ├── CHANGELOG.md           # Kit-specific release notes
        ├── LICENSE
        ├── README.md              # Consumer-facing README
        ├── Sources/               # Kit implementation
        ├── Tests/                 # Unit tests
        ├── Example/               # Sample apps
        └── *.xcodeproj            # Developer project
```

The version suffix (e.g., `braze-12`) corresponds to the **major version of the third-party SDK** that the kit integrates with, not the mParticle kit version itself. This allows multiple kit variants to coexist when a vendor ships breaking major releases (e.g., `braze-12`, `braze-13`).

## Available Kits

| Kit      | Path                  | Mirror Repo                                                                                                              | Third-Party SDK                                                      |
| -------- | --------------------- | ------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------- |
| Braze 12 | `kits/braze/braze-12` | [`mparticle-apple-integration-braze-12`](https://github.com/mparticle-integrations/mparticle-apple-integration-braze-12) | [Braze Swift SDK 12.x](https://github.com/braze-inc/braze-swift-sdk) |

## How Kits Are Released

Kit releases are driven by the monorepo's CI pipeline and a single `VERSION` file at the repository root.

### Release Flow

1. **Version bump** — The `sdk-release-ecosystem-manual.yml` workflow creates a release PR that bumps the `VERSION` file and updates all kit podspecs and `Package.swift` dependencies.
2. **Merge to main** — When the release PR merges, `release-ecosystem-from-main.yml` triggers automatically.
3. **Per-kit mirror and release** — For each kit in the workflow matrix:
   - The kit's XCFramework is built from its Xcode project.
   - `git subtree split` extracts the kit directory into an isolated branch.
   - The split branch is force-pushed to the kit's mirror repo under `mparticle-integrations/`.
   - A GitHub release is created on the mirror repo with the XCFramework artifact and release notes from the kit's `CHANGELOG.md`.

### Mirror Repos

Each kit directory is mirrored to its own standalone repository under the [`mparticle-integrations`](https://github.com/mparticle-integrations) GitHub organization. These mirror repos are what consumers add as SPM or CocoaPods dependencies. **Do not commit directly to mirror repos** — all changes flow through this monorepo.

```bash
monorepo                                           mirror repo
kits/braze/braze-12/  ──subtree split──>  mparticle-integrations/mparticle-apple-integration-braze-12
```

## Adding a New Kit

1. Create the directory structure under `kits/<provider>/<provider>-<version>/`.
2. Add the kit source in `Sources/`, tests in `Tests/`, and example apps in `Example/`.
3. Create a `Package.swift` that depends on `mParticle/mparticle-apple-sdk` and the third-party SDK.
4. Add an Xcode project with a framework scheme for building the XCFramework.
5. Add a `CHANGELOG.md`, `LICENSE`, and consumer-facing `README.md`.
6. Register the kit in the workflow matrix in `.github/workflows/release-ecosystem-from-main.yml`.
7. Create the corresponding mirror repo under `mparticle-integrations/`.

## Development

### Building a Kit Locally

Open the kit's Xcode project (e.g., `kits/braze/braze-12/mParticle-Braze.xcodeproj`) and build the framework scheme, or use SPM:

```bash
cd kits/braze/braze-12
swift build
```

### Running Kit Tests

```bash
cd kits/braze/braze-12
swift test
```

Or run tests from the Xcode project using Cmd+U.

### Important Notes

- **All kit changes happen here in the monorepo.** Never commit directly to mirror repos.
- **README files in kit directories are consumer-facing.** They get pushed to the mirror repo and are the first thing consumers see. Write them accordingly.
- **CHANGELOG.md entries are extracted during release** and used as GitHub release notes on the mirror repo.
- **Version alignment** — Kit versions are kept in sync with the core SDK version via the ecosystem release workflow.
