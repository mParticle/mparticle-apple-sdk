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
    name: "mParticle-Firebase",
    platforms: [ .iOS(.v15) ],
    products: [
        .library(
            name: "mParticle-Firebase",
            targets: ["mParticle-Firebase"]
        )
    ],
    dependencies: [
        mParticleAppleSDK,
        .package(
            url: "https://github.com/firebase/firebase-ios-sdk",
            .upToNextMajor(from: "12.0.0")
        )
    ],
    targets: [
        .target(
            name: "mParticle-Firebase",
            dependencies: [
                .product(name: "mParticle-Apple-SDK", package: "mparticle-apple-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk")
            ],
            resources: [.process("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "include"
        ),
        .testTarget(
            name: "mParticle-FirebaseTests",
            dependencies: [
                "mParticle-Firebase",
                .product(name: "FirebaseCore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk")
            ],
            resources: [.process("GoogleService-Info.plist")]
        )
    ]
)
