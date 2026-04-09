// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

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
    name: "mParticle-AppsFlyer",
    platforms: [ .iOS(.v15) ],
    products: [
        .library(
            name: "mParticle-AppsFlyer",
            targets: ["mParticle-AppsFlyer"]
        )
    ],
    dependencies: [
        mParticleAppleSDK,
        .package(url: "https://github.com/AppsFlyerSDK/AppsFlyerFramework-Static",
                 .upToNextMajor(from: "6.0.0")),
        .package(
            url: "https://github.com/erikdoe/ocmock",
            branch: "master"
        )
    ],
    targets: [
        .target(
            name: "mParticle-AppsFlyer",
            dependencies: [
                .product(name: "mParticle-Apple-SDK", package: "mparticle-apple-sdk"),
                .product(name: "AppsFlyerLib-Static", package: "AppsFlyerFramework-Static")
            ],
            resources: [.process("PrivacyInfo.xcprivacy")]
        ),
        .testTarget(
            name: "mParticle-AppsFlyerTests",
            dependencies: [
                "mParticle-AppsFlyer",
                .product(name: "OCMock", package: "ocmock")
            ],
        )
    ]
)
