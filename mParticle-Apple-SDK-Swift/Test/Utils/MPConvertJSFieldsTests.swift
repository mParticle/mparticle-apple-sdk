import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPConvertJSFieldsTests: XCTestCase {
    // MARK: - commerce event action

    /// MPJSCommerceEventAction and MPCommerceEventAction do not share an order,
    /// so every pair is spelled out rather than trusting a cast.
    func testCommerceEventActionRemapsEveryDefinedValue() {
        let expected: [Int: Int] = [
            1: 0, // AddToCart
            2: 1, // RemoveFromCart
            3: 4, // Checkout
            4: 5, // CheckoutOptions
            5: 6, // Click
            6: 7, // ViewDetail
            7: 8, // Purchase
            8: 9, // Refund
            9: 2, // AddToWishList
            10: 3 // RemoveFromWishlist
        ]

        for (js, core) in expected {
            XCTAssertEqual(
                MPConvertJSFields.commerceEventAction(forJSValue: NSNumber(value: js)),
                NSNumber(value: core),
                "JS action \(js) should map to core action \(core)"
            )
        }
    }

    func testCommerceEventActionIsNilForUnknownAndUndefinedValues() {
        // 0 is MPJSCommerceEventActionUnknown, which the ObjC switch also let
        // fall through to default:. nil is how the caller knows to log.
        for raw in [0, 11, 99, -1] {
            XCTAssertNil(MPConvertJSFields.commerceEventAction(forJSValue: NSNumber(value: raw)))
        }
        XCTAssertNil(MPConvertJSFields.commerceEventAction(forJSValue: nil))
    }

    func testCommerceEventActionAcceptsAStringEncodedValue() {
        // The ObjC read the value with -intValue, which NSString answers too,
        // and the parameter is declared NSNumber* without ObjC enforcing it.
        XCTAssertEqual(
            MPConvertJSFields.commerceEventAction(forJSValue: "7"),
            NSNumber(value: 8) // Purchase
        )
        XCTAssertNil(MPConvertJSFields.commerceEventAction(forJSValue: "not a number"))
        XCTAssertNil(MPConvertJSFields.commerceEventAction(forJSValue: ["unexpected": "shape"]))
    }

    // MARK: - promotion

    func testPromotionFieldsReadsEveryString() {
        let fields = MPConvertJSFields.promotionFields(from: [
            "Creative": "banner",
            "Name": "summer sale",
            "Position": "top",
            "Id": "promo-1"
        ])

        XCTAssertEqual(fields.creative, "banner")
        XCTAssertEqual(fields.name, "summer sale")
        XCTAssertEqual(fields.position, "top")
        XCTAssertEqual(fields.promotionId, "promo-1")
    }

    func testPromotionFieldsDropsNonStringsAndNulls() {
        // -isKindOfClass:[NSString class] rejected these rather than coercing.
        let fields = MPConvertJSFields.promotionFields(from: [
            "Creative": 42,
            "Name": NSNull(),
            "Position": ["nested": "value"],
            "Id": true
        ])

        XCTAssertNil(fields.creative)
        XCTAssertNil(fields.name)
        XCTAssertNil(fields.position)
        XCTAssertNil(fields.promotionId)
    }

    func testPromotionFieldsToleratesAnEmptyOrMissingPayload() {
        for json: [AnyHashable: Any]? in [[:], nil] {
            let fields = MPConvertJSFields.promotionFields(from: json)

            XCTAssertNil(fields.creative)
            XCTAssertNil(fields.name)
            XCTAssertNil(fields.position)
            XCTAssertNil(fields.promotionId)
        }
    }

    func testPromotionFieldsKeepsTheEmptyString() {
        // An empty string is still an NSString, so the ObjC assigned it.
        XCTAssertEqual(MPConvertJSFields.promotionFields(from: ["Name": ""]).name, "")
    }

    // MARK: - transaction attributes

    func testTransactionAttributesFieldsReadsEveryValue() {
        let fields = MPConvertJSFields.transactionAttributesFields(from: [
            "Affiliation": "store",
            "CouponCode": "SAVE10",
            "ShippingAmount": 4.5,
            "TaxAmount": 1.25,
            "TotalAmount": 99.99,
            "TransactionId": "txn-1"
        ])

        XCTAssertEqual(fields.affiliation, "store")
        XCTAssertEqual(fields.couponCode, "SAVE10")
        XCTAssertEqual(fields.shipping, NSNumber(value: 4.5))
        XCTAssertEqual(fields.tax, NSNumber(value: 1.25))
        XCTAssertEqual(fields.revenue, NSNumber(value: 99.99))
        XCTAssertEqual(fields.transactionId, "txn-1")
    }

    func testTransactionAttributesFieldsRejectsMismatchedTypes() {
        // Numbers in string slots and strings in number slots were both dropped.
        let fields = MPConvertJSFields.transactionAttributesFields(from: [
            "Affiliation": 7,
            "CouponCode": NSNull(),
            "ShippingAmount": "4.5",
            "TaxAmount": NSNull(),
            "TotalAmount": ["a": 1],
            "TransactionId": 12345
        ])

        XCTAssertNil(fields.affiliation)
        XCTAssertNil(fields.couponCode)
        XCTAssertNil(fields.shipping)
        XCTAssertNil(fields.tax)
        XCTAssertNil(fields.revenue)
        XCTAssertNil(fields.transactionId)
    }

    func testTransactionAttributesFieldsToleratesAnEmptyOrMissingPayload() {
        for json: [AnyHashable: Any]? in [[:], nil] {
            let fields = MPConvertJSFields.transactionAttributesFields(from: json)

            XCTAssertNil(fields.affiliation)
            XCTAssertNil(fields.revenue)
            XCTAssertNil(fields.transactionId)
        }
    }

    func testTransactionAttributesFieldsKeepsZeroAmounts() {
        // Zero is a real NSNumber, and the setters distinguish it from absent.
        let fields = MPConvertJSFields.transactionAttributesFields(from: [
            "ShippingAmount": 0,
            "TotalAmount": 0.0
        ])

        XCTAssertEqual(fields.shipping, NSNumber(value: 0))
        XCTAssertEqual(fields.revenue, NSNumber(value: 0.0))
    }

    // MARK: - product

    func testProductFieldsReadsEveryValue() {
        let fields = MPConvertJSFields.productFields(from: [
            "Brand": "Acme",
            "Category": "widgets",
            "CouponCode": "SAVE5",
            "Name": "Widget",
            "Price": 9.99,
            "Sku": "SKU-1",
            "Variant": "blue",
            "Position": 3,
            "Quantity": 2
        ])

        XCTAssertEqual(fields.brand, "Acme")
        XCTAssertEqual(fields.category, "widgets")
        XCTAssertEqual(fields.couponCode, "SAVE5")
        XCTAssertEqual(fields.name, "Widget")
        XCTAssertEqual(fields.price, NSNumber(value: 9.99))
        XCTAssertEqual(fields.sku, "SKU-1")
        XCTAssertEqual(fields.variant, "blue")
        XCTAssertEqual(fields.position, NSNumber(value: 3))
        XCTAssertEqual(fields.quantity, NSNumber(value: 2))
    }

    func testProductPriceAcceptsAStringAndFallsBackToZero() {
        // The ObjC had a second branch for NSString using -doubleValue, which
        // yields 0 for text that is not a number rather than dropping the field.
        XCTAssertEqual(MPConvertJSFields.productFields(from: ["Price": "9.99"]).price, NSNumber(value: 9.99))
        XCTAssertEqual(MPConvertJSFields.productFields(from: ["Price": "abc"]).price, NSNumber(value: 0.0))
        XCTAssertNil(MPConvertJSFields.productFields(from: ["Price": NSNull()]).price)
        XCTAssertNil(MPConvertJSFields.productFields(from: ["Price": ["a": 1]]).price)
    }

    func testProductPositionIsNilWhenAbsentOrNotANumber() {
        // position is a scalar on MPProduct, so nil has to mean "do not assign"
        // rather than "assign zero".
        XCTAssertNil(MPConvertJSFields.productFields(from: [:]).position)
        XCTAssertNil(MPConvertJSFields.productFields(from: ["Position": "3"]).position)
        XCTAssertEqual(MPConvertJSFields.productFields(from: ["Position": 0]).position, NSNumber(value: 0))
    }

    func testProductAttributesKeepsOnlyStringToStringPairs() {
        let fields = MPConvertJSFields.productFields(from: ["Attributes": [
            "good": "value",
            "numeric": 42,
            "null": NSNull(),
            "nested": ["a": "b"]
        ]])

        XCTAssertEqual(fields.attributes, ["good": "value"])
    }

    func testProductAttributesIsEmptyWhenAbsentOrNotADictionary() {
        for value: Any in ["not a dictionary", 7, NSNull(), ["a", "b"]] {
            XCTAssertTrue(MPConvertJSFields.productFields(from: ["Attributes": value]).attributes.isEmpty)
        }
        XCTAssertTrue(MPConvertJSFields.productFields(from: nil).attributes.isEmpty)
    }

    // MARK: - identity request

    func testIdentityRequestReadsThePairsInApplicationOrder() {
        let parsed = MPConvertJSFields.identityRequest(from: [
            "UserIdentities": [
                ["Identity": "a@example.com", "Type": 7],
                ["Identity": "cust-1", "Type": 1]
            ],
            "Identity": "last@example.com",
            "Type": 7
        ])

        XCTAssertEqual(parsed.outcome, .ok)
        XCTAssertEqual(parsed.pairs.count, 3)
        XCTAssertEqual(parsed.pairs.map(\.identity), ["a@example.com", "cust-1", "last@example.com"])
        // The top-level pair is applied last, so a duplicated type overwrites.
        XCTAssertEqual(parsed.pairs.last?.identityType, 7)
    }

    func testIdentityRequestReportsAMissingUserIdentitiesArray() {
        for json: [AnyHashable: Any]? in [[:], nil, ["UserIdentities": NSNull()], ["UserIdentities": "nope"]] {
            XCTAssertEqual(MPConvertJSFields.identityRequest(from: json).outcome, .missingUserIdentities)
        }
    }

    func testIdentityRequestReportsAMalformedEntrySeparately() {
        // Distinct from the missing-array case: the ObjC logged for that one and
        // returned nil silently for this one.
        let cases: [Any] = [
            ["Type": 7], // no Identity
            ["Identity": "a@example.com"], // no Type
            ["Identity": 42, "Type": 7], // Identity not a string
            ["Identity": "a@example.com", "Type": "7"], // Type not a number
            "not a dictionary" // crashed the ObjC outright
        ]

        for entry in cases {
            let parsed = MPConvertJSFields.identityRequest(from: ["UserIdentities": [entry]])
            XCTAssertEqual(parsed.outcome, .malformedEntry)
            XCTAssertTrue(parsed.pairs.isEmpty)
        }
    }

    func testIdentityRequestAcceptsAnEmptyArrayWithNoTopLevelPair() {
        let parsed = MPConvertJSFields.identityRequest(from: ["UserIdentities": []])

        XCTAssertEqual(parsed.outcome, .ok)
        XCTAssertTrue(parsed.pairs.isEmpty)
    }

    func testIdentityRequestIgnoresAPartialTopLevelPair() {
        for json: [AnyHashable: Any] in [
            ["UserIdentities": [], "Identity": "a@example.com"],
            ["UserIdentities": [], "Type": 7],
            ["UserIdentities": [], "Identity": 42, "Type": 7]
        ] {
            let parsed = MPConvertJSFields.identityRequest(from: json)

            XCTAssertEqual(parsed.outcome, .ok)
            XCTAssertTrue(parsed.pairs.isEmpty)
        }
    }
}
