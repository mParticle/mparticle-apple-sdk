// swift-tools-version: 5.9
import PackageDescription

let version = "9.2.1"

let package = Package(
    name: "RoktPaymentExtension",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "RoktPaymentExtension", targets: ["RoktPaymentExtension"])
    ],
    dependencies: [
        .package(url: "https://github.com/ROKT/rokt-contracts-apple.git", from: "2.0.2"),
        .package(url: "https://github.com/stripe/stripe-ios.git", from: "25.0.0")
    ],
    targets: [
        .target(
            name: "RoktPaymentExtension",
            dependencies: [
                .product(name: "RoktContracts", package: "rokt-contracts-apple"),
                .product(name: "StripeApplePay", package: "stripe-ios"),
                .product(name: "StripePayments", package: "stripe-ios")
            ]
        ),
        .testTarget(
            name: "RoktPaymentExtensionTests",
            dependencies: ["RoktPaymentExtension"]
        )
    ]
)
