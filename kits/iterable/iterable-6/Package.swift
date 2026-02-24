// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "mParticle-Iterable",
    platforms: [ .iOS(.v15), .tvOS(.v15) ],
    products: [
        .library(
            name: "mParticle-Iterable",
            targets: ["mParticle-Iterable"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/mParticle/mparticle-apple-sdk",
            branch: "workstation/9.0-Release"
        ),
        .package(
            url: "https://github.com/Iterable/swift-sdk",
            .upToNextMajor(from: "6.5.2")
        )
    ],
    targets: [
        .target(
            name: "mParticle-Iterable",
            dependencies: [
                .product(name: "mParticle-Apple-SDK", package: "mParticle-Apple-SDK"),
                .product(name: "IterableSDK", package: "swift-sdk"),
                .product(name: "IterableAppExtensions", package: "swift-sdk")
            ],
            resources: [.process("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "include"
        ),
        .testTarget(
            name: "mParticle-IterableTests",
            dependencies: [
                "mParticle-Iterable"
            ]
        )
    ]
)
