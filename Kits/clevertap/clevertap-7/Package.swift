// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "mParticle-CleverTap",
    platforms: [ .iOS(.v15) ],
    products: [
        .library(name: "mParticle-CleverTap", targets: ["mParticle-CleverTap"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/mParticle/mparticle-apple-sdk",
            branch: "workstation/9.0-Release"
        ),
        .package(url: "https://github.com/CleverTap/clevertap-ios-sdk", .upToNextMajor(from: "7.0.0"))
    ],
    targets: [
        .target(
            name: "mParticle-CleverTap",
            dependencies: [
                .product(name: "mParticle-Apple-SDK", package: "mparticle-apple-sdk"),
                .product(name: "CleverTapSDK", package: "clevertap-ios-sdk")
            ],
            resources: [.process("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "include",
            cSettings: [
                .unsafeFlags(["-Wno-non-modular-include-in-framework-module"])
            ]
        ),
        .testTarget(name: "mParticle-CleverTapTests", dependencies: ["mParticle-CleverTap"])
    ]
)
