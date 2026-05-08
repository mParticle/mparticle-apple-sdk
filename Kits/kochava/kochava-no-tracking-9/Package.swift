// swift-tools-version:5.5

import Foundation
import PackageDescription

let version = "9.0.0"

let useLocalVersion = ProcessInfo.processInfo.environment["USE_LOCAL_VERSION"] != nil
let buildXCFramework = ProcessInfo.processInfo.environment["BUILD_XCFRAMEWORK"] != nil

let mParticleAppleSDK: Package.Dependency = {
    if useLocalVersion {
        return .package(name: "mparticle-apple-sdk", path: "../../../")
    }

    let url = "https://github.com/mParticle/mparticle-apple-sdk"
    if version.isEmpty {
        return .package(url: url, branch: "main")
    }
    return .package(url: url, .upToNextMajor(from: Version(version)!))
}()

let package = Package(
    name: "mParticle-Kochava",
    platforms: [ .iOS(.v15), .tvOS(.v15) ],
    products: [
        .library(
            name: "mParticle-Kochava",
            type: buildXCFramework ? .dynamic : nil,
            targets: ["mParticle-Kochava"]
        )
    ],
    dependencies: [
        mParticleAppleSDK,
        .package(
            url: "https://github.com/Kochava/Apple-SwiftPackage-KochavaNetworking-XCFramework",
            .upToNextMajor(from: "9.0.0")
        ),
        .package(
            url: "https://github.com/Kochava/Apple-SwiftPackage-KochavaMeasurement-XCFramework",
            .upToNextMajor(from: "9.0.0")
        )
    ],
    targets: [
        .target(
            name: "mParticle-Kochava",
            dependencies: [
                .product(name: "mParticle-Apple-SDK", package: "mparticle-apple-sdk"),
                .product(name: "KochavaNetworking", package: "Apple-SwiftPackage-KochavaNetworking-XCFramework"),
                .product(name: "KochavaMeasurement", package: "Apple-SwiftPackage-KochavaMeasurement-XCFramework")
            ],
            resources: [.process("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "include"
        ),
        .testTarget(
            name: "mParticle-KochavaTests",
            dependencies: [
                "mParticle-Kochava"
            ]
        )
    ]
)
