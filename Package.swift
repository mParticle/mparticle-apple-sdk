// swift-tools-version:5.3

import PackageDescription

let mParticle_Apple_SDK_URL = "https://github.com/mParticle/mparticle-apple-sdk/releases/download/v8.23.2/mParticle_Apple_SDK.xcframework.zip"
let mParticle_Apple_SDK_Checksum = "4203313ecf5f27be2434f37af39d10898159a3dda6cca8c21ff237a272bf36e8"

let mParticle_Apple_SDK_NoLocation_URL = "https://github.com/mParticle/mparticle-apple-sdk/releases/download/v8.23.2/mParticle_Apple_SDK_NoLocation.xcframework.zip"
let mParticle_Apple_SDK_NoLocation_Checksum = "aca86f77832cbd91933a410037659f1bfda73315945adc32a64dca78aa553eee"

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
