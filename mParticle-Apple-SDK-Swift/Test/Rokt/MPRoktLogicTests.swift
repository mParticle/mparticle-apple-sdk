import XCTest
@testable import mParticle_Apple_SDK_Swift

private final class RoktKitDispatchTargetStub: NSObject, MPRoktKitDispatchTarget {
    var sessionId: String?
    var lastURL: URL?
    var handleURLResult = false
    var lastDiagnosticCode: String?

    func getSessionId() -> String? {
        sessionId
    }

    func handleURLCallback(_ url: URL) -> Bool {
        lastURL = url
        return handleURLResult
    }

    func logMParticleApiDiagnostic(_ code: String) {
        lastDiagnosticCode = code
    }
}

private final class NonconformingRoktKitStub: NSObject {
    @objc func handleURLCallback(_: URL) -> Bool {
        true
    }
}

final class MPRoktLogicTests: XCTestCase {
    func testKitIdMatchesLegacyConstant() {
        XCTAssertEqual(MPRoktLogicPRIVATE.kitId, 181)
    }

    func testKitConfigurationFindsKit181AndIgnoresOthers() {
        let configs: NSArray = [
            ["id": 80, "as": ["x": "y"]],
            ["id": 181, "as": ["accountId": 12345]]
        ]
        let found = MPRoktLogicPRIVATE.kitConfiguration(fromOriginalConfig: configs)
        XCTAssertEqual(found?["id"] as? Int, 181)
        XCTAssertEqual((found?["as"] as? NSDictionary)?["accountId"] as? Int, 12345)
        XCTAssertNil(MPRoktLogicPRIVATE.kitConfiguration(fromOriginalConfig: [["id": 80]]))
        XCTAssertNil(MPRoktLogicPRIVATE.kitConfiguration(fromOriginalConfig: []))
        XCTAssertNil(MPRoktLogicPRIVATE.kitConfiguration(fromOriginalConfig: nil))
    }

    func testKitIdsPreserveNilEntries() {
        let configs: NSArray = [
            ["id": 80],
            [:],
            ["id": 181]
        ]
        let ids = MPRoktLogicPRIVATE.kitIds(fromOriginalConfig: configs)
        XCTAssertEqual(ids[0] as? Int, 80)
        XCTAssertEqual(ids[1] as? String, "nil")
        XCTAssertEqual(ids[2] as? Int, 181)
    }

    func testPlacementAttributesMappingNilConfigReturnsNil() {
        XCTAssertNil(MPRoktLogicPRIVATE.placementAttributesMapping(from: nil))
    }

    func testPlacementAttributesMappingMissingMapReturnsEmptyArray() {
        let map = MPRoktLogicPRIVATE.placementAttributesMapping(from: ["id": 181, "as": [:]])
        XCTAssertEqual(map, [])
    }

    func testPlacementAttributesMappingParsesJSONIncludingNSNull() {
        let json = "[{\"jsmap\":null,\"map\":\"f.name\",\"maptype\":\"UserAttributeClass.Name\",\"value\":\"firstname\"}]"
        let map = MPRoktLogicPRIVATE.placementAttributesMapping(from: [
            "as": [MPRoktLogicPRIVATE.placementAttributesMappingKey: json]
        ])
        XCTAssertEqual(map?.count, 1)
        let first = map?.firstObject as? NSDictionary
        XCTAssertEqual(first?["map"] as? String, "f.name")
        XCTAssertEqual(first?["value"] as? String, "firstname")
        XCTAssertTrue(first?["jsmap"] is NSNull)
    }

    func testPlacementAttributesMappingPercentDecodes() {
        let encoded = "%5B%7B%22map%22%3A%22zip%22%2C%22value%22%3A%22billingzipcode%22%7D%5D"
        let map = MPRoktLogicPRIVATE.placementAttributesMapping(from: [
            "as": [MPRoktLogicPRIVATE.placementAttributesMappingKey: encoded]
        ])
        XCTAssertEqual((map?.firstObject as? NSDictionary)?["map"] as? String, "zip")
    }

    func testPlacementAttributesMappingInvalidJSONReturnsNil() {
        XCTAssertNil(MPRoktLogicPRIVATE.placementAttributesMapping(from: [
            "as": [MPRoktLogicPRIVATE.placementAttributesMappingKey: "{not-json"]
        ]))
    }

    func testHashedEmailIdentityTypeLowercasesAndLooksUp() {
        let type = MPRoktLogicPRIVATE.hashedEmailIdentityType(from: [
            "as": [MPRoktLogicPRIVATE.hashedEmailUserIdentityTypeKey: "Other3"]
        ])
        XCTAssertEqual(type, NSNumber(value: MPIdentitySwift.other3.rawValue))
        XCTAssertNil(MPRoktLogicPRIVATE.hashedEmailIdentityType(from: ["as": [:]]))
    }

