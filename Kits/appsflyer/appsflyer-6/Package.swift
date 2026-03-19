// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "mParticle-AppsFlyer",
    platforms: [ .iOS(.v15) ],
    products: [
        .library(
            name: "mParticle-AppsFlyer",
            targets: ["mParticle-AppsFlyer"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/mParticle/mparticle-apple-sdk",
            branch: "workstation/9.0-Release"
        ),
        .package(url: "https://github.com/AppsFlyerSDK/AppsFlyerFramework-Static",
                 .upToNextMajor(from: "6.0.0")),
        .package(
            url: "https://github.com/erikdoe/ocmock",
            branch: "master"
        )
    ],
    targets: [
        .target(
            name: "mParticle-AppsFlyer",
            dependencies: [
                .product(name: "mParticle-Apple-SDK", package: "mParticle-Apple-SDK"),
                .product(name: "AppsFlyerLib-Static", package: "AppsFlyerFramework-Static")
            ],
            resources: [.process("PrivacyInfo.xcprivacy")]
        ),
        .testTarget(
            name: "mParticle-AppsFlyerTests",
            dependencies: [
                "mParticle-AppsFlyer",
                .product(name: "OCMock", package: "ocmock")
            ],
        )
    ]
)
