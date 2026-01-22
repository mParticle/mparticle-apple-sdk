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
            sources: ["Sources/**"],
            dependencies: [
                .xcframework(path: "temp_artifacts/mParticle_Apple_SDK.xcframework"),
            ]
        )
    ],
    additionalFiles: [
        .glob(pattern: "wiremock-recordings/**/*.json"),
        .glob(pattern: "*.sh")
    ]
)