    func testMappedPlacementAttributesRemapsAndKeepsUnmapped() {
        let attributes: NSDictionary = ["f.name": "Brandon", "zip": "12345", "unmapped": "keep"]
        let attributeMap: NSArray = [
            ["map": "f.name", "value": "firstname"],
            ["map": "zip", "value": "billingzipcode"]
        ]
        let result = MPRoktLogicPRIVATE.mappedPlacementAttributes(attributes, attributeMap: attributeMap)
        XCTAssertEqual(result["firstname"] as? String, "Brandon")
        XCTAssertEqual(result["billingzipcode"] as? String, "12345")
        XCTAssertEqual(result["unmapped"] as? String, "keep")
        XCTAssertNil(result["f.name"])
        XCTAssertNil(result["zip"])
    }

    func testMappedPlacementAttributesNilAttributesReturnsEmptyMutableDictionary() {
        let result = MPRoktLogicPRIVATE.mappedPlacementAttributes(nil, attributeMap: [])
        XCTAssertEqual(result.count, 0)
    }

    func testConfirmSandboxAddsValueOnlyWhenMissing() {
        let added = MPRoktLogicPRIVATE.attributesByConfirmingSandbox(["email": "a@b.com"], isDevelopment: true)
        XCTAssertEqual(added["sandbox"] as? String, "true")
        XCTAssertEqual(added["email"] as? String, "a@b.com")

        let kept = MPRoktLogicPRIVATE.attributesByConfirmingSandbox(["sandbox": "false"], isDevelopment: true)
        XCTAssertEqual(kept["sandbox"] as? String, "false")

        let fromNil = MPRoktLogicPRIVATE.attributesByConfirmingSandbox(nil, isDevelopment: false)
        XCTAssertEqual(fromNil["sandbox"] as? String, "false")
        XCTAssertEqual(fromNil.count, 1)
    }

    func testConfirmUserDecisionMatchesEmailAndHashAgainstIdentities() {
        let identities: NSDictionary = [
            MPRoktLogicPRIVATE.emailIdentityNumber: "old@example.com",
            NSNumber(value: MPIdentitySwift.other3.rawValue): "oldhash"
        ]
        let identify = MPRoktLogicPRIVATE.confirmUserDecision(
            email: "new@example.com",
            hashedEmail: "newhash",
            hashedEmailIdentity: NSNumber(value: MPIdentitySwift.other3.rawValue),
            identities: identities
        )
        XCTAssertTrue(identify.shouldIdentifyFromEmail)
        XCTAssertTrue(identify.shouldIdentifyFromHash)
        XCTAssertTrue(identify.shouldIdentify)

        let skip = MPRoktLogicPRIVATE.confirmUserDecision(
            email: "old@example.com",
            hashedEmail: "oldhash",
            hashedEmailIdentity: NSNumber(value: MPIdentitySwift.other3.rawValue),
            identities: identities
        )
        XCTAssertFalse(skip.shouldIdentify)

        let nilUser = MPRoktLogicPRIVATE.confirmUserDecision(
            email: "a@b.com",
            hashedEmail: nil,
            hashedEmailIdentity: nil,
            identities: nil
        )
        XCTAssertTrue(nilUser.shouldIdentifyFromEmail)
        XCTAssertFalse(nilUser.shouldIdentifyFromHash)
    }

    func testKitDispatchUsesProtocolConformance() {
        let target = RoktKitDispatchTargetStub()
        target.sessionId = "session-1"
        target.handleURLResult = true
        let url = URL(string: "myapp://afterpay-redirect")!

        XCTAssertEqual(MPRoktLogicPRIVATE.sessionId(from: target), "session-1")
        XCTAssertTrue(MPRoktLogicPRIVATE.invokeHandleURLCallback(on: target, url: url))
        XCTAssertEqual(target.lastURL, url)

        MPRoktLogicPRIVATE.performLogMParticleApiDiagnostic(on: target, code: "SELECT_PLACEMENTS")
        XCTAssertEqual(target.lastDiagnosticCode, "SELECT_PLACEMENTS")
    }

    func testKitDispatchSafelyRejectsNonconformingTargets() {
        let target = NonconformingRoktKitStub()
        let url = URL(string: "myapp://afterpay-redirect")!

        XCTAssertNil(MPRoktLogicPRIVATE.sessionId(from: target))
        XCTAssertFalse(MPRoktLogicPRIVATE.invokeHandleURLCallback(on: target, url: url))
        XCTAssertFalse(MPRoktLogicPRIVATE.invokeHandleURLCallback(on: nil, url: url))
        XCTAssertFalse(MPRoktLogicPRIVATE.invokeHandleURLCallback(on: target, url: nil))
        MPRoktLogicPRIVATE.performLogMParticleApiDiagnostic(on: target, code: "SELECT_PLACEMENTS")
    }
}
