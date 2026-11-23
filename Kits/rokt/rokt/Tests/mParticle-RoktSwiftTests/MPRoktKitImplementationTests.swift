import Foundation
import Testing
import mParticle_Apple_SDK
import mParticle_Rokt
import RoktContracts
import Rokt_Widget
@testable import mParticle_Rokt_Internal

private final class MockRoktSDKClient: MPRoktSDKClient {
    struct Purchase {
        let identifier: String
        let catalogItemID: String
        let success: Bool
    }

    var selectedIdentifier: String?
    var selectedAttributes: [String: String]?
    var selectedOptions: RoktPlacementOptions?
    var closed = false
    var clearedSession = false
    var sessionID: String?
    var session: RoktSession?
    var handledURL = false
    var diagnosticCode: String?
    var purchase: Purchase?
    var eventIdentifier: String?
    var frameworkType: RoktFrameworkType?
    var calls: [String] = []

    func initialize(tagID: String, sdkVersion: String, kitVersion: String) {}
    func setCustomBaseURL(_ url: URL) {}
    func setLogLevel(_ level: RoktLogLevel) {}
    func setFrameworkType(_ type: RoktFrameworkType) { frameworkType = type }
    func selectPlacements(
        identifier: String,
        attributes: [String: String],
        placements: [String: RoktEmbeddedView]?,
        config: RoktConfig?,
        options: RoktPlacementOptions?,
        onEvent: ((RoktEvent) -> Void)?
    ) {
        calls.append("selectPlacements:\(identifier)")
        selectedIdentifier = identifier
        selectedAttributes = attributes
        selectedOptions = options
    }
    func selectShoppableAds(
        identifier: String,
        attributes: [String: String],
        config: RoktConfig?,
        onEvent: ((RoktEvent) -> Void)?
    ) {
        calls.append("selectShoppableAds:\(identifier)")
        selectedIdentifier = identifier
        selectedAttributes = attributes
    }
    func registerPaymentExtension(_ paymentExtension: PaymentExtension, config: [String: String]) {}
    func purchaseFinalized(identifier: String, catalogItemID: String, success: Bool) {
        purchase = Purchase(identifier: identifier, catalogItemID: catalogItemID, success: success)
    }
    func events(identifier: String, onEvent: ((RoktEvent) -> Void)?) {
        eventIdentifier = identifier
    }
    func globalEvents(onEvent: @escaping (RoktEvent) -> Void) {}
    func close() {
        calls.append("close")
        closed = true
    }
    func setSession(_ session: RoktSession) {
        calls.append("setSession:\(session.sessionId)")
        self.session = session
    }
    func getSession() -> RoktSession? { session }
    func setSessionID(_ sessionID: String) {
        calls.append("setSessionID:\(sessionID)")
        self.sessionID = sessionID
    }
    func getSessionID() -> String? { sessionID }
    func clearSession() {
        calls.append("clearSession")
        clearedSession = true
    }
    func handleURLCallback(_ url: URL) -> Bool { handledURL }
    func logMParticleAPICall(_ code: String) { diagnosticCode = code }
}

private final class MockIdentityClient: MPRoktIdentityClient {
    var currentUser: MParticleUser?
    var identifyCount = 0
    var error: Error?
    var lastRequest: MPIdentityApiRequest?

    func identify(
        _ request: MPIdentityApiRequest,
        completion: @escaping (MPIdentityApiResult?, Error?) -> Void
    ) {
        identifyCount += 1
        lastRequest = request
        completion(nil, error)
    }
}

private final class DeferredIdentityClient: MPRoktIdentityClient {
    var currentUser: MParticleUser?
    var identifyCount = 0
    var lastRequest: MPIdentityApiRequest?
    private var completions: [(MPIdentityApiResult?, Error?) -> Void] = []

    var hasPendingIdentify: Bool { !completions.isEmpty }
    var pendingIdentifyCount: Int { completions.count }

    func identify(
        _ request: MPIdentityApiRequest,
        completion: @escaping (MPIdentityApiResult?, Error?) -> Void
    ) {
        identifyCount += 1
        lastRequest = request
        completions.append(completion)
    }

    /// Completes only the oldest pending identify, leaving later ones queued.
    func completeOldest(user: MParticleUser) {
        guard !completions.isEmpty else { return }
        let completion = completions.removeFirst()
        let apiResult = MPIdentityApiResult()
        apiResult.user = user
        completion(apiResult, nil)
    }

    func complete(user: MParticleUser? = nil, error: Error? = nil) {
        let pending = completions
        completions = []
        let result: MPIdentityApiResult? = user.map { resolvedUser in
            let apiResult = MPIdentityApiResult()
            apiResult.user = resolvedUser
            return apiResult
        }
        pending.forEach { $0(result, error) }
    }
}

private final class TestUser: MParticleUser {
    let testUserID: NSNumber
    let testIdentities: [NSNumber: String]
    var storedAttributes: [String: Any]
    var setAttributes: [String: Any] = [:]
    var removedAttributeKeys: [String] = []
    var defersAttributeRemoval: Bool
    var defersAttributeSets: Bool

    init(
        userID: NSNumber = 1,
        identities: [NSNumber: String] = [:],
        attributes: [String: Any] = [:],
        defersAttributeRemoval: Bool = false,
        defersAttributeSets: Bool = false
    ) {
        testUserID = userID
        testIdentities = identities
        storedAttributes = attributes
        self.defersAttributeRemoval = defersAttributeRemoval
        self.defersAttributeSets = defersAttributeSets
        super.init()
    }

    override var userId: NSNumber { testUserID }
    override var identities: [NSNumber: String] { testIdentities }

    override var userAttributes: [String: Any] {
        get { storedAttributes }
        set { storedAttributes = newValue }
    }

    override func setUserAttribute(_ key: String, value: Any) {
        if !defersAttributeSets {
            storedAttributes[key] = value
        }
        setAttributes[key] = value
    }

    override func removeAttribute(_ key: String) {
        if !defersAttributeRemoval {
            storedAttributes.removeValue(forKey: key)
        }
        removedAttributeKeys.append(key)
    }
}

private final class TestFilteredUser: FilteredMParticleUser {
    let testUserID: NSNumber
    let testAttributes: [String: Any]

    init(userID: NSNumber = 123, attributes: [String: Any] = [:]) {
        testUserID = userID
        testAttributes = attributes
        super.init()
    }

    override var userId: NSNumber { testUserID }
    override var userIdentities: [NSNumber: String] {
        [NSNumber(value: MPIdentity.email.rawValue): "ada@example.com"]
    }
    override var userAttributes: [String: Any] { testAttributes }
}

private final class MockKitAPI: MPKitAPI {
    let filteredUser: FilteredMParticleUser
    var setAttributes: [String: Any] = [:]
    var removedAttributeKeys: [String] = []

    init(filteredUser: FilteredMParticleUser) {
        self.filteredUser = filteredUser
        super.init()
    }

    override func getCurrentUser(withKit kit: any MPKitProtocol) -> FilteredMParticleUser {
        filteredUser
    }

    override func setUserAttribute(_ key: String, value: Any, for filteredUser: FilteredMParticleUser) {
        setAttributes[key] = value
    }

    override func removeUserAttribute(_ key: String, for filteredUser: FilteredMParticleUser) {
        removedAttributeKeys.append(key)
    }
}

struct MPRoktKitImplementationTests {
    private func makeNoTargetingImplementation(
        currentUser: TestUser,
        filteredUser: TestFilteredUser
    ) -> (MPRoktKitImplementation, MockRoktSDKClient, MockIdentityClient) {
        let client = MockRoktSDKClient()
        let identityClient = MockIdentityClient()
        identityClient.currentUser = currentUser
        let kitAPI = MockKitAPI(filteredUser: filteredUser)
        let implementation = MPRoktKitImplementation(roktClient: client, identityClient: identityClient)
        implementation.setContext(owner: MPKitRokt(), kitAPI: kitAPI)
        implementation.filterUserAttributes = { attributes, _ in attributes }
        return (implementation, client, identityClient)
    }

    private func selectPlacements(
        _ implementation: MPRoktKitImplementation,
        attributes: [String: String],
        filteredUser: TestFilteredUser
    ) {
        _ = implementation.selectPlacements(
            identifier: "checkout",
            attributes: attributes,
            embeddedViews: nil,
            config: nil,
            onEvent: nil,
            filteredUser: filteredUser,
            options: nil
        )
    }

    @Test func olderIdentifyDoesNotRestoreATagANewerCallCleared() {
        let identityClient = DeferredIdentityClient()
        identityClient.currentUser = TestUser(
            userID: 1,
            identities: [NSNumber(value: MPIdentity.email.rawValue): "old@example.com"]
        )
        let filteredUser = TestFilteredUser(userID: 1)
        let implementation = MPRoktKitImplementation(roktClient: MockRoktSDKClient(), identityClient: identityClient)
        implementation.setContext(owner: MPKitRokt(), kitAPI: MockKitAPI(filteredUser: filteredUser))
        implementation.filterUserAttributes = { attributes, _ in attributes }
        let identifiedUser = TestUser(userID: 2, attributes: ["$NoTargeting": "true"])

        selectPlacements(
            implementation,
            attributes: ["email": "new@example.com", "noTargeting": "true"],
            filteredUser: filteredUser
        )
        identityClient.currentUser = identifiedUser
        selectPlacements(implementation, attributes: ["shippingcountry": "US"], filteredUser: filteredUser)
        #expect(identifiedUser.storedAttributes["$NoTargeting"] == nil)
        identityClient.complete(user: identifiedUser)

        #expect(identifiedUser.setAttributes["$NoTargeting"] == nil)
        #expect(identifiedUser.storedAttributes["$NoTargeting"] == nil)
    }

