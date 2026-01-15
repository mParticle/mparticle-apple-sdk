// swift-tools-version:5.3
//
// LocalSDK Package
//
// This package wraps a locally-built mParticle SDK xcframework.
// The xcframework is built from source by measure_size.sh before
// the test apps are compiled, ensuring we measure actual SDK
// source code changes rather than pre-built binaries from CDN.
//

import PackageDescription

let package = Package(
    name: "LocalSDK",
    platforms: [.iOS(.v15), .tvOS(.v15)],
    products: [
        .library(
            name: "mParticle-Apple-SDK",
            targets: ["mParticle_Apple_SDK"]
        )
    ],
    targets: [
        // References the xcframework built from source by measure_size.sh
        .binaryTarget(
            name: "mParticle_Apple_SDK",
            path: "../build/mParticle_Apple_SDK.xcframework"
        )
    ]
)
