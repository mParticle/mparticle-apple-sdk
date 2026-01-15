//
//  SizeTestAppWithSDKApp.swift
//  SizeTestAppWithSDK
//
//  Minimal app with mParticle SDK integration for size measurement.
//  Follows steps 1-2 of the Rokt iOS SDK Integration Guide.
//

import SwiftUI
import mParticle_Apple_SDK

@main
struct SizeTestAppWithSDKApp: App {
    
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
