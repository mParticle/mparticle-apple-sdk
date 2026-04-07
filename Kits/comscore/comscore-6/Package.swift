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
    name: "mParticle-ComScore",
    platforms: [.iOS(.v15), .tvOS(.v15)],
    products: [
        .library(
            name: "mParticle-ComScore",
            targets: ["mParticle-ComScore"]
        )
    ],
    dependencies: [
        mParticleAppleSDK,
        .package(url: "https://github.com/comScore/Comscore-Swift-Package-Manager", .upToNextMajor(from: "6.12.3"))
    ],
    targets: [
        .target(
            name: "mParticle-ComScore",
            dependencies: [
                .product(name: "mParticle-Apple-SDK", package: "mparticle-apple-sdk"),
                .product(name: "ComScore", package: "Comscore-Swift-Package-Manager")
            ],
            path: "Sources/mParticle-ComScore",
            resources: [.process("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "include",
            cSettings: [.headerSearchPath("include")],
            linkerSettings: [.linkedFramework("SystemConfiguration")]
        ),
        .testTarget(
            name: "mParticle-ComScoreTests",
            dependencies: ["mParticle-ComScore"]
        )
    ]
)
