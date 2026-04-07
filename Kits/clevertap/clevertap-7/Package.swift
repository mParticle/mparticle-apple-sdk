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
    name: "mParticle-CleverTap",
    platforms: [ .iOS(.v15) ],
    products: [
        .library(name: "mParticle-CleverTap", targets: ["mParticle-CleverTap"])
    ],
    dependencies: [
        mParticleAppleSDK,
        .package(url: "https://github.com/CleverTap/clevertap-ios-sdk", .upToNextMajor(from: "7.0.0"))
    ],
    targets: [
        .target(
            name: "mParticle-CleverTap",
            dependencies: [
                .product(name: "mParticle-Apple-SDK", package: "mparticle-apple-sdk"),
                .product(name: "CleverTapSDK", package: "clevertap-ios-sdk")
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
        .testTarget(name: "mParticle-CleverTapTests", dependencies: ["mParticle-CleverTap"])
    ]
)
