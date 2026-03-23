// swift-tools-version:5.3

import PackageDescription

let mParticle_Apple_SDK_URL = "https://static.mparticle.com/sdk/ios/v8.44.3/mParticle_Apple_SDK.xcframework.zip"
let mParticle_Apple_SDK_Checksum = "d07eba0c603498bcc61829b21697150be46f16baddd05edceb5cde62dc24754e"

let mParticle_Apple_SDK_NoLocation_URL =
    "https://static.mparticle.com/sdk/ios/v8.44.3/mParticle_Apple_SDK_NoLocation.xcframework.zip"
let mParticle_Apple_SDK_NoLocation_Checksum = "2c7168b29226f73c3d1806f94fba4b13aa89092b32fe866a5c7b85f6caaecd15"

let package = Package(
    name: "mParticle-Apple-SDK",
    platforms: [.iOS(.v9), .tvOS(.v9)],
    products: [
        .library(
            name: "mParticle-Apple-SDK",
            targets: ["mParticle_Apple_SDK"]
        ),
        .library(
            name: "mParticle-Apple-SDK-NoLocation",
            targets: ["mParticle_Apple_SDK_NoLocation"]
        ),
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
