//
//  SizeTestAppWithRoktKitApp.swift
//  SizeTestAppWithRoktKit
//
//  SizeTestAppCoreSource plus the Rokt kit, for size measurement.
//  Follows the Rokt iOS SDK Integration Guide through placement selection.
//

import SwiftUI
import SizeRoktKit

@main
struct SizeTestAppWithRoktKitApp: App {
    init() {
        // Reference: https://docs.rokt.com/developers/integration-guides/getting-started/ecommerce/ecommerce-ios-integration
        let options = MParticleOptions(key: "test-key", secret: "test-secret")
        options.environment = .development

        let identifyRequest = MPIdentityApiRequest.withEmptyUser()
        identifyRequest.email = "test@example.com"
        options.identifyRequest = identifyRequest

        options.onIdentifyComplete = { (result: MPIdentityApiResult?, _: Error?) in
            if let user = result?.user {
                user.setUserAttribute("app_type", value: "size_test")
            }
        }

        MParticle.sharedInstance().start(with: options)

        // Overlay placement, which routes through the kit to the Rokt SDK.
        MParticle.sharedInstance().rokt.selectPlacements("size_test", attributes: ["email": "test@example.com"])
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
