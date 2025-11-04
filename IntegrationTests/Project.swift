import ProjectDescription

let project = Project(
    name: "IntegrationTests",
    targets: [
        .target(
            name: "IntegrationTests",
            destinations: .macOS,
            product: .commandLineTool,
            bundleId: "dev.tuist.IntegrationTests",
            buildableFolders: [
                "IntegrationTests/Sources"
            ],
            dependencies: []
        )
    ]
)
