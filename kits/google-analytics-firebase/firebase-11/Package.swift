// swift-tools-version:5.9
import PackageDescription

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
        .package(
            url: "https://github.com/mParticle/mparticle-apple-sdk",
            branch: "workstation/9.0-Release"
        ),
        .package(
            url: "https://github.com/firebase/firebase-ios-sdk",
            .upToNextMajor(from: "11.0.0")
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
            dependencies: ["mParticle-Firebase"]
        )
    ]
)
