import SwiftUI
import mParticle_Apple_SDK

@main
struct SPMSwiftExampleApp: App {
    init() {
        let options = MParticleOptions(
            key: "REPLACE_ME",
            secret: "REPLACE_ME"
        )
        options.environment = .development
        options.logLevel = .debug
        let networkOptions = MPNetworkOptions()
        networkOptions.pinningDisabled = true
        options.networkOptions = networkOptions
        MParticle.sharedInstance().start(with: options)

        let identityRequest = MPIdentityApiRequest.withEmptyUser()
        identityRequest.email = "jenny.smith@rokt.com"
        MParticle.sharedInstance().identity.identify(identityRequest, completion: nil)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
