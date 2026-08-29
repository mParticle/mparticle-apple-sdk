// swift-tools-version:5.3

import PackageDescription

let mParticle_Apple_SDK_URL = "https://github.com/mParticle/mparticle-apple-sdk/releases/download/v8.15.2/mParticle_Apple_SDK.xcframework.zip"
let mParticle_Apple_SDK_Checksum = "82fc9874005a1297a4d40496a38d14dc36cae4c5aed534e8f5d04c3652f1b205"

let mParticle_Apple_SDK_NoLocation_URL = "https://github.com/mParticle/mparticle-apple-sdk/releases/download/v8.15.2/mParticle_Apple_SDK_NoLocation.xcframework.zip"
let mParticle_Apple_SDK_NoLocation_Checksum = "db2e29734420de551821ed81456622b3d9d1361754579c4002b1fb6bfbbfef42"

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
