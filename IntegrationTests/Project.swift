import ProjectDescription

let project = Project(
    name: "IntegrationTests",
    targets: [
        .target(
            name: "IntegrationTests",
            destinations: .iOS,
            product: .app,
            bundleId: "com.mparticle.IntegrationTests",
            deploymentTargets: .iOS("14.0"),
            buildableFolders: [
                "Sources"
            ],
            dependencies: [
                .external(name: "mParticle-Apple-SDK")
            ]
        )
    ]
)
