// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "mParticle-Adobe",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "mParticle-Adobe",
            targets: ["mParticle-Adobe"]
        ),
        .library(
            name: "mParticle-AdobeMedia",
            targets: ["mParticle-AdobeMedia"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/mParticle/mparticle-apple-sdk",
                 branch: "workstation/9.0-Release"),
        .package(url: "https://github.com/mParticle/mparticle-apple-media-sdk",
                 branch: "feat/remove-nolocation-product"),
        .package(url: "https://github.com/adobe/aepsdk-core-ios.git",
                 .upToNextMajor(from: "5.0.0")),
        .package(url: "https://github.com/adobe/aepsdk-userprofile-ios.git",
                 .upToNextMajor(from: "5.0.0")),
        .package(url: "https://github.com/adobe/aepsdk-analytics-ios.git",
                 .upToNextMajor(from: "5.0.0")),
        .package(url: "https://github.com/adobe/aepsdk-media-ios.git",
                 .upToNextMajor(from: "5.0.0"))
    ],
    targets: [
        .target(
            name: "mParticle-Adobe",
            dependencies: [
                .product(name: "mParticle-Apple-SDK", package: "mParticle-Apple-SDK")
            ],
            path: "Sources/mParticle-Adobe",
            resources: [.process("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "include"
        ),
        .target(
            name: "mParticle-AdobeMedia",
            dependencies: [
                .product(name: "mParticle-Apple-SDK", package: "mParticle-Apple-SDK"),
                .product(name: "mParticle-Apple-Media-SDK", package: "mparticle-apple-media-sdk"),
                .product(name: "AEPCore", package: "aepsdk-core-ios"),
                .product(name: "AEPIdentity", package: "aepsdk-core-ios"),
                .product(name: "AEPLifecycle", package: "aepsdk-core-ios"),
                .product(name: "AEPSignal", package: "aepsdk-core-ios"),
                .product(name: "AEPUserProfile", package: "aepsdk-userprofile-ios"),
                .product(name: "AEPAnalytics", package: "aepsdk-analytics-ios"),
                .product(name: "AEPMedia", package: "aepsdk-media-ios")
            ],
            path: "Sources/mParticle-AdobeMedia",
            resources: [.process("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "include"
        ),
        .testTarget(
            name: "mParticle-AdobeTests",
            dependencies: [
                "mParticle-Adobe"
            ]
        ),
        .testTarget(
            name: "mParticle-AdobeMediaTests",
            dependencies: [
                "mParticle-AdobeMedia"
            ]
        )
    ]
)
