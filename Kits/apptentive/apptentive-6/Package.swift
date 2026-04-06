// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "mParticle-Apptentive",
    platforms: [ .iOS(.v15) ],
    products: [
        .library(
            name: "mParticle-Apptentive",
            targets: ["mParticle-Apptentive"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/mParticle/mparticle-apple-sdk",
            branch: "workstation/9.0-Release"
        ),
        .package(
            url: "https://github.com/apptentive/apptentive-kit-ios",
            .upToNextMajor(from: "6.0.0")
        )
    ],
    targets: [
        .target(
            name: "mParticle-Apptentive",
            dependencies: [
                .product(name: "mParticle-Apple-SDK", package: "mparticle-apple-sdk"),
                .product(name: "ApptentiveKit", package: "apptentive-kit-ios")
            ],
            resources: [.process("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "include"
        ),
        .testTarget(
            name: "mParticle-ApptentiveTests",
            dependencies: [
                "mParticle-Apptentive"
            ],
        )
    ]
)
