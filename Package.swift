// swift-tools-version:5.3

import PackageDescription

let mParticle_Apple_SDK_URL = "https://static.mparticle.com/sdk/ios/v8.36.0/mParticle_Apple_SDK.xcframework.zip"
let mParticle_Apple_SDK_Checksum = "6cc700ccf09f9b7b46f7812448f2e787ab3b1442b52e0112d228ee00939287a6"

let mParticle_Apple_SDK_NoLocation_URL = "https://static.mparticle.com/sdk/ios/v8.36.0/mParticle_Apple_SDK_NoLocation.xcframework.zip"
let mParticle_Apple_SDK_NoLocation_Checksum = "a2e1e9d5fad86a38ee0f1c7c043c33392b5d3b256cfc1e334c3aa17f6b65300a"

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
