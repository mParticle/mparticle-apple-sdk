// swift-tools-version:5.3

import PackageDescription

let mParticle_Apple_SDK_URL = "https://github.com/mParticle/mparticle-apple-sdk/releases/download/v8.13.0/mParticle_Apple_SDK.xcframework.zip"
let mParticle_Apple_SDK_Checksum = "52e67d409428fedea2d9c59409634e8a7a5941207259bc81677a7aa6f0512626"

let mParticle_Apple_SDK_NoLocation_URL = "https://github.com/mParticle/mparticle-apple-sdk/releases/download/v8.13.0/mParticle_Apple_SDK_NoLocation.xcframework.zip"
let mParticle_Apple_SDK_NoLocation_Checksum = "6fbaccd6f88990476204d4bbcf753100ecdbb10a808f8b79f4c2e2333e992916"

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
