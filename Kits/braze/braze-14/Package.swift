// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

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
    name: "mParticle-Braze",
    platforms: [ .iOS(.v15), .tvOS(.v15) ],
    products: [
        .library(
            name: "mParticle-Braze",
            targets: ["mParticle-Braze"]
        )
    ],
    dependencies: [
        mParticleAppleSDK,
        .package(
            url: "https://github.com/braze-inc/braze-swift-sdk",
            .upToNextMajor(from: "14.0.0")
        ),
        .package(
            url: "https://github.com/erikdoe/ocmock",
            branch: "master"
        )
    ],
    targets: [
        .target(
            name: "mParticle-Braze",
            dependencies: [
                .product(name: "mParticle-Apple-SDK", package: "mparticle-apple-sdk"),
                .product(name: "BrazeUI", package: "braze-swift-sdk", condition: .when(platforms: [.iOS])),
                .product(name: "BrazeKit", package: "braze-swift-sdk")
            ],
            resources: [.process("PrivacyInfo.xcprivacy")]
        ),
        .testTarget(
            name: "mParticle-BrazeTests",
            dependencies: [
                "mParticle-Braze",
                .product(name: "OCMock", package: "ocmock")
            ]
        )
    ]
)
