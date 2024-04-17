// swift-tools-version:5.3

import PackageDescription

let mParticle_Apple_SDK_URL = "https://static.mparticle.com/sdk/ios/v8.21.1/mParticle_Apple_SDK.xcframework.zip"
let mParticle_Apple_SDK_Checksum = "fb0d8019c8d293f6ef54e6b4bf49763544759fd1c00528d7b11abe231a1087ae"

let mParticle_Apple_SDK_NoLocation_URL = "https://static.mparticle.com/sdk/ios/v8.21.1/mParticle_Apple_SDK_NoLocation.xcframework.zip"
let mParticle_Apple_SDK_NoLocation_Checksum = "9a8f92bc3020e3e15dbe6d9c5a6effbedd418116f784cccbd31b9680b198af01"

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
