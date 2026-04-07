// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

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
    name: "mParticle-Iterable",
    platforms: [ .iOS(.v15) ],
    products: [
        .library(
            name: "mParticle-Iterable",
            targets: ["mParticle-Iterable"]
        )
    ],
    dependencies: [
        mParticleAppleSDK,
        .package(
            url: "https://github.com/Iterable/swift-sdk",
            .upToNextMajor(from: "6.5.2")
        )
    ],
    targets: [
        .target(
            name: "mParticle-Iterable",
            dependencies: [
                .product(name: "mParticle-Apple-SDK", package: "mparticle-apple-sdk"),
                .product(name: "IterableSDK", package: "swift-sdk"),
                .product(name: "IterableAppExtensions", package: "swift-sdk")
            ],
            resources: [.process("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "include"
        ),
        .testTarget(
            name: "mParticle-IterableTests",
            dependencies: [
                "mParticle-Iterable"
            ]
        )
    ]
)
