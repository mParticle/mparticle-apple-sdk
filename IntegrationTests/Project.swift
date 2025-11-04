import ProjectDescription

let project = Project(
    name: "IntegrationTests",
    targets: [
        .target(
            name: "IntegrationTests",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.tuist.IntegrationTests",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                ]
            ),
            buildableFolders: [
                "IntegrationTests/Sources",
                "IntegrationTests/Resources",
            ],
            dependencies: []
        ),
        .target(
            name: "IntegrationTestsTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.IntegrationTestsTests",
            infoPlist: .default,
            buildableFolders: [
                "IntegrationTests/Tests"
            ],
            dependencies: [.target(name: "IntegrationTests")]
        ),
    ]
)
