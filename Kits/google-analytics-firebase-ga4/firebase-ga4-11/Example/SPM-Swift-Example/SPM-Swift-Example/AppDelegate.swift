import UIKit
import mParticle_Apple_SDK
import mParticle_FirebaseGA4

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let mparticle = MParticle.sharedInstance()
        mparticle.start(with: .init(
            key: "REPLACE WITH YOUR MPARTICLE API KEY",
            secret: "REPLACE WITH YOUR MPARTICLE API SECRET"
        ))
        mparticle.logLevel = .verbose
        if let event = MPEvent(name: "foo", type: .other) {
            mparticle.logEvent(event)
        }
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}
