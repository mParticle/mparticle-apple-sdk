import Foundation
import UIKit

/// The SDK's backend controller. It owns the session state and the collaborators that write
/// messages, run sessions and uploads, and start the SDK, and it answers the app's lifecycle
/// notifications.
///
/// Objective-C reaches it through `MPBackendControllerProtocol`, which the boundary category in
/// MPBackendController+ObjCBoundary.m adopts for it. That category also holds the entry points that
/// take or return Objective-C types this module cannot see.
@objc(MPBackendController_PRIVATE)
public final class MPBackendController_PRIVATE: NSObject, MPBackendAssemblyOwner { // swiftlint:disable:this type_name
    /// The session timeout a controller made for the SDK starts with, in seconds.
    /// Mirrors `DEFAULT_SESSION_TIMEOUT`, which this module cannot import.
    static let defaultSessionTimeout: TimeInterval = 60

    @objc public let sessionState: MPBackendSessionState
    /// Built right after `super.init()`, because the collaborators hold the controller weakly.
    private(set) var assembly: MPBackendAssembly!
    private let host: MPBackendHost
    private var storedPersistence: MPBackendPersistence?
    private var storedEventSet: NSMutableSet?

    private weak var delegate: MPBackendControllerDelegate?
    /// The network layer, typed as `MPNetworkCommunication_PRIVATE` by the boundary category.
    @objc public var networkCommunicationStorage: MPBackendUploadNetworking?
    /// The pending session, typed as `MParticleSession` by the boundary category.
    @objc public var pendingSessionStorage: AnyObject?

    /// A controller with no delegate, persistence, network layer or observers.
    @objc override public convenience init() {
        self.init(host: Self.sdkHost())
    }

    init(host: MPBackendHost) {
        self.host = host
        sessionState = MPBackendSessionState()
        super.init()
        assembly = MPBackendAssembly(state: sessionState, host: host, owner: self)
    }

    /// A controller for the SDK instance. The Objective-C boundary category's `-initWithDelegate:`
    /// initialisers call this with the SDK's host.
    @objc(initWithHost:delegate:persistence:)
    public convenience init(host: MPBackendHost, delegate: MPBackendControllerDelegate?, persistence: MPBackendPersistence?) {
        self.init(host: host, delegate: delegate, persistence: persistence, notificationCenter: .default)
    }

    /// `notificationCenter` is where the controller observes the app lifecycle; tests pass their own.
    convenience init(
        host: MPBackendHost,
        delegate: MPBackendControllerDelegate?,
        persistence: MPBackendPersistence?,
        notificationCenter center: NotificationCenter
    ) {
        self.init(host: host)
        storedPersistence = persistence
        networkCommunicationStorage = host.makeNetworkCommunication()
        sessionState.sessionTimeout = Self.defaultSessionTimeout
        sessionState.nextCleanUpTime = Date().timeIntervalSince1970
        self.delegate = delegate
        let checkQueue = OperationQueue()
        checkQueue.maxConcurrentOperationCount = 1
        lifecycleCoordinator.backgroundCheckQueue = checkQueue

        center.addObserver(
            self, selector: #selector(handleApplicationDidEnterBackground(_:)),
            name: UIApplication.didEnterBackgroundNotification, object: nil
        )
        center.addObserver(
            self, selector: #selector(handleApplicationWillEnterForeground(_:)),
            name: UIApplication.willEnterForegroundNotification, object: nil
        )
        center.addObserver(
            self, selector: #selector(handleApplicationDidFinishLaunching(_:)),
            name: UIApplication.didFinishLaunchingNotification, object: nil
        )
        center.addObserver(
            self, selector: #selector(handleApplicationDidBecomeActive(_:)),
            name: UIApplication.didBecomeActiveNotification, object: nil
        )
        #if os(iOS)
            center.addObserver(
                self, selector: #selector(handleDeviceTokenNotification(_:)),
                name: Notifications.kMPRemoteNotificationDeviceTokenNotification, object: nil
            )
        #endif
    }

    deinit {
        assembly?.lifecycleCoordinator.endUploadTimer()
    }

    /// The host for a controller made with the plain initialiser, which only tests use.
    /// MPUserDefaultsConnector, which this module cannot import, adopts `MPBackendHost`; the SDK's own
    /// controller gets it from the Objective-C boundary category, which names the class directly.
    private static func sdkHost() -> MPBackendHost {
        guard let host = (NSClassFromString("MPUserDefaultsConnector") as? NSObject.Type)?.init() as? MPBackendHost else {
            preconditionFailure("mParticle -> MPUserDefaultsConnector is unavailable; the backend cannot start.")
        }
        return host
    }

    // MARK: - Collaborators

