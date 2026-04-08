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
    name: "mParticle-Leanplum",
    platforms: [ .iOS(.v15) ],
    products: [
        .library(
            name: "mParticle-Leanplum",
            type: buildXCFramework ? .dynamic : nil,
            targets: ["mParticle-Leanplum"]
        )
    ],
    dependencies: [
        mParticleAppleSDK,
        .package(url: "https://github.com/leanplum/leanplum-ios-sdk",
                 .upToNextMajor(from: "6.0.0"))
    ],
    targets: [
        .target(
            name: "mParticle-Leanplum",
            dependencies: [
                .product(name: "mParticle-Apple-SDK", package: "mparticle-apple-sdk"),
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
