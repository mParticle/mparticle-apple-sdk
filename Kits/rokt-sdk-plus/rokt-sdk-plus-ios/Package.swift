// swift-tools-version: 5.9

import Foundation
import PackageDescription

let version = "9.1.0"

let useLocalVersion = ProcessInfo.processInfo.environment["USE_LOCAL_VERSION"] != nil

let mParticleRoktKitURL = "https://github.com/mparticle-integrations/mp-apple-integration-rokt.git"

let mParticleRoktDependency: Package.Dependency = {
    if useLocalVersion {
        return .package(path: "../../rokt/rokt")
    }
    if version.isEmpty {
        return .package(url: mParticleRoktKitURL, branch: "main")
    }
    return .package(url: mParticleRoktKitURL, .upToNextMajor(from: Version(version)!))
}()

let mParticleRoktProduct: Target.Dependency = useLocalVersion
    ? .product(name: "mParticle-Rokt", package: "rokt")
    : .product(name: "mParticle-Rokt", package: "mp-apple-integration-rokt")

let package = Package(
    name: "RoktSDKPlus",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "RoktSDKPlus",
            targets: ["RoktSDKPlus"]
        )
    ],
    dependencies: [
        mParticleRoktDependency,
        .package(
            url: "https://github.com/ROKT/rokt-payment-extension-ios.git",
            .upToNextMajor(from: "2.0.0")
        )
    ],
    targets: [
        .target(
            name: "RoktSDKPlus",
            dependencies: [
                mParticleRoktProduct,
                .product(name: "RoktPaymentExtension", package: "rokt-payment-extension-ios")
            ],
            path: "Sources/RoktSDKPlus"
        )
    ]
)
