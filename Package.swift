// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "mParticle-Apple-SDK",
    platforms: [ .iOS(.v9), .tvOS(.v9) ],
    products: [
        .library(
            name: "mParticle-Apple-SDK",
            targets: ["mParticle_Apple_SDK"]),
        .library(
            name: "mParticle-Apple-SDK-NoLocation",
            targets: ["mParticle_Apple_SDK_NoLocation"]),
    ],
    dependencies: [
    ],
    targets: [
        .binaryTarget(
            name: "mParticle_Apple_SDK",
            url: "https://github.com/einsteinx2/mparticle-apple-sdk/releases/download/v8.12.0/mParticle_Apple_SDK.xcframework.zip",
            checksum: "1927586494f7f6aba345fe4bf409ec46e3411068614cd46bb369d2688d6326be"
        ),
        .binaryTarget(
            name: "mParticle_Apple_SDK_NoLocation",
            url: "https://github.com/einsteinx2/mparticle-apple-sdk/releases/download/v8.12.0/mParticle_Apple_SDK_NoLocation.xcframework.zip",
            checksum: "fca73c3e6ab397f815ee58a64460648c625798a68439cfe999f64880e85c2d87"
        ),
    ]
)
