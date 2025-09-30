// swift-tools-version:5.3

import PackageDescription

let mParticle_Apple_SDK_URL = "https://github.com/mParticle/mparticle-apple-sdk/raw/test/spm-static-linking/mParticle_Apple_SDK.xcframework.zip"
let mParticle_Apple_SDK_Checksum = "913a8bf184b071d271a9a1db2cb375287fdcbb2dd2a747fb9b8ef2c39064f946"

let mParticle_Apple_SDK_NoLocation_URL = "https://github.com/mParticle/mparticle-apple-sdk/raw/test/spm-static-linking/mParticle_Apple_SDK_NoLocation.xcframework.zip"
let mParticle_Apple_SDK_NoLocation_Checksum = "15b3231ed3b531bd5beac5c993f30a2bbc4f61725458a81680844543e38ed457"

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
        )
    ]
)
