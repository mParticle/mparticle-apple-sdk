// swift-tools-version:5.3

import PackageDescription

let mParticle_Apple_SDK_URL = "https://github.com/mParticle/mparticle-apple-sdk/releases/download/v8.50.0/mParticle_Apple_SDK.xcframework.zip"
let mParticle_Apple_SDK_Checksum = "1927586494f7f6aba345fe4bf409ec46e3411068614cd46bb369d2688d6326be"

let mParticle_Apple_SDK_NoLocation_URL = "https://github.com/mParticle/mparticle-apple-sdk/releases/download/v8.50.0/mParticle_Apple_SDK_NoLocation.xcframework.zip"
let mParticle_Apple_SDK_NoLocation_Checksum = "fca73c3e6ab397f815ee58a64460648c625798a68439cfe999f64880e85c2d87"

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
            url: mParticle_Apple_SDK_URL,
            checksum: mParticle_Apple_SDK_Checksum
        ),
        .binaryTarget(
            name: "mParticle_Apple_SDK_NoLocation",
            url: mParticle_Apple_SDK_NoLocation_URL,
            checksum: mParticle_Apple_SDK_NoLocation_Checksum
        ),
    ]
)
