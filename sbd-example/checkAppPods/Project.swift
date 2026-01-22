import ProjectDescription

let project = Project(
    name: "CheckAppPods",
    targets: [
        .target(
            name: "CheckAppPods",
            destinations: .iOS,
            product: .app,
            bundleId: "com.example.CheckAppPods",
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
                // CocoaPods dependencies will be added via Podfile
                // Tuist will automatically create workspace with Pods
            ]
        )
    ],
    additionalFiles: [
        "Podfile"
    ]
)
