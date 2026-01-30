#import "MPConvertJS.h"
#import "MPCommerceEvent.h"
#import "MPCommerceEvent+Dictionary.h"
#import "MPProduct.h"
#import "MPPromotion.h"
#import "MPTransactionAttributes.h"
#import "mParticle.h"
#import "MPILogger.h"
#import "MPIdentityApiRequest.h"

@implementation MPConvertJS_PRIVATE

+ (MPCommerceEventAction)commerceEventAction:(NSNumber *)json {
    MPCommerceEventAction action;
    
    int actionInt = [json intValue];
    switch (actionInt) {
        case MPJSCommerceEventActionAddToCart:
            return MPCommerceEventActionAddToCart;
        case MPJSCommerceEventActionRemoveFromCart:
            return MPCommerceEventActionRemoveFromCart;
        case MPJSCommerceEventActionCheckout:
            return MPCommerceEventActionCheckout;
        case MPJSCommerceEventActionCheckoutOptions:
            return MPCommerceEventActionCheckoutOptions;
        case MPJSCommerceEventActionClick:
            return MPCommerceEventActionClick;
        case MPJSCommerceEventActionViewDetail:
            return MPCommerceEventActionViewDetail;
        case MPJSCommerceEventActionPurchase:
            return MPCommerceEventActionPurchase;
        case MPJSCommerceEventActionRefund:
            return MPCommerceEventActionRefund;
        case MPJSCommerceEventActionAddToWishList:
            return MPCommerceEventActionAddToWishList;
        case MPJSCommerceEventActionRemoveFromWishlist:
            return MPCommerceEventActionRemoveFromWishlist;
        default:
            MPILogError(@"Invalid commerce event action received from webview: %@", json);
            return MPCommerceEventActionAddToCart;
    }
}

+ (MPCommerceEvent *)commerceEvent:(NSDictionary *)json {
    if (!json || ![json isKindOfClass:[NSDictionary class]]) {
        MPILogError(@"Unexpected commerce event data received from webview");
        return nil;
    }
    if (json[@"ProductAction"] != nil && ![json[@"ProductAction"] isKindOfClass:[NSDictionary class]]) {
        MPILogError(@"Unexpected commerce event data received from webview");
        return nil;
    }
    
    NSDictionary *productAction = json[@"ProductAction"];
    BOOL isProductAction = productAction[@"ProductActionType"] != nil;
    BOOL isPromotion = json[@"PromotionAction"] != nil;
    BOOL isImpression = json[@"ProductImpressions"] != nil;
    BOOL isValid = isProductAction || isPromotion || isImpression;

    if (!isValid) {
        MPILogError(@"Invalid commerce event dictionary received from webview: %@", json);
        return nil;
    }

    MPCommerceEvent *commerceEvent = nil;
    if (isProductAction) {
        id productActionType = productAction[@"ProductActionType"];
        if (!productActionType || ![productActionType isKindOfClass:[NSNumber class]]) {
            MPILogError(@"Unexpected product action type received from webview");
            return nil;
        }
        MPCommerceEventAction action = [MPConvertJS_PRIVATE commerceEventAction:productActionType];
        commerceEvent = [[MPCommerceEvent alloc] initWithAction:action];
    }
    else if (isPromotion) {
        MPPromotionContainer *promotionContainer = [MPConvertJS_PRIVATE promotionContainer:json];
        commerceEvent = [[MPCommerceEvent alloc] initWithPromotionContainer:promotionContainer];
    }
    else {
        commerceEvent = [[MPCommerceEvent alloc] initWithImpressionName:nil product:nil];
    }

    if ((NSNull *)json[@"EventAttributes"] != [NSNull null]) {
        commerceEvent.customAttributes = json[@"EventAttributes"];
    }
    if ((NSNull *)json[@"CheckoutOptions"] != [NSNull null]) {
        commerceEvent.checkoutOptions = json[@"CheckoutOptions"];
    }
    if ((NSNull *)json[@"productActionListName"] != [NSNull null]) {
        commerceEvent.productListName = json[@"productActionListName"];
    }
    if ((NSNull *)json[@"productActionListSource"] != [NSNull null]) {
        commerceEvent.productListSource = json[@"productActionListSource"];
    }
    if ((NSNull *)json[@"CurrencyCode"] != [NSNull null]) {
        commerceEvent.currency = json[@"CurrencyCode"];
    }
    if ((NSNull *)productAction != [NSNull null]) {
        commerceEvent.transactionAttributes = [MPConvertJS_PRIVATE transactionAttributes:productAction];
    }
    if ([json[@"CheckoutStep"] isKindOfClass:[NSNumber class]]) {
        commerceEvent.checkoutStep = [json[@"CheckoutStep"] intValue];
    }
    if ((NSNull *)json[@"CustomFlags"] != [NSNull null]) {
        NSDictionary *customFlags = json[@"CustomFlags"];
        for (NSString *key in customFlags.allKeys) {
            id value = customFlags[key];
            if ([value isKindOfClass:[NSArray class]]) {
                [commerceEvent addCustomFlags:(NSArray *)value withKey:key];
            } else if ([value isKindOfClass:[NSString class]]) {
                [commerceEvent addCustomFlag:(NSString *)value withKey:key];
            }
        }
    }

    NSArray *jsonProducts = productAction[@"ProductList"];
    if ((NSNull *)jsonProducts != [NSNull null] && [jsonProducts isKindOfClass:[NSArray class]]) {
        NSMutableArray *products = [NSMutableArray array];
        [jsonProducts enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            MPProduct *product = [MPConvertJS_PRIVATE product:obj];
            [products addObject:product];
        }];
        [commerceEvent addProducts:products];
    }

    NSArray *jsonImpressions = json[@"ProductImpressions"];
    if ((NSNull *)jsonImpressions != [NSNull null] && [jsonImpressions isKindOfClass:[NSArray class]]) {
        [jsonImpressions enumerateObjectsUsingBlock:^(NSDictionary *jsonImpression, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *listName = jsonImpression[@"ProductImpressionList"];
            NSArray *jsonProducts = jsonImpression[@"ProductList"];
            if ((NSNull *)jsonProducts != [NSNull null] && [jsonProducts isKindOfClass:[NSArray class]]) {
                [jsonProducts enumerateObjectsUsingBlock:^(id  _Nonnull jsonProduct, NSUInteger idx, BOOL * _Nonnull stop) {
                    MPProduct *product = [MPConvertJS_PRIVATE product:jsonProduct];
                    [commerceEvent addImpression:product listName:listName];
                }];
            }
        }];
    }

    return commerceEvent;
}

