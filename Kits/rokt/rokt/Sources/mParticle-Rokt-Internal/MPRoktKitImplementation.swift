import Foundation
import mParticle_Apple_SDK
import RoktContracts
import Rokt_Widget

/// Test seam around the static Rokt SDK API.
///
/// Production uses `DefaultMPRoktSDKClient`; tests inject a recorder so the Swift implementation
/// can be verified without starting the Rokt SDK or relying on Objective-C runtime mocks.
protocol MPRoktSDKClient {
    func initialize(tagID: String, sdkVersion: String, kitVersion: String)
    func setCustomBaseURL(_ url: URL)
    func setLogLevel(_ level: RoktLogLevel)
    func setFrameworkType(_ type: RoktFrameworkType)
    func selectPlacements(
        identifier: String,
        attributes: [String: String],
        placements: [String: RoktEmbeddedView]?,
        config: RoktConfig?,
        options: RoktPlacementOptions?,
        onEvent: ((RoktEvent) -> Void)?
    )
    func selectShoppableAds(
        identifier: String,
        attributes: [String: String],
        config: RoktConfig?,
        onEvent: ((RoktEvent) -> Void)?
    )
    func registerPaymentExtension(_ paymentExtension: PaymentExtension, config: [String: String])
    func purchaseFinalized(identifier: String, catalogItemID: String, success: Bool)
    func events(identifier: String, onEvent: ((RoktEvent) -> Void)?)
    func globalEvents(onEvent: @escaping (RoktEvent) -> Void)
    func close()
    func setSessionID(_ sessionID: String)
    func getSessionID() -> String?
    func clearSession()
    func handleURLCallback(_ url: URL) -> Bool
    func logMParticleAPICall(_ code: String)
}

/// Test seam around mParticle identity state and identify requests.
protocol MPRoktIdentityClient: AnyObject {
    var currentUser: MParticleUser? { get }
    func identify(
        _ request: MPIdentityApiRequest,
        completion: @escaping (MPIdentityApiResult?, Error?) -> Void
    )
}

/// Production adapter that forwards the identity operations used during placement preparation.
private final class DefaultMPRoktIdentityClient: MPRoktIdentityClient {
    var currentUser: MParticleUser? {
        MParticle.sharedInstance().identity.currentUser
    }

    func identify(
        _ request: MPIdentityApiRequest,
        completion: @escaping (MPIdentityApiResult?, Error?) -> Void
    ) {
        MParticle.sharedInstance().identity.identify(request, completion: completion)
    }
}

/// Production adapter for the Rokt static API.
private final class DefaultMPRoktSDKClient: MPRoktSDKClient {
    func initialize(tagID: String, sdkVersion: String, kitVersion: String) {
        Rokt.initWith(roktTagId: tagID, mParticleSdkVersion: sdkVersion, mParticleKitVersion: kitVersion)
    }

    func setCustomBaseURL(_ url: URL) { Rokt.setCustomBaseURL(url) }
    func setLogLevel(_ level: RoktLogLevel) { Rokt.setLogLevel(level) }
    func setFrameworkType(_ type: RoktFrameworkType) { Rokt.setFrameworkType(frameworkType: type) }

    func selectPlacements(
        identifier: String,
        attributes: [String: String],
        placements: [String: RoktEmbeddedView]?,
        config: RoktConfig?,
        options: RoktPlacementOptions?,
        onEvent: ((RoktEvent) -> Void)?
    ) {
        Rokt.selectPlacements(
            identifier: identifier,
            attributes: attributes,
            placements: placements,
            config: config,
            placementOptions: options,
            onEvent: onEvent
        )
    }

    func selectShoppableAds(
        identifier: String,
        attributes: [String: String],
        config: RoktConfig?,
        onEvent: ((RoktEvent) -> Void)?
    ) {
        Rokt.selectShoppableAds(
            identifier: identifier,
            attributes: attributes,
            config: config,
            onEvent: onEvent
        )
    }

    func registerPaymentExtension(_ paymentExtension: PaymentExtension, config: [String: String]) {
        Rokt.registerPaymentExtension(paymentExtension, config: config)
    }

    func purchaseFinalized(identifier: String, catalogItemID: String, success: Bool) {
        Rokt.purchaseFinalized(identifier: identifier, catalogItemId: catalogItemID, success: success)
    }

    func events(identifier: String, onEvent: ((RoktEvent) -> Void)?) {
        Rokt.events(identifier: identifier, onEvent: onEvent)
    }

