import SwiftUI
import mParticle_Apple_SDK

@main
struct SPMSwiftExampleApp: App {
    init() {
        let options = MParticleOptions(
            key: "us2-db9c17968390524f8b04a51027f0cc76",
            secret: "gGrsbRzGWGRYRefV8w_JMH4xwE8d45-1U1NLkuBwcxiCQHhj4ST0iMkrGuynDmVt"
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
