import XCTest
import ObjectiveC.runtime
import mParticle_Apple_SDK_NoLocation

#if os(iOS)
final class MParticleOpenURLTests: MParticleTestBase {
    
    func test_openURLWithSourceApplication_doesNotCallHandler_whenProxiedDelegateExists() {
        mparticle.setValue(NSNumber(value: true), forKey: "proxiedAppDelegate")

        let url = URL(string: "https://example.com")!
        let sourceApp = "com.example.app"
        let annotation = "annotation"
        mparticle.open(url, sourceApplication: sourceApp, annotation: annotation)
        
        XCTAssertFalse(appNotificationHandler.openURLWithSourceApplicationAndAnnotationCalled)
    }
    
    func test_openURLWithSourceApplication_callsHandler_whenNoProxiedDelegate() {
        let sourceApp = "com.example.app"
        let annotation = "annotation"

        mparticle.open(url, sourceApplication: sourceApp, annotation: annotation)

        XCTAssertTrue(appNotificationHandler.openURLWithSourceApplicationAndAnnotationCalled)
        XCTAssertEqual(appNotificationHandler.openURLWithSourceApplicationAndAnnotationURLParam, url)
        XCTAssertEqual(appNotificationHandler.openURLWithSourceApplicationAndAnnotationSourceApplicationParam, sourceApp)
        XCTAssertEqual(appNotificationHandler.openURLWithSourceApplicationAndAnnotationAnnotationParam as! String, annotation)
    }
    
    func test_openURLOptions_callsHandler_whenNoProxiedDelegate_andSystemVersion9OrHigher() {
        let options = ["UIApplicationOpenURLOptionsSourceApplicationKey": "com.example.app"]
        
        mparticle.open(url, options: options)
        
        XCTAssertTrue(appNotificationHandler.openURLWithOptionsCalled)
        XCTAssertEqual(appNotificationHandler.openURLWithOptionsURLParam, url)
        XCTAssertEqual(
            appNotificationHandler.openURLWithOptionsOptionsParam?["UIApplicationOpenURLOptionsSourceApplicationKey"] as? String,
            "com.example.app"
        )
    }
    
    func test_openURLOptions_doesNotCallHandler_whenProxiedDelegateExists() {
        mparticle.setValue(NSNumber(value: true), forKey: "proxiedAppDelegate")
        
        let options = ["UIApplicationOpenURLOptionsSourceApplicationKey": "com.example.app"]
        mparticle.open(url, options: options)

        XCTAssertFalse(appNotificationHandler.openURLWithOptionsCalled)
    }

    func test_openURLOptions_doesNotCallHandler_whenSystemVersionBelow9() {
        let currentDevice = UIDevice.current
        let origSelector = NSSelectorFromString("systemVersion")
        let mockedVersion: @convention(block) () -> String = { "8.4" }
        let imp = imp_implementationWithBlock(mockedVersion)
        class_replaceMethod(object_getClass(currentDevice), origSelector, imp, "@@:")
        
        let options = ["UIApplicationOpenURLOptionsSourceApplicationKey": "com.example.app"]
        mparticle.open(url, options: options)
        
        XCTAssertFalse(appNotificationHandler.openURLWithOptionsCalled)
    }
}
#endif
