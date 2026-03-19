import UIKit
import mParticle_Apple_SDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let options = MParticleOptions(key: "REPLACE WITH YOUR MPARTICLE API KEY",
                                       secret: "REPLACE WITH YOUR MPARTICLE API SECRET")
        MParticle.sharedInstance().start(with: options)
        MParticle.sharedInstance().logLevel = .verbose

        let event = MPEvent(name: "foo", type: .other)!
        MParticle.sharedInstance().logEvent(event)

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}
