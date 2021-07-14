// swift-tools-version:5.1

import PackageDescription

#if swift(>=5.3)
let ios = SupportedPlatform.iOS(.v9)
#else
let ios = SupportedPlatform.iOS(.v8)
#endif

let package = Package(
    name: "mParticle-Apple-SDK",
    platforms: [ ios, .tvOS(.v9) ],
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
