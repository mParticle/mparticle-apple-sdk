import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPKitConfigurationTests: XCTestCase {
    private let outOfRangeProjection: [String: Any] = [
        "id": 1,
        "action": ["projected_event_name": "Bogus Event"],
        "matches": [["message_type": 99]]
    ]

    private func parse(_ dictionary: [String: Any]) -> MPKitConfiguration? {
        MPKitConfiguration(dictionary: dictionary)
    }

    // MARK: - configuration hash

    // The expected values are the ones the Objective-C implementation produced for the same
    // dictionaries, pinned in the Objective-C MPKitConfigurationTests.
    func testConfigurationHashMatchesTheObjectiveCHash() {
        let full: [String: Any] = [
            "id": 37,
            "avf": ["i": true, "a": 12345, "v": 54321],
            "as": [
                "appId": "MyAppId",
                "currency": "USD",
                "useCustomerId": "True",
                "passAllOtherIdentities": "True",
                "retrieveAttributionData": "true",
                "enableLogging": "False",
                "limitAdTracking": "True"
            ],
            "bk": ["lo": 10, "hi": 20],
            "hs": [
                "mt": ["ss": 0],
                "et": ["52": 0],
                "ec": ["1594525888": 0],
                "ea": ["1217787541": 0],
                "svec": ["1594525888": 0],
                "svea": ["1217787541": 0],
                "uid": ["2": 0],
                "ua": ["1217787541": 0],
                "eaa": ["330558866": "Tap Count"],
                "ear": ["330558866": "Tap Count"],
                "eas": ["-94160813": "Amount"]
            ]
        ]
        let withNulls: [String: Any] = [
            "id": 80,
            "avf": NSNull(),
            "as": ["appId": "MyAppId"],
            "bk": NSNull(),
            "hs": NSNull()
        ]

        XCTAssertEqual(parse(full)?.configurationHash, 969_680_750)
        XCTAssertEqual(parse(withNulls)?.configurationHash, -1_872_513_399)
    }

    func testHashNumberReadsTheHashAsNSStringIntValueDoes() {
        XCTAssertEqual(MPKitConfiguration.hashNumber(from: "-94160813"), -94_160_813)
        XCTAssertEqual(MPKitConfiguration.hashNumber(from: ""), 0)
        XCTAssertEqual(MPKitConfiguration.hashNumber(from: "2147483648"), NSNumber(value: Int32.max))
        XCTAssertEqual(MPKitConfiguration.hashNumber(from: "-2147483649"), NSNumber(value: Int32.min))
    }

    func testEqualityFollowsTheConfigurationHash() {
        let configuration: [String: Any] = ["id": 80, "as": ["appId": "MyAppId"]]
        let first = parse(configuration)
        let second = parse(configuration)
        let other = parse(["id": 81, "as": ["appId": "MyAppId"]])

        XCTAssertEqual(first, second)
        XCTAssertEqual(first?.hash, second?.hash)
        XCTAssertNotEqual(first, other)
        XCTAssertFalse(first?.isEqual(configuration) ?? true)
    }

    // MARK: - type guards

    func testAnEntryThatIsNotAJSONObjectIsRejectedWithoutLogging() {
        let notObjects: [Any?] = [nil, "kit", ["kit"], 37, NSNull(), ["id": 80, "date": Date()] as [String: Any]]
        let logger = MPLog(logLevel: .verbose)

        for entry in notObjects {
            logger.customLogger = { XCTFail("Logged \($0) for \(String(describing: entry))") }
            XCTAssertNil(MPKitConfiguration(dictionary: entry, logger: logger), "\(String(describing: entry))")
        }
    }

    func testAnEntryWithoutANumericIdIsRejected() {
        for id in ["80", [80], ["id": 80], NSNull()] as [Any] {
            XCTAssertNil(parse(["id": id]), "\(id)")
        }
        XCTAssertNil(parse(["as": ["appId": "MyAppId"]]))
    }

    func testWrongTypedMembersAreIgnored() {
        let configuration = parse([
            "id": 80,
            "as": ["appId"],
            "bk": [10, 20],
            "pr": "pr",
            "eau": ["a": 1],
            "crvf": "filter"
        ])

        XCTAssertNotNil(configuration)
        XCTAssertNil(configuration?.configuration)
        XCTAssertNil(configuration?.bracketConfiguration)
        XCTAssertNil(configuration?.projections)
        XCTAssertNil(configuration?.consentKitFilter)
        XCTAssertEqual(configuration?.excludeAnonymousUsers, false)
    }

    func testExcludeAnonymousUsersReadsANumberOrAString() {
        XCTAssertEqual(parse(["id": 80, "eau": true])?.excludeAnonymousUsers, true)
        XCTAssertEqual(parse(["id": 80, "eau": "true"])?.excludeAnonymousUsers, true)
        XCTAssertEqual(parse(["id": 80, "eau": "False"])?.excludeAnonymousUsers, false)
    }

    // MARK: - sub-filters

    func testEachSubFilterReadsItsOwnKey() throws {
        let keys = [
            "et", "ec", "ea", "mt", "svec", "svea", "uid", "ua",
            "cea", "ent", "afa", "eaa", "ear", "eas", "reg", "pur"
        ]
        var filters: [String: Any] = [:]
        for key in keys {
            filters[key] = [key: 0]
        }
        let configuration = try XCTUnwrap(parse(["id": 80, "hs": filters]))

        let reads: [String: NSDictionary?] = [
            "et": configuration.eventTypeFilters,
            "ec": configuration.eventNameFilters,
            "ea": configuration.eventAttributeFilters,
            "mt": configuration.messageTypeFilters,
            "svec": configuration.screenNameFilters,
            "svea": configuration.screenAttributeFilters,
            "uid": configuration.userIdentityFilters,
            "ua": configuration.userAttributeFilters,
            "cea": configuration.commerceEventAttributeFilters,
            "ent": configuration.commerceEventEntityTypeFilters,
            "afa": configuration.commerceEventAppFamilyAttributeFilters,
            "eaa": configuration.addEventAttributeList,
            "ear": configuration.removeEventAttributeList,
            "eas": configuration.singleItemEventAttributeList,
            "reg": configuration.consentRegulationFilters,
            "pur": configuration.consentPurposeFilters
        ]
        XCTAssertEqual(Set(reads.keys), Set(keys))
        for (key, read) in reads {
            XCTAssertEqual(read, [key: 0] as NSDictionary, key)
        }
    }

    func testAWrongTypedSubFilterIsDroppedAndItsSiblingsKept() {
        let configuration = parse([
            "id": 80,
            "hs": ["et": "not-a-filter", "uid": [0], "mt": NSNull(), "ua": ["1217787541": 0]]
        ])

        XCTAssertNil(configuration?.eventTypeFilters)
        XCTAssertNil(configuration?.userIdentityFilters)
        XCTAssertNil(configuration?.messageTypeFilters)
        XCTAssertNil(configuration?.filters?["mt"], "A null filter is not kept")
        XCTAssertEqual(configuration?.userAttributeFilters, ["1217787541": 0] as NSDictionary)
    }

    func testTheAttributeListsAreMergedIntoTheConfiguration() {
        let configuration = parse([
            "id": 80,
            "as": ["appId": "MyAppId"],
            "hs": ["eaa": ["330558866": "Tap Count"]]
        ])

        XCTAssertEqual(configuration?.configuration?["appId"] as? String, "MyAppId")
        XCTAssertEqual(configuration?.configuration?["eaa"] as? NSDictionary, ["330558866": "Tap Count"] as NSDictionary)
    }

    // MARK: - logger and message type count

    func testProjectionsLogThroughTheGivenLogger() {
        var messages: [String] = []
        let logger = MPLog(logLevel: .error)
        logger.customLogger = { messages.append($0) }
        let configuration = MPKitConfiguration(
            dictionary: ["id": 42, "pr": [outOfRangeProjection]] as [String: Any],
            logger: logger
        )

        XCTAssertNotNil(configuration)
        XCTAssertEqual(messages, ["mParticle -> Ignoring projection with out-of-range message type: 99"])
    }

    func testProjectionArraysHoldOneSlotPerMessageType() {
        let configuration = parse(["id": 42, "pr": [outOfRangeProjection]])

        XCTAssertEqual(MPKitConfiguration.messageTypeSize, 20)
        XCTAssertEqual(configuration?.configuredMessageTypeProjections?.count, 20)
        XCTAssertEqual(configuration?.defaultProjections?.count, 20)
    }
}
