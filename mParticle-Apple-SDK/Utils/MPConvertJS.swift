//
//  MPConvertJS.swift
//  mParticle-Apple-SDK
//
//  Created by Brandon Stalnaker on 10/3/24.
//

import Foundation

@objc public enum MPJSCommerceEventAction: UInt, @unchecked Sendable {
    case unknown = 0
    case addToCart = 1
    case removeFromCart = 2
    case checkout = 3
    case checkoutOptions = 4
    case click = 5
    case viewDetail = 6
    case purchase = 7
    case refund = 8
    case addToWishList = 9
    case removeFromWishlist = 10
}

@objc final public class MPConvertJS_PRIVATE: NSObject {
    
    @objc public static func commerceEventAction(_ json: NSNumber) -> MPCommerceEventAction {
        switch json.uintValue {
        case MPJSCommerceEventAction.addToCart.rawValue:
            return .addToCart
        case MPJSCommerceEventAction.removeFromCart.rawValue:
            return .removeFromCart
        case MPJSCommerceEventAction.checkout.rawValue:
            return .checkout
        case MPJSCommerceEventAction.checkoutOptions.rawValue:
            return .checkoutOptions
        case MPJSCommerceEventAction.click.rawValue:
            return .click
        case MPJSCommerceEventAction.viewDetail.rawValue:
            return .viewDetail
        case MPJSCommerceEventAction.purchase.rawValue:
            return .purchase
        case MPJSCommerceEventAction.refund.rawValue:
            return .refund
        case MPJSCommerceEventAction.addToWishList.rawValue:
            return .addToWishList
        case MPJSCommerceEventAction.removeFromWishlist.rawValue:
            return .removeFromWishlist
        default:
            MPLog.error("Invalid commerce event action received from webview: %@", json)
            return .addToCart
        }
    }
    
    @objc public static func commerceEvent(_ json: [AnyHashable : Any]) -> MPCommerceEvent? {
        guard json["ProductAction"] == nil || json["ProductAction"] is [String: Any] else {
            MPLog.error("Unexpected commerce event data received from webview")
            return nil
        }
        
        let productAction = json["ProductAction"] as? [String: Any]
        let isProductAction = productAction?["ProductActionType"] != nil
        let isPromotion = json["PromotionAction"] != nil
        let isImpression = json["ProductImpressions"] != nil
        let isValid = isProductAction || isPromotion || isImpression
        
        if !isValid {
            MPLog.error("Invalid commerce event dictionary received from webview: %@", json)
            return nil
        }
        
        let commerceEvent: MPCommerceEvent
        if isProductAction {
            guard let productActionType = productAction?["ProductActionType"] as? NSNumber else {
                MPLog.error("Unexpected product action type received from webview")
                return nil
            }
            let action = Self.commerceEventAction(productActionType)
            commerceEvent = MPCommerceEvent(action: action)
        } else if isPromotion {
            let promotionContainer = Self.promotionContainer(json)
            commerceEvent = MPCommerceEvent(promotionContainer: promotionContainer)
        } else {
            commerceEvent = MPCommerceEvent(impressionName: nil, product: nil)
        }
        
        if let eventAttributes = json["EventAttributes"] as? [String : Any] {
            commerceEvent.customAttributes = eventAttributes
        }
        if let checkoutOptions = json["CheckoutOptions"] as? String {
            commerceEvent.checkoutOptions = checkoutOptions
        }
        if let productActionListName = json["productActionListName"] as? String {
            commerceEvent.productListName = productActionListName
        }
        if let productActionListSource = json["productActionListSource"] as? String {
            commerceEvent.productListSource = productActionListSource
        }
        if let currencyCode = json["CurrencyCode"] as? String {
            commerceEvent.currency = currencyCode
        }
        if let productAction = productAction {
            commerceEvent.transactionAttributes = Self.transactionAttributes(productAction)
        }
        if let checkoutStep = json["CheckoutStep"] as? NSNumber {
            commerceEvent.checkoutStep = checkoutStep.intValue
        }
        if let customFlags = json["CustomFlags"] as? [String : Any] {
            for key in customFlags.keys {
                if let valueArray = customFlags[key] as? [String] {
                    commerceEvent.addCustomFlags(valueArray, withKey: key)
                } else if let valueString = customFlags[key] as? String {
                    commerceEvent.addCustomFlag(valueString, withKey: key)
                }
            }
        }

        if let jsonProducts = productAction?["ProductList"] as? [[AnyHashable : Any]] {
            let products = jsonProducts.map { Self.product($0) }
            commerceEvent.addProducts(products)
        }

        if let jsonImpressions = json["ProductImpressions"] as? [[AnyHashable : Any]] {
            for jsonImpression in jsonImpressions {
                if let listName = jsonImpression["ProductImpressionList"] as? String,
                   let jsonProducts = jsonImpression["ProductList"] as? [[AnyHashable : Any]] {
                    for jsonObject in jsonProducts {
                        let product = MPConvertJS_PRIVATE.product(jsonObject)
                        commerceEvent.addImpression(product, listName: listName)
                    }
                }
            }
        }
        
        return commerceEvent
    }
    
