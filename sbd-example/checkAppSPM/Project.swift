import ProjectDescription

let project = Project(
    name: "CheckAppSPM",
    packages: [
        // Local SPM package from check folder
        .package(path: "../check")
    ],
    targets: [
        .target(
            name: "CheckAppSPM",
            destinations: .iOS,
            product: .app,
            bundleId: "com.example.CheckAppSPM",
            deploymentTargets: .iOS("14.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                ]
            ),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            dependencies: [
                // Dependency on module A via SPM
                .package(product: "A", type: .runtime)
            ]
        )
    ]
)
