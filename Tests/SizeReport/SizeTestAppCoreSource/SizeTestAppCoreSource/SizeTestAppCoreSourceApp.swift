//
//  SizeTestAppCoreSourceApp.swift
//  SizeTestAppCoreSource
//
//  SizeTestAppWithSDK, but with the SDK built from source by SwiftPM, so it is
//  the like-for-like baseline for SizeTestAppWithRoktKit.
//  Follows steps 1-2 of the Rokt iOS SDK Integration Guide.
//

import SwiftUI
import SizeCore

@main
struct SizeTestAppCoreSourceApp: App {
    init() {
        // Step 2: Initialize the mParticle SDK
        // Reference: https://docs.rokt.com/developers/integration-guides/getting-started/ecommerce/ecommerce-ios-integration
        let options = MParticleOptions(key: "test-key", secret: "test-secret")

        // Set environment to development for testing
        options.environment = .development

        // Create identity request with empty user
        let identifyRequest = MPIdentityApiRequest.withEmptyUser()
        identifyRequest.email = "test@example.com"
        options.identifyRequest = identifyRequest

        // Set callback for identity completion
        options.onIdentifyComplete = { (result: MPIdentityApiResult?, _: Error?) in
            if let user = result?.user {
                user.setUserAttribute("app_type", value: "size_test")
            }
        }

        // Start the SDK
        MParticle.sharedInstance().start(with: options)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
