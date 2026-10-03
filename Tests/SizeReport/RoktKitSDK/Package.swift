// swift-tools-version:5.5
//
// RoktKitSDK Package
//
// Builds the mParticle SDK and the Rokt kit from this checkout's source, so
// the Core + Rokt kit numbers move with SDK and kit changes. Resolve with
// USE_LOCAL_VERSION=1, or the kit pulls the core SDK from GitHub instead.
//
// The Rokt dependencies are pinned exactly, so a Rokt release does not show up
// as a size change on an unrelated pull request. Bump them deliberately.
//

import PackageDescription

let package = Package(
    name: "RoktKitSDK",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "SizeCore", targets: ["SizeCore"]),
        .library(name: "SizeRoktKit", targets: ["SizeRoktKit"])
    ],
    dependencies: [
        .package(name: "mparticle-apple-sdk", path: "../../.."),
        .package(name: "mParticle-Rokt", path: "../../../Kits/rokt/rokt"),
        // Pins only: nothing here depends on these directly.
        .package(url: "https://github.com/ROKT/rokt-sdk-ios", .exact("5.5.1")),
        .package(url: "https://github.com/ROKT/rokt-ux-helper-ios.git", .exact("2.1.2")),
        .package(url: "https://github.com/ROKT/dcui-swift-schema.git", .exact("2.10.0")),
        .package(url: "https://github.com/ROKT/rokt-contracts-apple.git", .exact("2.0.2"))
    ],
    targets: [
        .target(
            name: "SizeCore",
            dependencies: [.product(name: "mParticle-Apple-SDK", package: "mparticle-apple-sdk")]
        ),
        .target(
            name: "SizeRoktKit",
            dependencies: [.product(name: "mParticle-Rokt", package: "mParticle-Rokt")]
        )
    ]
)
