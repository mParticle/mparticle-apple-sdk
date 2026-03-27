// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "mParticle-ComScore",
    platforms: [.iOS(.v15), .tvOS(.v15)],
    products: [
        .library(
            name: "mParticle-ComScore",
            targets: ["mParticle-ComScore"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/mParticle/mparticle-apple-sdk",
            branch: "workstation/9.0-Release"
        ),
        .package(url: "https://github.com/comScore/Comscore-Swift-Package-Manager", .upToNextMajor(from: "6.12.3"))
    ],
    targets: [
        .target(
            name: "mParticle-ComScore",
            dependencies: [
                .product(name: "mParticle-Apple-SDK", package: "mparticle-apple-sdk"),
                .product(name: "ComScore", package: "Comscore-Swift-Package-Manager")
            ],
            path: "Sources/mParticle-ComScore",
            publicHeadersPath: "include",
            cSettings: [.headerSearchPath("include")],
            linkerSettings: [.linkedFramework("SystemConfiguration")]
        ),
        .testTarget(
            name: "mParticle-ComScoreTests",
            dependencies: ["mParticle-ComScore"]
        )
    ]
)
