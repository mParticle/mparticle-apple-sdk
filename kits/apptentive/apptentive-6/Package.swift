// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "mParticle-Apptentive",
    platforms: [ .iOS(.v13) ],
    products: [
        .library(
            name: "mParticle-Apptentive",
            targets: ["mParticle-Apptentive"]),
    ],
    dependencies: [
        .package(url: "https://github.com/mParticle/mparticle-apple-sdk",
                 .upToNextMajor(from: "8.22.0")),
        .package(url: "https://github.com/apptentive/apptentive-kit-ios",
                 .upToNextMajor(from: "6.6.0")),
    ],
    targets: [
        .target(
            name: "mParticle-Apptentive",
            dependencies: [
                .product(name: "mParticle-Apple-SDK", package: "mparticle-apple-sdk"),
                .product(name: "ApptentiveKit", package: "apptentive-kit-ios"),
            ],
            path: "mParticle-Apptentive",
            exclude: ["Info.plist"],
            resources: [.process("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "."),
    ])
