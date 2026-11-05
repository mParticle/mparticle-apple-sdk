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
    name: "mParticle-Leanplum",
    platforms: [ .iOS(.v15) ],
    products: [
        .library(
            name: "mParticle-Leanplum",
            targets: ["mParticle-Leanplum"]
        )
    ],
    dependencies: [
        mParticleAppleSDK,
        .package(url: "https://github.com/leanplum/leanplum-ios-sdk",
                 .upToNextMajor(from: "6.0.0")),
        // Leanplum 6 declares iOS 9 but takes any CleverTap 7.x, and CleverTap 7.9.1 raised its
        // minimum to iOS 15, which fails the Leanplum target's build. Hold CleverTap below it.
        .package(url: "https://github.com/CleverTap/clevertap-ios-sdk",
                 "7.1.1"..<"7.9.1")
    ],
    targets: [
        .target(
            name: "mParticle-Leanplum",
            dependencies: [
                .product(name: "mParticle-Apple-SDK", package: "mparticle-apple-sdk"),
                .product(name: "Leanplum", package: "leanplum-ios-sdk"),
                // Already linked through Leanplum. Naming it keeps the cap above in force for apps
                // that consume this package, since SwiftPM ignores their dependencies' unused packages.
                .product(name: "CleverTapSDK", package: "clevertap-ios-sdk")
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
