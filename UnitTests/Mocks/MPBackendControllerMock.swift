import XCTest
import mParticle_Apple_SDK_NoLocation

class MPBackendControllerMock: NSObject, MPBackendControllerProtocol {
    var sessionTimeout: TimeInterval = 0.0
    var uploadInterval: TimeInterval = 0.0
    var eventSet: NSMutableSet? = NSMutableSet()
    var session: MPSession?

    // MARK: - Opt-out

    var setOptOutCalled = false
    var setOptOutOptOutStatusParam: Bool?
    var setOptOutCompletionHandler: ((Bool, MPExecStatus) -> Void)?

    func setOptOut(_ optOutStatus: Bool, completionHandler: @escaping (Bool, MPExecStatus) -> Void) {
        setOptOutCalled = true
        setOptOutOptOutStatusParam = optOutStatus
        setOptOutCompletionHandler = completionHandler
    }

    // MARK: - User attributes

    var userAttributesCalled = false
    var userAttributesUserIdParam: NSNumber?
    var userAttributesReturnValue: NSMutableDictionary = [:]

    func userAttributes(forUserId userId: NSNumber) -> NSMutableDictionary {
        userAttributesCalled = true
        userAttributesUserIdParam = userId
        return userAttributesReturnValue
    }

    // MARK: - Start

    var startCalled = false
    var startApiKeyParam: String?
    var startSecretParam: String?
    var startNetworkOptionsParam: MPNetworkOptions?
    var startFirstRunParam: Bool?
    var startInstallationTypeParam: MPInstallationType?
    var startProxyAppDelegateParam: Bool?
    var startStartKitsAsyncParam: Bool?
    var startConsentStateParam: MPConsentState?
    var startCompletionHandler: (() -> Void)?

    func start(
        withKey apiKey: String,
        secret: String,
        networkOptions: MPNetworkOptions?,
        firstRun: Bool,
        installationType: MPInstallationType,
        proxyAppDelegate: Bool,
        startKitsAsync: Bool,
        consentState: MPConsentState?,
        completionHandler: @escaping () -> Void
    ) {
        startCalled = true
        startApiKeyParam = apiKey
        startSecretParam = secret
        startNetworkOptionsParam = networkOptions
        startFirstRunParam = firstRun
        startInstallationTypeParam = installationType
        startProxyAppDelegateParam = proxyAppDelegate
        startStartKitsAsyncParam = startKitsAsync
        startConsentStateParam = consentState
        startCompletionHandler = completionHandler
    }

    // MARK: - Prepare batches

    var prepareBatchesCalled = false
    var prepareBatchesUploadSettingsParam: MPUploadSettings?

    func prepareBatches(forUpload uploadSettings: MPUploadSettings) {
        prepareBatchesCalled = true
        prepareBatchesUploadSettingsParam = uploadSettings
    }

    // MARK: - Temp session

    var tempSessionCalled = false
    var tempSessionReturnValue: MParticleSession?

    func tempSession() -> MParticleSession? {
        tempSessionCalled = true
        return tempSessionReturnValue
    }

    // MARK: - App delegate proxying

    var unproxyOriginalAppDelegateCalled = false

    func unproxyOriginalAppDelegate() {
        unproxyOriginalAppDelegateCalled = true
    }

    // MARK: - Session lifecycle

    var endSessionCalled = false

    func endSession() {
        endSessionCalled = true
    }

    var beginTimedEventCalled = false
    var beginTimedEventEventParam: MPEvent?
    var beginTimedEventCompletionHandler: ((MPEvent, MPExecStatus) -> Void)?

    func beginTimedEvent(_ event: MPEvent, completionHandler: @escaping (MPEvent, MPExecStatus) -> Void) {
        beginTimedEventCalled = true
        beginTimedEventEventParam = event
        beginTimedEventCompletionHandler = completionHandler
    }

    // MARK: - Events

    var logEventCalled = false
    var logEventEventParam: MPEvent?
    var logEventCompletionHandler: ((MPEvent, MPExecStatus) -> Void)?

    func logEvent(_ event: MPEvent, completionHandler: @escaping (MPEvent, MPExecStatus) -> Void) {
        logEventCalled = true
        logEventEventParam = event
        logEventCompletionHandler = completionHandler
    }
    
    var eventWithNameCalled = false
    var eventWithNameEventNameParam: String?
    var eventWithNameReturnValue: MPEvent? = nil

    func event(withName eventName: String) -> MPEvent? {
        eventWithNameCalled = true
        eventWithNameEventNameParam = eventName
        guard let set = eventSet else { return nil }
        for case let evt as MPEvent in set {
            if evt.name == eventName { return evt }
        }
        return eventWithNameReturnValue
    }

    // MARK: - Base events

    var logBaseEventCalled = false
    var logBaseEventEventParam: MPBaseEvent?
    var logBaseEventCompletionHandler: ((MPBaseEvent, MPExecStatus) -> Void)?

    func logBaseEvent(_ event: MPBaseEvent, completionHandler: @escaping (MPBaseEvent, MPExecStatus) -> Void) {
        logBaseEventCalled = true
        logBaseEventEventParam = event
        logBaseEventCompletionHandler = completionHandler
    }

    // MARK: - Commerce events

    var logCommerceEventCalled = false
    var logCommerceEventParam: MPCommerceEvent?
    var logCommerceEventCompletionHandler: ((MPCommerceEvent, MPExecStatus) -> Void)?

    func logCommerceEvent(_ commerceEvent: MPCommerceEvent,
                          completionHandler: @escaping (MPCommerceEvent, MPExecStatus) -> Void) {
        logCommerceEventCalled = true
        logCommerceEventParam = commerceEvent
        logCommerceEventCompletionHandler = completionHandler
    }

