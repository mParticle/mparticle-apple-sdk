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

/// Why a promotion container payload could not be read. Each case maps to a
/// distinct MPILogError the caller still emits.
@objc public enum MPPromotionContainerOutcomeJS: Int {
    case ok = 0
    case missingAction = 1
    case missingActionType = 2
    case missingList = 3
}

@objc(MPPromotionContainerFieldsJS)
public final class MPPromotionContainerFieldsJS: NSObject {
    @objc public let outcome: MPPromotionContainerOutcomeJS
    /// The ObjC ternary was `== 1 ? View : Click`, so every other value — including
    /// a negative one — is Click.
    @objc public let isViewAction: Bool
    /// Only the dictionary entries of PromotionList.
    @objc public let promotions: [[AnyHashable: Any]]

    init(
        outcome: MPPromotionContainerOutcomeJS,
        isViewAction: Bool,
        promotions: [[AnyHashable: Any]]
    ) {
        self.outcome = outcome
        self.isViewAction = isViewAction
        self.promotions = promotions
        super.init()
    }
}

/// Why a commerce event payload could not be read.
@objc public enum MPCommerceEventOutcomeJS: Int {
    case ok = 0
    case malformedProductAction = 1
    case invalidPayload = 2
    case malformedProductActionType = 3
}

/// Which initialiser the caller should use.
@objc public enum MPCommerceEventKindJS: Int {
    case none = 0
    case productAction = 1
    case promotion = 2
    case impression = 3
}

@objc(MPCommerceFlagJS)
public final class MPCommerceFlagJS: NSObject {
    @objc public let key: String
    @objc public let values: [String]

    init(key: String, values: [String]) {
        self.key = key
        self.values = values
        super.init()
    }
}

@objc(MPCommerceImpressionJS)
public final class MPCommerceImpressionJS: NSObject {
    @objc public let listName: String
    @objc public let products: [[AnyHashable: Any]]

    init(listName: String, products: [[AnyHashable: Any]]) {
        self.listName = listName
        self.products = products
        super.init()
    }
}

@objc(MPCommerceEventFieldsJS)
public final class MPCommerceEventFieldsJS: NSObject {
    @objc public let outcome: MPCommerceEventOutcomeJS
    @objc public let kind: MPCommerceEventKindJS
    /// The raw ProductActionType, still to go through commerceEventActionForJSValue:.
    @objc public let productActionType: NSNumber?
    /// Present whenever ProductAction was a dictionary, which is what gated
    /// reading transaction attributes off it.
    @objc public let productAction: [AnyHashable: Any]?
    @objc public let customAttributes: [AnyHashable: Any]?
    @objc public let checkoutOptions: String?
    @objc public let productListName: String?
    @objc public let productListSource: String?
    @objc public let currency: String?
    @objc public let checkoutStep: NSNumber?
    @objc public let customFlags: [MPCommerceFlagJS]
    @objc public let products: [[AnyHashable: Any]]
    @objc public let impressions: [MPCommerceImpressionJS]

    // swiftlint:disable:next function_parameter_count
    init(
        outcome: MPCommerceEventOutcomeJS,
        kind: MPCommerceEventKindJS,
        productActionType: NSNumber?,
        productAction: [AnyHashable: Any]?,
        customAttributes: [AnyHashable: Any]?,
        checkoutOptions: String?,
        productListName: String?,
        productListSource: String?,
        currency: String?,
        checkoutStep: NSNumber?,
        customFlags: [MPCommerceFlagJS],
        products: [[AnyHashable: Any]],
        impressions: [MPCommerceImpressionJS]
    ) {
        self.outcome = outcome
        self.kind = kind
        self.productActionType = productActionType
        self.productAction = productAction
        self.customAttributes = customAttributes
        self.checkoutOptions = checkoutOptions
        self.productListName = productListName
        self.productListSource = productListSource
        self.currency = currency
        self.checkoutStep = checkoutStep
        self.customFlags = customFlags
        self.products = products
        self.impressions = impressions
        super.init()
    }

    static func failed(_ outcome: MPCommerceEventOutcomeJS) -> MPCommerceEventFieldsJS {
        MPCommerceEventFieldsJS(
            outcome: outcome, kind: .none, productActionType: nil, productAction: nil,
            customAttributes: nil, checkoutOptions: nil, productListName: nil,
            productListSource: nil, currency: nil, checkoutStep: nil,
            customFlags: [], products: [], impressions: []
        )
    }
}

