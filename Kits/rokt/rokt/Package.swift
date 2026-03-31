// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "mParticle-Rokt",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "mParticle-Rokt",
            targets: ["mParticle-Rokt-Swift"]
        )
    ],
    dependencies: [
        // Monorepo root — must match the app’s local mParticle-Apple-SDK package so SPM resolves one SDK.
        .package(path: "../../../"),
        .package(
            url: "https://github.com/ROKT/rokt-sdk-ios",
            branch: "workstation/5.0.0"
        ),
        .package(
            url: "https://github.com/ROKT/rokt-contracts-apple.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/erikdoe/ocmock",
            branch: "master"
        )
    ],
    targets: [
        .target(
            name: "mParticle-Rokt",
            dependencies: [
                .product(name: "mParticle-Apple-SDK", package: "mParticle-Apple-SDK"),
                .product(name: "Rokt-Widget", package: "rokt-sdk-ios"),
                .product(name: "RoktContracts", package: "rokt-contracts-apple")
            ],
            path: "Sources/mParticle-Rokt",
            resources: [.process("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "include"
        ),
        .target(
            name: "mParticle-Rokt-Swift",
            dependencies: [
                "mParticle-Rokt",
                .product(name: "mParticle-Apple-SDK", package: "mParticle-Apple-SDK"),
                .product(name: "Rokt-Widget", package: "rokt-sdk-ios"),
                .product(name: "RoktContracts", package: "rokt-contracts-apple")
            ],
            path: "Sources/mParticle-Rokt-Swift"
        ),
        .testTarget(
            name: "mParticle-RoktObjCTests",
            dependencies: [
                "mParticle-Rokt",
                .product(name: "OCMock", package: "ocmock")
            ]
        ),
        .testTarget(
            name: "mParticle-RoktSwiftTests",
            dependencies: [
                "mParticle-Rokt",
                "mParticle-Rokt-Swift",
                .product(name: "RoktContracts", package: "rokt-contracts-apple")
            ]
        )
    ]
)
