import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPUploadBuilderTests: XCTestCase {
    private var fixture: MPUploadTestFixture!

    override func setUp() {
        super.setUp()
        fixture = MPUploadTestFixture()
    }

    override func tearDown() {
        fixture.userDefaults.resetDefaults()
        fixture = nil
        super.tearDown()
    }

    func testEmptyMessagesDoNotCreateBuilder() {
        XCTAssertNil(fixture.builder(messages: []))
    }

    func testSessionlessUploadUsesFallbacksWithoutQueryingSession() throws {
        let upload = try fixture.build(sessionId: nil)
        let dictionary = try XCTUnwrap(upload.dictionaryRepresentation())
        XCTAssertEqual(fixture.persistence.sessionReads, [])
        XCTAssertEqual(fixture.applicationReads, 1)
        XCTAssertEqual(fixture.deviceReads, [42])
        XCTAssertEqual(dictionary["ai"] as? NSDictionary, ["source": "fallback-app"])
        XCTAssertEqual(dictionary["di"] as? NSDictionary, ["source": "fallback-device"])
    }

    func testStoredSessionInfoAvoidsFallbacks() throws {
        fixture.persistence.sessionInfo = ["ai": ["saved": "app"], "di": ["saved": "device"]]
        let upload = try fixture.build(sessionId: 7)
        XCTAssertEqual(fixture.persistence.sessionReads, [7])
        XCTAssertEqual(fixture.applicationReads, 0)
        XCTAssertTrue(fixture.deviceReads.isEmpty)
        XCTAssertEqual(upload.dictionaryRepresentation()?["ai"] as? NSDictionary, ["saved": "app"])
    }

    func testMissingDeviceInfoOnlyLoadsDeviceFallback() throws {
        fixture.persistence.sessionInfo = ["ai": ["saved": "app"]]
        _ = try fixture.build(sessionId: 7)
        XCTAssertEqual(fixture.applicationReads, 0)
        XCTAssertEqual(fixture.deviceReads, [42])
    }

    func testSeedValuesStayAtConstructionAndHeadersStayLive() throws {
        fixture.state.optOut = false
        fixture.lifetimeValue = 10
        let builder = try XCTUnwrap(fixture.builder())
        fixture.lifetimeValue = 20
        fixture.state.apiKey = "changed-key"
        fixture.state.optOut = true
        let upload = try fixture.finish(builder)
        let dictionary = try XCTUnwrap(upload.dictionaryRepresentation())
        XCTAssertEqual(dictionary["ltv"] as? NSNumber, 10)
        XCTAssertEqual(dictionary["oo"] as? Bool, false)
        XCTAssertEqual(dictionary["a"] as? String, "changed-key")
        XCTAssertEqual(upload.uuid, "batch-id")
        XCTAssertEqual(dictionary["ct"] as? NSNumber, 123000)
    }

    func testDataPlanAndSettingsArePreserved() throws {
        let settings = NSObject()
        let builder = try XCTUnwrap(fixture.builder(planId: "plan", planVersion: 3, settings: settings))
        let upload = try fixture.finish(builder)
        XCTAssertEqual(upload.dataPlanId, "plan")
        XCTAssertEqual(upload.dataPlanVersion, 3)
        XCTAssertTrue(upload.uploadSettings === settings)
        XCTAssertEqual(upload.dictionaryRepresentation()?["ctx"] as? NSDictionary, ["dpln": ["id": "plan", "v": 3]])
    }

    func testVersionWithoutPlanIsOmitted() throws {
        let upload = try fixture.finish(XCTUnwrap(fixture.builder(planVersion: 3)))
        XCTAssertNil(upload.dataPlanVersion)
        XCTAssertNil(upload.dictionaryRepresentation()?["ctx"])
    }

    func testAdvertiserIDOnlyUpdatesWhenAuthorized() throws {
        fixture.persistence.sessionInfo = ["di": ["aid": "saved"]]
        fixture.advertiserID = "current"
        for status: NSNumber? in [nil, 0, 1, 2, 3] {
            fixture.state.attAuthorizationStatus = status
            let upload = try fixture.build(sessionId: 7)
            let device = try XCTUnwrap(upload.dictionaryRepresentation()?["di"] as? NSDictionary)
            XCTAssertEqual(device["aid"] as? String, status == 3 ? "current" : "saved")
        }
    }

    func testConsentIsReadAfterForwardRecordDeletionAndBeforeHook() throws {
        fixture.persistence.records = [MPForwardRecordPRIVATE(recordId: 7, dataDictionary: ["mid": 1], mpid: 42)]
        fixture.consent = ["ccpa": ["data_sale_opt_out": ["c": true]]]
        fixture.transform = { [unowned self] batch in
            XCTAssertEqual(self.fixture.persistence.deletedRecordIds, [7])
            XCTAssertEqual(batch["con"] as? NSDictionary, self.fixture.consent)
            return nil
        }
        let builder = try XCTUnwrap(fixture.builder())
        builder.build { _ in XCTFail("Blocked batch must suppress completion") }
        XCTAssertEqual(fixture.persistence.deletedRecordIds, [7])
    }

    func testOnlyValidForwardRecordsAreIncludedAndDeleted() throws {
        fixture.persistence.records = [
            MPForwardRecordPRIVATE(recordId: 1, dataDictionary: ["mid": 7], mpid: 42),
            MPForwardRecordPRIVATE(recordId: 2, dataDictionary: nil, mpid: 42)
        ]
        let upload = try fixture.build()
        XCTAssertEqual(upload.dictionaryRepresentation()?["fsr"] as? [NSDictionary], [["mid": 7]])
        XCTAssertEqual(fixture.persistence.deletedRecordIds, [1])
    }

    func testEqualReplacementDoesNotMarkBatch() throws {
        fixture.transform = { NSDictionary(dictionary: $0) }
        XCTAssertNil(try fixture.build().dictionaryRepresentation()?["mb"])
    }

    func testDifferentReplacementMarksBatch() throws {
        fixture.transform = { batch in
            let replacement = NSMutableDictionary(dictionary: batch)
            replacement["custom"] = "value"
            return replacement
        }
        let dictionary = try XCTUnwrap(fixture.build().dictionaryRepresentation())
        XCTAssertEqual(dictionary["mb"] as? Bool, true)
        XCTAssertEqual(dictionary["custom"] as? String, "value")
    }

    func testInPlaceMutationDoesNotMarkBatch() throws {
        fixture.transform = { batch in
            (batch as? NSMutableDictionary)?["custom"] = "value"
            return batch
        }
        let dictionary = try XCTUnwrap(fixture.build().dictionaryRepresentation())
        XCTAssertEqual(dictionary["custom"] as? String, "value")
        XCTAssertNil(dictionary["mb"])
    }

    func testNonDictionaryHookResultLeavesBatchUnchanged() throws {
        fixture.transform = { _ in NSNull() }
        XCTAssertNotNil(try fixture.build().dictionaryRepresentation()?["msgs"])
    }

    func testSerializationFailureCallsCompletionWithNil() throws {
        fixture.transform = { batch in
            let replacement = NSMutableDictionary(dictionary: batch)
            replacement["invalid-number"] = Double.nan
            return replacement
        }
        var completed = false
        try XCTUnwrap(fixture.builder()).build { upload in
            completed = true
            XCTAssertNil(upload)
        }
        XCTAssertTrue(completed)
    }

    func testDeletedAttributesRequireSessionAndNumbersAreStringified() throws {
        for sessionId: NSNumber? in [nil, 7] {
            let builder = try XCTUnwrap(fixture.builder(sessionId: sessionId))
            _ = builder.withUserAttributes(["number": 5], deletedUserAttributes: NSSet(array: ["removed"]))
            _ = builder.withUserIdentities([["n": 1, "i": "customer"]])
            let dictionary = try XCTUnwrap(fixture.finish(builder).dictionaryRepresentation())
            XCTAssertEqual(dictionary["ua"] as? NSDictionary, ["number": "5"])
            XCTAssertEqual(dictionary["uad"] as? [String], sessionId == nil ? nil : ["removed"])
            XCTAssertEqual(dictionary["ui"] as? [NSDictionary], [["n": 1, "i": "customer"]])
        }
    }
}