    // MARK: - Network perf

    var logNetworkPerformanceCalled = false
    var logNetworkPerformanceParam: MPNetworkPerformance?
    var logNetworkPerformanceCompletionHandler: ((MPNetworkPerformance, MPExecStatus) -> Void)?

    func logNetworkPerformanceMeasurement(
        _ networkPerformance: MPNetworkPerformance,
        completionHandler: ((MPNetworkPerformance, MPExecStatus) -> Void)? = nil
    ) {
        logNetworkPerformanceCalled = true
        logNetworkPerformanceParam = networkPerformance
        logNetworkPerformanceCompletionHandler = completionHandler
    }

    // MARK: - Screen

    var logScreenCalled = false
    var logScreenEventParam: MPEvent?
    var logScreenCompletionHandler: ((MPEvent, MPExecStatus) -> Void)?

    func logScreen(_ event: MPEvent, completionHandler: @escaping (MPEvent, MPExecStatus) -> Void) {
        logScreenCalled = true
        logScreenEventParam = event
        logScreenCompletionHandler = completionHandler
    }

    // MARK: - Breadcrumbs

    var leaveBreadcrumbCalled = false
    var leaveBreadcrumbEventParam: MPEvent?
    var leaveBreadcrumbCompletionHandler: ((MPEvent, MPExecStatus) -> Void)?

    func leaveBreadcrumb(_ event: MPEvent, completionHandler: @escaping (MPEvent, MPExecStatus) -> Void) {
        leaveBreadcrumbCalled = true
        leaveBreadcrumbEventParam = event
        leaveBreadcrumbCompletionHandler = completionHandler
    }

    // MARK: - Errors & Crashes

    var logErrorCalled = false
    var logErrorMessageParam: String?
    var logErrorExceptionParam: NSException?
    var logErrorTopmostContextParam: Any?
    var logErrorEventInfoParam: [AnyHashable: Any]?
    var logErrorCompletionHandler: ((String?, MPExecStatus) -> Void)?

    func logError(
        _ message: String?,
        exception: NSException?,
        topmostContext: Any?,
        eventInfo: [AnyHashable: Any]?,
        completionHandler: @escaping (String?, MPExecStatus) -> Void
    ) {
        logErrorCalled = true
        logErrorMessageParam = message
        logErrorExceptionParam = exception
        logErrorTopmostContextParam = topmostContext
        logErrorEventInfoParam = eventInfo
        logErrorCompletionHandler = completionHandler
    }

    var logCrashCalled = false
    var logCrashMessageParam: String?
    var logCrashStackTraceParam: String?
    var logCrashPlReportParam: String?
    var logCrashCompletionHandler: ((String?, MPExecStatus) -> Void)?

    func logCrash(
        _ message: String?,
        stackTrace: String?,
        plCrashReport: String,
        completionHandler: @escaping (String?, MPExecStatus) -> Void
    ) {
        logCrashCalled = true
        logCrashMessageParam = message
        logCrashStackTraceParam = stackTrace
        logCrashPlReportParam = plCrashReport
        logCrashCompletionHandler = completionHandler
    }

    // MARK: - Session attributes

    var sessionAttributesStore: [String: Any] = [:]
    var setSessionAttributeCalled = false
    var setSessionAttributeKeyParam: String?
    var setSessionAttributeValueParam: Any?
    var setSessionAttributeReturnValue = MPExecStatus.success

    func setSessionAttribute(_: MPSession, key: String, value: Any) -> MPExecStatus {
        setSessionAttributeCalled = true
        setSessionAttributeKeyParam = key
        setSessionAttributeValueParam = value
        sessionAttributesStore[key] = value
        return setSessionAttributeReturnValue
    }

    var incrementSessionAttributeCalled = false
    var incrementSessionAttributeKeyParam: String?
    var incrementSessionAttributeByValueParam: NSNumber?
    var incrementSessionAttributeReturnValue: NSNumber?

    func incrementSessionAttribute(_: MPSession, key: String, byValue value: NSNumber) -> NSNumber? {
        incrementSessionAttributeCalled = true
        incrementSessionAttributeKeyParam = key
        incrementSessionAttributeByValueParam = value

        return incrementSessionAttributeReturnValue
    }

    // MARK: - Session mgmt

    var createTempSessionCalled = false

    func createTempSession() {
        createTempSessionCalled = true
    }

    var beginSessionCalled = false
    var beginSessionIsManualParam: Bool?
    var beginSessionDateParam: Date?

    func beginSession(withIsManual isManual: Bool, date: Date) {
        beginSessionCalled = true
        beginSessionIsManualParam = isManual
        beginSessionDateParam = date
    }

    var endSessionWithIsManualCalled = false
    var endSessionIsManualParam: Bool?

    func endSession(withIsManual isManual: Bool) {
        endSessionWithIsManualCalled = true
        endSessionIsManualParam = isManual
        endSessionCalled = true
    }

    // MARK: - Upload & Kits

    var waitForKitsAndUploadCalled = false
    var waitForKitsAndUploadCompletionHandler: (() -> Void)?
    var waitForKitsAndUploadReturnValue: MPExecStatus = .success

    func waitForKitsAndUpload(completionHandler: (() -> Void)? = nil) -> MPExecStatus {
        waitForKitsAndUploadCalled = true
        waitForKitsAndUploadCompletionHandler = completionHandler
        return waitForKitsAndUploadReturnValue
    }

    #if os(iOS)

        // MARK: - Notifications

        var logUserNotificationCalled = false
        var logUserNotificationParam: MParticleUserNotification?

        func logUserNotification(_ userNotification: MParticleUserNotification) {
            logUserNotificationCalled = true
            logUserNotificationParam = userNotification
        }
    #endif
}
