import ProjectDescription

let project = Project(
    name: "IntegrationTests",
    packages: [
        .package(path: "../")
    ],
    targets: [
        .target(
            name: "IntegrationTests",
            destinations: .iOS,
            product: .app,
            bundleId: "com.mparticle.IntegrationTests",
            deploymentTargets: .iOS("15.0"),
            sources: ["Sources/**"],
            dependencies: [
                .package(product: "mParticle-Apple-SDK-NoLocation", type: .runtime)
            ]
        )
    ],
    additionalFiles: [
        .glob(pattern: "wiremock-recordings/**/*.json"),
        .glob(pattern: "*.sh")
    ]
)