final class MPUploadTestFixture {
    let connector = MPUserDefaultsConnectorMock()
    let userDefaults: MPUserDefaults
    let state: MPStateMachinePRIVATE
    var persistence = MPUploadEnrichmentMock()
    var lifetimeValue: NSNumber = 0
    var advertiserID: String?
    var consent: NSDictionary?
    var applicationReads = 0
    var deviceReads: [NSNumber] = []
    var transform: (NSDictionary) -> Any? = { $0 }

    init() {
        userDefaults = MPUserDefaults(connector: connector)
        state = MPStateMachinePRIVATE(userDefaults: userDefaults, connector: connector,
                                      messageQueue: .main, sdkVersion: "test", deploymentTarget: 0, buildSDK: 0)
    }

    lazy var context: MPUploadBuilderContext = {
        let context = MPUploadBuilderContext(
            stateMachine: { [unowned self] in self.state },
            lifetimeValue: { [unowned self] _ in self.lifetimeValue },
            persistence: { [unowned self] in self.persistence },
            applicationInfo: { [unowned self] _ in
                self.applicationReads += 1
                return ["source": "fallback-app"]
            },
            deviceInfo: { [unowned self] mpid in
                self.deviceReads.append(mpid)
                return ["source": "fallback-device"]
            },
            advertiserID: { [unowned self] _ in self.advertiserID },
            consent: { [unowned self] _ in self.consent },
            transformBatch: { [unowned self] in self.transform($0) },
            logger: { nil }, sdkVersion: "test-sdk"
        )
        context.timestamp = { 123000 }
        context.messageID = { "batch-id" }
        return context
    }()