    private var lifecycleCoordinator: MPBackendLifecycleCoordinator { assembly.lifecycleCoordinator }
    private var sessionCoordinator: MPBackendSessionCoordinator { assembly.sessionCoordinator }
    private var userAttributeWriter: MPBackendUserAttributeWriter { assembly.userAttributeWriter }
    @objc public var uploadCoordinator: MPBackendUploadCoordinator { assembly.uploadCoordinator }
    @objc public var eventLogger: MPBackendEventLogger { assembly.eventLogger }
    @objc public var identityWriter: MPBackendIdentityWriter { assembly.identityWriter }
    @objc public var startupCoordinator: MPBackendStartupCoordinator { assembly.startupCoordinator }

    // MARK: - State

    @objc public var session: MPSessionPRIVATE? {
        get { sessionState.session }
        set { sessionState.session = newValue }
    }

    @objc var timeOfLastEventInBackground: TimeInterval {
        get { sessionState.timeOfLastEventInBackground }
        set { sessionState.timeOfLastEventInBackground = newValue }
    }

    @objc var timeAppWentToBackgroundInCurrentSession: TimeInterval {
        get { sessionState.timeAppWentToBackgroundInCurrentSession }
        set { sessionState.timeAppWentToBackgroundInCurrentSession = newValue }
    }

    /// The timed events in progress, created on first read.
    @objc public var eventSet: NSMutableSet? {
        get {
            if storedEventSet == nil {
                storedEventSet = NSMutableSet(capacity: 1)
            }
            return storedEventSet
        }
        set { storedEventSet = newValue }
    }

    @objc public var sessionTimeout: TimeInterval {
        get { lifecycleCoordinator.sessionTimeout }
        set { lifecycleCoordinator.sessionTimeout = newValue }
    }

    @objc public var uploadInterval: TimeInterval {
        get { lifecycleCoordinator.uploadInterval }
        set { lifecycleCoordinator.uploadInterval = newValue }
    }

    @objc var backgroundCheckQueue: OperationQueue? {
        get { lifecycleCoordinator.backgroundCheckQueue }
        set { lifecycleCoordinator.backgroundCheckQueue = newValue }
    }

    @objc(userAttributesForUserId:)
    public func userAttributes(forUserId userId: NSNumber) -> NSMutableDictionary {
        userAttributeWriter.userAttributes(forUserId: userId)
    }

    @objc(userIdentitiesForUserId:)
    func userIdentities(forUserId userId: NSNumber) -> NSMutableArray {
        identityWriter.userIdentities(forUserId: userId)
    }

    // MARK: - MPBackendAssemblyOwner

    public func persistence() -> MPBackendPersistence? {
        storedPersistence
    }

    public func setPersistence(_ persistence: MPBackendPersistence?) {
        storedPersistence = persistence
    }

    public func messageBuilderContext() -> MPMessageBuilderContext {
        MPMessageBuilderContext(host: host)
    }

    public func upload(completionHandler: (() -> Void)?) {
        _ = waitForKitsAndUpload(completionHandler: completionHandler)
    }

    public func requestConfig() {
        uploadCoordinator.requestConfig(nil)
    }

    public func uploadNetworking() -> MPBackendUploadNetworking? {
        networkCommunicationStorage
    }

    public func backendDelegate() -> MPBackendControllerDelegate? {
        delegate
    }

    public func clearEmptyTimedEvents() {
        if (eventSet?.count ?? 0) == 0 {
            eventSet = nil
        }
    }

