@testable import mParticle_Apple_SDK_Swift
import XCTest

final class MPKitFilterEngineTests: XCTestCase {
    private let hasher = MPIHasher(logger: MPLog(logLevel: .none))

    func testEventDecisionAppliesNameAttributeAndMessageFilters() {
        let engine = MPKitFilterEngine(hasher: hasher)
        let eventType: UInt = 1
        let eventName = "Viewed"
        let blockedAttribute = hasher.hashString("\(eventType)\(eventName)secret")
        let snapshot = configuration(filters: [
            "ea": [blockedAttribute: 0],
            "mt": ["e": 1]
        ])
        let event = MPKitEventSnapshot(type: eventType,
                                       name: eventName,
                                       attributes: ["keep": NSNull(), "secret": "value"],
                                       selectorName: "logEvent:")

        let decision = engine.filterEvent(event, configuration: snapshot)

        XCTAssertFalse(decision.shouldFilter)
        XCTAssertEqual(decision.messageType, "e")
        XCTAssertEqual(decision.filteredAttributes?.count, 1)
        XCTAssertTrue(decision.filteredAttributes?["keep"] is NSNull)
    }

    func testOnlyNumericZeroBlocksAFilterKey() {
        let engine = MPKitFilterEngine(hasher: hasher)
        let eventType: UInt = 2
        let hash = hasher.hashString(String(eventType))
        let event = MPKitEventSnapshot(type: eventType,
                                       name: "event",
                                       attributes: nil,
                                       selectorName: "logEvent:")

        XCTAssertFalse(engine.filterEvent(event,
                                          configuration: configuration(filters: ["et": [hash: 0.5]]))
            .shouldFilter)
        XCTAssertTrue(engine.filterEvent(event,
                                         configuration: configuration(filters: ["et": [hash: 0]]))
            .shouldFilter)
    }

    func testCommerceDecisionReturnsEntityAndAttributeActions() {
        let engine = MPKitFilterEngine(hasher: hasher)
        let eventType: UInt = 16
        let blockedAttribute = hasher.hashString("\(eventType)coupon")

        let entityDecision = engine.filterCommerceEvent(
            type: eventType,
            kind: 1,
            customAttributes: nil,
            beautifiedAttributes: nil,
            transactionAttributes: nil,
            configuration: configuration(filters: ["ent": ["1": 0]])
        )
        XCTAssertEqual(entityDecision.entityAction, .removeProductsAndImpressions)

        let attributeDecision = engine.filterCommerceEvent(
            type: eventType,
            kind: 1,
            customAttributes: ["coupon": "private", "keep": NSNull()],
            beautifiedAttributes: [:],
            transactionAttributes: ["coupon": "private", "transaction_id": "id"],
            configuration: configuration(filters: ["cea": [blockedAttribute: 0]])
        )
        XCTAssertTrue(attributeDecision.hasAttributeFilters)
        XCTAssertTrue(attributeDecision.filteredCustomAttributes?["keep"] is NSNull)
        XCTAssertNil(attributeDecision.filteredCustomAttributes?["coupon"])
        XCTAssertFalse(attributeDecision.allowedTransactionAttributeKeys?.contains("coupon") == true)
        XCTAssertTrue(attributeDecision.allowedTransactionAttributeKeys?.contains("transaction_id") == true)
    }

    func testCCPAConsentTakesPrecedenceOverGDPR() {
        let engine = MPKitFilterEngine(hasher: hasher)
        let gdprRegulation = hasher.hashConsentPurpose("1", purpose: "")
        let consent = MPKitConsentSnapshot(gdprConsents: ["analytics": true], ccpaConsent: false)

        let decision = engine.filterConsent(
            consent,
            configuration: configuration(filters: ["reg": [gdprRegulation: 0]])
        )

        XCTAssertEqual(decision.action, .forwardCCPA)
    }

    func testConsentAndAnonymousDecisionsComposeWithActiveState() {
        let engine = MPKitFilterEngine(hasher: hasher)
        let hash = Int32(hasher.hashConsentPurpose("1", purpose: "analytics"))!
        let consent = MPKitConsentSnapshot(gdprConsents: ["analytics": true], ccpaConsent: nil)
        let filter = MPKitConsentFilterSnapshot(javascriptHashes: [NSNumber(value: hash)],
                                                consentedValues: [true],
                                                shouldIncludeOnMatch: true)

        XCTAssertFalse(engine.isDisabledByConsentFilter(filter, consent: consent))
        XCTAssertFalse(engine.isKitActive(active: true,
                                          mpId: 256,
                                          bracketLow: 0,
                                          bracketHigh: 100,
                                          hasBracket: true,
                                          consentFilter: filter,
                                          consent: consent,
                                          excludesAnonymousUsers: true,
                                          isLoggedIn: false,
                                          isDisabledKit: false))
    }

    private func configuration(filters: [String: Any]) -> MPKitFilterConfigurationSnapshot {
        MPKitFilterConfigurationSnapshot(
            filters: filters,
            attributeValueFilteringIsActive: false,
            attributeValueFilteringHashedAttribute: nil,
            attributeValueFilteringHashedValue: nil,
            attributeValueFilteringShouldIncludeMatches: false
        )
    }
}