    func globalEvents(onEvent: @escaping (RoktEvent) -> Void) { Rokt.globalEvents(onEvent: onEvent) }
    func close() { Rokt.close() }
    @available(*, deprecated)
    func setSessionID(_ sessionID: String) { Rokt.setSessionId(sessionId: sessionID) }
    @available(*, deprecated)
    func getSessionID() -> String? { Rokt.getSessionId() }
    func clearSession() { Rokt.clearSession() }
    func handleURLCallback(_ url: URL) -> Bool { Rokt.handleURLCallback(with: url) }
    func logMParticleAPICall(_ code: String) { Rokt.logMParticleApiCall(code) }
}

/// Owns Rokt kit behavior while `MPKitRokt` retains the stable Objective-C runtime boundary.
///
/// `MPKitRokt.m` creates this object and forwards `MPKitProtocol` and
/// `MPRoktKitDispatchTarget` selectors to it. Keeping registration and selector declarations in
/// Objective-C preserves existing package and runtime behavior while the implementation lives here.
@objc(MPRoktKitImplementation)
public final class MPRoktKitImplementation: NSObject {
    private enum Constants {
        static let kitCode = 181
        static let kitVersion = "9.4.1"
        static let sandbox = "sandbox"
        static let mapping = "placementAttributesMapping"
        static let mappingSource = "map"
        static let mappingDestination = "value"
        static let hashedEmailIdentity = "hashedEmailUserIdentityType"
        static let stripePublishableKey = "stripePublishableKey"
        static let emailSHA256 = "emailsha256"
        static let mpid = "mpid"
    }

    // SwiftUI layout construction does not have an MPKitRokt instance, so it resolves the current
    // workspace through this weak reference. It is cleared during a workspace switch.
    private static weak var activeInstance: MPRoktKitImplementation?
    private static let activeInstanceLock = NSLock()
    private static var didRegisterGlobalEvents = false

    @objc public var configuration: [AnyHashable: Any]?
    @objc public private(set) var started = false

    // These closures bridge operations that are intentionally kept at the Objective-C boundary:
    // variadic kit logging, the core message queue, and access to the connection-filtered user.
    @objc public var warningHandler: ((String) -> Void)?
    @objc public var afterPendingAttributeWrites: ((@escaping () -> Void) -> Void)?
    @objc public var filterUserAttributes: (([String: Any], FilteredMParticleUser) -> [String: Any]?)?

    private weak var owner: (any MPKitProtocol)?
    private weak var kitAPI: MPKitAPI?
    private let roktClient: MPRoktSDKClient
    private let identityClient: MPRoktIdentityClient
    private let pendingAttributesLock = NSLock()
    private var pendingMappedAttributes: [String: String] = [:]
    private var pendingAttributesUserID: NSNumber?
    private var pendingAttributesGeneration: UInt = 0
    private let preparationQueueLock = NSRecursiveLock()
    private var preparationQueue: [(UInt, (UInt) -> Void)] = []
    private var preparationInProgress = false
    private var preparationGeneration: UInt = 0

    /// Entry point used by the Objective-C shell in production.
    @objc public override convenience init() {
        self.init(
            roktClient: DefaultMPRoktSDKClient(),
            identityClient: DefaultMPRoktIdentityClient()
        )
    }

    init(
        roktClient: MPRoktSDKClient,
        identityClient: MPRoktIdentityClient? = nil
    ) {
        self.roktClient = roktClient
        self.identityClient = identityClient ?? DefaultMPRoktIdentityClient()
        super.init()
    }

    /// Injects the shell and its kit API after the container creates `MPKitRokt`.
    ///
    /// The references are weak because the Objective-C shell owns this implementation.
    @objc public func setContext(owner: any MPKitProtocol, kitAPI: MPKitAPI?) {
        self.owner = owner
        self.kitAPI = kitAPI
    }

    // MARK: - Lifecycle

    /// Validates the dashboard configuration and initializes Rokt for the current workspace.
    ///
    /// Rokt reports completion through its global event stream; `start()` is invoked only after a
    /// successful `InitComplete` event.
    @objc(didFinishLaunchingWithConfiguration:)
    public func didFinishLaunching(configuration: [AnyHashable: Any]) -> MPKitExecStatus {
        guard let partnerID = configuration["accountId"] as? String, !partnerID.isEmpty else {
            return status(.requirementsNotMet)
        }

        self.configuration = configuration
        Self.setActiveInstance(self)
        Self.log("Attempting to initialize Rokt with Kit Version: \(Constants.kitVersion)")
        applyMParticleLogLevel()
        registerGlobalEventsIfNeeded()

        if let customBaseURL = MParticle.sharedInstance().networkOptions?.customBaseURL {
            roktClient.setCustomBaseURL(customBaseURL)
        }

        roktClient.initialize(
            tagID: partnerID,
            sdkVersion: MParticle.sharedInstance().version,
            kitVersion: Constants.kitVersion
        )
        return status(.success)
    }

