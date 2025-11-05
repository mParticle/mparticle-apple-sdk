import ProjectDescription

let project = Project(
    name: "IntegrationTests",
    targets: [
        .target(
            name: "IntegrationTests",
            destinations: .iOS,
            product: .app,
            bundleId: "com.mparticle.IntegrationTests",
            buildableFolders: [
                "Sources"
            ],
            dependencies: [
                .external(name: "mParticle-Apple-SDK")
            ]
        )
    ]
)
