import XCTest
#if MPARTICLE_LOCATION_DISABLE
    import mParticle_Apple_SDK_NoLocation
#else
    import mParticle_Apple_SDK
#endif

class OpenURLHandlerProtocolMock: NSObject, OpenURLHandlerProtocol {

    var openURLWithOptionsCalled = false
    var openURLWithOptionsURLParam: URL?
    var openURLWithOptionsOptionsParam: [String: Any]?

    @objc(openURL:options:)
    func open(_ url: URL, options: [String: Any]?) {
        openURLWithOptionsCalled = true
        openURLWithOptionsURLParam = url
        openURLWithOptionsOptionsParam = options
    }

    var continueUserActivityCalled = false
    var continueUserActivityUserActivityParam: NSUserActivity?
    var continueUserActivityRestorationHandlerParam: (([UIUserActivityRestoring]?) -> Void)?
    var continueUserActivityReturnValue: Bool = false

    @objc(continueUserActivity:restorationHandler:)
    func continueUserActivity(
        _ userActivity: NSUserActivity,
        restorationHandler: @escaping ([any UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        continueUserActivityCalled = true
        continueUserActivityUserActivityParam = userActivity
        continueUserActivityRestorationHandlerParam = restorationHandler
        return continueUserActivityReturnValue
    }
}
