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
    name: "mParticle-FirebaseGA4",
    platforms: [ .iOS(.v15), .tvOS(.v15) ],
    products: [
        .library(
            name: "mParticle-FirebaseGA4",
            targets: ["mParticle-FirebaseGA4"]
        )
    ],
    dependencies: [
        mParticleAppleSDK,
        .package(
            url: "https://github.com/firebase/firebase-ios-sdk",
            .upToNextMajor(from: "11.0.0")
        )
    ],
    targets: [
        .target(
            name: "mParticle-FirebaseGA4",
            dependencies: [
                .product(name: "mParticle-Apple-SDK", package: "mparticle-apple-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk")
            ],
            resources: [.process("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "include"
        ),
        .testTarget(
            name: "mParticle-FirebaseGA4-Swift-Tests",
            dependencies: ["mParticle-FirebaseGA4"],
            path: "Tests/mParticle-FirebaseGA4Test/Swift"
        ),
        .testTarget(
            name: "mParticle-FirebaseGA4-Objc-Tests",
            dependencies: ["mParticle-FirebaseGA4"],
            path: "Tests/mParticle-FirebaseGA4Test/Objc",
            resources: [.process("GoogleService-Info.plist")]
        )
    ]
)
