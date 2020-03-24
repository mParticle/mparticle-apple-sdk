// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "mParticle-Apple-SDK",
    platforms: [ .iOS(.v8), .tvOS(.v9) ],
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
        ]),
    ],
    cxxLanguageStandard: .cxx11
)
