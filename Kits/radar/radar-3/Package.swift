// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "mParticle-Radar",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "mParticle-Radar", targets: ["mParticle-Radar"])
    ],
    dependencies: [
        .package(url: "https://github.com/mParticle/mparticle-apple-sdk", branch: "workstation/9.0-Release"),
        .package(url: "https://github.com/radarlabs/radar-sdk-ios-spm", .upToNextMajor(from: "3.25.0"))
    ],
    targets: [
        .target(
            name: "mParticle-Radar",
            dependencies: [
                .product(name: "mParticle-Apple-SDK", package: "mparticle-apple-sdk"),
                .product(name: "RadarSDK", package: "radar-sdk-ios-spm")
            ],
            resources: [.process("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "include"
        ),
        .testTarget(name: "mParticle-RadarTests", dependencies: ["mParticle-Radar"])
    ]
)
