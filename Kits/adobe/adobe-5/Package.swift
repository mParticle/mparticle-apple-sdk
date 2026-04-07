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
    name: "mParticle-Adobe",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "mParticle-Adobe",
            targets: ["mParticle-Adobe"]
        )
    ],
    dependencies: [
        mParticleAppleSDK
    ],
    targets: [
        .target(
            name: "mParticle-Adobe",
            dependencies: [
                .product(name: "mParticle-Apple-SDK", package: "mparticle-apple-sdk")
            ],
            path: "Sources/mParticle-Adobe",
            resources: [.process("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "include"
        ),
        .testTarget(
            name: "mParticle-AdobeTests",
            dependencies: [
                "mParticle-Adobe"
            ]
        )
    ]
)
