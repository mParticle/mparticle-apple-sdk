// swift-tools-version:5.9

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
        .package(
            url: "https://github.com/mParticle/mparticle-apple-sdk",
            branch: "workstation/9.0-Release"
        ),
        .package(
            url: "https://github.com/ROKT/rokt-sdk-ios",
            .upToNextMajor(from: "4.16.1")
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
                .product(name: "Rokt-Widget", package: "rokt-sdk-ios")
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
                .product(name: "Rokt-Widget", package: "rokt-sdk-ios")
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
                "mParticle-Rokt-Swift"
            ]
        )
    ]
)