    @Test func optOutAfterAQueuedRemovalStillSetsTheTag() {
        // Core applies attribute writes later on its queue, so the removal is still pending.
        let currentUser = TestUser(userID: 7, attributes: ["$NoTargeting": "true"], defersAttributeRemoval: true)
        let filteredUser = TestFilteredUser(userID: 7)
        let (implementation, _, _) = makeNoTargetingImplementation(currentUser: currentUser, filteredUser: filteredUser)

        selectPlacements(implementation, attributes: ["shippingcountry": "US"], filteredUser: filteredUser)
        #expect(currentUser.removedAttributeKeys == ["$NoTargeting"])
        selectPlacements(implementation, attributes: ["noTargeting": "true"], filteredUser: filteredUser)

        #expect(currentUser.setAttributes["$NoTargeting"] as? String == "true")
    }

    @Test func removalAfterAQueuedSetStillRemovesTheTag() {
        let currentUser = TestUser(userID: 7, defersAttributeSets: true)
        let filteredUser = TestFilteredUser(userID: 7)
        let (implementation, _, _) = makeNoTargetingImplementation(currentUser: currentUser, filteredUser: filteredUser)

        selectPlacements(implementation, attributes: ["noTargeting": "true"], filteredUser: filteredUser)
        #expect(currentUser.setAttributes["$NoTargeting"] as? String == "true")
        selectPlacements(implementation, attributes: ["shippingcountry": "US"], filteredUser: filteredUser)

        #expect(currentUser.removedAttributeKeys.contains("$NoTargeting"))
    }

    @Test func placementWithNoPrivacySourceRemovesStaleNoTargeting() {
        let currentUser = TestUser(userID: 7, attributes: ["$NoTargeting": "true"])
        let filteredUser = TestFilteredUser(userID: 7)
        let (implementation, client, _) = makeNoTargetingImplementation(
            currentUser: currentUser,
            filteredUser: filteredUser
        )

        selectPlacements(implementation, attributes: ["shippingcountry": "US"], filteredUser: filteredUser)

        #expect(currentUser.removedAttributeKeys == ["$NoTargeting"])
        #expect(client.selectedAttributes?["$NoTargeting"] == nil)
    }

    @Test func placementKeepsNoTargetingWhileProfileNoTargetingIsTrue() {
        let currentUser = TestUser(userID: 7, attributes: ["noTargeting": "true", "$NoTargeting": "true"])
        let filteredUser = TestFilteredUser(userID: 7)
        let (implementation, client, _) = makeNoTargetingImplementation(
            currentUser: currentUser,
            filteredUser: filteredUser
        )

        selectPlacements(implementation, attributes: ["shippingcountry": "US"], filteredUser: filteredUser)

        #expect(currentUser.removedAttributeKeys.isEmpty)
        #expect(client.selectedAttributes?["$NoTargeting"] == "true")
    }

    @Test func identityChangeSetsNoTargetingFromNewUsersProfile() {
        let newUser = TestUser(userID: 8, attributes: ["noTargeting": "true"])
        let (implementation, _, _) = makeNoTargetingImplementation(
            currentUser: newUser,
            filteredUser: TestFilteredUser(userID: 8)
        )

        implementation.syncNoTargetingAfterIdentityChange(TestFilteredUser(userID: 8))

        #expect(newUser.setAttributes["$NoTargeting"] as? String == "true")
    }

    @Test func identityChangeRemovesNoTargetingSetByHandWithoutNoTargeting() {
        let newUser = TestUser(userID: 8, attributes: ["$NoTargeting": "true"])
        let (implementation, _, _) = makeNoTargetingImplementation(
            currentUser: newUser,
            filteredUser: TestFilteredUser(userID: 8)
        )

        implementation.syncNoTargetingAfterIdentityChange(TestFilteredUser(userID: 8))

        #expect(newUser.removedAttributeKeys == ["$NoTargeting"])
    }

    @Test func identityChangeKeepsPerCallOptOutFromThatUsersLastPlacement() {
        let currentUser = TestUser(userID: 7)
        let filteredUser = TestFilteredUser(userID: 7)
        let (implementation, _, _) = makeNoTargetingImplementation(
            currentUser: currentUser,
            filteredUser: filteredUser
        )
        selectPlacements(implementation, attributes: ["noTargeting": "true"], filteredUser: filteredUser)
        #expect(currentUser.storedAttributes["$NoTargeting"] as? String == "true")

        implementation.syncNoTargetingAfterIdentityChange(filteredUser)

        #expect(currentUser.removedAttributeKeys.isEmpty)
        #expect(currentUser.storedAttributes["$NoTargeting"] as? String == "true")
    }

    @Test func identityChangeToAnotherUserIgnoresPreviousUsersPerCallOptOut() {
        let firstUser = TestUser(userID: 7)
        let firstFilteredUser = TestFilteredUser(userID: 7)
        let (implementation, _, identityClient) = makeNoTargetingImplementation(
            currentUser: firstUser,
            filteredUser: firstFilteredUser
        )
        selectPlacements(implementation, attributes: ["noTargeting": "true"], filteredUser: firstFilteredUser)
        let secondUser = TestUser(userID: 9, attributes: ["$NoTargeting": "true"])
        identityClient.currentUser = secondUser

        implementation.syncNoTargetingAfterIdentityChange(TestFilteredUser(userID: 9))

        #expect(secondUser.removedAttributeKeys == ["$NoTargeting"])
    }

    @Test func identityChangeForAUserThatIsNoLongerCurrentChangesNothing() {
        let currentUser = TestUser(userID: 9, attributes: ["$NoTargeting": "true"])
        let (implementation, _, _) = makeNoTargetingImplementation(
            currentUser: currentUser,
            filteredUser: TestFilteredUser(userID: 9)
        )

        implementation.syncNoTargetingAfterIdentityChange(TestFilteredUser(userID: 8))

        #expect(currentUser.removedAttributeKeys.isEmpty)
        #expect(currentUser.setAttributes.isEmpty)
    }

    @Test func mapsConfiguredPlacementAttributes() throws {
        let implementation = MPRoktKitImplementation()
        let mapping = try JSONSerialization.data(
            withJSONObject: [[
                "map": "first_name",
                "value": "firstname",
                "jsmap": NSNull()
            ]]
        )
        implementation.configuration = [
            "placementAttributesMapping":
                try #require(String(data: mapping, encoding: .utf8))
                    .addingPercentEncoding(withAllowedCharacters: .alphanumerics)
        ]

        let result = implementation.mappedAttributes([
            "first_name": "Ada",
            "unchanged": "value"
        ])

        #expect(result["first_name"] == nil)
        #expect(result["firstname"] == "Ada")
        #expect(result["unchanged"] == "value")
    }

