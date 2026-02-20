// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "mParticle-Kochava",
    platforms: [
        .iOS("14.0"),
        .tvOS("14.0"),
    ],
    products: [
        .library(
            name: "mParticle-Kochava",
            targets: ["mParticle-Kochava"]
        ),
        .library(
            name: "mParticle-Kochava-NoTracking",
            targets: ["mParticle-Kochava-NoTracking"]
        ),
    ],
    dependencies: [
        .package(
            name: "mParticle-Apple-SDK",
            url: "https://github.com/mParticle/mparticle-apple-sdk",
            .upToNextMajor(from: "8.22.0")
        ),
        .package(
            name: "KochavaNetworking",
            url: "https://github.com/Kochava/Apple-SwiftPackage-KochavaNetworking-XCFramework",
            .upToNextMajor(from: "9.0.0")
        ),
        .package(
            name: "KochavaMeasurement",
            url: "https://github.com/Kochava/Apple-SwiftPackage-KochavaMeasurement-XCFramework",
            .upToNextMajor(from: "9.0.0")
        ),
        .package(
            name: "KochavaTracking",
            url: "https://github.com/Kochava/Apple-SwiftPackage-KochavaTracking-XCFramework",
            .upToNextMajor(from: "9.0.0")
        ),
    ],
    targets: [
        .target(
            name: "mParticle-Kochava",
            dependencies: ["mParticle-Apple-SDK", "KochavaNetworking", "KochavaMeasurement", "KochavaTracking"],
            path: "mParticle-Kochava",
            resources: [.process("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "."
        ),
        .target(
            name: "mParticle-Kochava-NoTracking",
            dependencies: ["mParticle-Apple-SDK", "KochavaNetworking", "KochavaMeasurement"],
            path: "mParticle-Kochava-NoTracking",
            resources: [.process("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "."
        ),
    ]
)
