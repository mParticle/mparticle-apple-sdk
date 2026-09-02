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
}
