// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "mParticle-OneTrust",
    platforms: [ .iOS(.v11), .tvOS(.v11) ],
    products: [
        .library(
            name: "mParticle-OneTrust",
            targets: ["mParticle-OneTrust"]
        ),
    ],
    dependencies: [
        .package(name: "mParticle-Apple-SDK",
                 url: "https://github.com/mParticle/mparticle-apple-sdk",
                 .upToNextMajor(from: "8.22.0")),
        // OneTrust's unique version formating makes automatic support up to the next major version no longer possible. Additionally, as a specific version is required in their UI for their SDK to function we do not include a specific version of the 'OTPublishersHeadlessSDK' here and expect the version to be defined in the client app.
    ],
    targets: [
        .target(
            name: "mParticle-OneTrust",
            dependencies: ["mParticle-Apple-SDK"],
            path: "mParticle-OneTrust",
            exclude: ["Info.plist"],
            resources: [.process("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "."
        ),
    ]
)
