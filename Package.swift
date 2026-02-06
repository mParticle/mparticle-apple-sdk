// swift-tools-version:5.5

import PackageDescription

let mParticle_Apple_SDK_URL =
    "https://static.mparticle.com/sdk/ios/v8.41.1/mParticle_Apple_SDK_.xcframework.zip"
let mParticle_Apple_SDK_Checksum = "c9aeeb511c407604dd31137e5c714120404ca8d884fd965c4e919b0060d52e12"

let package = Package(
    name: "mParticle-Apple-SDK",
    platforms: [.iOS(.v15), .tvOS(.v15)],
    products: [
        .library(
            name: "mParticle-Apple-SDK",
            targets: ["mParticle_Apple_SDK"]
        ),
    ],
    dependencies: [
    ],
    targets: [
        // Swift-only components
        .target(
            name: "mParticle_Apple_SDK_Swift",
            path: "mParticle-Apple-SDK-Swift/Sources",
        ),
        // Objective-C SDK (NoLocation variant) - source-based distribution
        .target(
            name: "mParticle_Apple_SDK",
            dependencies: ["mParticle_Apple_SDK_Swift"],
            path: "mParticle-Apple-SDK",
            sources: nil,
            resources: [
                .process("../PrivacyInfo.xcprivacy")
            ],
            publicHeadersPath: "Include",
            cSettings: [
                .headerSearchPath("."),
                .headerSearchPath("Include"),
                .headerSearchPath("Logger"),
                .headerSearchPath("Network"),
                .headerSearchPath("Identity"),
                .headerSearchPath("Event"),
                .headerSearchPath("Ecommerce"),
                .headerSearchPath("Kits"),
                .headerSearchPath("Utils"),
                .headerSearchPath("Persistence"),
                .headerSearchPath("Consent"),
                .headerSearchPath("Custom Modules"),
                .headerSearchPath("AppNotifications"),
                .headerSearchPath("Data Model"),
                .headerSearchPath("Libraries/Reachability")
            ],
            linkerSettings: [
                .linkedFramework("Foundation"),
                .linkedFramework("UIKit", .when(platforms: [.iOS])),
                .linkedFramework("WebKit", .when(platforms: [.iOS])),
                .linkedFramework("UserNotifications", .when(platforms: [.iOS]))
            ]
        ),
        // Binary target (kept for backward compatibility or as alternative)
        .binaryTarget(
            name: "mParticle_Apple_SDK_Binary",
            url: mParticle_Apple_SDK_URL,
            checksum: mParticle_Apple_SDK_Checksum
        ),
    ]
)
