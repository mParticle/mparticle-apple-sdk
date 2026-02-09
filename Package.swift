// swift-tools-version:5.5

import PackageDescription

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
        // Objective-C SDK - source-based distribution
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
    ]
)
