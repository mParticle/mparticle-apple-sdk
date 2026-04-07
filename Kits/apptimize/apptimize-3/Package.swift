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
    name: "mParticle-Apptimize",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "mParticle-Apptimize",
            targets: ["mParticle-Apptimize"]
        )
    ],
    dependencies: [
        mParticleAppleSDK,
        .package(url: "https://github.com/urbanairship/apptimize-ios-kit",
                 .upToNextMajor(from: "3.5.25"))
    ],
    targets: [
        .target(
            name: "mParticle-Apptimize",
            dependencies: [
                .product(name: "mParticle-Apple-SDK", package: "mparticle-apple-sdk"),
                .product(name: "Apptimize", package: "apptimize-ios-kit")
            ],
            path: "Sources/mParticle-Apptimize",
            resources: [.process("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "include"
        ),
        .testTarget(
            name: "mParticle-ApptimizeTests",
            dependencies: [
                "mParticle-Apptimize"
            ]
        )
    ]
)
