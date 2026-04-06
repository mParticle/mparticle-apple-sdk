// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "mParticle-Localytics",
    platforms: [ .iOS(.v15) ],
    products: [
        .library(
            name: "mParticle-Localytics",
            targets: ["mParticle-Localytics"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/mParticle/mparticle-apple-sdk",
                 branch: "workstation/9.0-Release"),
        .package(url: "https://github.com/localytics/Localytics-swiftpm",
                 .upToNextMajor(from: "6.0.0"))
    ],
    targets: [
        .target(
            name: "mParticle-Localytics",
            dependencies: [
                .product(name: "mParticle-Apple-SDK", package: "mparticle-apple-sdk"),
                .product(name: "Localytics", package: "Localytics-swiftpm")
            ],
            resources: [.process("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "include"
        ),
        .testTarget(
            name: "mParticle-LocalyticsTests",
            dependencies: [
                "mParticle-Localytics"
            ]
        )
    ]
)