+ (MPPromotionContainer *)promotionContainer:(NSDictionary *)json {
    if (!json || ![json isKindOfClass:[NSDictionary class]]) {
        MPILogError(@"Unexpected promotion container data received from webview");
        return nil;
    }
    
    NSDictionary *promotionActionDictionary = json[@"PromotionAction"];
    if (!promotionActionDictionary || ![promotionActionDictionary isKindOfClass:[NSDictionary class]]) {
        MPILogError(@"Unexpected promotion container action data received from webview");
        return nil;
    }
    
    NSNumber *promotionActionTypeNumber = promotionActionDictionary[@"PromotionActionType"];
    if (promotionActionTypeNumber == nil || ![promotionActionTypeNumber isKindOfClass:[NSNumber class]]) {
        MPILogError(@"Unexpected promotion container action type data received from webview");
        return nil;
    }
    
    int promotionActionInt = [promotionActionTypeNumber intValue];
    MPPromotionAction promotionAction = promotionActionInt == 1 ? MPPromotionActionView : MPPromotionActionClick;
    MPPromotionContainer *promotionContainer = [[MPPromotionContainer alloc] initWithAction:promotionAction promotion:nil];
    
    NSArray *jsonPromotions = promotionActionDictionary[@"PromotionList"];
    if (!jsonPromotions || ![jsonPromotions isKindOfClass:[NSArray class]]) {
        MPILogError(@"Unexpected promotion container list data received from webview");
        return nil;
    }
    
    [jsonPromotions enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        MPPromotion *promotion = [MPConvertJS_PRIVATE promotion:obj];
        [promotionContainer addPromotion:promotion];
    }];

    return promotionContainer;
}

+ (MPPromotion *)promotion:(NSDictionary *)json {
    if (!json || ![json isKindOfClass:[NSDictionary class]]) {
        MPILogError(@"Unexpected promotion data received from webview");
        return nil;
    }
    MPPromotion *promotion = [[MPPromotion alloc] init];
    
    if ((NSNull *)json[@"Creative"] != [NSNull null]) {
        promotion.creative = json[@"Creative"];
    }
    
    if ((NSNull *)json[@"Name"] != [NSNull null]) {
        promotion.name = json[@"Name"];
    }
    
    if ((NSNull *)json[@"Position"] != [NSNull null]) {
        promotion.position = json[@"Position"];
    }
    
    if ((NSNull *)json[@"Id"] != [NSNull null]) {
        promotion.promotionId = json[@"Id"];
    }
    
    return promotion;
}

