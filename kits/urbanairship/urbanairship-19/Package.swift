// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "mParticle-UrbanAirship",
    platforms: [ .iOS(.v16) ],
    products: [
        .library(
            name: "mParticle-UrbanAirship",
            targets: ["mParticle-UrbanAirship"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/mParticle/mparticle-apple-sdk",
            branch: "workstation/9.0-Release"
        ),
        .package(url: "https://github.com/urbanairship/ios-library",
                 from: "20.0.3"),
        .package(url: "https://github.com/erikdoe/ocmock",
                 branch: "master"),
    ],
    targets: [
        .target(
            name: "mParticle-UrbanAirship",
            dependencies: [
                .product(name: "mParticle-Apple-SDK", package: "mparticle-apple-sdk"),
                .product(name: "AirshipObjectiveC", package: "ios-library"),
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
