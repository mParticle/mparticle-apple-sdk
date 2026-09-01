@testable import mParticle_Apple_SDK_Swift
import XCTest

final class MPKitProjectionEngineTests: XCTestCase {
    private let hasher = MPIHasher(logger: MPLog(logLevel: .none))
    private lazy var engine = MPKitProjectionEngine(
        hasher: hasher,
        valueTransformer: MPKitValueTransformer(logger: MPLog(logLevel: .none))
    )

    func testEventProjectionMatchesCaseInsensitivelyAndMapsAttributes() {
        let projection = eventProjection(
            id: 10,
            name: "checkout",
            projectedName: "purchase",
            matches: [MPKitProjectionMatchSnapshot(attributeKey: "PLAN", attributeValues: ["PREMIUM"])],
            attributes: [
                attribute(name: "plan", projectedName: "tier", matchType: 0),
                attribute(name: "true", projectedName: "successful", matchType: 3, dataType: 3)
            ]
        )
        let source = MPKitEventProjectionSource(
            type: 8,
            name: "CHECKOUT",
            attributes: ["plan": "premium", "unmapped": "value"],
            attributeKeys: ["plan", "unmapped"],
            matchingAttributes: ["plan": "premium", "unmapped": "value"],
            messageType: 4
        )

        let outputs = engine.projectEvent(source, projections: [projection], defaultProjection: nil)

        XCTAssertEqual(outputs.count, 1)
        XCTAssertEqual(outputs[0].kind, .projectedEvent)
        XCTAssertEqual(outputs[0].projectionId, 10)
        XCTAssertEqual(outputs[0].projectedName, "purchase")
        XCTAssertEqual(outputs[0].attributes?["tier"] as? String, "premium")
        XCTAssertEqual(outputs[0].attributes?["successful"] as? NSNumber, true)
        XCTAssertEqual(outputs[0].attributes?["unmapped"] as? String, "value")
    }

    func testMissingRequiredAttributeReturnsOriginalEvent() {
        let projection = eventProjection(
            id: 11,
            name: "event",
            attributes: [attribute(name: "required", projectedName: "mapped", matchType: 0, required: true)]
        )
        let source = MPKitEventProjectionSource(
            type: 8,
            name: "event",
            attributes: ["other": "value"],
            attributeKeys: ["other"],
            matchingAttributes: ["other": "value"],
            messageType: 4
        )

        let outputs = engine.projectEvent(source, projections: [projection], defaultProjection: nil)

        XCTAssertEqual(outputs.count, 1)
        XCTAssertEqual(outputs[0].kind, .originalEvent)
        XCTAssertNil(outputs[0].projectionId)
    }

    func testEventProjectionAppliesDefaultAndCustomAttributeLimit() {
        let defaultProjection = eventProjection(
            id: 12,
            name: nil,
            projectedName: "default",
            matchType: -1,
            maxCustomParameters: 1
        )
        let source = MPKitEventProjectionSource(
            type: 8,
            name: "event",
            attributes: ["a": "first", "z": "last"],
            attributeKeys: ["a", "z"],
            matchingAttributes: ["a": "first", "z": "last"],
            messageType: 4
        )

        let outputs = engine.projectEvent(source, projections: [], defaultProjection: defaultProjection)

        XCTAssertEqual(outputs[0].projectedName, "default")
        XCTAssertEqual(outputs[0].attributes?["a"] as? String, "first")
        XCTAssertNil(outputs[0].attributes?["z"])
    }

    func testCommerceProjectionExpandsEveryProductAndAppendsLimitedCustomAttributes() {
        let productKeyHash = hasher.hashCommerceEventAttribute(.viewDetail, key: "sku")
        let projection = eventProjection(
            id: 20,
            name: nil,
            projectedName: "content_view",
            matchType: 1,
            attributes: [attribute(
                name: productKeyHash,
                projectedName: "content_id",
                matchType: 1,
                propertyKind: 3
            )],
            messageType: 16,
            eventType: MPEventTypeSwift.viewDetail.rawValue,
            maxCustomParameters: 1,
            outboundMessageType: 4
        )
        let source = commerceSource(
            type: .viewDetail,
            customAttributes: ["a": "first", "z": "last"],
            products: [
                MPKitCommerceEntityProjectionSource(fields: nil, attributes: ["sku": "one"]),
                MPKitCommerceEntityProjectionSource(fields: nil, attributes: ["sku": "two"])
            ]
        )

        let outputs = engine.projectCommerceEvent(source, projections: [projection])

        XCTAssertEqual(outputs.count, 2)
        XCTAssertEqual(outputs.map(\.kind), [.projectedEvent, .projectedEvent])
        XCTAssertEqual(outputs.map(\.projectedName), ["content_view", "content_view"])
        XCTAssertEqual(outputs[0].attributes?["content_id"] as? String, "one")
        XCTAssertEqual(outputs[1].attributes?["content_id"] as? String, "two")
        XCTAssertEqual(outputs[0].attributes?["a"] as? String, "first")
        XCTAssertNil(outputs[0].attributes?["z"])
    }

