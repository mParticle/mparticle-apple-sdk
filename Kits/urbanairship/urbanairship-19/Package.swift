// swift-tools-version:6.0
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
    name: "mParticle-UrbanAirship",
    platforms: [ .iOS(.v15) ],
    products: [
        .library(
            name: "mParticle-UrbanAirship",
            type: buildXCFramework ? .dynamic : nil,
            targets: ["mParticle-UrbanAirship"]
        )
    ],
    dependencies: [
        mParticleAppleSDK,
        .package(url: "https://github.com/urbanairship/ios-library",
                 .upToNextMajor(from: "19.1.0"))
    ],
    targets: [
        .target(
            name: "mParticle-UrbanAirship",
            dependencies: [
                .product(name: "mParticle-Apple-SDK", package: "mparticle-apple-sdk"),
                .product(name: "AirshipObjectiveC", package: "ios-library")
            ],
            resources: [.process("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "."
        ),
        .testTarget(
            name: "mParticle-UrbanAirshipTests",
            dependencies: [
                "mParticle-UrbanAirship"
            ]
        )
    ]
)
