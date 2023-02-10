// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "mParticle-Apple-SDK",
    platforms: [ .iOS(.v9), .tvOS(.v9) ],
    products: [
        .library(
            name: "mParticle-Apple-SDK",
            targets: ["mParticle-Apple-SDK"]),
        .library(
            name: "mParticle-Apple-SDK-NoLocation",
            targets: ["mParticle-Apple-SDK-NoLocation"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "mParticle-Apple-SDK",
            dependencies: [],
            path: "mParticle-Apple-SDK",
            publicHeadersPath: "./Include",
            cSettings: [
                CSetting.headerSearchPath("./**"),
                .define("NS_BLOCK_ASSERTIONS", to: "1", .when(configuration: .release))
        ]),
        .target(
            name: "mParticle-Apple-SDK-NoLocation",
            dependencies: [],
            path: "SPM/mParticle-Apple-SDK-NoLocation",
            publicHeadersPath: "./Include",
            cSettings: [
                CSetting.headerSearchPath("./**"),
                .define("NS_BLOCK_ASSERTIONS", to: "1", .when(configuration: .release)),
                .define("MPARTICLE_LOCATION_DISABLE", to: "1")
            ],
            swiftSettings: [
                .define("MPARTICLE_LOCATION_DISABLE")
        ]),
    ],
    cxxLanguageStandard: .cxx11
)