    func message() -> MPMessagePRIVATE {
        MPMessagePRIVATE(session: nil, messageType: "e", messageInfo: ["n": "event"],
                         uploadStatus: 1, uuid: "message-id", timestamp: 100, userId: 42,
                         dataPlanId: nil, dataPlanVersion: nil)
    }

    func builder(sessionId: NSNumber? = nil, messages: [MPMessagePRIVATE]? = nil,
                 planId: String? = nil, planVersion: NSNumber? = nil,
                 settings: NSObject = NSObject()) -> MPUploadBuilderPRIVATE? {
        MPUploadBuilderPRIVATE(mpid: 42, sessionId: sessionId, messages: messages ?? [message()],
                               sessionTimeout: 60, uploadInterval: 30, dataPlanId: planId,
                               dataPlanVersion: planVersion, uploadSettings: settings, context: context)
    }

    func finish(_ builder: MPUploadBuilderPRIVATE) throws -> MPUploadPRIVATE {
        var result: MPUploadPRIVATE?
        builder.build { result = $0 }
        return try XCTUnwrap(result)
    }

    func build(sessionId: NSNumber? = nil) throws -> MPUploadPRIVATE {
        try finish(XCTUnwrap(builder(sessionId: sessionId)))
    }
}

final class MPUploadEnrichmentMock: NSObject, MPUploadEnrichmentPersistence {
    var sessionInfo: NSDictionary = [:]
    var sessionReads: [NSNumber] = []
    var records: [MPForwardRecordPRIVATE]?
    var integrationAttributes: [MPIntegrationAttributesPRIVATE]?
    var deletedRecordIds: [NSNumber] = []

    func objectiveCAppAndDeviceInfo(forSessionId sessionId: NSNumber) -> NSDictionary {
        sessionReads.append(sessionId)
        return sessionInfo
    }

    func objectiveCFetchForwardRecords() -> NSArray? { records as NSArray? }
    func objectiveCDeleteForwardRecords(ids: [NSNumber]) { deletedRecordIds.append(contentsOf: ids) }
    func objectiveCFetchIntegrationAttributes() -> NSArray? { integrationAttributes as NSArray? }
}
