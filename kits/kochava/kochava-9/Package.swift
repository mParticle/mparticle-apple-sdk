// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "mParticle-Kochava",
    platforms: [ .iOS(.v15), .tvOS(.v15) ],
    products: [
        .library(
            name: "mParticle-Kochava",
            targets: ["mParticle-Kochava"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/mParticle/mparticle-apple-sdk",
            branch: "workstation/9.0-Release"
        ),
        .package(
            url: "https://github.com/Kochava/Apple-SwiftPackage-KochavaNetworking-XCFramework",
            .upToNextMajor(from: "9.0.0")
        ),
        .package(
            url: "https://github.com/Kochava/Apple-SwiftPackage-KochavaMeasurement-XCFramework",
            .upToNextMajor(from: "9.0.0")
        ),
        .package(
            url: "https://github.com/Kochava/Apple-SwiftPackage-KochavaTracking-XCFramework",
            .upToNextMajor(from: "9.0.0")
        ),
    ],
    targets: [
        .target(
            name: "mParticle-Kochava",
            dependencies: [
                .product(name: "mParticle-Apple-SDK", package: "mParticle-Apple-SDK"),
                .product(name: "KochavaNetworking", package: "Apple-SwiftPackage-KochavaNetworking-XCFramework"),
                .product(name: "KochavaMeasurement", package: "Apple-SwiftPackage-KochavaMeasurement-XCFramework"),
                .product(name: "KochavaTracking", package: "Apple-SwiftPackage-KochavaTracking-XCFramework")
            ],
            resources: [.process("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "include"
        ),
        .testTarget(
            name: "mParticle-KochavaTests",
            dependencies: [
                "mParticle-Kochava"
            ]
        )
    ]
)
