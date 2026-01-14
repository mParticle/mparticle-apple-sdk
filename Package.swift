// swift-tools-version:5.3

import PackageDescription

let mParticle_Apple_SDK_URL = "https://static.mparticle.com/sdk/ios/v8.41.0/mParticle_Apple_SDK.xcframework.zip"
let mParticle_Apple_SDK_Checksum = "9c2550ac04ca41fa4475b43f4b20405560cb7e16bfa4a0205d6d0e96bd3301aa"

let mParticle_Apple_SDK_NoLocation_URL =
    "https://static.mparticle.com/sdk/ios/v8.40.0/mParticle_Apple_SDK_NoLocation.xcframework.zip"
let mParticle_Apple_SDK_NoLocation_Checksum = "37d974c1b754c2f6a6b156dc05c4573c1860bb26141dc8ffcaaf2834a8dae67d"

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