    func testCommerceProjectionUsesLastPromotionAndPreservesCommerceOutput() {
        let projection = eventProjection(
            id: 21,
            name: nil,
            projectedName: nil,
            matchType: 1,
            attributes: [attribute(name: "name", projectedName: "promotion", matchType: 2, propertyKind: 4)],
            behaviorSelector: 1,
            messageType: 16,
            eventType: MPEventTypeSwift.promotionView.rawValue,
            outboundMessageType: 16
        )
        let source = MPKitCommerceProjectionSource(
            type: MPEventTypeSwift.promotionView.rawValue,
            kind: 2,
            eventFields: nil,
            eventAttributes: nil,
            originalCustomAttributes: nil,
            products: nil,
            impressions: nil,
            promotions: [
                MPKitCommerceEntityProjectionSource(fields: ["name": "first"], attributes: nil),
                MPKitCommerceEntityProjectionSource(fields: ["name": "last"], attributes: nil)
            ]
        )

        let outputs = engine.projectCommerceEvent(source, projections: [projection])

        XCTAssertEqual(outputs.count, 1)
        XCTAssertEqual(outputs[0].kind, .projectedCommerceEvent)
        XCTAssertEqual(outputs[0].attributes?["promotion"] as? String, "last")
        XCTAssertEqual(outputs[0].projectionId, 21)
    }

    func testCommerceProjectionRequiresEveryMatch() {
        let keyHash = hasher.hashCommerceEventAttribute(.purchase, key: "currency")
        let projection = eventProjection(
            id: 22,
            name: nil,
            projectedName: "purchase",
            matchType: 1,
            matches: [MPKitProjectionMatchSnapshot(attributeKey: keyHash, attributeValues: ["USD"])],
            messageType: 16,
            eventType: MPEventTypeSwift.purchase.rawValue
        )
        let source = commerceSource(type: .purchase, eventFields: ["currency": "EUR"])

        let outputs = engine.projectCommerceEvent(source, projections: [projection])

        XCTAssertEqual(outputs.count, 1)
        XCTAssertEqual(outputs[0].kind, .originalCommerceEvent)
        XCTAssertNil(outputs[0].projectionId)
    }

    private func eventProjection(
        id: UInt,
        name: String?,
        projectedName: String? = nil,
        matchType: Int = 0,
        matches: [MPKitProjectionMatchSnapshot]? = nil,
        attributes: [MPKitAttributeProjectionSnapshot] = [],
        behaviorSelector: UInt = 0,
        messageType: UInt = 4,
        eventType: UInt = 8,
        maxCustomParameters: UInt = .max,
        outboundMessageType: UInt = 4
    ) -> MPKitProjectionSnapshot {
        MPKitProjectionSnapshot(
            projectionId: id,
            name: name,
            projectedName: projectedName,
            matchType: matchType,
            projectionType: 1,
            propertyKind: 0,
            projectionMatches: matches,
            attributeProjections: attributes,
            behaviorSelector: behaviorSelector,
            eventType: eventType,
            messageType: messageType,
            outboundMessageType: outboundMessageType,
            maxCustomParameters: maxCustomParameters,
            appendAsIs: true
        )
    }

    private func attribute(
        name: String,
        projectedName: String,
        matchType: Int,
        propertyKind: UInt = 0,
        dataType: Int = 1,
        required: Bool = false
    ) -> MPKitAttributeProjectionSnapshot {
        MPKitAttributeProjectionSnapshot(
            name: name,
            projectedName: projectedName,
            matchType: matchType,
            propertyKind: propertyKind,
            dataType: dataType,
            required: required
        )
    }

    private func commerceSource(
        type: MPEventTypeSwift,
        eventFields: [String: Any]? = nil,
        customAttributes: [String: Any]? = nil,
        products: [MPKitCommerceEntityProjectionSource]? = nil
    ) -> MPKitCommerceProjectionSource {
        MPKitCommerceProjectionSource(
            type: type.rawValue,
            kind: 1,
            eventFields: eventFields,
            eventAttributes: customAttributes,
            originalCustomAttributes: customAttributes,
            products: products,
            impressions: nil,
            promotions: nil
        )
    }
}
