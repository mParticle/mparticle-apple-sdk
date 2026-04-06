// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "mParticle-OneTrust",
    platforms: [ .iOS(.v15), .tvOS(.v15) ],
    products: [
        .library(
            name: "mParticle-OneTrust",
            targets: ["mParticle-OneTrust"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/mParticle/mparticle-apple-sdk",
            branch: "workstation/9.0-Release"
        ),
        // iOS OneTrust
        .package(
            url: "https://github.com/Zentrust/OTPublishersHeadlessSDK",
            "0.0.0"..<"999999.0.0"
        ),

        // tvOS OneTrust
        .package(
            url: "https://github.com/Zentrust/OTPublishersHeadlessSDKtvOS",
            "0.0.0"..<"999999.0.0"
        )
    ],
    targets: [
        .target(
            name: "mParticle-OneTrust",
            dependencies: [
                .product(name: "mParticle-Apple-SDK", package: "mParticle-Apple-SDK"),
                .product(
                    name: "OTPublishersHeadlessSDK",
                    package: "OTPublishersHeadlessSDK",
                    condition: .when(platforms: [.iOS])
                ),
                .product(
                    name: "OTPublishersHeadlessSDKtvOS",
                    package: "OTPublishersHeadlessSDKtvOS",
                    condition: .when(platforms: [.tvOS])
                )
            ],
            resources: [.process("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "include"
        ),
        .testTarget(
            name: "mParticle-OneTrustTests",
            dependencies: [
                "mParticle-OneTrust"
            ]
        )
    ]
)
