// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "mParticle-BranchMetrics",
    platforms: [ .iOS(.v15) ],
    products: [
        .library(name: "mParticle-BranchMetrics", targets: ["mParticle-BranchMetrics"])
    ],
    dependencies: [
        .package(url: "https://github.com/mParticle/mparticle-apple-sdk", branch: "workstation/9.0-Release"),
        .package(url: "https://github.com/BranchMetrics/ios-branch-sdk-spm", .upToNextMajor(from: "3.4.1"))
    ],
    targets: [
        .target(
            name: "mParticle-BranchMetrics",
            dependencies: [
                .product(name: "mParticle-Apple-SDK", package: "mParticle-Apple-SDK"),
                .product(name: "BranchSDK", package: "ios-branch-sdk-spm")
            ],
            resources: [.process("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "include"
        ),
        .testTarget(name: "mParticle-BranchMetricsTests", dependencies: ["mParticle-BranchMetrics"])
    ]
)
