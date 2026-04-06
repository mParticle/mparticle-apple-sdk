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
        // Standalone kit CI/releases: use .package(url: "https://github.com/mParticle/mparticle-apple-sdk", branch: "…").
        .package(name: "mparticle-apple-sdk", path: "../../../"),
        .package(url: "https://github.com/localytics/Localytics-swiftpm",
                 .upToNextMajor(from: "7.0.0"))
    ],
    targets: [
        .target(
            name: "mParticle-Localytics",
            dependencies: [
                .product(name: "mParticle-Apple-SDK", package: "mparticle-apple-sdk"),
                .product(name: "Localytics", package: "Localytics-swiftpm")
            ],
            resources: [.process("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "include",
            cSettings: [
                .unsafeFlags([
                    "-Wno-non-modular-include-in-framework-module",
                    "-Wno-error=non-modular-include-in-framework-module"
                ])
            ],
            linkerSettings: [
                .linkedFramework("CoreLocation")
            ]
        ),
        .testTarget(
            name: "mParticle-LocalyticsTests",
            dependencies: [
                "mParticle-Localytics"
            ]
        )
    ]
)
