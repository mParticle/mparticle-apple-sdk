import ProjectDescription

let project = Project(
    name: "IntegrationTests",
    targets: [
        .target(
            name: "IntegrationTests",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.tuist.IntegrationTests",
            buildableFolders: [
                "Sources"
            ],
            dependencies: []
        )
    ]
)
