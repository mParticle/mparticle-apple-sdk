// swift-tools-version:5.5
//
// RoktKitSDK Package
//
// Builds the mParticle SDK and the Rokt kit from this checkout's source, so
// the Core + Rokt kit numbers move with SDK and kit changes. Resolve with
// USE_LOCAL_VERSION=1, or the kit pulls the core SDK from GitHub instead.
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
        .package(name: "mParticle-Rokt", path: "../../../Kits/rokt/rokt")
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
