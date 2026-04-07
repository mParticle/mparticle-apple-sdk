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
    name: "mParticle-Singular",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "mParticle-Singular",
            targets: ["mParticle-Singular"]
        )
    ],
    dependencies: [
        mParticleAppleSDK,
        .package(url: "https://github.com/singular-labs/Singular-iOS-SDK",
                 .upToNextMajor(from: "12.4.1"))
    ],
    targets: [
        .target(
            name: "mParticle-Singular",
            dependencies: [
                .product(name: "mParticle-Apple-SDK", package: "mparticle-apple-sdk"),
                .product(name: "Singular", package: "Singular-iOS-SDK")
            ],
            path: "Sources/mParticle-Singular",
            resources: [.process("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "include",
            linkerSettings: [
                .linkedFramework("StoreKit")
            ]
        ),
        .testTarget(
            name: "mParticle-SingularTests",
            dependencies: [
                "mParticle-Singular"
            ]
        )
    ]
)
