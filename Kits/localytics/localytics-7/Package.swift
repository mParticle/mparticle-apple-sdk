// swift-tools-version:5.5
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
    name: "mParticle-Localytics",
    platforms: [ .iOS(.v15) ],
    products: [
        .library(
            name: "mParticle-Localytics",
            targets: ["mParticle-Localytics"]
        )
    ],
    dependencies: [
        mParticleAppleSDK,
        .package(url: "https://github.com/localytics/Localytics-swiftpm",
                 .upToNextMajor(from: "7.0.0"))
    ],
    targets: [
        .target(
            name: "mParticle-Localytics",
            dependencies: [
                .product(name: "mParticle-Apple-SDK", package: "mparticle-apple-sdk"),
                .product(name: "Localytics", package: "Localytics-swiftpm")
            ],
            resources: [.process("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "include",
            cSettings: [
                .unsafeFlags([
                    "-Wno-non-modular-include-in-framework-module",
                    "-Wno-error=non-modular-include-in-framework-module"
                ])
            ],
            linkerSettings: [
                .linkedFramework("CoreLocation")
            ]
        ),
        .testTarget(
            name: "mParticle-LocalyticsTests",
            dependencies: [
                "mParticle-Localytics"
            ]
        )
    ]
)
