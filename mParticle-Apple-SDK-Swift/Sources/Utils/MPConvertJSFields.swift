import Foundation

/// The strings the webview bridge sends for one promotion.
@objc(MPPromotionFieldsJS)
public final class MPPromotionFieldsJS: NSObject {
    @objc public let creative: String?
    @objc public let name: String?
    @objc public let position: String?
    @objc public let promotionId: String?

    init(creative: String?, name: String?, position: String?, promotionId: String?) {
        self.creative = creative
        self.name = name
        self.position = position
        self.promotionId = promotionId
        super.init()
    }
}

/// The values the webview bridge sends for one set of transaction attributes.
@objc(MPTransactionAttributesFieldsJS)
public final class MPTransactionAttributesFieldsJS: NSObject {
    @objc public let affiliation: String?
    @objc public let couponCode: String?
    @objc public let shipping: NSNumber?
    @objc public let tax: NSNumber?
    @objc public let revenue: NSNumber?
    @objc public let transactionId: String?

    init(
        affiliation: String?,
        couponCode: String?,
        shipping: NSNumber?,
        tax: NSNumber?,
        revenue: NSNumber?,
        transactionId: String?
    ) {
        self.affiliation = affiliation
        self.couponCode = couponCode
        self.shipping = shipping
        self.tax = tax
        self.revenue = revenue
        self.transactionId = transactionId
        super.init()
    }
}

/// Reads the webview bridge's JSON payloads. Building the SDK types themselves
/// stays in MPConvertJS.m: this module cannot see MPPromotion, MPCommerceEvent
/// or the rest, per docs/swift-migration/CONVERSION-RECIPE.md.
@objc(MPConvertJSFields)
public final class MPConvertJSFields: NSObject {
    /// Mirrors MPJSCommerceEventAction (MPConvertJS.h) on the way in and
    /// MPCommerceEventAction (MPCommerceEvent.h) on the way out. The two enums
    /// do not share an order, so this is a genuine remap rather than a cast.
    ///
    /// Returns nil for a value the bridge does not define — including its own
    /// `Unknown` (0) — so the caller keeps logging before falling back to
    /// AddToCart, exactly as the Objective-C switch's `default:` did.
    @objc(commerceEventActionForJSValue:)
    public static func commerceEventAction(forJSValue value: Any?) -> NSNumber? {
        // -intValue, so a string-encoded action behaves as it did in ObjC.
        guard let raw = MPJSONCoercion.integerValue(value) else {
            return nil
        }

        let action: Int? = switch raw {
        case 1: 0 // AddToCart
        case 2: 1 // RemoveFromCart
        case 3: 4 // Checkout
        case 4: 5 // CheckoutOptions
        case 5: 6 // Click
        case 6: 7 // ViewDetail
        case 7: 8 // Purchase
        case 8: 9 // Refund
        case 9: 2 // AddToWishList
        case 10: 3 // RemoveFromWishlist
        default: nil
        }

        return action.map { NSNumber(value: $0) }
    }

    @objc(promotionFieldsFromJSON:)
    public static func promotionFields(from json: [AnyHashable: Any]?) -> MPPromotionFieldsJS {
        MPPromotionFieldsJS(
            creative: string(json?["Creative"]),
            name: string(json?["Name"]),
            position: string(json?["Position"]),
            promotionId: string(json?["Id"])
        )
    }

    @objc(transactionAttributesFieldsFromJSON:)
    public static func transactionAttributesFields(
        from json: [AnyHashable: Any]?
    ) -> MPTransactionAttributesFieldsJS {
        MPTransactionAttributesFieldsJS(
            affiliation: string(json?["Affiliation"]),
            couponCode: string(json?["CouponCode"]),
            shipping: number(json?["ShippingAmount"]),
            tax: number(json?["TaxAmount"]),
            revenue: number(json?["TotalAmount"]),
            transactionId: string(json?["TransactionId"])
        )
    }

    /// `-isKindOfClass:[NSString class]`: a number or a null is dropped rather
    /// than coerced, which is what the ObjC guards did.
    private static func string(_ value: Any?) -> String? {
        value as? String
    }

    /// `-isKindOfClass:[NSNumber class]`. Note a Swift `Bool` bridges to
    /// NSNumber, matching ObjC, where `@YES` is an NSNumber too.
    private static func number(_ value: Any?) -> NSNumber? {
        value as? NSNumber
    }
}