    /// Separated so a test can substitute the session and assert the data task is resumed without
    /// reaching Apple's attribution endpoint. Dynamic, as are `saveMessage(_:updateSession:)` and
    /// `waitForKitsAndUpload(completionHandler:)`, so an Objective-C test's partial mock sees the
    /// controller's own calls.
    @objc public dynamic func attributionURLSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 30
        return URLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
    }

    @objc(saveMessage:updateSession:)
    public dynamic func saveMessage(_ message: MPMessagePRIVATE, updateSession: Bool) {
        assembly.messageWriter.saveMessage(message, updateSession: updateSession)
    }

    // MARK: - Start-up and launch

    @objc(processDidFinishLaunching:)
    func processDidFinishLaunching(_ notification: Notification?) {
        startupCoordinator.processDidFinishLaunching(notification)
    }

    @objc(handleApplicationDidFinishLaunching:)
    func handleApplicationDidFinishLaunching(_ notification: Notification) {
        startupCoordinator.didFinishLaunchingNotification = notification
    }

    // MARK: - Sessions

    @objc public func createTempSession() {
        sessionCoordinator.createTempSession()
    }

    @objc func beginSession() {
        sessionCoordinator.beginSession()
    }

    @objc public func endSession() {
        sessionCoordinator.endSession()
    }

    @objc(beginSessionWithIsManual:date:)
    public func beginSession(isManual: Bool, date: Date?) {
        sessionCoordinator.beginSession(isManual: isManual, date: date)
    }

    @objc(endSessionWithIsManual:)
    public func endSession(isManual: Bool) {
        sessionCoordinator.endSession(isManual: isManual)
    }

    @objc(processOpenSessionsEndingCurrent:completionHandler:)
    func processOpenSessions(endingCurrent: Bool, completionHandler: (() -> Void)?) {
        sessionCoordinator.processOpenSessions(endingCurrent: endingCurrent, completionHandler: completionHandler)
    }

    @discardableResult
    @objc(setSessionAttribute:key:value:)
    public func setSessionAttribute(_ session: MPSessionPRIVATE?, key: Any?, value: Any?) -> MPExecStatus {
        assert(session != nil, "session cannot be nil.")
        return assembly.sessionAttributeWriter.setAttribute(session, key: key, value: value)
    }

    @discardableResult
    @objc(incrementSessionAttribute:key:byValue:)
    public func incrementSessionAttribute(_ session: MPSessionPRIVATE?, key: Any?, byValue value: Any?) -> NSNumber? {
        assembly.sessionAttributeWriter.incrementAttribute(session, key: key, byValue: value)
    }

    // MARK: - Uploads

    @discardableResult
    @objc(waitForKitsAndUploadWithCompletionHandler:)
    public dynamic func waitForKitsAndUpload(completionHandler: (() -> Void)?) -> MPExecStatus {
        uploadCoordinator.waitForKitsAndUpload(completionHandler: completionHandler)
        return .success
    }

    @discardableResult
    @objc(checkForKitsAndUploadWithCompletionHandler:)
    func checkForKitsAndUpload(completionHandler: ((Bool) -> Void)?) -> MPExecStatus {
        uploadCoordinator.checkForKitsAndUpload(completionHandler: completionHandler)
        return .success
    }

    @objc public func skipNextUpload() {
        uploadCoordinator.skipNextUpload()
    }

    @objc(batchMessageArraysFromMessageArray:maxBatchMessages:maxBatchBytes:maxMessageBytes:)
    func batchMessageArrays(
        from messages: [MPMessagePRIVATE], maxBatchMessages: Int, maxBatchBytes: Int, maxMessageBytes: Int
    ) -> [[MPMessagePRIVATE]] {
        let sdkLimits = host.uploadBatchLimits()
        let limits = MPUploadBatchLimits(
            maxMessages: maxBatchMessages, maxBatchBytes: maxBatchBytes, maxMessageBytes: maxMessageBytes,
            crashBatchBytes: sdkLimits.crashBatchBytes, crashMessageBytes: sdkLimits.crashMessageBytes
        )
        return uploadCoordinator.batchMessages(messages, limits: limits)
    }

    @objc func beginUploadTimer() {
        lifecycleCoordinator.beginUploadTimer()
    }

    @objc func endUploadTimer() {
        lifecycleCoordinator.endUploadTimer()
    }

    // MARK: - Messages

    @objc(logError:exception:topmostContext:eventInfo:completionHandler:)
    public func logError(
        _ message: String?,
        exception: NSException?,
        topmostContext: Any?,
        eventInfo: [AnyHashable: Any]?,
        completionHandler: (String?, MPExecStatus) -> Void
    ) {
        let topmostContextDescription = topmostContext.map { NSStringFromClass(type(of: $0 as AnyObject)) }
        let execMessage = assembly.errorReporter.logError(
            message: message, exception: exception,
            topmostContextDescription: topmostContextDescription, eventInfo: eventInfo
        )
        completionHandler(execMessage, .success)
    }

    @objc(logCrash:stackTrace:plCrashReport:completionHandler:)
    public func logCrash(
        _ message: String?,
        stackTrace: String?,
        plCrashReport: String?,
        completionHandler: (String?, MPExecStatus) -> Void
    ) {
        let execMessage = assembly.errorReporter.logCrash(
            message: message, stackTrace: stackTrace, plCrashReport: plCrashReport
        )
        completionHandler(execMessage, .success)
    }

    @objc(logNetworkPerformanceMeasurement:completionHandler:)
    public func logNetworkPerformanceMeasurement(
        _ networkPerformance: MPNetworkPerformance,
        completionHandler: ((MPNetworkPerformance, MPExecStatus) -> Void)?
    ) {
        assembly.messageLogger.logNetworkPerformance(networkPerformance, completionHandler: completionHandler)
    }

    @objc(setOptOut:completionHandler:)
    public func setOptOut(_ optOut: Bool, completionHandler: @escaping (Bool, MPExecStatus) -> Void) {
        assembly.messageLogger.setOptOut(optOut, completionHandler: completionHandler)
    }

    @discardableResult
    @objc(fetchAudiencesWithCompletionHandler:)
    public func fetchAudiences(completionHandler: @escaping ([Any]?, Error?) -> Void) -> MPExecStatus {
        assembly.messageLogger.fetchAudiences(completionHandler: completionHandler)
        return .success
    }

    @objc(handleDeviceTokenNotification:)
    func handleDeviceTokenNotification(_ notification: Notification) {
        assembly.messageLogger.handleDeviceTokenNotification(notification)
    }

    @objc(logUserNotification:)
    public func logUserNotification(_ userNotification: MParticleUserNotificationPRIVATE) {
        assembly.messageLogger.logUserNotification(userNotification)
    }

    // MARK: - User attributes

    @objc(setUserTag:timestamp:completionHandler:)
    public func setUserTag(_ key: Any?, timestamp: Date?, completionHandler: ((Any?, Any?, MPExecStatus) -> Void)?) {
        report(userAttributeWriter.setUserTag(key, timestamp: timestamp), to: completionHandler)
    }

    @objc(setUserAttribute:value:timestamp:completionHandler:)
    public func setUserAttribute(
        _ key: Any?, value: Any?, timestamp: Date?, completionHandler: ((Any?, Any?, MPExecStatus) -> Void)?
    ) {
        report(userAttributeWriter.setUserAttribute(key, value: value, timestamp: timestamp), to: completionHandler)
    }

    @objc(setUserAttribute:values:timestamp:completionHandler:)
    public func setUserAttribute(
        _ key: Any?, values: Any?, timestamp: Date?, completionHandler: ((Any?, Any?, MPExecStatus) -> Void)?
    ) {
        report(userAttributeWriter.setUserAttribute(key, values: values, timestamp: timestamp), to: completionHandler)
    }

    @objc(removeUserAttribute:timestamp:completionHandler:)
    public func removeUserAttribute(
        _ key: Any?, timestamp: Date?, completionHandler: ((Any?, Any?, MPExecStatus) -> Void)?
    ) {
        report(userAttributeWriter.removeUserAttribute(key, timestamp: timestamp), to: completionHandler)
    }

    @discardableResult
    @objc(incrementUserAttribute:byValue:)
    public func incrementUserAttribute(_ key: Any?, byValue value: Any?) -> NSNumber? {
        assert(key is String, "'key' must be a string.")
        assert(value is NSNumber, "'value' must be a number.")
        return userAttributeWriter.incrementUserAttribute(key, byValue: value)
    }

    private func report(_ outcome: MPBackendUserAttributeOutcome, to completionHandler: ((Any?, Any?, MPExecStatus) -> Void)?) {
        completionHandler?(outcome.key, outcome.value, outcome.status)
    }

    // MARK: - Background handling

    @objc func beginBackgroundTask() {
        lifecycleCoordinator.beginBackgroundTask()
    }

    @objc func endBackgroundTask() {
        lifecycleCoordinator.endBackgroundTask()
    }

    @objc func endSessionIfTimedOut() {
        lifecycleCoordinator.endSessionIfTimedOut()
    }

    @objc(cleanUp:)
    func cleanUp(currentTime: TimeInterval) {
        lifecycleCoordinator.cleanUp(currentTime: currentTime)
    }

    @objc func cancelBackgroundTimeCheckLoop() {
        lifecycleCoordinator.cancelBackgroundTimeCheckLoop()
    }

    @objc func beginBackgroundTimeCheckLoop() {
        lifecycleCoordinator.beginBackgroundTimeCheckLoop()
    }

    @objc(handleApplicationDidEnterBackground:)
    func handleApplicationDidEnterBackground(_ notification: Notification) {
        lifecycleCoordinator.applicationDidEnterBackground()
    }

    @objc(handleApplicationWillEnterForeground:)
    func handleApplicationWillEnterForeground(_ notification: Notification) {
        lifecycleCoordinator.applicationWillEnterForeground()
    }

    @objc(handleApplicationDidBecomeActive:)
    func handleApplicationDidBecomeActive(_ notification: Notification?) {
        lifecycleCoordinator.applicationDidBecomeActive()
    }

    // MARK: - Search Ads attribution

    @objc(singleShotBlock:)
    func singleShotBlock(_ block: @escaping () -> Void) -> () -> Void {
        MPSearchAdsAttribution.singleShot(block)
    }

    @objc(requestAttributionDetailsWithBlock:requestsCompleted:)
    func requestAttributionDetails(withBlock completionHandler: @escaping () -> Void, requestsCompleted: Int32) {
        assembly.searchAdsAttribution.requestAttributionDetails(
            completion: completionHandler, requestsCompleted: Int(requestsCompleted)
        )
    }
}