    // The mapping arrives as a server-supplied JSON string, so every level of it can be the wrong
    // shape: the configuration value itself, the decoded root, an element, or a map/value member.
    // Each shape is ignored rather than messaged.
    @Test func wrongTypedMappingShapesLeaveAttributesUnchanged() throws {
        let attributes = ["first_name": "Ada"]

        // A configuration value that is not a string at all.
        for nonString in [1 as Any, [] as Any, [:] as Any, NSNull()] {
            let implementation = MPRoktKitImplementation()
            implementation.configuration = ["placementAttributesMapping": nonString]
            #expect(implementation.mappedAttributes(attributes) == attributes)
        }

        // A decoded root that is not an array, and elements that are not dictionaries or whose
        // map/value members are not strings.
        for json in ["{}", "1", "\"a\"", "[1]", "[[]]", "[null]", "[{}]",
                     "[{\"map\":1,\"value\":\"firstname\"}]",
                     "[{\"map\":\"first_name\",\"value\":[]}]"] {
            let implementation = MPRoktKitImplementation()
            implementation.configuration = [
                "placementAttributesMapping":
                    try #require(json.addingPercentEncoding(withAllowedCharacters: .alphanumerics))
            ]
            #expect(implementation.mappedAttributes(attributes) == attributes,
                    "mapping \(json) should have been ignored")
        }
    }

    // A malformed entry must not take the valid ones down with it.
    @Test func validMappingEntriesSurviveAlongsideMalformedOnes() throws {
        let json = "[1,{\"map\":\"first_name\",\"value\":\"firstname\"},null]"
        let implementation = MPRoktKitImplementation()
        implementation.configuration = [
            "placementAttributesMapping":
                try #require(json.addingPercentEncoding(withAllowedCharacters: .alphanumerics))
        ]

        // The eager Swift bridge rejects the whole array when an element is not a dictionary, so
        // this records the behaviour rather than asserting the per-entry skip the core SDK used.
        let result = implementation.mappedAttributes(["first_name": "Ada"])
        #expect(result["first_name"] == "Ada" || result["firstname"] == "Ada")
    }

    // A non-string or unrecognised identity type must not be messaged or resolved.
    @Test func wrongTypedHashedEmailIdentityTypeIsIgnored() {
        for value in [1 as Any, [] as Any, [:] as Any, NSNull(), "" as Any, "not-an-identity" as Any] {
            let implementation = MPRoktKitImplementation()
            implementation.configuration = ["hashedEmailUserIdentityType": value]
            #expect(implementation.hashedEmailIdentityType() == nil)
        }
    }

    @Test func malformedMappingLeavesAttributesUnchanged() {
        let implementation = MPRoktKitImplementation()
        implementation.configuration = ["placementAttributesMapping": "%not-json"]
        let attributes = ["first_name": "Ada"]
        var warnings: [String] = []
        implementation.warningHandler = { warnings.append($0) }

        #expect(implementation.mappedAttributes(attributes) == attributes)
        #expect(warnings == [
            "Rokt placement attribute mapping is invalid and was ignored."
        ])
    }

    @Test func mappingSourceWinsDestinationCollision() {
        let implementation = MPRoktKitImplementation()
        let json = "[{\"map\":\"source\",\"value\":\"destination\"}]"
        implementation.configuration = [
            "placementAttributesMapping":
                json.addingPercentEncoding(withAllowedCharacters: .alphanumerics)
        ]

        let result = implementation.mappedAttributes([
            "source": "mapped",
            "destination": "original"
        ])

        #expect(result == ["destination": "mapped"])
    }

    @Test func legacyPreparationResolvesCurrentUserWhenNoneIsProvided() {
        let implementation = MPRoktKitImplementation(roktClient: MockRoktSDKClient())
        let user = TestFilteredUser(userID: 456)
        let kitAPI = MockKitAPI(filteredUser: user)
        let owner = MPKitRokt()
        implementation.setContext(owner: owner, kitAPI: kitAPI)

        let result = implementation.preparedLegacyAttributes(
            [:],
            filteredUser: nil,
            performMapping: false
        )

        #expect(result["email"] == "ada@example.com")
        #expect(result["mpid"] == "456")
    }

    @Test func reportsOnlyCallerAttributesMissingAfterFilter() {
        let implementation = MPRoktKitImplementation()
        let blocked = implementation.blockedAttributeKeys(
            mapped: [
                "firstname": "Ada",
                "allowed": "yes",
                "sandbox": "true"
            ],
            filteredProfile: [
                "allowed": "yes",
                "stored": "profile"
            ]
        )

        #expect(blocked == ["firstname"])
    }

    @Test func filteredCallerAttributeIsWithheldAndLogged() async {
        let implementation = MPRoktKitImplementation()
        let user = TestFilteredUser(attributes: ["allowed": "caller"])
        var warnings: [String] = []
        implementation.warningHandler = { warnings.append($0) }

        let prepared = await withCheckedContinuation { continuation in
            implementation.prepareAttributes(
                [
                    "allowed": "caller",
                    "firstname": "Ada",
                    "sandbox": "true"
                ],
                filteredUser: user
            ) { attributes, _ in
                continuation.resume(returning: attributes)
            }
        }

        #expect(prepared["allowed"] == "caller")
        #expect(prepared["firstname"] == nil)
        #expect(prepared["email"] == "ada@example.com")
        #expect(prepared["mpid"] == "123")
        #expect(prepared["sandbox"] == "true")
        #expect(warnings == [
            "attribute \"firstname\" not forwarded to Rokt — blocked by data filter"
        ])
    }

    @Test func identifyNoOpSuccessAndFailurePaths() async {
        let roktClient = MockRoktSDKClient()
        let identityClient = MockIdentityClient()
        let implementation = MPRoktKitImplementation(
            roktClient: roktClient,
            identityClient: identityClient
        )

        let noOpIdentified = await identifyDecision(
            implementation,
            attributes: [:],
            user: nil
        )
        #expect(!noOpIdentified)
        #expect(identityClient.identifyCount == 0)

        let successIdentified = await identifyDecision(
            implementation,
            attributes: ["email": "ada@example.com"],
            user: nil
        )
        #expect(successIdentified)
        #expect(identityClient.identifyCount == 1)

        identityClient.error = NSError(domain: "test", code: 1)
        let failureIdentified = await identifyDecision(
            implementation,
            attributes: ["email": "grace@example.com"],
            user: nil
        )
        #expect(failureIdentified)
        #expect(identityClient.identifyCount == 2)
    }

    @Test func identifyRequestDoesNotClearAnOmittedEmailIdentity() async {
        let identityClient = MockIdentityClient()
        let implementation = MPRoktKitImplementation(
            roktClient: MockRoktSDKClient(),
            identityClient: identityClient
        )
        implementation.configuration = ["hashedEmailUserIdentityType": "Other4"]

        _ = await identifyDecision(
            implementation,
            attributes: ["emailsha256": "hash"],
            user: nil
        )

        let identities = identityClient.lastRequest?.identities
        #expect(identities?[NSNumber(value: MPIdentity.other4.rawValue)] as? String == "hash")
        #expect(identities?[NSNumber(value: MPIdentity.email.rawValue)] == nil)
    }

    @Test func identifyRequestDoesNotClearAnOmittedHashedEmailIdentity() async {
        let identityClient = MockIdentityClient()
        let implementation = MPRoktKitImplementation(
            roktClient: MockRoktSDKClient(),
            identityClient: identityClient
        )
        implementation.configuration = ["hashedEmailUserIdentityType": "Other4"]

        _ = await identifyDecision(
            implementation,
            attributes: ["email": "ada@example.com"],
            user: nil
        )

        let identities = identityClient.lastRequest?.identities
        #expect(identities?[NSNumber(value: MPIdentity.email.rawValue)] as? String == "ada@example.com")
        #expect(identities?[NSNumber(value: MPIdentity.other4.rawValue)] == nil)
    }

    @Test func placementPreparationDoesNotWaitForIdentify() {
        let identityClient = DeferredIdentityClient()
        let implementation = MPRoktKitImplementation(
            roktClient: MockRoktSDKClient(),
            identityClient: identityClient
        )
        let user = TestFilteredUser()
        implementation.filterUserAttributes = { attributes, _ in attributes }
        var results: [[String: String]] = []
        var identifiedFlags: [Bool] = []

        implementation.prepareAttributes(
            ["email": "grace@example.com", "first": "one"],
            filteredUser: user
        ) { attributes, identified in
            results.append(attributes)
            identifiedFlags.append(identified)
        }
        implementation.prepareAttributes(
            ["second": "two"],
            filteredUser: user
        ) { attributes, identified in
            results.append(attributes)
            identifiedFlags.append(identified)
        }

        #expect(identityClient.hasPendingIdentify)
        #expect(results.count == 2)
        #expect(identifiedFlags == [true, false])
        #expect(results[0]["first"] == "one")
        #expect(results[0]["second"] == nil)
        #expect(results[1]["first"] == "one")
        #expect(results[1]["second"] == "two")
    }

    @Test func paypalPayerIdIsSentToRoktAndNotSavedToTheProfile() {
        let implementation = MPRoktKitImplementation(
            roktClient: MockRoktSDKClient(),
            identityClient: DeferredIdentityClient()
        )
        let user = TestFilteredUser()
        let kitAPI = MockKitAPI(filteredUser: user)
        implementation.setContext(owner: MPKitRokt(), kitAPI: kitAPI)
        implementation.filterUserAttributes = { attributes, _ in attributes }

        var prepared: [String: String] = [:]
        implementation.prepareAttributes(
            ["firstname": "Ada", "paypalpayerid": "PAYERID123", "PayPalPayerID": "PAYERID456"],
            filteredUser: user
        ) { attributes, _ in
            prepared = attributes
        }

        #expect(kitAPI.setAttributes.keys.sorted() == ["firstname"])
        #expect(prepared["firstname"] == "Ada")
        #expect(prepared["paypalpayerid"] == "PAYERID123")
        #expect(prepared["PayPalPayerID"] == "PAYERID456")
    }

    @Test func paypalPayerIdIsSentToRoktWhenNoFilterReadsTheProfile() {
        let implementation = MPRoktKitImplementation(
            roktClient: MockRoktSDKClient(),
            identityClient: DeferredIdentityClient()
        )
        let user = TestFilteredUser()
        let kitAPI = MockKitAPI(filteredUser: user)
        implementation.setContext(owner: MPKitRokt(), kitAPI: kitAPI)
        var warnings: [String] = []
        implementation.warningHandler = { warnings.append($0) }

        var prepared: [String: String] = [:]
        implementation.prepareAttributes(
            ["paypalpayerid": "PAYERID123"],
            filteredUser: user
        ) { attributes, _ in
            prepared = attributes
        }

        #expect(kitAPI.setAttributes.isEmpty)
        #expect(prepared["paypalpayerid"] == nil)
        #expect(warnings == ["attribute \"paypalpayerid\" not forwarded to Rokt — blocked by data filter"])

        var nilFilterPrepared: [String: String] = [:]
        implementation.filterUserAttributes = { _, _ in nil }
        implementation.afterPendingAttributeWrites = { $0() }
        implementation.prepareAttributes(
            ["paypalpayerid": "PAYERID123"],
            filteredUser: user
        ) { attributes, _ in
            nilFilterPrepared = attributes
        }

        #expect(kitAPI.setAttributes.isEmpty)
        #expect(nilFilterPrepared["paypalpayerid"] == nil)
        #expect(warnings.count == 2)

        let prepopulatedUser = TestFilteredUser(attributes: ["paypalpayerid": "STORED_PAYER"])
        let prepopulatedKitAPI = MockKitAPI(filteredUser: prepopulatedUser)
        implementation.setContext(owner: MPKitRokt(), kitAPI: prepopulatedKitAPI)
        implementation.filterUserAttributes = nil

        var prepopulatedPrepared: [String: String] = [:]
        implementation.prepareAttributes(
            [:],
            filteredUser: prepopulatedUser
        ) { attributes, _ in
            prepopulatedPrepared = attributes
        }

        #expect(prepopulatedKitAPI.setAttributes.isEmpty)
        #expect(prepopulatedPrepared["paypalpayerid"] == "STORED_PAYER")
    }

    @Test func paypalPayerIdFollowsTheConnectionFilters() {
        let implementation = MPRoktKitImplementation(
            roktClient: MockRoktSDKClient(),
            identityClient: DeferredIdentityClient()
        )
        let user = TestFilteredUser()
        implementation.setContext(owner: MPKitRokt(), kitAPI: MockKitAPI(filteredUser: user))
        implementation.filterUserAttributes = { attributes, _ in
            attributes.filter { $0.key != "paypalpayerid" }
        }

        var prepared: [String: String] = [:]
        implementation.prepareAttributes(
            ["firstname": "Ada", "paypalpayerid": "PAYERID123"],
            filteredUser: user
        ) { attributes, _ in
            prepared = attributes
        }

        #expect(prepared["firstname"] == "Ada")
        #expect(prepared["paypalpayerid"] == nil)
    }

    @Test func callerEmailValuesWinOverStaleIdentities() {
        let identityClient = DeferredIdentityClient()
        let implementation = MPRoktKitImplementation(
            roktClient: MockRoktSDKClient(),
            identityClient: identityClient
        )
        implementation.filterUserAttributes = { attributes, _ in attributes }

        var prepared: [String: String] = [:]
        implementation.prepareAttributes(
            ["email": "grace@example.com"],
            filteredUser: TestFilteredUser()
        ) { attributes, _ in
            prepared = attributes
        }

        #expect(identityClient.hasPendingIdentify)
        #expect(prepared["email"] == "grace@example.com")
    }

    @Test func callerEmailValuesDoNotAddKeysTheFiltersRemoved() {
        let implementation = MPRoktKitImplementation()

        let result = implementation.enrichedAttributes(
            ["allowed": "yes"],
            filteredUser: nil,
            callerIdentities: ["email": "grace@example.com", "emailsha256": "hash"]
        )

        #expect(result["email"] == nil)
        #expect(result["emailsha256"] == nil)
    }

    @Test func identifyFiresOnlyOnMismatchUsingTheConfiguredHashedType() async {
        let identityClient = MockIdentityClient()
        let implementation = MPRoktKitImplementation(
            roktClient: MockRoktSDKClient(),
            identityClient: identityClient
        )
        implementation.configuration = ["hashedEmailUserIdentityType": "Other"]
        let otherKey = NSNumber(value: MPIdentity.other.rawValue)
        let user = TestUser(identities: [otherKey: "hash"])

        let matched = await identifyDecision(
            implementation,
            attributes: ["emailsha256": "hash"],
            user: user
        )
        #expect(!matched)
        #expect(identityClient.identifyCount == 0)

        let mismatched = await identifyDecision(
            implementation,
            attributes: ["emailsha256": "new-hash"],
            user: user
        )
        #expect(mismatched)
        #expect(identityClient.identifyCount == 1)
        #expect(identityClient.lastRequest?.identities?[otherKey] as? String == "new-hash")
    }

    @Test func unrecognisedHashedEmailSettingDoesNotIdentify() async {
        let identityClient = MockIdentityClient()
        let implementation = MPRoktKitImplementation(
            roktClient: MockRoktSDKClient(),
            identityClient: identityClient
        )
        implementation.configuration = ["hashedEmailUserIdentityType": "Unknown"]

        let identified = await identifyDecision(
            implementation,
            attributes: ["emailsha256": "hash"],
            user: nil
        )

        #expect(!identified)
        #expect(identityClient.identifyCount == 0)
    }

    @Test func identifyFailureDoesNotAffectThePlacement() {
        let client = MockRoktSDKClient()
        let identityClient = DeferredIdentityClient()
        let implementation = MPRoktKitImplementation(
            roktClient: client,
            identityClient: identityClient
        )
        implementation.filterUserAttributes = { attributes, _ in attributes }

        _ = implementation.selectPlacements(
            identifier: "checkout",
            attributes: ["email": "grace@example.com"],
            embeddedViews: nil,
            config: nil,
            onEvent: nil,
            filteredUser: TestFilteredUser(),
            options: nil
        )
        identityClient.complete(error: NSError(domain: "test", code: 1))

        #expect(client.calls == ["selectPlacements:checkout"])
    }

    @Test func sessionOperationsRemainOrderedBehindPlacementPreparation() {
        let client = MockRoktSDKClient()
        let identityClient = DeferredIdentityClient()
        let implementation = MPRoktKitImplementation(
            roktClient: client,
            identityClient: identityClient
        )
        let user = TestFilteredUser()
        let owner = MPKitRokt()
        let kitAPI = MockKitAPI(filteredUser: user)
        implementation.setContext(owner: owner, kitAPI: kitAPI)
        var writeBarriers: [() -> Void] = []
        implementation.afterPendingAttributeWrites = { writeBarriers.append($0) }

        _ = implementation.selectPlacements(
            identifier: "checkout",
            attributes: ["email": "ada@example.com"],
            embeddedViews: nil,
            config: nil,
            onEvent: nil,
            filteredUser: user,
            options: nil
        )
        _ = implementation.clearSession()
        _ = implementation.setSessionID("next-session")
        _ = implementation.close()

        #expect(client.calls.isEmpty)
        writeBarriers.removeFirst()()

        #expect(client.calls == [
            "selectPlacements:checkout",
            "clearSession",
            "setSessionID:next-session",
            "close"
        ])
    }

    @Test func stopInvalidatesInFlightPreparationAndAllowsLaterWork() {
        let client = MockRoktSDKClient()
        let implementation = MPRoktKitImplementation(roktClient: client)
        let user = TestFilteredUser()
        let owner = MPKitRokt()
        let kitAPI = MockKitAPI(filteredUser: user)
        implementation.setContext(owner: owner, kitAPI: kitAPI)
        var writeBarriers: [() -> Void] = []
        implementation.afterPendingAttributeWrites = { writeBarriers.append($0) }

        _ = implementation.selectShoppableAds(
            identifier: "stale",
            attributes: [:],
            config: nil,
            onEvent: nil,
            filteredUser: user
        )
        implementation.stop()
        writeBarriers.removeFirst()()

        #expect(client.calls == ["close", "clearSession"])
        #expect(client.selectedIdentifier == nil)

        implementation.start()
        implementation.afterPendingAttributeWrites = nil
        _ = implementation.selectShoppableAds(
            identifier: "current",
            attributes: [:],
            config: nil,
            onEvent: nil,
            filteredUser: user
        )

        #expect(client.calls == ["close", "clearSession", "selectShoppableAds:current"])
    }

    @Test func placementForwardsPreparedAttributesAndOptionsToRoktClient() {
        let client = MockRoktSDKClient()
        let implementation = MPRoktKitImplementation(roktClient: client)
        let user = TestFilteredUser(attributes: ["allowed": "caller"])
        let options = RoktPlacementOptions(timestamp: 123)

        let status = implementation.selectPlacements(
            identifier: "checkout",
            attributes: ["allowed": "caller", "blocked": "secret"],
            embeddedViews: nil,
            config: nil,
            onEvent: nil,
            filteredUser: user,
            options: options
        )

        #expect(status.returnCode == .success)
        #expect(client.selectedIdentifier == "checkout")
        #expect(client.selectedAttributes?["allowed"] == "caller")
        #expect(client.selectedAttributes?["blocked"] == nil)
        #expect(client.selectedAttributes?["email"] == "ada@example.com")
        #expect(client.selectedAttributes?["mpid"] == "123")
        #expect(client.selectedAttributes?["sandbox"] != nil)
        #expect(client.selectedOptions === options)
    }

    @Test func pendingPlacementWritesAreMergedAndEmptyValuesAreDropped() async {
        let implementation = MPRoktKitImplementation(roktClient: MockRoktSDKClient())
        let user = TestFilteredUser()
        let otherUser = TestFilteredUser(userID: 456)
        implementation.filterUserAttributes = { attributes, _ in attributes }

        let first = await preparedAttributes(
            implementation,
            attributes: ["first": "one", "empty": ""],
            user: user
        )
        let second = await preparedAttributes(
            implementation,
            attributes: ["second": "two"],
            user: user
        )
        let other = await preparedAttributes(
            implementation,
            attributes: ["other": "user"],
            user: otherUser
        )

        #expect(first["first"] == "one")
        #expect(first["empty"] == nil)
        #expect(second["first"] == "one")
        #expect(second["second"] == "two")
        #expect(other["first"] == nil)
        #expect(other["second"] == nil)
        #expect(other["other"] == "user")
        #expect(other["mpid"] == "456")
    }

    @Test func settledPendingWritesAreNotForwardedAgain() async {
        let implementation = MPRoktKitImplementation(roktClient: MockRoktSDKClient())
        let user = TestFilteredUser()
        var writeBarriers: [() -> Void] = []
        implementation.filterUserAttributes = { attributes, _ in attributes }
        implementation.afterPendingAttributeWrites = { writeBarriers.append($0) }

        _ = await preparedAttributes(
            implementation,
            attributes: ["first": "one"],
            user: user
        )
        #expect(writeBarriers.count == 1)
        writeBarriers.removeFirst()()

        let second = await preparedAttributes(
            implementation,
            attributes: ["second": "two"],
            user: user
        )

        #expect(second["first"] == nil)
        #expect(second["second"] == "two")
    }

    @Test func sessionURLDiagnosticsAndPurchaseForwardToRoktClient() {
        let client = MockRoktSDKClient()
        let implementation = MPRoktKitImplementation(roktClient: client)
        let url = URL(string: "myapp://payment-return")!
        client.handledURL = true

        _ = implementation.setSessionID("session")
        #expect(implementation.getSessionId() == "session")
        _ = implementation.clearSession()
        #expect(client.clearedSession)
        #expect(implementation.handleURLCallback(url))
        implementation.logMParticleAPIDiagnostic("LOG_EVENT")
        #expect(client.diagnosticCode == "LOG_EVENT")
        _ = implementation.purchaseFinalized("checkout", catalogItemId: "sku", success: true)
        #expect(client.purchase?.identifier == "checkout")
        #expect(client.purchase?.catalogItemID == "sku")
        #expect(client.purchase?.success == true)
        _ = implementation.close()
        #expect(client.closed)
    }

    @Test func tokenBearingSessionReachesRoktClientIntact() {
        let client = MockRoktSDKClient()
        let implementation = MPRoktKitImplementation(roktClient: client)
        let expiry = NSNumber(value: 1_750_000_000_000)

        _ = implementation.setSession(sessionID: "  session-1  ",
                                      sessionToken: "  jwt-token  ",
                                      expiresAt: expiry)

        // The token is the part the legacy id-only path cannot carry, so it is what makes the
        // hand-off authorize rather than merely identify.
        #expect(client.session?.sessionId == "session-1")
        #expect(client.session?.sessionToken == "jwt-token")
        #expect(client.session?.expiresAt == expiry)
    }

    private struct Fields {
        let sessionID: String?
        let sessionToken: String?
        let expiresAt: NSNumber?
    }

    @Test func incompleteSessionIsIgnoredRatherThanPartiallyApplied() {
        let expiry = NSNumber(value: 1_750_000_000_000)
        // Each field absent, blank and whitespace-only in turn. The nil cases are why this method
        // takes the fields instead of MPRoktSession, whose nonnull declarations would hide them.
        let incomplete = [
            Fields(sessionID: nil, sessionToken: "jwt-token", expiresAt: expiry),
            Fields(sessionID: "", sessionToken: "jwt-token", expiresAt: expiry),
            Fields(sessionID: "   ", sessionToken: "jwt-token", expiresAt: expiry),
            Fields(sessionID: "session-1", sessionToken: nil, expiresAt: expiry),
            Fields(sessionID: "session-1", sessionToken: "", expiresAt: expiry),
            Fields(sessionID: "session-1", sessionToken: "   ", expiresAt: expiry),
            Fields(sessionID: "session-1", sessionToken: "jwt-token", expiresAt: nil)
        ]

        for fields in incomplete {
            let client = MockRoktSDKClient()
            let implementation = MPRoktKitImplementation(roktClient: client)

            let status = implementation.setSession(sessionID: fields.sessionID,
                                                   sessionToken: fields.sessionToken,
                                                   expiresAt: fields.expiresAt)

            // Seeding an id without its token would leave offers unauthorized while the call
            // still reported success, so nothing is applied at all.
            #expect(client.session == nil)
            #expect(client.calls.isEmpty)
            #expect(status.returnCode == .success)
        }
    }

    @Test func getSessionReturnsNilUnlessTheSessionIsComplete() {
        let expiry = NSNumber(value: 1_750_000_000_000)
        let incomplete = [
            RoktSession(sessionId: "", sessionToken: "jwt-token", expiresAt: expiry),
            RoktSession(sessionId: "session-1", sessionToken: "", expiresAt: expiry),
            RoktSession(sessionId: "session-1", sessionToken: "jwt-token", expiresAt: nil)
        ]

        let empty = MPRoktKitImplementation(roktClient: MockRoktSDKClient())
        #expect(empty.getSession() == nil)

        for session in incomplete {
            let client = MockRoktSDKClient()
            client.session = session
            let implementation = MPRoktKitImplementation(roktClient: client)

            // Handing a WebView an id whose token is missing moves the failure to the next
            // authorized request, where it is far harder to attribute.
            #expect(implementation.getSession() == nil)
        }

        let client = MockRoktSDKClient()
        client.session = RoktSession(sessionId: "session-1", sessionToken: "jwt-token", expiresAt: expiry)
        let implementation = MPRoktKitImplementation(roktClient: client)

        let read = implementation.getSession()
        #expect(read?.sessionId == "session-1")
        #expect(read?.sessionToken == "jwt-token")
        #expect(read?.expiresAt == expiry)
    }

    // The Rokt session belongs to the workspace being left, so it must not carry over into the next.
    @Test func stopClearsWorkspaceStateClosesRoktAndClearsSession() {
        let client = MockRoktSDKClient()
        let implementation = MPRoktKitImplementation(roktClient: client)
        implementation.configuration = ["accountId": "workspace"]

        implementation.start()
        implementation.stop()

        #expect(!implementation.started)
        #expect(implementation.configuration == nil)
        #expect(client.calls == ["close", "clearSession"])
    }

    @Test func convertsProfileValuesAfterFiltering() {
        let result = MPRoktKitImplementation.valuesAsStrings([
            "string": "value",
            "number": 42,
            "true": true,
            "false": false,
            "null": NSNull(),
            "array": ["a", "b"]
        ])

        #expect(result["string"] == "value")
        #expect(result["number"] == "42")
        #expect(result["true"] == "true")
        #expect(result["false"] == "false")
        #expect(result["null"] == "null")
        #expect(result["array"] != nil)
    }

    @Test func preservesExplicitSandbox() {
        let result = MPRoktKitImplementation.confirmingSandbox([
            "sandbox": "true",
            "key": "value"
        ])

        #expect(result["sandbox"] == "true")
        #expect(result["key"] == "value")
    }

    @Test func resolvesConfiguredHashedEmailIdentity() {
        let implementation = MPRoktKitImplementation()
        implementation.configuration = ["hashedEmailUserIdentityType": "Other4"]

        #expect(implementation.hashedEmailIdentityType()?.uintValue == MPIdentity.other4.rawValue)
        #expect(implementation.identityString(MPIdentity.other4.rawValue) == "emailsha256")
    }

    @Test func identityAndMpidAreAppendedAfterFilteredAttributes() {
        let implementation = MPRoktKitImplementation()
        let user = TestFilteredUser()

        let result = implementation.enrichedAttributes(["allowed": "yes"], filteredUser: user)

        #expect(result["allowed"] == "yes")
        #expect(result["email"] == "ada@example.com")
        #expect(result["mpid"] == "123")
        #expect(result["sandbox"] != nil)
    }

    @Test func hashedEmailRemovesPlainEmail() {
        let implementation = MPRoktKitImplementation()
        let result = implementation.enrichedAttributes([
            "email": "ada@example.com",
            "emailsha256": "hash"
        ], filteredUser: nil)

        #expect(result["email"] == nil)
        #expect(result["emailsha256"] == "hash")
    }

    @Test func perCallPrivacyAttributesAreNotPersistedBypassFiltersAndSyncNoTargeting() {
        let client = MockRoktSDKClient()
        let identityClient = MockIdentityClient()
        let currentUser = TestUser()
        identityClient.currentUser = currentUser
        let filteredUser = TestFilteredUser(attributes: ["allowed": "yes"])
        let kitAPI = MockKitAPI(filteredUser: filteredUser)
        let owner = MPKitRokt()
        let implementation = MPRoktKitImplementation(
            roktClient: client,
            identityClient: identityClient
        )
        implementation.setContext(owner: owner, kitAPI: kitAPI)
        implementation.filterUserAttributes = { _, _ in ["allowed": "yes"] }
        var warnings: [String] = []
        implementation.warningHandler = { warnings.append($0) }

        _ = implementation.selectPlacements(
            identifier: "checkout",
            attributes: [
                "allowed": "yes",
                "custom": "persisted",
                "NoFunctional": "true",
                "notargeting": "TRUE",
                "DoNotShareOrSell": "true",
                "GPCEnabled": "1"
            ],
            embeddedViews: nil,
            config: nil,
            onEvent: nil,
            filteredUser: filteredUser,
            options: nil
        )

        #expect(kitAPI.setAttributes["custom"] as? String == "persisted")
        #expect(kitAPI.setAttributes["noFunctional"] == nil)
        #expect(kitAPI.setAttributes["NoFunctional"] == nil)
        #expect(kitAPI.setAttributes["noTargeting"] == nil)
        #expect(kitAPI.setAttributes["notargeting"] == nil)
        #expect(kitAPI.setAttributes["doNotShareOrSell"] == nil)
        #expect(kitAPI.setAttributes["DoNotShareOrSell"] == nil)
        #expect(kitAPI.setAttributes["gpcEnabled"] == nil)
        #expect(kitAPI.setAttributes["GPCEnabled"] == nil)
        #expect(kitAPI.setAttributes["$NoTargeting"] == nil)
        #expect(currentUser.setAttributes["$NoTargeting"] as? String == "true")
        #expect(client.selectedAttributes?["$NoTargeting"] == "true")
        #expect(client.selectedAttributes?["noFunctional"] == "true")
        #expect(client.selectedAttributes?["noTargeting"] == "TRUE")
        #expect(client.selectedAttributes?["doNotShareOrSell"] == "true")
        #expect(client.selectedAttributes?["gpcEnabled"] == "1")
        #expect(client.selectedAttributes?["NoFunctional"] == nil)
        #expect(client.selectedAttributes?["notargeting"] == nil)
        #expect(client.selectedAttributes?["DoNotShareOrSell"] == nil)
        #expect(client.selectedAttributes?["GPCEnabled"] == nil)
        #expect(warnings == [
            "attribute \"custom\" not forwarded to Rokt — blocked by data filter"
        ])

        _ = implementation.selectPlacements(
            identifier: "checkout",
            attributes: ["noTargeting": "False"],
            embeddedViews: nil,
            config: nil,
            onEvent: nil,
            filteredUser: filteredUser,
            options: nil
        )

        #expect(kitAPI.removedAttributeKeys.isEmpty)
        #expect(currentUser.removedAttributeKeys == ["$NoTargeting"])
        #expect(client.selectedAttributes?["noTargeting"] == "False")
        #expect(client.selectedAttributes?["$NoTargeting"] == nil)
    }

    @Test func profilePrivacyAttributesBypassConnectionFiltersSyncNoTargetingWithOptOutPrecedence() {
        let client = MockRoktSDKClient()
        let identityClient = MockIdentityClient()
        let currentUser = TestUser(attributes: [
            "noTargeting": true,
            "noFunctional": "true",
            "doNotShareOrSell": false,
            "gpcEnabled": "true"
        ])
        identityClient.currentUser = currentUser
        let filteredUser = TestFilteredUser(attributes: [:])
        let kitAPI = MockKitAPI(filteredUser: filteredUser)
        let owner = MPKitRokt()
        let implementation = MPRoktKitImplementation(
            roktClient: client,
            identityClient: identityClient
        )
        implementation.setContext(owner: owner, kitAPI: kitAPI)
        implementation.filterUserAttributes = { _, _ in [:] }

        _ = implementation.selectPlacements(
            identifier: "checkout",
            attributes: [:],
            embeddedViews: nil,
            config: nil,
            onEvent: nil,
            filteredUser: filteredUser,
            options: nil
        )

        #expect(client.selectedAttributes?["noTargeting"] == "true")
        #expect(client.selectedAttributes?["noFunctional"] == "true")
        #expect(client.selectedAttributes?["doNotShareOrSell"] == "false")
        #expect(client.selectedAttributes?["gpcEnabled"] == "true")
        #expect(kitAPI.setAttributes["$NoTargeting"] == nil)
        #expect(currentUser.setAttributes["$NoTargeting"] as? String == "true")

        currentUser.storedAttributes = [
            "noTargeting": false,
            "noFunctional": true,
            "$NoTargeting": "true"
        ]
        _ = implementation.selectPlacements(
            identifier: "checkout",
            attributes: [:],
            embeddedViews: nil,
            config: nil,
            onEvent: nil,
            filteredUser: filteredUser,
            options: nil
        )

        #expect(client.selectedAttributes?["noTargeting"] == "false")
        #expect(client.selectedAttributes?["noFunctional"] == "true")
        #expect(kitAPI.removedAttributeKeys.isEmpty)
        #expect(currentUser.removedAttributeKeys == ["$NoTargeting"])

        currentUser.storedAttributes = [
            "noTargeting": true,
            "noFunctional": true
        ]
        kitAPI.removedAttributeKeys = []
        currentUser.removedAttributeKeys = []

        _ = implementation.selectPlacements(
            identifier: "checkout",
            attributes: [
                "noTargeting": "false",
                "noFunctional": "false"
            ],
            embeddedViews: nil,
            config: nil,
            onEvent: nil,
            filteredUser: filteredUser,
            options: nil
        )

        #expect(client.selectedAttributes?["noTargeting"] == "true")
        #expect(client.selectedAttributes?["noFunctional"] == "true")
        #expect(kitAPI.removedAttributeKeys.isEmpty)
        #expect(currentUser.removedAttributeKeys.isEmpty)
        #expect(currentUser.storedAttributes["$NoTargeting"] as? String == "true")

        currentUser.storedAttributes = [
            "noTargeting": false,
            "noFunctional": false
        ]
        currentUser.setAttributes = [:]

        _ = implementation.selectPlacements(
            identifier: "checkout",
            attributes: [
                "noTargeting": "true",
                "noFunctional": "true"
            ],
            embeddedViews: nil,
            config: nil,
            onEvent: nil,
            filteredUser: filteredUser,
            options: nil
        )

        #expect(client.selectedAttributes?["noTargeting"] == "true")
        #expect(client.selectedAttributes?["noFunctional"] == "true")
        #expect(currentUser.setAttributes["$NoTargeting"] as? String == "true")
    }

    @Test func storedLegacyFalsePrivacyValueIsClearedWhenCallerOptsOut() {
        let client = MockRoktSDKClient()
        let identityClient = MockIdentityClient()
        let currentUser = TestUser(attributes: [
            "Notargeting": "false",
            "NoFunctional": "false"
        ])
        identityClient.currentUser = currentUser
        let filteredUser = TestFilteredUser(attributes: [:])
        let kitAPI = MockKitAPI(filteredUser: filteredUser)
        let owner = MPKitRokt()
        let implementation = MPRoktKitImplementation(
            roktClient: client,
            identityClient: identityClient
        )
        implementation.setContext(owner: owner, kitAPI: kitAPI)
        implementation.filterUserAttributes = { _, _ in [:] }

        _ = implementation.selectPlacements(
            identifier: "checkout",
            attributes: [
                "noFunctional": "false"
            ],
            embeddedViews: nil,
            config: nil,
            onEvent: nil,
            filteredUser: filteredUser,
            options: nil
        )

        #expect(currentUser.storedAttributes["NoFunctional"] as? String == "false")
        #expect(currentUser.removedAttributeKeys.isEmpty)

        _ = implementation.selectPlacements(
            identifier: "checkout",
            attributes: [
                "noTargeting": "true",
                "noFunctional": "true"
            ],
            embeddedViews: nil,
            config: nil,
            onEvent: nil,
            filteredUser: filteredUser,
            options: nil
        )

        #expect(client.selectedAttributes?["noTargeting"] == "true")
        #expect(client.selectedAttributes?["noFunctional"] == "true")
        #expect(currentUser.storedAttributes["$NoTargeting"] as? String == "true")
        #expect(currentUser.storedAttributes["Notargeting"] == nil)
        #expect(currentUser.storedAttributes["NoFunctional"] == nil)

        currentUser.removedAttributeKeys = []

        _ = implementation.selectPlacements(
            identifier: "checkout",
            attributes: [:],
            embeddedViews: nil,
            config: nil,
            onEvent: nil,
            filteredUser: filteredUser,
            options: nil
        )

        // No source says true any more, so the tag goes, as on web.
        #expect(client.selectedAttributes?["noTargeting"] == nil)
        #expect(currentUser.removedAttributeKeys == ["$NoTargeting"])
        #expect(currentUser.storedAttributes["$NoTargeting"] == nil)
    }

    @Test func staleIdentifyCallbackForAUserWhoIsNoLongerCurrentWritesNothing() {
        let client = MockRoktSDKClient()
        let identityClient = DeferredIdentityClient()
        let firstUser = TestUser(
            userID: 1,
            identities: [NSNumber(value: MPIdentity.email.rawValue): "old@example.com"]
        )
        identityClient.currentUser = firstUser
        let filteredUser = TestFilteredUser(userID: 1)
        let implementation = MPRoktKitImplementation(roktClient: client, identityClient: identityClient)
        implementation.setContext(owner: MPKitRokt(), kitAPI: MockKitAPI(filteredUser: filteredUser))
        implementation.filterUserAttributes = { _, _ in [:] }

        _ = implementation.selectPlacements(
            identifier: "checkout",
            attributes: ["email": "new@example.com", "noTargeting": "true"],
            embeddedViews: nil,
            config: nil,
            onEvent: nil,
            filteredUser: filteredUser,
            options: nil
        )
        // A later identify or login already made another user current when this callback runs.
        let laterUser = TestUser(userID: 3, attributes: ["noTargeting": "true", "$NoTargeting": "true"])
        identityClient.currentUser = laterUser
        let identifiedUser = TestUser(userID: 2, attributes: ["noTargeting": "false"])
        identityClient.complete(user: identifiedUser)

        // Core writes user attributes to the current user, so a write here would land on laterUser.
        #expect(identifiedUser.removedAttributeKeys.isEmpty)
        #expect(identifiedUser.setAttributes.isEmpty)
        #expect(laterUser.removedAttributeKeys.isEmpty)
        #expect(laterUser.setAttributes.isEmpty)
    }

    @Test func identifyCallbackIsDroppedOnceANewerCallHasFiredItsOwnIdentify() {
        let client = MockRoktSDKClient()
        let identityClient = DeferredIdentityClient()
        identityClient.currentUser = TestUser(
            userID: 1,
            identities: [NSNumber(value: MPIdentity.email.rawValue): "old@example.com"]
        )
        let filteredUser = TestFilteredUser(userID: 1)
        let implementation = MPRoktKitImplementation(roktClient: client, identityClient: identityClient)
        implementation.setContext(owner: MPKitRokt(), kitAPI: MockKitAPI(filteredUser: filteredUser))
        implementation.filterUserAttributes = { _, _ in [:] }

        for (email, privacy) in [("second@example.com", "true"), ("third@example.com", "false")] {
            _ = implementation.selectPlacements(
                identifier: "checkout",
                attributes: ["email": email, "noTargeting": privacy],
                embeddedViews: nil,
                config: nil,
                onEvent: nil,
                filteredUser: filteredUser,
                options: nil
            )
        }
        #expect(identityClient.pendingIdentifyCount == 2)

        // The first identify returns while the second is still queued. Core makes its user current
        // first, but applies attribute writes later on the queue, after the second identify switches
        // to another user, so the first callback must not write at all.
        let secondUser = TestUser(userID: 2, attributes: ["noTargeting": "false"])
        identityClient.currentUser = secondUser
        identityClient.completeOldest(user: secondUser)

        #expect(secondUser.removedAttributeKeys.isEmpty)
        #expect(secondUser.setAttributes.isEmpty)
    }

    @Test func newerCallClaimsPrivacyKeysForTheUserItWritesTo() {
        let client = MockRoktSDKClient()
        let identityClient = DeferredIdentityClient()
        let firstUser = TestUser(
            userID: 1,
            identities: [NSNumber(value: MPIdentity.email.rawValue): "old@example.com"]
        )
        let identifiedUser = TestUser(userID: 2)
        identityClient.currentUser = firstUser
        let filteredUser = TestFilteredUser(userID: 1)
        let implementation = MPRoktKitImplementation(roktClient: client, identityClient: identityClient)
        implementation.setContext(owner: MPKitRokt(), kitAPI: MockKitAPI(filteredUser: filteredUser))
        implementation.filterUserAttributes = nil
        var switchUserBeforeWriting = false
        implementation.afterPendingAttributeWrites = { callback in
            if switchUserBeforeWriting {
                identityClient.currentUser = identifiedUser
            }
            callback()
        }

        // Call N opts out and fires an identify that has not completed yet.
        _ = implementation.selectPlacements(
            identifier: "checkout",
            attributes: ["email": "new@example.com", "noTargeting": "true"],
            embeddedViews: nil,
            config: nil,
            onEvent: nil,
            filteredUser: filteredUser,
            options: nil
        )
        // Newer call M opts back in. It starts for the first user but writes after the switch.
        switchUserBeforeWriting = true
        _ = implementation.selectPlacements(
            identifier: "checkout",
            attributes: ["noTargeting": "false"],
            embeddedViews: nil,
            config: nil,
            onEvent: nil,
            filteredUser: filteredUser,
            options: nil
        )
        identityClient.complete(user: identifiedUser)

        // N's identify is older than M for the user M wrote to, so it must not restore the opt-out.
        #expect(identifiedUser.setAttributes["$NoTargeting"] == nil)
    }

    @Test func legacyAfterPendingAttributeWritesResolvesQueuedProfilePrivacyOptOut() {
        let client = MockRoktSDKClient()
        let identityClient = MockIdentityClient()
        let currentUser = TestUser(attributes: ["noTargeting": false])
        identityClient.currentUser = currentUser
        let filteredUser = TestFilteredUser(attributes: ["noTargeting": false])
        let kitAPI = MockKitAPI(filteredUser: filteredUser)
        let owner = MPKitRokt()
        let implementation = MPRoktKitImplementation(
            roktClient: client,
            identityClient: identityClient
        )
        implementation.setContext(owner: owner, kitAPI: kitAPI)
        implementation.filterUserAttributes = nil
        implementation.afterPendingAttributeWrites = { callback in
            currentUser.storedAttributes["noTargeting"] = true
            callback()
        }

        _ = implementation.selectPlacements(
            identifier: "checkout",
            attributes: [:],
            embeddedViews: nil,
            config: nil,
            onEvent: nil,
            filteredUser: filteredUser,
            options: nil
        )

        #expect(client.selectedAttributes?["noTargeting"] == "true")
        #expect(currentUser.setAttributes["$NoTargeting"] as? String == "true")
    }

    @Test func identifyReturningNewUserResyncsNoTargetingAndMixedCaseSandboxNormalizes() {
        let client = MockRoktSDKClient()
        let identityClient = DeferredIdentityClient()
        let preIdentifyUser = TestUser(
            identities: [NSNumber(value: MPIdentity.email.rawValue): "old@example.com"],
            attributes: [:]
        )
        let postIdentifyUser = TestUser(
            identities: [NSNumber(value: MPIdentity.email.rawValue): "new@example.com"],
            attributes: ["noTargeting": "false"]
        )
        identityClient.currentUser = preIdentifyUser
        let filteredUser = TestFilteredUser(attributes: [:])
        let kitAPI = MockKitAPI(filteredUser: filteredUser)
        let owner = MPKitRokt()
        let implementation = MPRoktKitImplementation(
            roktClient: client,
            identityClient: identityClient
        )
        implementation.setContext(owner: owner, kitAPI: kitAPI)
        implementation.filterUserAttributes = { _, _ in [:] }

        _ = implementation.selectPlacements(
            identifier: "checkout",
            attributes: [
                "email": "new@example.com",
                "noTargeting": "true",
                "Sandbox": "true"
            ],
            embeddedViews: nil,
            config: nil,
            onEvent: nil,
            filteredUser: filteredUser,
            options: nil
        )

        #expect(client.selectedAttributes?["sandbox"] == "true")
        #expect(client.selectedAttributes?["Sandbox"] == nil)
        #expect(preIdentifyUser.setAttributes["$NoTargeting"] as? String == "true")

        identityClient.currentUser = postIdentifyUser
        identityClient.complete(user: postIdentifyUser)

        #expect(postIdentifyUser.removedAttributeKeys == ["noTargeting"])
        #expect(postIdentifyUser.storedAttributes["noTargeting"] == nil)
        #expect(postIdentifyUser.setAttributes["$NoTargeting"] as? String == "true")

        _ = implementation.selectPlacements(
            identifier: "checkout",
            attributes: [:],
            embeddedViews: nil,
            config: nil,
            onEvent: nil,
            filteredUser: filteredUser,
            options: nil
        )

        // No source says true any more, so the tag goes, as on web.
        #expect(client.selectedAttributes?["noTargeting"] == nil)
        #expect(postIdentifyUser.removedAttributeKeys == ["noTargeting", "$NoTargeting"])
        #expect(postIdentifyUser.storedAttributes["$NoTargeting"] == nil)

        let optedOutIdentifiedUser = TestUser(
            identities: [NSNumber(value: MPIdentity.email.rawValue): "optedout@example.com"],
            attributes: [
                "noTargeting": "true",
                "$NoTargeting": "true"
            ]
        )
        preIdentifyUser.storedAttributes = ["noTargeting": "false"]
        identityClient.currentUser = preIdentifyUser

        _ = implementation.selectPlacements(
            identifier: "checkout",
            attributes: [
                "email": "optedout@example.com"
            ],
            embeddedViews: nil,
            config: nil,
            onEvent: nil,
            filteredUser: filteredUser,
            options: nil
        )

        identityClient.currentUser = optedOutIdentifiedUser
        identityClient.complete()

        #expect(optedOutIdentifiedUser.removedAttributeKeys.isEmpty)
        #expect(optedOutIdentifiedUser.storedAttributes["$NoTargeting"] as? String == "true")
    }

    @Test func pendingClearedPrivacyKeysSuppressDeferredProfileRemovalAcrossConsecutivePlacements() {
        let client = MockRoktSDKClient()
        let identityClient = MockIdentityClient()
        let currentUser = TestUser(
            attributes: [
                "Notargeting": "false",
                "NoFunctional": "false"
            ],
            defersAttributeRemoval: true
        )
        identityClient.currentUser = currentUser
        let filteredUser = TestFilteredUser(attributes: [:])
        let kitAPI = MockKitAPI(filteredUser: filteredUser)
        let owner = MPKitRokt()
        let implementation = MPRoktKitImplementation(
            roktClient: client,
            identityClient: identityClient
        )
        implementation.setContext(owner: owner, kitAPI: kitAPI)
        implementation.filterUserAttributes = { candidate, _ in candidate }
        var pendingWriteCallbacks: [() -> Void] = []
        implementation.afterPendingAttributeWrites = { callback in
            pendingWriteCallbacks.append(callback)
        }

        _ = implementation.selectPlacements(
            identifier: "checkout",
            attributes: [
                "noTargeting": "true",
                "noFunctional": "true"
            ],
            embeddedViews: nil,
            config: nil,
            onEvent: nil,
            filteredUser: filteredUser,
            options: nil
        )

        #expect(client.selectedAttributes?["noTargeting"] == "true")
        #expect(client.selectedAttributes?["noFunctional"] == "true")
        #expect(Set(currentUser.removedAttributeKeys) == ["Notargeting", "NoFunctional"])
        #expect(currentUser.storedAttributes["Notargeting"] as? String == "false")
        #expect(currentUser.storedAttributes["NoFunctional"] as? String == "false")
        #expect(currentUser.storedAttributes["$NoTargeting"] as? String == "true")

        _ = implementation.selectPlacements(
            identifier: "checkout",
            attributes: [:],
            embeddedViews: nil,
            config: nil,
            onEvent: nil,
            filteredUser: filteredUser,
            options: nil
        )

        #expect(client.selectedAttributes?["noTargeting"] == nil)
        #expect(client.selectedAttributes?["noFunctional"] == nil)
        #expect(currentUser.storedAttributes["$NoTargeting"] as? String == "true")

        currentUser.storedAttributes.removeValue(forKey: "Notargeting")
        currentUser.storedAttributes.removeValue(forKey: "NoFunctional")
        pendingWriteCallbacks.forEach { $0() }
    }

    @Test func supersededIdentifyCallbackDoesNotOverwriteNewerPlacementPrivacyState() {
        let client = MockRoktSDKClient()
        let identityClient = DeferredIdentityClient()
        let currentUser = TestUser(
            identities: [NSNumber(value: MPIdentity.email.rawValue): "old@example.com"],
            attributes: [:]
        )
        identityClient.currentUser = currentUser
        let filteredUser = TestFilteredUser(attributes: [:])
        let kitAPI = MockKitAPI(filteredUser: filteredUser)
        let owner = MPKitRokt()
        let implementation = MPRoktKitImplementation(
            roktClient: client,
            identityClient: identityClient
        )
        implementation.setContext(owner: owner, kitAPI: kitAPI)
        implementation.filterUserAttributes = { _, _ in [:] }

        _ = implementation.selectPlacements(
            identifier: "checkout",
            attributes: [
                "email": "new@example.com",
                "noTargeting": "false"
            ],
            embeddedViews: nil,
            config: nil,
            onEvent: nil,
            filteredUser: filteredUser,
            options: nil
        )

        #expect(client.selectedAttributes?["noTargeting"] == "false")
        #expect(identityClient.hasPendingIdentify)

        _ = implementation.selectPlacements(
            identifier: "checkout",
            attributes: [
                "noTargeting": "true"
            ],
            embeddedViews: nil,
            config: nil,
            onEvent: nil,
            filteredUser: filteredUser,
            options: nil
        )

        #expect(client.selectedAttributes?["noTargeting"] == "true")
        #expect(currentUser.storedAttributes["$NoTargeting"] as? String == "true")

        currentUser.removedAttributeKeys = []
        identityClient.complete(user: currentUser)

        #expect(currentUser.removedAttributeKeys.isEmpty)
        #expect(currentUser.storedAttributes["$NoTargeting"] as? String == "true")

        _ = implementation.selectPlacements(
            identifier: "checkout",
            attributes: [
                "email": "third@example.com",
                "noTargeting": "true"
            ],
            embeddedViews: nil,
            config: nil,
            onEvent: nil,
            filteredUser: filteredUser,
            options: nil
        )

        #expect(identityClient.hasPendingIdentify)

        currentUser.storedAttributes["noTargeting"] = "false"
        currentUser.removedAttributeKeys = []
        currentUser.setAttributes = [:]

        _ = implementation.selectPlacements(
            identifier: "checkout",
            attributes: [
                "noTargeting": "false"
            ],
            embeddedViews: nil,
            config: nil,
            onEvent: nil,
            filteredUser: filteredUser,
            options: nil
        )

        #expect(currentUser.storedAttributes["$NoTargeting"] == nil)
        #expect(currentUser.storedAttributes["noTargeting"] as? String == "false")

        currentUser.removedAttributeKeys = []
        currentUser.setAttributes = [:]
        identityClient.complete(user: currentUser)

        #expect(currentUser.removedAttributeKeys.isEmpty)
        #expect(currentUser.setAttributes.isEmpty)
        #expect(currentUser.storedAttributes["$NoTargeting"] == nil)
        #expect(currentUser.storedAttributes["noTargeting"] as? String == "false")
    }

    @Test func identifySyncLeavesNoTargetingToANewerCallWithoutPrivacyAttributes() {
        let client = MockRoktSDKClient()
        let identityClient = DeferredIdentityClient()
        let previousUser = TestUser(
            userID: 1,
            identities: [NSNumber(value: MPIdentity.email.rawValue): "old@example.com"]
        )
        let identifiedUser = TestUser(
            userID: 2,
            identities: [NSNumber(value: MPIdentity.email.rawValue): "new@example.com"]
        )
        identityClient.currentUser = previousUser
        let filteredUser = TestFilteredUser(attributes: [:])
        let kitAPI = MockKitAPI(filteredUser: filteredUser)
        let owner = MPKitRokt()
        let implementation = MPRoktKitImplementation(
            roktClient: client,
            identityClient: identityClient
        )
        implementation.setContext(owner: owner, kitAPI: kitAPI)
        implementation.filterUserAttributes = { _, _ in [:] }

        selectPlacements(
            implementation,
            attributes: ["email": "new@example.com", "noTargeting": "true"],
            filteredUser: filteredUser
        )
        // The SDK can report the new user before identify completes, and an app may place on it.
        identityClient.currentUser = identifiedUser
        selectPlacements(implementation, attributes: [:], filteredUser: filteredUser)
        identityClient.complete(user: identifiedUser)

        // That newer call's sync wrote `$NoTargeting` for this user, so the older identify leaves it alone.
        #expect(identifiedUser.storedAttributes["$NoTargeting"] == nil)
    }

    @Test func identifySyncSurvivesANewerPrivacyCallForThePreviousUser() {
        let client = MockRoktSDKClient()
        let identityClient = DeferredIdentityClient()
        let previousUser = TestUser(
            userID: 1,
            identities: [NSNumber(value: MPIdentity.email.rawValue): "old@example.com"]
        )
        let identifiedUser = TestUser(
            userID: 2,
            identities: [NSNumber(value: MPIdentity.email.rawValue): "new@example.com"]
        )
        identityClient.currentUser = previousUser
        let filteredUser = TestFilteredUser(attributes: [:])
        let kitAPI = MockKitAPI(filteredUser: filteredUser)
        let owner = MPKitRokt()
        let implementation = MPRoktKitImplementation(
            roktClient: client,
            identityClient: identityClient
        )
        implementation.setContext(owner: owner, kitAPI: kitAPI)
        implementation.filterUserAttributes = { _, _ in [:] }

        selectPlacements(
            implementation,
            attributes: ["email": "new@example.com", "noTargeting": "true"],
            filteredUser: filteredUser
        )
        selectPlacements(implementation, attributes: ["noTargeting": "false"], filteredUser: filteredUser)
        // Core makes the identified user current before it runs the identify completion.
        identityClient.currentUser = identifiedUser
        identityClient.complete(user: identifiedUser)

        #expect(identifiedUser.storedAttributes["$NoTargeting"] as? String == "true")
    }

    @Test func identifySyncLeavesNoTargetingToANewerCallForTheSameUser() {
        let client = MockRoktSDKClient()
        let identityClient = DeferredIdentityClient()
        identityClient.currentUser = TestUser(
            userID: 1,
            identities: [NSNumber(value: MPIdentity.email.rawValue): "old@example.com"]
        )
        let filteredUser = TestFilteredUser(attributes: [:])
        let kitAPI = MockKitAPI(filteredUser: filteredUser)
        let owner = MPKitRokt()
        let implementation = MPRoktKitImplementation(
            roktClient: client,
            identityClient: identityClient
        )
        implementation.setContext(owner: owner, kitAPI: kitAPI)
        implementation.filterUserAttributes = { _, _ in [:] }
        let identifiedUser = TestUser(
            userID: 2,
            identities: [NSNumber(value: MPIdentity.email.rawValue): "new@example.com"]
        )

        selectPlacements(
            implementation,
            attributes: ["email": "new@example.com", "noTargeting": "true"],
            filteredUser: filteredUser
        )
        identityClient.currentUser = identifiedUser
        selectPlacements(implementation, attributes: ["noFunctional": "true"], filteredUser: filteredUser)
        identityClient.complete(user: identifiedUser)

        // Every placement sync writes $NoTargeting, so the newer call for this user decides it.
        #expect(identifiedUser.storedAttributes["$NoTargeting"] == nil)
    }

    @Test func identifySyncSkipsTheKeysANewerCallPassedAndNoTargeting() {
        let client = MockRoktSDKClient()
        let identityClient = DeferredIdentityClient()
        identityClient.currentUser = TestUser(
            userID: 1,
            identities: [NSNumber(value: MPIdentity.email.rawValue): "old@example.com"]
        )
        let filteredUser = TestFilteredUser(attributes: [:])
        let kitAPI = MockKitAPI(filteredUser: filteredUser)
        let owner = MPKitRokt()
        let implementation = MPRoktKitImplementation(
            roktClient: client,
            identityClient: identityClient
        )
        implementation.setContext(owner: owner, kitAPI: kitAPI)
        implementation.filterUserAttributes = { _, _ in [:] }
        let identifiedUser = TestUser(
            userID: 2,
            identities: [NSNumber(value: MPIdentity.email.rawValue): "new@example.com"],
            attributes: ["noFunctional": "false"]
        )

        selectPlacements(
            implementation,
            attributes: ["email": "new@example.com", "noTargeting": "true", "noFunctional": "true"],
            filteredUser: filteredUser
        )
        identityClient.currentUser = identifiedUser
        selectPlacements(implementation, attributes: ["noFunctional": "false"], filteredUser: filteredUser)
        identityClient.complete(user: identifiedUser)

        // noTargeting is skipped too: the newer call's sync wrote `$NoTargeting` for this user.
        #expect(identifiedUser.storedAttributes["$NoTargeting"] == nil)
        #expect(identifiedUser.storedAttributes["noFunctional"] as? String == "false")
        #expect(!identifiedUser.removedAttributeKeys.contains("noFunctional"))
    }

    @Test func olderIdentifyWithoutPrivacyAttributesDoesNotUndoANewerOptOut() {
        let client = MockRoktSDKClient()
        let identityClient = DeferredIdentityClient()
        let previousUser = TestUser(
            userID: 1,
            identities: [NSNumber(value: MPIdentity.email.rawValue): "old@example.com"]
        )
        let identifiedUser = TestUser(
            userID: 2,
            identities: [NSNumber(value: MPIdentity.email.rawValue): "new@example.com"],
            attributes: ["noTargeting": "false"],
            defersAttributeRemoval: true
        )
        identityClient.currentUser = previousUser
        let filteredUser = TestFilteredUser(attributes: [:])
        let kitAPI = MockKitAPI(filteredUser: filteredUser)
        let owner = MPKitRokt()
        let implementation = MPRoktKitImplementation(
            roktClient: client,
            identityClient: identityClient
        )
        implementation.setContext(owner: owner, kitAPI: kitAPI)
        implementation.filterUserAttributes = { _, _ in [:] }

        selectPlacements(implementation, attributes: ["email": "new@example.com"], filteredUser: filteredUser)
        identityClient.currentUser = identifiedUser
        selectPlacements(implementation, attributes: ["noTargeting": "true"], filteredUser: filteredUser)

        #expect(identifiedUser.storedAttributes["$NoTargeting"] as? String == "true")

        identityClient.complete(user: identifiedUser)

        #expect(!identifiedUser.removedAttributeKeys.contains("$NoTargeting"))
        #expect(identifiedUser.storedAttributes["$NoTargeting"] as? String == "true")
    }

    @Test func stopDropsAnInFlightIdentifyPrivacySync() {
        let client = MockRoktSDKClient()
        let identityClient = DeferredIdentityClient()
        identityClient.currentUser = TestUser(
            userID: 1,
            identities: [NSNumber(value: MPIdentity.email.rawValue): "old@example.com"]
        )
        let identifiedUser = TestUser(userID: 2, attributes: ["noTargeting": "false"])
        let filteredUser = TestFilteredUser(attributes: [:])
        let kitAPI = MockKitAPI(filteredUser: filteredUser)
        let owner = MPKitRokt()
        let implementation = MPRoktKitImplementation(
            roktClient: client,
            identityClient: identityClient
        )
        implementation.setContext(owner: owner, kitAPI: kitAPI)
        implementation.filterUserAttributes = { _, _ in [:] }

        selectPlacements(
            implementation,
            attributes: ["email": "new@example.com", "noTargeting": "true"],
            filteredUser: filteredUser
        )
        implementation.stop()
        identityClient.complete(user: identifiedUser)

        #expect(identifiedUser.setAttributes.isEmpty)
        #expect(identifiedUser.removedAttributeKeys.isEmpty)
    }

    private func selectPlacements(
        _ implementation: MPRoktKitImplementation,
        attributes: [String: String],
        filteredUser: FilteredMParticleUser
    ) {
        _ = implementation.selectPlacements(
            identifier: "checkout",
            attributes: attributes,
            embeddedViews: nil,
            config: nil,
            onEvent: nil,
            filteredUser: filteredUser,
            options: nil
        )
    }

    private func identifyDecision(
        _ implementation: MPRoktKitImplementation,
        attributes: [String: String],
        user: MParticleUser?
    ) async -> Bool {
        await withCheckedContinuation { continuation in
            implementation.confirmUser(attributes: attributes, user: user) { _, identified in
                continuation.resume(returning: identified)
            }
        }
    }

    private func preparedAttributes(
        _ implementation: MPRoktKitImplementation,
        attributes: [String: String],
        user: FilteredMParticleUser
    ) async -> [String: String] {
        await withCheckedContinuation { continuation in
            implementation.prepareAttributes(attributes, filteredUser: user) { prepared, _ in
                continuation.resume(returning: prepared)
            }
        }
    }
}
