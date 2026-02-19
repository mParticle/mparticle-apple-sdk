// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "mParticle-Adjust",
    platforms: [ .iOS(.v15), .tvOS(.v15) ],
    products: [
        .library(
            name: "mParticle-Adjust",
            targets: ["mParticle-Adjust"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/mParticle/mparticle-apple-sdk",
            branch: "workstation/9.0-Release"
        ),
        .package(url: "https://github.com/adjust/ios_sdk",
                 .upToNextMajor(from: "5.0.0"))
    ],
    targets: [
        .target(
            name: "mParticle-Adjust",
            dependencies: [
                .product(name: "mParticle-Apple-SDK", package: "mParticle-Apple-SDK"),
                .product(name: "AdjustSdk", package: "ios_sdk")
            ],
            resources: [.process("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "include"
        ),
        .testTarget(
            name: "mParticle-AdjustTests",
            dependencies: [
                "mParticle-Adjust"
            ]
        )
    ]
)
