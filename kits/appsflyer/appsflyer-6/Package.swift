// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "mParticle-AppsFlyer",
    platforms: [ .iOS(.v9) ],
    products: [
        .library(
            name: "mParticle-AppsFlyer",
            targets: ["mParticle-AppsFlyer"]
        ),
        .library(
            name: "mParticle-AppsFlyer-NoLocation",
            targets: ["mParticle-AppsFlyer-NoLocation"]
        )
    ],
    dependencies: [
        .package(name: "mParticle-Apple-SDK",
                 url: "https://github.com/mParticle/mparticle-apple-sdk",
                 .upToNextMajor(from: "8.19.0")),
        .package(name: "AppsFlyerLib",
                 url: "https://github.com/AppsFlyerSDK/AppsFlyerFramework-Static",
                 .upToNextMajor(from: "6.14.3")),
    ],
    targets: [
        .target(
            name: "mParticle-AppsFlyer",
            dependencies: [
                .product(name: "mParticle-Apple-SDK", package: "mParticle-Apple-SDK"),
                .product(name: "AppsFlyerLib-Static", package: "AppsFlyerLib"),
            ],
            resources: [.process("PrivacyInfo.xcprivacy")]
        ),
        .target(
            name: "mParticle-AppsFlyer-NoLocation",
            dependencies: [
                .product(name: "mParticle-Apple-SDK-NoLocation", package: "mParticle-Apple-SDK"),
                .product(name: "AppsFlyerLib-Static", package: "AppsFlyerLib"),
            ],
            path: "SPM/mParticle-AppsFlyer-NoLocation",
            resources: [.process("PrivacyInfo.xcprivacy")]
        ),
        
        .testTarget(
            name: "mParticle-AppsFlyer-Swift-Tests",
            dependencies: ["mParticle-AppsFlyer"],
            path: "mParticle_AppsFlyerTests"
        ),
    ]
)
