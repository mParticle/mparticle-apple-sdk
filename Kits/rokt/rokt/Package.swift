// swift-tools-version:5.5

import Foundation
import PackageDescription

let version = "9.0.0"

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
    name: "mParticle-Rokt",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "mParticle-Rokt",
            targets: ["mParticle-Rokt-Swift"]
        )
    ],
    dependencies: [
        mParticleAppleSDK,
        .package(
            url: "https://github.com/ROKT/rokt-sdk-ios",
            .upToNextMajor(from: "5.0.0")
        ),
        .package(
            url: "https://github.com/ROKT/rokt-contracts-apple.git",
            .upToNextMajor(from: "0.1.3")
        ),
        .package(
            url: "https://github.com/erikdoe/ocmock",
            branch: "master"
        )
    ],
    targets: [
        .target(
            name: "mParticle-Rokt",
            dependencies: [
                .product(name: "mParticle-Apple-SDK", package: "mparticle-apple-sdk"),
                .product(name: "Rokt-Widget", package: "rokt-sdk-ios"),
                .product(name: "RoktContracts", package: "rokt-contracts-apple")
            ],
            path: "Sources/mParticle-Rokt",
            resources: [.process("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "include"
        ),
        .target(
            name: "mParticle-Rokt-Swift",
            dependencies: [
                "mParticle-Rokt",
                .product(name: "mParticle-Apple-SDK", package: "mparticle-apple-sdk"),
                .product(name: "Rokt-Widget", package: "rokt-sdk-ios"),
                .product(name: "RoktContracts", package: "rokt-contracts-apple")
            ],
            path: "Sources/mParticle-Rokt-Swift"
        ),
        .testTarget(
            name: "mParticle-RoktObjCTests",
            dependencies: [
                "mParticle-Rokt",
                .product(name: "OCMock", package: "ocmock")
            ]
        ),
        .testTarget(
            name: "mParticle-RoktSwiftTests",
            dependencies: [
                "mParticle-Rokt",
                "mParticle-Rokt-Swift",
                .product(name: "RoktContracts", package: "rokt-contracts-apple")
            ]
        )
    ]
)
