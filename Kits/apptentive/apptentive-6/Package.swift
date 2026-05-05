// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

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
    name: "mParticle-Apptentive",
    platforms: [ .iOS(.v15) ],
    products: [
        .library(
            name: "mParticle-Apptentive",
            type: buildXCFramework ? .dynamic : nil,
            targets: ["mParticle-Apptentive"]
        )
    ],
    dependencies: [
        mParticleAppleSDK,
        .package(
            url: "https://github.com/apptentive/apptentive-kit-ios",
            .upToNextMajor(from: "6.0.0")
        )
    ],
    targets: [
        .target(
            name: "mParticle-Apptentive",
            dependencies: [
                .product(name: "mParticle-Apple-SDK", package: "mparticle-apple-sdk"),
                .product(name: "ApptentiveKit", package: "apptentive-kit-ios")
            ],
            resources: [.process("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "include"
        ),
        .testTarget(
            name: "mParticle-ApptentiveTests",
            dependencies: [
                "mParticle-Apptentive"
            ],
        )
    ]
)
