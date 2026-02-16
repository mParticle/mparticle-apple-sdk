// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "mParticle-Appboy",
    platforms: [ .iOS(.v15), .tvOS(.v15) ],
    products: [
        .library(
            name: "mParticle-Appboy",
            targets: ["mParticle-Appboy"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/mParticle/mparticle-apple-sdk",
            branch: "workstation/9.0-Release"
        ),
        .package(
            url: "https://github.com/braze-inc/braze-swift-sdk",
            .upToNextMajor(from: "12.0.0")
        ),
    ],
    targets: [
        .target(
            name: "mParticle-Appboy",
            dependencies: [
                .product(name: "mParticle-Apple-SDK", package: "mParticle-Apple-SDK"),
                .product(name: "BrazeUI", package: "braze-swift-sdk", condition: .when(platforms: [.iOS])),
                .product(name: "BrazeKit", package: "braze-swift-sdk"),
                .product(name: "BrazeKitCompat", package: "braze-swift-sdk"),
            ],
            resources: [.process("PrivacyInfo.xcprivacy")]
        )
    ]
)
