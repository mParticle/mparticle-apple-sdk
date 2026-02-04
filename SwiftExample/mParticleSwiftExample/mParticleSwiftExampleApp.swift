import SwiftUI
import mParticle_Apple_SDK
import AdSupport
import AppTrackingTransparency
import UserNotifications

@main
// swiftlint:disable:next type_name
struct mParticleSwiftExampleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Initialize mParticle
        let options = MParticleOptions(
            key: "REPLACE_WITH_APP_KEY",
            secret: "REPLACE_WITH_APP_SECRET"
        )

        let identityRequest = MPIdentityApiRequest.withEmptyUser()
        identityRequest.email = "foo@example.com"
        identityRequest.customerId = "123456"
        options.identifyRequest = identityRequest

        options.onIdentifyComplete = { (apiResult, error) in
            if let result = apiResult {
                result.user.setUserAttribute("example attribute key", value: "example attribute value")
            } else {
                // Handle failure - see https://docs.mparticle.com/developers/sdk/ios/idsync/#error-handling
                print("Identify failed: \(error?.localizedDescription ?? "Unknown error")")
            }
        }

        options.logLevel = .verbose

        // Uncomment to configure custom network options
        // let networkOptions = MPNetworkOptions()
        // networkOptions.configHost = "config2-origin-qa1.qa.corp.mparticle.com"
        // networkOptions.eventsHost = "nativesdks-qa1.qa.corp.mparticle.com"
        // networkOptions.identityHost = "identity-qa1.qa.corp.mparticle.com"
        // networkOptions.pinningDisabled = true
        // options.networkOptions = networkOptions

        MParticle.sharedInstance().start(with: options)

        // Request IDFA tracking authorization
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                switch status {
                case .authorized:
                    print("Authorized")
                    print(ASIdentifierManager.shared().advertisingIdentifier)
                case .denied:
                    print("Denied")
                case .notDetermined:
                    print("Not Determined")
                case .restricted:
                    print("Restricted")
                @unknown default:
                    print("Unknown")
                }
            }
        }

        // Request push notification authorization
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, error in
            if let error = error {
                print("Failed to register: \(error.localizedDescription)")
            } else {
                print("Notification Request Successful")
            }
        }

        return true
    }
}
