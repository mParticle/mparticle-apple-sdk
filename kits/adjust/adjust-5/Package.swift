// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "mParticle-Adjust",
    platforms: [ .iOS(.v9), .tvOS(.v9) ],
    products: [
        .library(
            name: "mParticle-Adjust",
            targets: ["mParticle-Adjust"]
        ),
    ],
    dependencies: [
        .package(name: "mParticle-Apple-SDK",
                 url: "https://github.com/mParticle/mparticle-apple-sdk",
                 .upToNextMajor(from: "8.22.0")),
        .package(name: "AdjustSdk",
                 url: "https://github.com/adjust/ios_sdk",
                 .upToNextMajor(from: "5.0.0")),
    ],
    targets: [
        .target(
            name: "mParticle-Adjust",
            dependencies: [
                .byName(name: "mParticle-Apple-SDK"),
                .byName(name: "AdjustSdk")
            ],
            resources: [.process("PrivacyInfo.xcprivacy")]
        )
    ]
)
