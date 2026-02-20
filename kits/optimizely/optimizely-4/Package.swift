// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "mParticle-Optimizely",
    platforms: [ .iOS(.v15), .tvOS(.v15) ],
    products: [
        .library(
            name: "mParticle-Optimizely",
            targets: ["mParticle-Optimizely"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/mParticle/mparticle-apple-sdk",
            branch: "workstation/9.0-Release"
        ),
        .package(
            url: "https://github.com/optimizely/swift-sdk",
            .upToNextMajor(from: "4.0.0")
        ),
        .package(
            url: "https://github.com/erikdoe/ocmock",
            branch: "master"
        )
    ],
    targets: [
        .target(
            name: "mParticle-Optimizely",
            dependencies: [
                .product(name: "mParticle-Apple-SDK", package: "mParticle-Apple-SDK"),
                .product(name: "Optimizely", package: "swift-sdk")
            ],
            resources: [.process("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "include"
        ),
        .testTarget(
            name: "mParticle-OptimizelyTests",
            dependencies: [
                "mParticle-Optimizely",
                .product(name: "OCMock", package: "ocmock")
            ]
        )
    ]
)