+ (MPTransactionAttributes *)transactionAttributes:(NSDictionary *)json {
    if (!json || ![json isKindOfClass:[NSDictionary class]]) {
        json = @{};
    }
    MPTransactionAttributes *transactionAttributes = [[MPTransactionAttributes alloc] init];
    
    if ((NSNull *)json[@"Affiliation"] != [NSNull null]) {
        transactionAttributes.affiliation = json[@"Affiliation"];
    }
    if ((NSNull *)json[@"CouponCode"] != [NSNull null]) {
        transactionAttributes.couponCode = json[@"CouponCode"];
    }
    if ((NSNull *)json[@"ShippingAmount"] != [NSNull null]) {
        transactionAttributes.shipping = json[@"ShippingAmount"];
    }
    if ((NSNull *)json[@"TaxAmount"] != [NSNull null]) {
        transactionAttributes.tax = json[@"TaxAmount"];
    }
    if ((NSNull *)json[@"TotalAmount"] != [NSNull null]) {
        transactionAttributes.revenue = json[@"TotalAmount"];
    }
    if ((NSNull *)json[@"TransactionId"] != [NSNull null]) {
        transactionAttributes.transactionId = json[@"TransactionId"];
    }
    
    return transactionAttributes;
}

+ (MPProduct *)product:(NSDictionary *)json {
    if (!json || ![json isKindOfClass:[NSDictionary class]]) {
        MPILogError(@"Unexpected product data received from webview");
        return nil;
    }
    MPProduct *product = [[MPProduct alloc] init];
    
    if ((NSNull *)json[@"Brand"] != [NSNull null]) {
        product.brand = json[@"Brand"];
    }
    if ((NSNull *)json[@"Category"] != [NSNull null]) {
        product.category = json[@"Category"];
    }
    if ((NSNull *)json[@"CouponCode"] != [NSNull null]) {
        product.couponCode = json[@"CouponCode"];
    }
    if ((NSNull *)json[@"Name"] != [NSNull null]) {
        product.name = json[@"Name"];
    }
    
    // Handle price as NSNumber or String
    if (!json[@"Price"] || [json[@"Price"] isKindOfClass:[NSNumber class]]) {
        product.price = json[@"Price"];
    } else if ([json[@"Price"] isKindOfClass:[NSString class]]) {
        product.price = [NSNumber numberWithDouble:[(NSString *)json[@"Price"] doubleValue]];
    }
    
    if ((NSNull *)json[@"Sku"] != [NSNull null]) {
        product.sku = json[@"Sku"];
    }
    if ((NSNull *)json[@"Variant"] != [NSNull null]) {
        product.variant = json[@"Variant"];
    }
    if ((NSNull *)json[@"Position"] != [NSNull null]) {
        product.position = [json[@"Position"] unsignedIntValue];
    }
    if (!json[@"Quantity"] || [json[@"Quantity"] isKindOfClass:[NSNumber class]]) {
        product.quantity = json[@"Quantity"];
    }

    NSDictionary *jsonAttributes = json[@"Attributes"];
    if ((NSNull *)jsonAttributes != [NSNull null] && [jsonAttributes isKindOfClass:[NSDictionary class]]) {
        for (NSString *key in jsonAttributes) {
            NSString *value = jsonAttributes[key];
            if ((NSNull *)value != [NSNull null]) {
                [product setObject:value forKeyedSubscript:key];
            }
        }
    }
    return product;
}

+ (MPIdentityApiRequest *)identityApiRequest:(NSDictionary *)json {
    MPIdentityApiRequest *request = [MPIdentityApiRequest requestWithEmptyUser];
    
    if (!json || ![json isKindOfClass:[NSDictionary class]]) {
        MPILogError(@"Unexpected identity api request data received from webview");
        return nil;
    }
    
    NSArray *userIdentities = json[@"UserIdentities"];
    if (!userIdentities || ![userIdentities isKindOfClass:[NSArray class]]) {
        MPILogError(@"Unexpected user identity data received from webview");
        return nil;
    }
    
    if (userIdentities.count > 0) {
        __block BOOL allSuccess = YES;
        
        [userIdentities enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull identityDictionary, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *identity = identityDictionary[@"Identity"];
            NSNumber *identityTypeNumber = identityDictionary[@"Type"];
            
            if (!identity || ![identity isKindOfClass:[NSString class]]) {
                allSuccess = NO;
                *stop = YES;
                return;
            }
            
            if (!identityTypeNumber || ![identityTypeNumber isKindOfClass:[NSNumber class]]) {
                allSuccess = NO;
                *stop = YES;
                return;
            }
            
            MPIdentity identityType = (MPIdentity)[identityTypeNumber unsignedIntegerValue];
            [request setIdentity:identity identityType:identityType];
        }];
        
        if (!allSuccess) {
            return nil;
        }
    }
    
    NSString *identity = json[@"Identity"];
    NSNumber *identityTypeNumber = json[@"Type"];
    
    if (identity && [identity isKindOfClass:[NSString class]] && 
        identityTypeNumber && [identityTypeNumber isKindOfClass:[NSNumber class]]) {
        MPIdentity identityType = (MPIdentity)[identityTypeNumber unsignedIntegerValue];
        [request setIdentity:identity identityType:identityType];
    }
    
    return request;
}

@end
