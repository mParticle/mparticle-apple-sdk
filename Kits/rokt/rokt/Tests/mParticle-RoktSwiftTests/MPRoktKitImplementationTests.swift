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
    private var completion: ((MPIdentityApiResult?, Error?) -> Void)?

    func identify(
        _ request: MPIdentityApiRequest,
        completion: @escaping (MPIdentityApiResult?, Error?) -> Void
    ) {
        self.completion = completion
    }

    func complete() {
        completion?(nil, nil)
        completion = nil
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

    init(filteredUser: FilteredMParticleUser) {
        self.filteredUser = filteredUser
        super.init()
    }

    override func getCurrentUser(withKit kit: any MPKitProtocol) -> FilteredMParticleUser {
        filteredUser
    }
}

struct MPRoktKitImplementationTests {
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

    @Test func identifyWaitDoesNotReorderOrMixPlacementAttributes() async {
        let identityClient = DeferredIdentityClient()
        let implementation = MPRoktKitImplementation(
            roktClient: MockRoktSDKClient(),
            identityClient: identityClient
        )
        let user = TestFilteredUser()
        implementation.filterUserAttributes = { attributes, _ in attributes }
        var results: [[String: String]] = []
        var allCompleted: CheckedContinuation<Void, Never>?

        implementation.prepareAttributes(
            ["email": "ada@example.com", "first": "one"],
            filteredUser: user
        ) { attributes, _ in
            results.append(attributes)
            if results.count == 2 {
                allCompleted?.resume()
            }
        }
        implementation.prepareAttributes(
            ["second": "two"],
            filteredUser: user
        ) { attributes, _ in
            results.append(attributes)
            if results.count == 2 {
                allCompleted?.resume()
            }
        }

        #expect(results.isEmpty)
        await withCheckedContinuation { continuation in
            allCompleted = continuation
            identityClient.complete()
        }

        #expect(results.count == 2)
        #expect(results[0]["first"] == "one")
        #expect(results[0]["second"] == nil)
        #expect(results[1]["first"] == "one")
        #expect(results[1]["second"] == "two")
    }

    @Test func sessionOperationsRemainOrderedBehindPlacementPreparation() {
        let client = MockRoktSDKClient()
        let identityClient = DeferredIdentityClient()
        let implementation = MPRoktKitImplementation(
            roktClient: client,
            identityClient: identityClient
        )
        implementation.filterUserAttributes = { attributes, _ in attributes }

        _ = implementation.selectPlacements(
            identifier: "checkout",
            attributes: ["email": "ada@example.com"],
            embeddedViews: nil,
            config: nil,
            onEvent: nil,
            filteredUser: TestFilteredUser(),
            options: nil
        )
        _ = implementation.clearSession()
        _ = implementation.setSessionID("next-session")
        _ = implementation.close()

        #expect(client.calls.isEmpty)
        identityClient.complete()

        #expect(client.calls == [
            "selectPlacements:checkout",
            "clearSession",
            "setSessionID:next-session",
            "close"
        ])
    }

    @Test func stopInvalidatesInFlightPreparationAndAllowsLaterWork() {
        let client = MockRoktSDKClient()
        let identityClient = DeferredIdentityClient()
        let implementation = MPRoktKitImplementation(
            roktClient: client,
            identityClient: identityClient
        )
        implementation.filterUserAttributes = { attributes, _ in attributes }
        let user = TestFilteredUser()

        _ = implementation.selectShoppableAds(
            identifier: "stale",
            attributes: ["email": "ada@example.com"],
            config: nil,
            onEvent: nil,
            filteredUser: user
        )
        implementation.stop()
        identityClient.complete()

        #expect(client.calls == ["close"])
        #expect(client.selectedIdentifier == nil)

        implementation.start()
        _ = implementation.selectShoppableAds(
            identifier: "current",
            attributes: [:],
            config: nil,
            onEvent: nil,
            filteredUser: user
        )

        #expect(client.calls == ["close", "selectShoppableAds:current"])
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

    @Test func stopClearsWorkspaceStateAndClosesRokt() {
        let client = MockRoktSDKClient()
        let implementation = MPRoktKitImplementation(roktClient: client)
        implementation.configuration = ["accountId": "workspace"]

        implementation.start()
        implementation.stop()

        #expect(!implementation.started)
        #expect(implementation.configuration == nil)
        #expect(client.closed)
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
