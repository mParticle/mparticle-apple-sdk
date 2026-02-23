// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "mParticle-Leanplum",
    platforms: [ .iOS(.v15) ],
    products: [
        .library(
            name: "mParticle-Leanplum",
            targets: ["mParticle-Leanplum"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/mParticle/mparticle-apple-sdk",
                 branch: "workstation/9.0-Release"),
        .package(url: "https://github.com/leanplum/leanplum-ios-sdk",
                 .upToNextMajor(from: "6.0.0"))
    ],
    targets: [
        .target(
            name: "mParticle-Leanplum",
            dependencies: [
                .product(name: "mParticle-Apple-SDK", package: "mParticle-Apple-SDK"),
                .product(name: "Leanplum", package: "leanplum-ios-sdk")
            ],
            resources: [.process("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "include"
        ),
        .testTarget(
            name: "mParticle-LeanplumTests",
            dependencies: [
                "mParticle-Leanplum"
            ]
        )
    ]
)
