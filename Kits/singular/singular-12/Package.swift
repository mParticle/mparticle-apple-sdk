// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "mParticle-Singular",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "mParticle-Singular",
            targets: ["mParticle-Singular"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/mParticle/mparticle-apple-sdk",
                 branch: "workstation/9.0-Release"),
        .package(url: "https://github.com/singular-labs/Singular-iOS-SDK",
                 .upToNextMajor(from: "12.4.1"))
    ],
    targets: [
        .target(
            name: "mParticle-Singular",
            dependencies: [
                .product(name: "mParticle-Apple-SDK", package: "mParticle-Apple-SDK"),
                .product(name: "Singular", package: "Singular-iOS-SDK")
            ],
            path: "Sources/mParticle-Singular",
            resources: [.process("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "include",
            linkerSettings: [
                .linkedFramework("StoreKit")
            ]
        ),
        .testTarget(
            name: "mParticle-SingularTests",
            dependencies: [
                "mParticle-Singular"
            ]
        )
    ]
)
