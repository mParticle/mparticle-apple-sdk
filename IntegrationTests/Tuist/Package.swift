// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        productTypes: [
            "mParticle-Apple-SDK": .framework
        ]
    )
#endif

let package = Package(
    name: "IntegrationTests",
    dependencies: [
        .package(path: "../..")
    ]
)
