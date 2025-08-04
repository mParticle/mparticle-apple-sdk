// swift-tools-version:5.3

import PackageDescription

let mParticle_Apple_SDK_URL = "https://static.mparticle.com/sdk/ios/v8.37.0/mParticle_Apple_SDK.xcframework.zip"
let mParticle_Apple_SDK_Checksum = "f9a450ba35ed9a489a350eb889f0ac3d737b825ba10c037f13acbf67f75c0e4c"

let mParticle_Apple_SDK_NoLocation_URL = "https://static.mparticle.com/sdk/ios/v8.37.0/mParticle_Apple_SDK_NoLocation.xcframework.zip"
let mParticle_Apple_SDK_NoLocation_Checksum = "dc8b83af5787fde69cc7cf1f7c3f312fb21e9f7ea80c4067de1fbc84229d5ac6"

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
