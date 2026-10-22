import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPConsentStateTests: XCTestCase {
    func testCanonicalizeTrimsAndLowercases() {
        XCTAssertEqual(MPConsentStatePRIVATE.canonicalizeForDeduplication("  TeSt pUrpose     "), "test purpose")
        XCTAssertNil(MPConsentStatePRIVATE.canonicalizeForDeduplication(nil))
        XCTAssertNil(MPConsentStatePRIVATE.canonicalizeForDeduplication(""))
        XCTAssertNil(MPConsentStatePRIVATE.canonicalizeForDeduplication(NSNull()))
        XCTAssertNil(MPConsentStatePRIVATE.canonicalizeForDeduplication("   "))
    }

    func testAddAndRetrieveGDPRRecord() {
        let state = MPConsentStatePRIVATE()
        let record = MPConsentRecordPRIVATE()
        record.consented = true
        record.document = "doc"

        XCTAssertEqual(state.addGDPRConsentRecord(record, purpose: "  Test Purpose "), .success)
        let stored = state.gdprConsentRecords()["test purpose"] as? MPConsentRecordPRIVATE
        XCTAssertTrue(stored?.consented ?? false)
        XCTAssertEqual(stored?.document, "doc")
        XCTAssertFalse(stored === record)
    }

    func testAddRejectsInvalidPurposeAndConsent() {
        let state = MPConsentStatePRIVATE()
        let record = MPConsentRecordPRIVATE()
        XCTAssertEqual(state.addGDPRConsentRecord(record, purpose: ""), .invalidPurpose)
        XCTAssertEqual(state.addGDPRConsentRecord(NSNull(), purpose: "purpose"), .invalidConsent)
        XCTAssertEqual(state.gdprConsentRecords().count, 0)
    }

    func testTooManyGDPRPurposes() {
        let state = MPConsentStatePRIVATE()
        for index in 0..<MPConsentStatePRIVATE.maxGDPRConsentPurposes {
            XCTAssertEqual(state.addGDPRConsentRecord(MPConsentRecordPRIVATE(), purpose: "purpose-\(index)"), .success)
        }
        XCTAssertEqual(state.addGDPRConsentRecord(MPConsentRecordPRIVATE(), purpose: "one-more"), .tooManyPurposes)
        XCTAssertEqual(state.gdprConsentRecords().count, MPConsentStatePRIVATE.maxGDPRConsentPurposes)
    }

    func testCCPACopyOnSetAndRemove() {
        let state = MPConsentStatePRIVATE()
        let record = MPConsentRecordPRIVATE()
        record.consented = true
        state.setCCPAConsentRecord(record)
        XCTAssertTrue(state.ccpaConsentRecord()?.consented ?? false)
        XCTAssertFalse(state.ccpaConsentRecord() === record)
        state.removeCCPAConsentRecord()
        XCTAssertNil(state.ccpaConsentRecord())
    }

    func testServerDictionaryUsesShortKeys() {
        let record = MPConsentRecordPRIVATE()
        record.consented = true
        record.document = "foo-document-1"
        record.location = "foo-location-1"
        record.hardwareId = "foo-hardware-id-1"
        let gdpr: NSDictionary = ["test purpose 1": record]

        let dictionary = MPConsentSerializationPRIVATE.serverDictionary(fromGDPR: gdpr, ccpa: nil)
        let gdprDictionary = dictionary["gdpr"] as? NSDictionary
        let purpose = gdprDictionary?["test purpose 1"] as? NSDictionary
        XCTAssertEqual(purpose?["c"] as? Bool, true)
        XCTAssertEqual(purpose?["d"] as? String, "foo-document-1")
        XCTAssertEqual(purpose?["l"] as? String, "foo-location-1")
        XCTAssertEqual(purpose?["h"] as? String, "foo-hardware-id-1")
        XCTAssertNotNil(purpose?["ts"])
    }

    func testStorageRoundTrip() {
        let record = MPConsentRecordPRIVATE()
        record.consented = true
        record.document = "foo-document-1"
        record.location = "foo-location-1"
        record.hardwareId = "foo-hardware-id-1"
        let timestamp = Date(timeIntervalSince1970: 1_524_176_880.888195/1000)
        record.timestamp = timestamp

        let dictionary = MPConsentSerializationPRIVATE.storageDictionary(fromGDPR: ["test purpose 1": record], ccpa: nil)
        XCTAssertNotNil(dictionary)
        guard let string = MPConsentSerializationPRIVATE.string(from: dictionary ?? NSDictionary()) else {
            XCTFail("Expected storage dictionary to serialize")
            return
        }
        guard let parsed = MPConsentSerializationPRIVATE.dictionary(from: string) else {
            XCTFail("Expected string to deserialize")
            return
        }
        let restored = MPConsentSerializationPRIVATE.gdprRecords(fromStorage: parsed)["test purpose 1"] as? MPConsentRecordPRIVATE
        XCTAssertTrue(restored?.consented ?? false)
        XCTAssertEqual(restored?.document, "foo-document-1")
        XCTAssertEqual(restored?.location, "foo-location-1")
        XCTAssertEqual(restored?.hardwareId, "foo-hardware-id-1")
        XCTAssertEqual(restored?.timestamp, timestamp)
    }

    func testServerDictionaryFromConsentState() {
        XCTAssertEqual(MPConsentSerializationPRIVATE.serverDictionary(from: nil).count, 0)
        let state = MPConsentStatePRIVATE()
        XCTAssertEqual(MPConsentSerializationPRIVATE.serverDictionary(from: state).count, 0)

        let record = MPConsentRecordPRIVATE()
        record.consented = true
        record.document = "foo-document-1"
        _ = state.addGDPRConsentRecord(record, purpose: "test purpose 1")
        state.setCCPAConsentRecord(record)

        let dictionary = MPConsentSerializationPRIVATE.serverDictionary(from: state)
        let gdpr = (dictionary["gdpr"] as? NSDictionary)?["test purpose 1"] as? NSDictionary
        let ccpa = (dictionary["ccpa"] as? NSDictionary)?["data_sale_opt_out"] as? NSDictionary
        XCTAssertEqual(gdpr?["d"] as? String, "foo-document-1")
        XCTAssertEqual(ccpa?["c"] as? Bool, true)
    }

    func testConsentStateStringRoundTrip() {
        XCTAssertNil(MPConsentSerializationPRIVATE.string(from: nil, logger: nil))
        let state = MPConsentStatePRIVATE()
        XCTAssertNil(MPConsentSerializationPRIVATE.string(from: state, logger: nil))

        let record = MPConsentRecordPRIVATE()
        record.consented = true
        record.document = "foo-document-1"
        _ = state.addGDPRConsentRecord(record, purpose: "test purpose 1")
        state.setCCPAConsentRecord(record)

        guard let string = MPConsentSerializationPRIVATE.string(from: state, logger: nil) else {
            XCTFail("Expected consent state to serialize")
            return
        }
        let restored = MPConsentSerializationPRIVATE.consentState(from: string, logger: nil)
        let gdpr = restored?.gdprConsentRecords()["test purpose 1"] as? MPConsentRecordPRIVATE
        XCTAssertEqual(gdpr?.document, "foo-document-1")
        XCTAssertEqual(restored?.ccpaConsentRecord()?.consented, true)
    }

    func testConsentStateFromStringLogsOnlyUnreadableStrings() {
        var messages: [String] = []
        let logger = MPLog(logLevel: .error)
        logger.customLogger = { messages.append($0) }

        XCTAssertNil(MPConsentSerializationPRIVATE.consentState(from: "not json", logger: logger))
        XCTAssertEqual(messages, ["mParticle -> Failed to create consent state from string=not json"])

        XCTAssertNil(MPConsentSerializationPRIVATE.consentState(from: "{}", logger: logger))
        XCTAssertNotNil(MPConsentSerializationPRIVATE.consentState(from: "{\"gdpr\":{}}", logger: logger))
        XCTAssertEqual(messages.count, 1)
    }

    func testFilterFromDictionary() {
        let config: NSDictionary = [
            "i": true,
            "v": [
                ["c": true, "h": 48_278_946],
                ["c": true, "h": 1_556_641]
            ]
        ]
        let filter = MPConsentSerializationPRIVATE.filter(from: config)
        XCTAssertEqual(filter?.shouldIncludeOnMatch, true)
        XCTAssertEqual(filter?.filterItems?.count, 2)
        XCTAssertEqual(filter?.filterItems?.first?.javascriptHash, 48_278_946)
        XCTAssertEqual(filter?.filterItems?.last?.javascriptHash, 1_556_641)
    }
}
