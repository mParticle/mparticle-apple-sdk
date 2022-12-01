// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "mParticle-Apple-SDK",
    platforms: [ .iOS(.v11), .tvOS(.v11) ],
    products: [
        .library(
            name: "mParticle-Apple-SDK",
            targets: ["mParticle-Apple-SDK"]),
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
    ],
    cxxLanguageStandard: .cxx11
)
