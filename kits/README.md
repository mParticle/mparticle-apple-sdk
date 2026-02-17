# mParticle Apple SDK — Integration Kits

Kits forward events from the mParticle Apple SDK to partner services. To use a partner integration, add mParticle core plus the kit that matches the partner SDK major version you use.

## How to Choose a Kit

Kits are versioned by the partner SDK major:

- `braze-12` → Braze Swift SDK 12.x

Pick the kit that matches the partner SDK major you want in your app.

## Important Note (Monorepo Paths)

The `kits/<provider>/<provider>-<major>/` paths are how kits are organized in this repository. For your app, use the **Standalone Repository** link below (or the kit's README) to install via your dependency manager.

## Setup Instructions

Each kit has its own README with installation and configuration steps.

## Available Kits

| Kit      | Standalone Repository                                                                                                    | Partner SDK                                                          |
| -------- | ------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------- |
| Braze 12 | [`mparticle-apple-integration-braze-12`](https://github.com/mparticle-integrations/mparticle-apple-integration-braze-12) | [Braze Swift SDK 12.x](https://github.com/braze-inc/braze-swift-sdk) |