    /// Marks the kit active and posts the notification consumed by the core kit container.
    @objc public func start() {
        guard !started else { return }
        started = true
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .mParticleKitDidBecomeActive,
                object: nil,
                userInfo: [mParticleKitInstanceKey: NSNumber(value: Constants.kitCode)]
            )
        }
    }

    /// Ends the current workspace and removes all workspace- and user-scoped state.
    @objc public func stop() {
        Self.log("Stopping Rokt Kit for workspace switch")
        preparationQueueLock.lock()
        preparationGeneration &+= 1
        preparationQueue = []
        preparationInProgress = false
        roktClient.close()
        preparationQueueLock.unlock()
        Self.activeInstanceLock.lock()
        if Self.activeInstance === self {
            Self.activeInstance = nil
        }
        Self.activeInstanceLock.unlock()
        started = false
        configuration = nil
        pendingAttributesLock.lock()
        pendingMappedAttributes = [:]
        pendingAttributesUserID = nil
        pendingAttributesLock.unlock()
    }

    // MARK: - Placement APIs

    /// Prepares filtered attributes and then invokes Rokt's standard placement API.
    ///
    /// Preparation may complete asynchronously when an identity update or legacy-core write
    /// barrier is required. The call-time `RoktPlacementOptions` supplied by core is preserved.
    @objc(selectPlacementsWithIdentifier:attributes:embeddedViews:config:onEvent:filteredUser:options:)
    public func selectPlacements(
        identifier: String?,
        attributes: [String: String],
        embeddedViews: [String: RoktEmbeddedView]?,
        config: RoktConfig?,
        onEvent: ((RoktEvent) -> Void)?,
        filteredUser: FilteredMParticleUser,
        options: RoktPlacementOptions?
    ) -> MPKitExecStatus {
        prepareAttributes(attributes, filteredUser: filteredUser) { finalAttributes, _ in
            Self.logPlacementEvent(name: "selectPlacements", attributes: finalAttributes)
            let views = self.confirmedEmbeddedViews(embeddedViews)
            let placementOptions = options ?? RoktPlacementOptions(timestamp: 0)
            self.roktClient.selectPlacements(
                identifier: identifier ?? "",
                attributes: finalAttributes,
                placements: views,
                config: config,
                options: placementOptions,
                onEvent: onEvent
            )
        }
        return status(.success)
    }

    /// Uses the same attribute pipeline as standard placements before selecting Shoppable Ads.
    @objc(selectShoppableAdsWithIdentifier:attributes:config:onEvent:filteredUser:)
    public func selectShoppableAds(
        identifier: String,
        attributes: [String: String],
        config: RoktConfig?,
        onEvent: ((RoktEvent) -> Void)?,
        filteredUser: FilteredMParticleUser
    ) -> MPKitExecStatus {
        prepareAttributes(attributes, filteredUser: filteredUser) { finalAttributes, _ in
            Self.logPlacementEvent(name: "selectShoppableAds", attributes: finalAttributes)
            self.roktClient.selectShoppableAds(
                identifier: identifier,
                attributes: finalAttributes,
                config: config,
                onEvent: onEvent
            )
        }
        return status(.success)
    }

    // MARK: - Rokt API forwarding

    /// Registers a payment extension and adds the dashboard Stripe key when configured.
    @objc(registerPaymentExtension:)
    public func registerPaymentExtension(_ paymentExtension: PaymentExtension) -> MPKitExecStatus {
        var paymentConfig: [String: String] = [:]
        if let stripeKey = configuration?[Constants.stripePublishableKey] as? String, !stripeKey.isEmpty {
            paymentConfig["stripeKey"] = stripeKey
        }
        roktClient.registerPaymentExtension(paymentExtension, config: paymentConfig)
        return status(.success)
    }

    /// Forwards purchase completion after validating the Objective-C nullable arguments.
    @objc(purchaseFinalized:catalogItemId:success:)
    public func purchaseFinalized(
        _ identifier: String?,
        catalogItemId: String?,
        success: NSNumber?
    ) -> MPKitExecStatus {
        guard let identifier, let catalogItemId, let success else {
            return status(.fail)
        }
        roktClient.purchaseFinalized(
            identifier: identifier,
            catalogItemID: catalogItemId,
            success: success.boolValue
        )
        return status(.success)
    }

    @objc(events:onEvent:)
    public func events(_ identifier: String, onEvent: ((RoktEvent) -> Void)?) -> MPKitExecStatus {
        roktClient.events(identifier: identifier, onEvent: onEvent)
        return status(.success)
    }

    @objc(globalEvents:)
    public func globalEvents(_ onEvent: @escaping (RoktEvent) -> Void) -> MPKitExecStatus {
        roktClient.globalEvents(onEvent: onEvent)
        return status(.success)
    }

    @objc public func close() -> MPKitExecStatus {
        enqueuePreparation { [weak self] generation in
            self?.completePreparation(generation: generation) {
                self?.roktClient.close()
            }
        }
        return status(.success)
    }

    @objc(setSessionId:)
    public func setSessionID(_ sessionID: String) -> MPKitExecStatus {
        enqueuePreparation { [weak self] generation in
            self?.completePreparation(generation: generation) {
                self?.roktClient.setSessionID(sessionID)
            }
        }
        return status(.success)
    }

    @objc public func getSessionId() -> String? {
        roktClient.getSessionID()
    }

    @objc public func clearSession() -> MPKitExecStatus {
        Self.log("Rokt Kit clearing the Rokt session")
        enqueuePreparation { [weak self] generation in
            self?.completePreparation(generation: generation) {
                self?.roktClient.clearSession()
            }
        }
        return status(.success)
    }

    @objc(handleURLCallback:)
    public func handleURLCallback(_ url: URL) -> Bool {
        roktClient.handleURLCallback(url)
    }

    @objc(logMParticleApiDiagnostic:)
    public func logMParticleAPIDiagnostic(_ code: String) {
        roktClient.logMParticleAPICall(code)
    }

    @objc(setWrapperSdk:version:)
    public func setWrapperSDK(_ wrapperSDK: MPWrapperSdk, version: String) -> MPKitExecStatus {
        roktClient.setFrameworkType(Self.roktFrameworkType(wrapperSDK))
        return status(.success)
    }

    // MARK: - Compatibility and SwiftUI entry points

    /// Compatibility helper retained for callers of the existing Objective-C class method.
    ///
    /// New placement calls use `prepareAttributes(_:filteredUser:completion:)`, which also applies
    /// profile filtering and identity synchronization.
    @objc(prepareAttributes:filteredUser:performMapping:)
    public static func prepareLegacyAttributes(
        _ attributes: [String: String],
        filteredUser: FilteredMParticleUser?,
        performMapping: Bool
    ) -> [String: String] {
        guard let instance = currentActiveInstance() else {
            return confirmingSandbox(attributes)
        }
        return instance.preparedLegacyAttributes(
            attributes,
            filteredUser: filteredUser,
            performMapping: performMapping
        )
    }

    func preparedLegacyAttributes(
        _ attributes: [String: String],
        filteredUser: FilteredMParticleUser?,
        performMapping: Bool
    ) -> [String: String] {
        let mapped = performMapping ? mappedAttributes(attributes) : attributes
        let resolvedUser = filteredUser ?? currentFilteredUser(fallback: nil)
        return enrichedAttributes(mapped, filteredUser: resolvedUser)
    }

    @objc public static func getRoktHashedEmailUserIdentityType() -> NSNumber? {
        currentActiveInstance()?.hashedEmailIdentityType()
    }

    @objc(logSelectPlacementEvent:)
    public static func logSelectPlacementEvent(_ attributes: [String: String]) {
        logPlacementEvent(name: "selectPlacements", attributes: attributes)
    }

    @objc(logSelectShoppableAdsEvent:)
    public static func logSelectShoppableAdsEvent(_ attributes: [String: String]) {
        logPlacementEvent(name: "selectShoppableAds", attributes: attributes)
    }

    /// Gives `MPRoktLayout` the same workspace, identity, mapping, and filtering behavior as the
    /// imperative placement APIs.
    public static func prepareAttributesForLayout(
        _ attributes: [String: String],
        completion: @escaping ([String: String], Bool) -> Void
    ) {
        guard let instance = currentActiveInstance(),
              let filteredUser = instance.currentFilteredUser(fallback: nil) else {
            completion(confirmingSandbox(attributes), false)
            return
        }
        instance.prepareAttributes(attributes, filteredUser: filteredUser, completion: completion)
    }

    // MARK: - Attribute and identity pipeline

    /// Produces the final dictionary sent to Rokt.
    ///
    /// Processing order is deliberately significant:
    /// 1. synchronize mismatched email identities;
    /// 2. apply dashboard key mapping;
    /// 3. persist non-empty caller attributes;
    /// 4. merge the profile and apply connection/data-plan filters;
    /// 5. warn for caller keys removed by those filters; and
    /// 6. append identities, MPID, and sandbox after filtering.
    func prepareAttributes(
        _ attributes: [String: String],
        filteredUser: FilteredMParticleUser,
        completion: @escaping ([String: String], Bool) -> Void
    ) {
        enqueuePreparation { [weak self] generation in
            guard let self else { return }
            self.performAttributePreparation(attributes, filteredUser: filteredUser) { prepared, identified in
                self.completePreparation(generation: generation) {
                    completion(prepared, identified)
                }
            }
        }
    }

    /// Runs one placement preparation. `prepareAttributes` serializes calls to this method so an
    /// asynchronous identify cannot let a later placement overtake or modify the earlier request.
    private func performAttributePreparation(
        _ attributes: [String: String],
        filteredUser: FilteredMParticleUser,
        completion: @escaping ([String: String], Bool) -> Void
    ) {
        confirmUser(attributes: attributes, user: identityClient.currentUser) { _, identified in
            let currentFilteredUser = self.currentFilteredUser(fallback: filteredUser)
            let mapped = self.mappedAttributes(attributes)
            let persistableMapped = mapped.filter {
                $0.key != Constants.sandbox && !$0.value.isEmpty
            }

            for (key, value) in persistableMapped {
                if let kitAPI = self.kitAPI, let currentFilteredUser {
                    kitAPI.setUserAttribute(key, value: value, for: currentFilteredUser)
                }
            }

            let finishPreparation: ([String: Any], FilteredMParticleUser?) -> Void = { filteredProfile, refreshedUser in
                for key in self.blockedAttributeKeys(mapped: persistableMapped, filteredProfile: filteredProfile) {
                    self.warning("attribute \"\(key)\" not forwarded to Rokt — blocked by data filter")
                }

                var stringProfile = Self.valuesAsStrings(filteredProfile)
                if let explicitSandbox = attributes[Constants.sandbox] {
                    stringProfile[Constants.sandbox] = explicitSandbox
                }
                completion(self.enrichedAttributes(stringProfile, filteredUser: refreshedUser), identified)
            }
            if let currentFilteredUser, let filterUserAttributes = self.filterUserAttributes {
                let pending = self.attributesByMergingPendingWrites(
                    persistableMapped,
                    userID: currentFilteredUser.userId
                )
                if let filteredProfile = filterUserAttributes(pending.attributes, currentFilteredUser) {
                    finishPreparation(filteredProfile, currentFilteredUser)
                    self.afterPendingAttributeWrites? {
                        self.clearPendingAttributes(
                            generation: pending.generation,
                            userID: currentFilteredUser.userId
                        )
                    }
                } else {
                    self.clearPendingAttributes(
                        generation: pending.generation,
                        userID: currentFilteredUser.userId
                    )
                    self.finishAfterPendingWrites(
                        currentFilteredUser: currentFilteredUser,
                        finishPreparation: finishPreparation
                    )
                }
            } else {
                self.finishAfterPendingWrites(
                    currentFilteredUser: currentFilteredUser,
                    finishPreparation: finishPreparation
                )
            }
        }
    }

    private func enqueuePreparation(_ preparation: @escaping (UInt) -> Void) {
        preparationQueueLock.lock()
        let generation = preparationGeneration
        preparationQueue.append((generation, preparation))
        let next: (UInt, (UInt) -> Void)?
        if preparationInProgress {
            next = nil
        } else {
            preparationInProgress = true
            next = preparationQueue.removeFirst()
        }
        preparationQueueLock.unlock()
        if let next {
            next.1(next.0)
        }
    }

    /// Completes an operation only if it still belongs to the active workspace, then advances the
    /// FIFO. Holding the recursive lock through `action` prevents `stop()` from closing Rokt between
    /// the generation check and the SDK call.
    private func completePreparation(generation: UInt, action: () -> Void) {
        preparationQueueLock.lock()
        guard generation == preparationGeneration, preparationInProgress else {
            preparationQueueLock.unlock()
            return
        }

        action()

        guard generation == preparationGeneration, preparationInProgress else {
            preparationQueueLock.unlock()
            return
        }

        let next: (UInt, (UInt) -> Void)?
        if preparationQueue.isEmpty {
            preparationInProgress = false
            next = nil
        } else {
            next = preparationQueue.removeFirst()
        }
        preparationQueueLock.unlock()
        if let next {
            next.1(next.0)
        }
    }

    /// Legacy-core fallback used when synchronous candidate filtering is unavailable.
    ///
    /// The shell schedules this callback behind queued user-attribute writes, then returns to the
    /// main queue before Rokt is invoked.
    private func finishAfterPendingWrites(
        currentFilteredUser: FilteredMParticleUser?,
        finishPreparation: @escaping ([String: Any], FilteredMParticleUser?) -> Void
    ) {
        if let afterPendingAttributeWrites, kitAPI != nil {
            afterPendingAttributeWrites {
                let refreshedUser = self.currentFilteredUser(fallback: currentFilteredUser)
                finishPreparation(refreshedUser?.userAttributes ?? [:], refreshedUser)
            }
        } else {
            finishPreparation(currentFilteredUser?.userAttributes ?? [:], currentFilteredUser)
        }
    }

    private func currentFilteredUser(fallback: FilteredMParticleUser?) -> FilteredMParticleUser? {
        guard let owner, let kitAPI else { return fallback }
        return kitAPI.getCurrentUser(withKit: owner)
    }

    /// Identifies only when a supplied email or configured hashed-email identity differs from the
    /// current user. Failure intentionally falls back to the original user so placement continues.
    func confirmUser(
        attributes: [String: String],
        user: MParticleUser?,
        completion: @escaping (MParticleUser?, Bool) -> Void
    ) {
        let email = attributes["email"]
        let hashedEmail = attributes[Constants.emailSHA256]
        let hashedIdentity = hashedEmailIdentityType()
        let emailKey = NSNumber(value: MPIdentity.email.rawValue)
        let emailMismatch = email.map { user?.identities[emailKey] != $0 } ?? false
        let hashMismatch = hashedEmail.map { value in
            guard let hashedIdentity else { return false }
            return user?.identities[hashedIdentity] != value
        } ?? false

        guard emailMismatch || hashMismatch else {
            completion(user, false)
            return
        }

        if emailMismatch {
            warning(
                "The existing email on the user does not match the email passed in to " +
                    "`selectPlacements:`. Please sync the email identity to mParticle as soon " +
                    "as you receive it. The placement will wait for identify to complete."
            )
        } else if hashMismatch {
            warning(
                "The existing hashed email on the user does not match the hashed email passed " +
                    "in to `selectPlacements:`. Please sync the hashed email identity to " +
                    "mParticle as soon as you receive it. The placement will wait for identify."
            )
        }

        let request = user.map(MPIdentityApiRequest.init(user:)) ?? MPIdentityApiRequest()
        if let email {
            request.setIdentity(email, identityType: MPIdentity.email)
        }
        if let hashedEmail,
           let hashedIdentity,
           let identity = MPIdentity(rawValue: hashedIdentity.uintValue) {
            request.setIdentity(hashedEmail, identityType: identity)
        }
        identityClient.identify(request) { result, error in
            DispatchQueue.main.async {
                if let error {
                    Self.log("Failed to sync email from selectPlacements to user: \(error)")
                    completion(user, true)
                } else {
                    completion(result?.user, true)
                }
            }
        }
    }

    /// Applies the URL-encoded dashboard `placementAttributesMapping` configuration.
    ///
    /// Invalid or incomplete mapping configuration is treated as no mapping.
    func mappedAttributes(_ attributes: [String: String]) -> [String: String] {
        guard let encoded = configuration?[Constants.mapping] as? String else {
            return attributes
        }
        guard let decoded = encoded.removingPercentEncoding,
              let data = decoded.data(using: .utf8) else {
            warning("Rokt placement attribute mapping is invalid and was ignored.")
            return attributes
        }

        let json: Any
        do {
            json = try JSONSerialization.jsonObject(with: data)
        } catch {
            warning("Rokt placement attribute mapping is invalid and was ignored.")
            return attributes
        }
        guard let mappings = json as? [[String: Any]] else {
            warning("Rokt placement attribute mapping is invalid and was ignored.")
            return attributes
        }

        var result = attributes
        for mapping in mappings {
            guard let source = mapping[Constants.mappingSource] as? String,
                  let destination = mapping[Constants.mappingDestination] as? String,
                  let value = result.removeValue(forKey: source) else {
                continue
            }
            result[destination] = value
        }
        return result
    }

    /// Adds filtered user identities and MPID, applies hashed-email precedence, and guarantees a
    /// sandbox value. These values are appended after user-attribute filtering by design.
    func enrichedAttributes(
        _ attributes: [String: String],
        filteredUser: FilteredMParticleUser?
    ) -> [String: String] {
        var result = attributes
        if let filteredUser {
            for (key, value) in filteredUser.userIdentities {
                if let identityKey = identityString(key.uintValue) {
                    result[identityKey] = value
                }
            }
            result[Constants.mpid] = filteredUser.userId.stringValue
        }

        if result[Constants.emailSHA256] != nil {
            result.removeValue(forKey: "email")
        }
        return Self.confirmingSandbox(result)
    }

    func identityString(_ identity: UInt) -> String? {
        if hashedEmailIdentityType()?.uintValue == identity {
            return Constants.emailSHA256
        }
        let values: [UInt: String] = [
            MPIdentity.alias.rawValue: "alias",
            MPIdentity.customerId.rawValue: "customerid",
            MPIdentity.email.rawValue: "email",
            MPIdentity.facebook.rawValue: "facebook",
            MPIdentity.facebookCustomAudienceId.rawValue: "facebookcustomaudienceid",
            MPIdentity.google.rawValue: "google",
            MPIdentity.microsoft.rawValue: "microsoft",
            MPIdentity.other.rawValue: "other",
            MPIdentity.twitter.rawValue: "twitter",
            MPIdentity.yahoo.rawValue: "yahoo",
            MPIdentity.other2.rawValue: "other2",
            MPIdentity.other3.rawValue: "other3",
            MPIdentity.other4.rawValue: "other4",
            MPIdentity.other5.rawValue: "other5",
            MPIdentity.other6.rawValue: "other6",
            MPIdentity.other7.rawValue: "other7",
            MPIdentity.other8.rawValue: "other8",
            MPIdentity.other9.rawValue: "other9",
            MPIdentity.other10.rawValue: "other10",
            MPIdentity.mobileNumber.rawValue: "mobile_number",
            MPIdentity.phoneNumber2.rawValue: "phone_number_2",
            MPIdentity.phoneNumber3.rawValue: "phone_number_3",
            MPIdentity.iosAdvertiserId.rawValue: "ios_idfa",
            MPIdentity.iosVendorId.rawValue: "ios_idfv",
            MPIdentity.pushToken.rawValue: "push_token",
            MPIdentity.deviceApplicationStamp.rawValue: "device_application_stamp"
        ]
        return values[identity]
    }

    func hashedEmailIdentityType() -> NSNumber? {
        guard let value = configuration?[Constants.hashedEmailIdentity] as? String else { return nil }
        let identities: [String: MPIdentity] = [
            "alias": .alias, "customerid": .customerId, "email": .email,
            "facebook": .facebook, "facebookcustomaudienceid": .facebookCustomAudienceId,
            "google": .google, "microsoft": .microsoft, "other": .other,
            "twitter": .twitter, "yahoo": .yahoo, "other2": .other2, "other3": .other3,
            "other4": .other4, "other5": .other5, "other6": .other6, "other7": .other7,
            "other8": .other8, "other9": .other9, "other10": .other10,
            "mobile_number": .mobileNumber, "phone_number_2": .phoneNumber2,
            "phone_number_3": .phoneNumber3, "ios_idfa": .iosAdvertiserId,
            "ios_idfv": .iosVendorId, "push_token": .pushToken,
            "device_application_stamp": .deviceApplicationStamp
        ]
        guard let identity = identities[value.lowercased()] else { return nil }
        return NSNumber(value: identity.rawValue)
    }

    func confirmedEmbeddedViews(
        _ embeddedViews: [String: RoktEmbeddedView]?
    ) -> [String: RoktEmbeddedView] {
        embeddedViews ?? [:]
    }

    private func warning(_ message: String) {
        if let warningHandler {
            warningHandler(message)
        } else {
            Self.log(message)
        }
    }

    private func status(_ code: MPKitReturnCode) -> MPKitExecStatus {
        MPKitExecStatus(sdkCode: NSNumber(value: Constants.kitCode), returnCode: code)
    }

    static func confirmingSandbox(_ attributes: [String: String]) -> [String: String] {
        var result = attributes
        if result[Constants.sandbox] == nil {
            result[Constants.sandbox] =
                MParticle.sharedInstance().environment == .development ? "true" : "false"
        }
        return result
    }

    static func valuesAsStrings(_ values: [String: Any]) -> [String: String] {
        var result: [String: String] = [:]
        for (key, value) in values {
            switch value {
            case let string as String:
                result[key] = string
            case let number as NSNumber:
                result[key] = CFGetTypeID(number) == CFBooleanGetTypeID()
                    ? (number.boolValue ? "true" : "false")
                    : number.stringValue
            case let date as Date:
                result[key] = MPKitAPI.string(fromDateRFC3339: date)
            case let data as Data where !data.isEmpty:
                result[key] = String(data: data, encoding: .utf8)
            case is NSNull:
                result[key] = "null"
            case let collection as NSArray:
                result[key] = collection.description
            case let dictionary as NSDictionary:
                result[key] = dictionary.description
            default:
                continue
            }
        }
        return result
    }

    func blockedAttributeKeys(
        mapped: [String: String],
        filteredProfile: [String: Any]
    ) -> [String] {
        mapped.keys
            .filter { $0 != Constants.sandbox && filteredProfile[$0] == nil }
            .sorted()
    }

    /// Keeps writes from immediately consecutive placements visible until the core message queue
    /// persists them. State is scoped by MPID to prevent attributes crossing user boundaries.
    private func attributesByMergingPendingWrites(
        _ attributes: [String: String],
        userID: NSNumber
    ) -> (attributes: [String: String], generation: UInt) {
        pendingAttributesLock.lock()
        defer { pendingAttributesLock.unlock() }
        if pendingAttributesUserID != userID {
            pendingMappedAttributes = [:]
            pendingAttributesUserID = userID
        }
        pendingMappedAttributes.merge(attributes) { _, latest in latest }
        pendingAttributesGeneration &+= 1
        return (pendingMappedAttributes, pendingAttributesGeneration)
    }

    /// Clears only the latest pending-write generation; an older queue callback must not erase
    /// attributes belonging to a newer placement.
    private func clearPendingAttributes(generation: UInt, userID: NSNumber) {
        pendingAttributesLock.lock()
        defer { pendingAttributesLock.unlock() }
        guard pendingAttributesGeneration == generation, pendingAttributesUserID == userID else {
            return
        }
        pendingMappedAttributes = [:]
        pendingAttributesUserID = nil
    }

    /// Installs one process-wide initialization observer while routing success to the active
    /// workspace instance.
    private func registerGlobalEventsIfNeeded() {
        Self.activeInstanceLock.lock()
        guard !Self.didRegisterGlobalEvents else {
            Self.activeInstanceLock.unlock()
            return
        }
        Self.didRegisterGlobalEvents = true
        Self.activeInstanceLock.unlock()

        roktClient.globalEvents { event in
            guard let complete = event as? RoktEvent.InitComplete, complete.success,
                  let instance = Self.currentActiveInstance() else {
                return
            }
            instance.start()
            NotificationCenter.default.post(
                name: NSNotification.Name(rawValue: "mParticle.Rokt.Initialized"),
                object: nil,
                userInfo: [mParticleKitInstanceKey: NSNumber(value: Constants.kitCode)]
            )
        }
    }

    private static func setActiveInstance(_ instance: MPRoktKitImplementation) {
        activeInstanceLock.lock()
        activeInstance = instance
        activeInstanceLock.unlock()
    }

    private static func currentActiveInstance() -> MPRoktKitImplementation? {
        activeInstanceLock.lock()
        defer { activeInstanceLock.unlock() }
        return activeInstance
    }

    private func applyMParticleLogLevel() {
        let level: RoktLogLevel
        switch MParticle.sharedInstance().logLevel {
        case .verbose: level = .verbose
        case .debug: level = .debug
        case .warning: level = .warning
        case .error: level = .error
        default: level = .none
        }
        roktClient.setLogLevel(level)
    }

    private static func roktFrameworkType(_ wrapperSDK: MPWrapperSdk) -> RoktFrameworkType {
        switch wrapperSDK {
        case .cordova: return .Cordova
        case .reactNative: return .ReactNative
        case .flutter: return .Flutter
        default: return .iOS
        }
    }

    private static func logPlacementEvent(name: String, attributes: [String: String]) {
        guard let event = MPEvent(name: name, type: .other) else { return }
        event.customAttributes = attributes
        MParticle.sharedInstance().logEvent(event)
    }

    private static func log(_ message: String) {
        if MParticle.sharedInstance().environment == .development {
            print("MPRokt -> \(message)")
        }
    }
}
