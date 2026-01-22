// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MyModules",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        .library(name: "A", targets: ["A"]),
        .library(name: "B", targets: ["B"]),
        .library(name: "BObjC", targets: ["BObjC"]),
        .executable(name: "ClientAppExample", targets: ["ClientAppExample"]),
    ],
    targets: [
        // Swift core - pure Swift module
        .target(
            name: "B"
        ),

        // Swift bridge - ObjC-friendly API
        .target(
            name: "BObjC",
            dependencies: ["B"]
        ),

        // Objective-C target
        .target(
            name: "A",
            dependencies: ["BObjC"],
            publicHeadersPath: "include"
        ),
        
        // Executable example
        .executableTarget(
            name: "ClientAppExample",
            dependencies: ["A"]
        ),
        
        // Tests
        .testTarget(
            name: "MyModulesTests",
            dependencies: ["A", "B", "BObjC"]
        )
    ]
)
