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
    name: "mParticle-Radar",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "mParticle-Radar", targets: ["mParticle-Radar"])
    ],
    dependencies: [
        mParticleAppleSDK,
        .package(url: "https://github.com/radarlabs/radar-sdk-ios-spm", .upToNextMajor(from: "3.25.0"))
    ],
    targets: [
        .target(
            name: "mParticle-Radar",
            dependencies: [
                .product(name: "mParticle-Apple-SDK", package: "mparticle-apple-sdk"),
                .product(name: "RadarSDK", package: "radar-sdk-ios-spm")
            ],
            resources: [.process("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "include"
        ),
        .testTarget(name: "mParticle-RadarTests", dependencies: ["mParticle-Radar"])
    ]
)
