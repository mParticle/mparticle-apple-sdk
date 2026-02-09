// swift-tools-version:5.3

import PackageDescription

let mParticle_Apple_SDK_URL = "https://static.mparticle.com/sdk/ios/v8.42.0/mParticle_Apple_SDK.xcframework.zip"
let mParticle_Apple_SDK_Checksum = "76899bed916384639366499bb582c0a142782ed341207e62bbeb07b0142042ed"

let mParticle_Apple_SDK_NoLocation_URL =
    "https://static.mparticle.com/sdk/ios/v8.42.0/mParticle_Apple_SDK_NoLocation.xcframework.zip"
let mParticle_Apple_SDK_NoLocation_Checksum = "e64008a8ab4af84bbf1b4585d791f9db103cc48a3ef7d204d5239a3372b82dab"

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
