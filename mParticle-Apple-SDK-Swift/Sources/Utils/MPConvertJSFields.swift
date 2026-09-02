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

/// The values the webview bridge sends for one product. Every field is optional
/// so the caller can keep the Objective-C guards: `name`, `sku` and `quantity`
/// are `nonnull` on MPProduct, and `position` is a scalar, so "absent" and
/// "nil" are not interchangeable the way they are for a promotion.
@objc(MPProductFieldsJS)
public final class MPProductFieldsJS: NSObject {
    @objc public let brand: String?
    @objc public let category: String?
    @objc public let couponCode: String?
    @objc public let name: String?
    @objc public let price: NSNumber?
    @objc public let sku: String?
    @objc public let variant: String?
    @objc public let position: NSNumber?
    @objc public let quantity: NSNumber?
    /// Already filtered to the string-key/string-value pairs the ObjC accepted.
    @objc public let attributes: [String: String]

    init(
        brand: String?,
        category: String?,
        couponCode: String?,
        name: String?,
        price: NSNumber?,
        sku: String?,
        variant: String?,
        position: NSNumber?,
        quantity: NSNumber?,
        attributes: [String: String]
    ) {
        self.brand = brand
        self.category = category
        self.couponCode = couponCode
        self.name = name
        self.price = price
        self.sku = sku
        self.variant = variant
        self.position = position
        self.quantity = quantity
        self.attributes = attributes
        super.init()
    }
}

/// One `Identity`/`Type` pair from the webview bridge.
@objc(MPWebviewIdentityPairJS)
public final class MPWebviewIdentityPairJS: NSObject {
    @objc public let identity: String
    @objc public let identityType: UInt

    init(identity: String, identityType: UInt) {
        self.identity = identity
        self.identityType = identityType
        super.init()
    }
}

/// Why an identity payload could not be read. The two failures are not
/// interchangeable: a missing `UserIdentities` array logged before returning
/// nil, while a malformed entry returned nil silently.
@objc public enum MPWebviewIdentityOutcomeJS: Int {
    case ok = 0
    case missingUserIdentities = 1
    case malformedEntry = 2
}

@objc(MPWebviewIdentityRequestJS)
public final class MPWebviewIdentityRequestJS: NSObject {
    @objc public let outcome: MPWebviewIdentityOutcomeJS
    /// In application order: the `UserIdentities` entries, then the top-level
    /// pair when present, so a duplicated type keeps its last-write-wins result.
    @objc public let pairs: [MPWebviewIdentityPairJS]

    init(outcome: MPWebviewIdentityOutcomeJS, pairs: [MPWebviewIdentityPairJS]) {
        self.outcome = outcome
        self.pairs = pairs
        super.init()
    }
}

public extension MPConvertJSFields {
    @objc(productFieldsFromJSON:)
    static func productFields(from json: [AnyHashable: Any]?) -> MPProductFieldsJS {
        MPProductFieldsJS(
            brand: json?["Brand"] as? String,
            category: json?["Category"] as? String,
            couponCode: json?["CouponCode"] as? String,
            name: json?["Name"] as? String,
            price: price(json?["Price"]),
            sku: json?["Sku"] as? String,
            variant: json?["Variant"] as? String,
            position: json?["Position"] as? NSNumber,
            quantity: json?["Quantity"] as? NSNumber,
            attributes: stringAttributes(json?["Attributes"])
        )
    }

    /// An NSNumber passes through; a string goes through `-doubleValue`, which
    /// yields 0 for text that is not a number — the ObjC did exactly that, so a
    /// `"Price": "abc"` still produces 0 rather than being dropped.
    private static func price(_ value: Any?) -> NSNumber? {
        switch value {
        case let number as NSNumber: number
        case let string as String: NSNumber(value: (string as NSString).doubleValue)
        default: nil
        }
    }

    /// Both the key and the value had to be strings; anything else was skipped.
    private static func stringAttributes(_ value: Any?) -> [String: String] {
        guard let dictionary = value as? [AnyHashable: Any] else {
            return [:]
        }

        return dictionary.reduce(into: [String: String]()) { result, element in
            if let key = element.key as? String, let value = element.value as? String {
                result[key] = value
            }
        }
    }

    @objc(identityRequestFromJSON:)
    static func identityRequest(from json: [AnyHashable: Any]?) -> MPWebviewIdentityRequestJS {
        guard let userIdentities = json?["UserIdentities"] as? [Any] else {
            return MPWebviewIdentityRequestJS(outcome: .missingUserIdentities, pairs: [])
        }

        var pairs: [MPWebviewIdentityPairJS] = []
        for entry in userIdentities {
            let dictionary = entry as? [AnyHashable: Any]
            guard let identity = dictionary?["Identity"] as? String,
                  let type = dictionary?["Type"] as? NSNumber
            else {
                // One bad entry abandoned the whole request, without logging.
                return MPWebviewIdentityRequestJS(outcome: .malformedEntry, pairs: [])
            }
            pairs.append(MPWebviewIdentityPairJS(identity: identity, identityType: type.uintValue))
        }

        // Applied last, so it overwrites a type the array already set.
        if let identity = json?["Identity"] as? String, let type = json?["Type"] as? NSNumber {
            pairs.append(MPWebviewIdentityPairJS(identity: identity, identityType: type.uintValue))
        }

        return MPWebviewIdentityRequestJS(outcome: .ok, pairs: pairs)
    }
}
