import UIKit
import A

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        // Create window
        window = UIWindow(frame: UIScreen.main.bounds)
        
        // Create view controller
        let viewController = ViewController()
        let navigationController = UINavigationController(rootViewController: viewController)
        
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        
        // Demonstration of using module A
        print("=== CheckAppPods ===")
        print("Using module A via CocoaPods\n")
        
        let thing = AThing()
        thing.demo()
        
        return true
    }
}