public extension MPConvertJSFields {
    @objc(promotionContainerFieldsFromJSON:)
    static func promotionContainerFields(from json: [AnyHashable: Any]?) -> MPPromotionContainerFieldsJS {
        guard let action = json?["PromotionAction"] as? [AnyHashable: Any] else {
            return MPPromotionContainerFieldsJS(outcome: .missingAction, isViewAction: false, promotions: [])
        }
        guard let type = action["PromotionActionType"] as? NSNumber else {
            return MPPromotionContainerFieldsJS(outcome: .missingActionType, isViewAction: false, promotions: [])
        }
        // -intValue, then `== 1 ? View : Click`.
        let isViewAction = type.intValue == 1
        guard let list = action["PromotionList"] as? [Any] else {
            return MPPromotionContainerFieldsJS(outcome: .missingList, isViewAction: isViewAction, promotions: [])
        }

        return MPPromotionContainerFieldsJS(
            outcome: .ok,
            isViewAction: isViewAction,
            promotions: dictionaries(in: list)
        )
    }

    @objc(commerceEventFieldsFromJSON:)
    static func commerceEventFields(from json: [AnyHashable: Any]?) -> MPCommerceEventFieldsJS {
        let rawProductAction = json?["ProductAction"]
        if rawProductAction != nil, !(rawProductAction is [AnyHashable: Any]) {
            return .failed(.malformedProductAction)
        }
        let productAction = rawProductAction as? [AnyHashable: Any]

        // Each of these was a bare nil check, so an explicit null still counts as
        // present, exactly as before.
        let isProductAction = productAction?["ProductActionType"] != nil
        let isPromotion = json?["PromotionAction"] != nil
        let isImpression = json?["ProductImpressions"] != nil

        guard isProductAction || isPromotion || isImpression else {
            return .failed(.invalidPayload)
        }

        var productActionType: NSNumber?
        if isProductAction {
            guard let type = productAction?["ProductActionType"] as? NSNumber else {
                return .failed(.malformedProductActionType)
            }
            productActionType = type
        }

        // The ObjC chain was if/else-if/else, so a payload that is both a product
        // action and a promotion is a product action.
        let kind: MPCommerceEventKindJS = if isProductAction {
            .productAction
        } else if isPromotion {
            .promotion
        } else {
            .impression
        }

        return MPCommerceEventFieldsJS(
            outcome: .ok,
            kind: kind,
            productActionType: productActionType,
            productAction: productAction,
            customAttributes: json?["EventAttributes"] as? [AnyHashable: Any],
            checkoutOptions: json?["CheckoutOptions"] as? String,
            productListName: json?["productActionListName"] as? String,
            productListSource: json?["productActionListSource"] as? String,
            currency: json?["CurrencyCode"] as? String,
            checkoutStep: json?["CheckoutStep"] as? NSNumber,
            customFlags: commerceFlags(json?["CustomFlags"]),
            products: dictionaries(in: productAction?["ProductList"] as? [Any] ?? []),
            impressions: impressions(json?["ProductImpressions"])
        )
    }

    /// A string value becomes a single-element array: -addCustomFlag:withKey:
    /// forwards to -addCustomFlags:@[flag]:withKey: (MPBaseEvent.m:100), and its
    /// only extra behaviour is a nil check the isKindOfClass: guard already made
    /// unreachable. An array is kept only when every element is a string.
    private static func commerceFlags(_ value: Any?) -> [MPCommerceFlagJS] {
        guard let dictionary = value as? [AnyHashable: Any] else {
            return []
        }

        return dictionary.compactMap { element in
            guard let key = element.key as? String else {
                return nil
            }
            if let single = element.value as? String {
                return MPCommerceFlagJS(key: key, values: [single])
            }
            guard let array = element.value as? [Any] else {
                return nil
            }
            let strings = array.compactMap { $0 as? String }
            guard strings.count == array.count else {
                return nil
            }
            return MPCommerceFlagJS(key: key, values: strings)
        }
    }

    /// An impression needs both a string list name and an array of products;
    /// anything else was skipped rather than partially applied.
    private static func impressions(_ value: Any?) -> [MPCommerceImpressionJS] {
        guard let list = value as? [Any] else {
            return []
        }

        return dictionaries(in: list).compactMap { entry in
            guard let listName = entry["ProductImpressionList"] as? String,
                  let products = entry["ProductList"] as? [Any]
            else {
                return nil
            }
            return MPCommerceImpressionJS(listName: listName, products: dictionaries(in: products))
        }
    }

    private static func dictionaries(in list: [Any]) -> [[AnyHashable: Any]] {
        list.compactMap { $0 as? [AnyHashable: Any] }
    }
}
