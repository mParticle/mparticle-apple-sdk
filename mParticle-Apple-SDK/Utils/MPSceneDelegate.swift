#if os(iOS)
import UIKit

@available(iOS 13.0, *)
public class MPSceneDelegate: NSObject, UIWindowSceneDelegate {

    public var window: UIWindow?
    
   // Called when scene connects
    public func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard scene is UIWindowScene else { return }
        
        // Handle URLs passed during launch
        if let urlContext = connectionOptions.urlContexts.first {
            MParticle.sharedInstance().handleURLContext(urlContext)
        }
        
        // Handle user activities (Universal Links)
        if let userActivity = connectionOptions.userActivities.first {
            MParticle.sharedInstance().handleUserActivity(userActivity)
        }
    }
    
    // Called when app is already running and receives URL
    public func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        for context in URLContexts {
            MParticle.sharedInstance().handleURLContext(context)
        }
    }
    
    // Called for Universal Links
    public func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        MParticle.sharedInstance().handleUserActivity(userActivity)
    }
}
#endif
