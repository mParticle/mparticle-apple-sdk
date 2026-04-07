// swift-tools-version:5.5

import Foundation
import PackageDescription

let version = ""

let useLocalVersion = ProcessInfo.processInfo.environment["USE_LOCAL_VERSION"] != nil

let mParticleAppleSDK: Package.Dependency = {
    if useLocalVersion {
        return .package(path: "../../../")
    }

    let url = "https://github.com/mParticle/mparticle-apple-sdk"
    if version.isEmpty {
        return .package(url: url, branch: "main")
    }
    return .package(url: url, .upToNextMajor(from: Version(version)!))
}()

let package = Package(
    name: "mParticle-BranchMetrics",
    platforms: [ .iOS(.v15) ],
    products: [
        .library(name: "mParticle-BranchMetrics", targets: ["mParticle-BranchMetrics"])
    ],
    dependencies: [
        mParticleAppleSDK,
        .package(url: "https://github.com/BranchMetrics/ios-branch-sdk-spm", .upToNextMajor(from: "3.4.1"))
    ],
    targets: [
        .target(
            name: "mParticle-BranchMetrics",
            dependencies: [
                .product(name: "mParticle-Apple-SDK", package: "mparticle-apple-sdk"),
                .product(name: "BranchSDK", package: "ios-branch-sdk-spm")
            ],
            resources: [.process("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "include"
        ),
        .testTarget(name: "mParticle-BranchMetricsTests", dependencies: ["mParticle-BranchMetrics"])
    ]
)
