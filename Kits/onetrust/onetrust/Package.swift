// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.
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
    name: "mParticle-OneTrust",
    platforms: [ .iOS(.v15), .tvOS(.v15) ],
    products: [
        .library(
            name: "mParticle-OneTrust",
            type: buildXCFramework ? .dynamic : nil,
            targets: ["mParticle-OneTrust"]
        )
    ],
    dependencies: [
        mParticleAppleSDK,
        // iOS OneTrust
        .package(
            url: "https://github.com/Zentrust/OTPublishersHeadlessSDK",
            "0.0.0"..<"999999.0.0"
        ),

        // tvOS OneTrust
        .package(
            url: "https://github.com/Zentrust/OTPublishersHeadlessSDKtvOS",
            "0.0.0"..<"999999.0.0"
        )
    ],
    targets: [
        .target(
            name: "mParticle-OneTrust",
            dependencies: [
                .product(name: "mParticle-Apple-SDK", package: "mparticle-apple-sdk"),
                .product(
                    name: "OTPublishersHeadlessSDK",
                    package: "OTPublishersHeadlessSDK",
                    condition: .when(platforms: [.iOS])
                ),
                .product(
                    name: "OTPublishersHeadlessSDKtvOS",
                    package: "OTPublishersHeadlessSDKtvOS",
                    condition: .when(platforms: [.tvOS])
                )
            ],
            resources: [.process("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "include"
        ),
        .testTarget(
            name: "mParticle-OneTrustTests",
            dependencies: [
                "mParticle-OneTrust"
            ]
        )
    ]
)