    @objc public static func promotionContainer(_ json: [AnyHashable : Any]) -> MPPromotionContainer? {
        guard let promotionDictionary = (json["PromotionAction"] as? [String: Any]) else {
            MPLog.error("Unexpected promotion container action data received from webview")
            return nil
        }
        
        guard let promotionActionTypeNumber = (promotionDictionary["PromotionActionType"] as? NSNumber) else {
            MPLog.error("Unexpected promotion container action type data received from webview")
            return nil
        }
        
        let promotionAction = promotionActionTypeNumber.intValue == 1 ? MPPromotionAction.view : MPPromotionAction.click
        let promotionContainer = MPPromotionContainer(action: promotionAction, promotion: nil)
        if let jsonPromotions = promotionDictionary["PromotionList"] as? [[AnyHashable : Any]] {
            for jsonObject in jsonPromotions {
                promotionContainer.addPromotion(MPConvertJS_PRIVATE.promotion(jsonObject))
            }
        } else {
            MPLog.error("Unexpected promotion container list data received from webview")
            return nil
        }

        return promotionContainer;
    }
    
    @objc public static func promotion(_ json: [AnyHashable : Any]) -> MPPromotion {
        let promotion = MPPromotion()

        if let creative = json["Creative"] as? String {
            promotion.creative = creative
        }
        if let name = json["Name"] as? String {
            promotion.name = name
        }
        if let position = json["Position"] as? String {
            promotion.position = position
        }
        if let id = json["Id"] as? String {
            promotion.promotionId = id
        }
        
        return promotion;
    }
    
    @objc public static func transactionAttributes(_ json: [AnyHashable : Any] = [:]) -> MPTransactionAttributes! {
        let transactionAttributes = MPTransactionAttributes()
        
        if let affiliation = json["Affiliation"] as? String {
            transactionAttributes.affiliation = affiliation
        }
        if let couponCode = json["CouponCode"] as? String {
            transactionAttributes.couponCode = couponCode
        }
        if let shippingAmount = json["ShippingAmount"] as? NSNumber {
            transactionAttributes.shipping = shippingAmount
        }
        if let taxAmount = json["TaxAmount"] as? NSNumber {
            transactionAttributes.tax = taxAmount
        }
        if let totalAmount = json["TotalAmount"] as? NSNumber {
            transactionAttributes.revenue = totalAmount
        }
        if let transactionId = json["TransactionId"] as? String {
            transactionAttributes.transactionId = transactionId
        }
        
        return transactionAttributes;
    }
    
    @objc public static func product(_ json: [AnyHashable : Any]) -> MPProduct {
        let product = MPProduct()
        
        if let brand = json["Brand"] as? String {
            product.brand = brand
        }
        if let category = json["Category"] as? String {
            product.category = category
        }
        if let couponCode = json["CouponCode"] as? String {
            product.couponCode = couponCode
        }
        if let name = json["Name"] as? String {
            product.name = name
        }
        if let price = json["Price"] as? NSNumber {
            product.price = price
        } else if let price = json["Price"] as? String, let double = double_t(price) {
            product.price = NSNumber(value: double)
        }
        if let sku = json["Sku"] as? String {
            product.sku = sku
        }
        if let variant = json["Variant"] as? String {
            product.variant = variant
        }
        if let position = json["Position"] as? NSNumber {
            product.position = position.uintValue
        }
        if let quantity = json["Quantity"] as? NSNumber {
            product.quantity = quantity
        }
        if let jsonAttributes = json["Attributes"] as? [String : String] {
            for (key, value) in jsonAttributes {
                product.setValue(value, forKey: key)
            }
        }

        return product;
    }
    
    @objc private static func identityFromNumber(_ identityTypeNumber: NSNumber) -> MPIdentity {
        return MPIdentity(rawValue: identityTypeNumber.uintValue) ?? .other
    }
    
    @objc public static func identityApiRequest(_ json: [AnyHashable : Any]?) -> MPIdentityApiRequest? {
        let request = MPIdentityApiRequest.withEmptyUser()
        
        guard let userIdentities = json?["UserIdentities"] as? [[AnyHashable : Any]] else {
            MPLog.error("Unexpected user identity data received from webview")
            return nil
        }
        
        for identityDictionary in userIdentities {
            if let identity = identityDictionary["Identity"] as? String,
               let identityTypeNumber = identityDictionary["Type"] as? NSNumber,
               let identityType = MPIdentity(rawValue: identityTypeNumber.uintValue) {
                request.setIdentity(identity, identityType: identityType)
            } else {
                return nil
            }
        }

        if let identity = json?["Identity"] as? String,
           let identityTypeNumber = json?["Type"] as? NSNumber,
           let identityType = MPIdentity(rawValue: identityTypeNumber.uintValue) {
            request.setIdentity(identity, identityType: identityType)
        }
        
        return request
    }
}
