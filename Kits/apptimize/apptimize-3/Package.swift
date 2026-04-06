// swift-tools-version:5.5
import PackageDescription

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
        .package(url: "https://github.com/mParticle/mparticle-apple-sdk",
                 branch: "workstation/9.0-Release"),
        .package(url: "https://github.com/urbanairship/apptimize-ios-kit",
                 .upToNextMajor(from: "3.5.25"))
    ],
    targets: [
        .target(
            name: "mParticle-Apptimize",
            dependencies: [
                .product(name: "mParticle-Apple-SDK", package: "mParticle-Apple-SDK"),
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
