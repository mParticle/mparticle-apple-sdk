#import "MPConvertJS.h"
#import "MPCommerceEvent.h"
#import "MPCommerceEvent+Dictionary.h"
#import "MPProduct.h"
#import "MPPromotion.h"
#import "MPTransactionAttributes.h"
#import "mParticle.h"
#import "MPILogger.h"

typedef NS_ENUM(NSUInteger, MPJSIdentityType) {
    MPJSIdentityTypeOther = 0,
    MPJSIdentityTypeCustomerId,
    MPJSIdentityTypeFacebook,
    MPJSIdentityTypeTwitter,
    MPJSIdentityTypeGoogle,
    MPJSIdentityTypeMicrosoft,
    MPJSIdentityTypeYahoo,
    MPJSIdentityTypeEmail,
    MPJSIdentityTypeAlias,
    MPJSIdentityTypeFacebookCustomAudienceId,
    MPJSIdentityTypeOther2,
    MPJSIdentityTypeOther3,
    MPJSIdentityTypeOther4
};

@implementation MPConvertJS

+ (MPCommerceEventAction)MPCommerceEventAction:(NSNumber *)json {
    MPCommerceEventAction action;
    
    int actionInt = [json intValue];
    switch (actionInt) {
        case MPJSCommerceEventActionAddToCart:
            action = MPCommerceEventActionAddToCart;
            break;

        case MPJSCommerceEventActionRemoveFromCart:
            action = MPCommerceEventActionRemoveFromCart;
            break;

        case MPJSCommerceEventActionCheckout:
            action = MPCommerceEventActionCheckout;
            break;

        case MPJSCommerceEventActionCheckoutOptions:
            action = MPCommerceEventActionCheckoutOptions;
            break;

        case MPJSCommerceEventActionClick:
            action = MPCommerceEventActionClick;
            break;

        case MPJSCommerceEventActionViewDetail:
            action = MPCommerceEventActionViewDetail;
            break;

        case MPJSCommerceEventActionPurchase:
            action = MPCommerceEventActionPurchase;
            break;

        case MPJSCommerceEventActionRefund:
            action = MPCommerceEventActionRefund;
            break;

        case MPJSCommerceEventActionAddToWishList:
            action = MPCommerceEventActionAddToWishList;
            break;

        case MPJSCommerceEventActionRemoveFromWishlist:
            action = MPCommerceEventActionRemoveFromWishlist;
            break;

        default:
            action = MPCommerceEventActionAddToCart;
            MPILogError(@"Invalid commerce event action received from webview: %@", @(action));
            break;
    }
    return action;
}

+ (MPCommerceEvent *)MPCommerceEvent:(NSDictionary *)json {
    if (!json || ![json isKindOfClass:[NSDictionary class]]) {
        MPILogError(@"Unexpected commerce event data received from webview");
        return nil;
    }
    if (json[@"ProductAction"] != nil && ![json[@"ProductAction"] isKindOfClass:[NSDictionary class]]) {
        MPILogError(@"Unexpected commerce product action data received from webview");
        return nil;
    }
    BOOL isProductAction = json[@"ProductAction"][@"ProductActionType"] != nil;
    BOOL isPromotion = json[@"PromotionAction"] != nil;
    BOOL isImpression = json[@"ProductImpressions"] != nil;
    BOOL isValid = isProductAction || isPromotion || isImpression;

    MPCommerceEvent *commerceEvent = nil;
    if (!isValid) {
        MPILogError(@"Invalid commerce event dictionary received from webview: %@", json);
        return commerceEvent;
    }

    if (isProductAction) {
        id productActionJson = json[@"ProductAction"][@"ProductActionType"];
        if (!productActionJson || ![productActionJson isKindOfClass:[NSNumber class]]) {
            MPILogError(@"Unexpected product action type received from webview");
            return nil;
        }
        MPCommerceEventAction action = [MPConvertJS MPCommerceEventAction:productActionJson];
        commerceEvent = [[MPCommerceEvent alloc] initWithAction:action];
    }
    else if (isPromotion) {
        MPPromotionContainer *promotionContainer = [MPConvertJS MPPromotionContainer:json];
        commerceEvent = [[MPCommerceEvent alloc] initWithPromotionContainer:promotionContainer];
    }
    else {
        commerceEvent = [[MPCommerceEvent alloc] initWithImpressionName:nil product:nil];
    }

    commerceEvent.customAttributes = json[@"EventAttributes"];
    commerceEvent.checkoutOptions = json[@"CheckoutOptions"];
    commerceEvent.productListName = json[@"productActionListName"];
    commerceEvent.productListSource = json[@"productActionListSource"];
    commerceEvent.currency = json[@"CurrencyCode"];
    commerceEvent.transactionAttributes = [MPConvertJS MPTransactionAttributes:json[@"ProductAction"]];
    commerceEvent.checkoutStep = [json[@"CheckoutStep"] intValue];

    NSMutableArray *products = [NSMutableArray array];
    NSArray *jsonProducts = json[@"ProductAction"][@"ProductList"];
    if ((NSNull *)jsonProducts != [NSNull null]) {
        [jsonProducts enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            MPProduct *product = [MPConvertJS MPProduct:obj];
            [products addObject:product];
        }];
    }
    [commerceEvent addProducts:products];

    NSArray *jsonImpressions = json[@"ProductImpressions"];
    if ((NSNull *)jsonImpressions != [NSNull null]) {
        [jsonImpressions enumerateObjectsUsingBlock:^(NSDictionary *jsonImpression, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *listName = jsonImpression[@"ProductImpressionList"];
            NSArray *jsonProducts = jsonImpression[@"ProductList"];
            if ((NSNull *)jsonProducts != [NSNull null]) {
                [jsonProducts enumerateObjectsUsingBlock:^(id  _Nonnull jsonProduct, NSUInteger idx, BOOL * _Nonnull stop) {
                    MPProduct *product = [MPConvertJS MPProduct:jsonProduct];
                    [commerceEvent addImpression:product listName:listName];
                }];
            }
        }];
    }

    return commerceEvent;
}

+ (MPPromotionContainer *)MPPromotionContainer:(NSDictionary *)json {
    if (!json || ![json isKindOfClass:[NSDictionary class]]) {
        MPILogError(@"Unexpected promotion container data received from webview");
        return nil;
    }
    NSDictionary *promotionActionDictionary = json[@"PromotionAction"];
    if (!promotionActionDictionary || ![promotionActionDictionary isKindOfClass:[NSDictionary class]]) {
        MPILogError(@"Unexpected promotion container action data received from webview");
        return nil;
    }
    NSNumber *promotionActionTypeNumber = json[@"PromotionAction"][@"PromotionActionType"];
    if (promotionActionTypeNumber == nil || ![promotionActionTypeNumber isKindOfClass:[NSNumber class]]) {
        MPILogError(@"Unexpected promotion container action type data received from webview");
        return nil;
    }
    int promotionActionInt = [promotionActionTypeNumber intValue];
    MPPromotionAction promotionAction = promotionActionInt == 1 ? MPPromotionActionView : MPPromotionActionClick;
    MPPromotionContainer *promotionContainer = [[MPPromotionContainer alloc] initWithAction:promotionAction promotion:nil];
    NSArray *jsonPromotions = json[@"PromotionAction"][@"PromotionList"];
    if (!jsonPromotions || ![jsonPromotions isKindOfClass:[NSArray class]]) {
        MPILogError(@"Unexpected promotion container list data received from webview");
        return nil;
    }
    [jsonPromotions enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        MPPromotion *promotion = [MPConvertJS MPPromotion:obj];
        [promotionContainer addPromotion:promotion];
    }];

    return promotionContainer;
}

+ (MPPromotion *)MPPromotion:(NSDictionary *)json {
    if (!json || ![json isKindOfClass:[NSDictionary class]]) {
        MPILogError(@"Unexpected promotion data received from webview");
        return nil;
    }
    MPPromotion *promotion = [[MPPromotion alloc] init];
    promotion.creative = json[@"Creative"];
    promotion.name = json[@"Name"];
    promotion.position = json[@"Position"];
    promotion.promotionId = json[@"Id"];
    return promotion;
}

+ (MPTransactionAttributes *)MPTransactionAttributes:(NSDictionary *)json {
    if (!json || ![json isKindOfClass:[NSDictionary class]]) {
        MPILogError(@"Unexpected transaction attributes data received from webview");
        return nil;
    }
    MPTransactionAttributes *transactionAttributes = [[MPTransactionAttributes alloc] init];
    transactionAttributes.affiliation = json[@"Affiliation"];
    transactionAttributes.couponCode = json[@"CouponCode"];
    transactionAttributes.shipping = json[@"ShippingAmount"];
    transactionAttributes.tax = json[@"TaxAmount"];
    transactionAttributes.revenue = json[@"TotalAmount"];
    transactionAttributes.transactionId = json[@"TransactionId"];
    return transactionAttributes;
}

+ (MPProduct *)MPProduct:(NSDictionary *)json {
    if (!json || ![json isKindOfClass:[NSDictionary class]]) {
        MPILogError(@"Unexpected product data received from webview");
        return nil;
    }
    MPProduct *product = [[MPProduct alloc] init];
    product.brand = json[@"Brand"];
    product.category = json[@"Category"];
    product.couponCode = json[@"CouponCode"];
    product.name = json[@"Name"];
    
    if (!json[@"Price"] || [json[@"Price"] isKindOfClass:[NSNumber class]]) {
        product.price = json[@"Price"];
    }
    
    product.sku = json[@"Sku"];
    product.variant = json[@"Variant"];
    product.position = [json[@"Position"] intValue];
    if (!json[@"Quantity"] || [json[@"Quantity"] isKindOfClass:[NSNumber class]]) {
        product.quantity = json[@"Quantity"];
    }

    NSDictionary *jsonAttributes = json[@"Attributes"];
    if ((NSNull *)jsonAttributes != [NSNull null]) {
        for (NSString *key in jsonAttributes) {
            NSString *value = jsonAttributes[key];
            [product setObject:value forKeyedSubscript:key];
        }
    }
    return product;
}

+ (BOOL)MPUserIdentity:(NSNumber *)json identity:(MPUserIdentity *)identity {
    MPUserIdentity localIdentity;
    
    if (json == nil || ![json isKindOfClass:[NSNumber class]]) {
        return NO;
    }
    
    int identityInt = [json intValue];
    switch (identityInt) {
        case MPJSIdentityTypeCustomerId:
            localIdentity = MPUserIdentityCustomerId;
            break;
            
        case MPJSIdentityTypeFacebook:
            localIdentity = MPUserIdentityFacebook;
            break;
            
        case MPJSIdentityTypeTwitter:
            localIdentity = MPUserIdentityTwitter;
            break;
            
        case MPJSIdentityTypeGoogle:
            localIdentity = MPUserIdentityGoogle;
            break;
            
        case MPJSIdentityTypeMicrosoft:
            localIdentity = MPUserIdentityMicrosoft;
            break;
            
        case MPJSIdentityTypeYahoo:
            localIdentity = MPUserIdentityYahoo;
            break;
            
        case MPJSIdentityTypeEmail:
            localIdentity = MPUserIdentityEmail;
            break;
            
        case MPJSIdentityTypeAlias:
            localIdentity = MPUserIdentityAlias;
            break;
            
        case MPJSIdentityTypeFacebookCustomAudienceId:
            localIdentity = MPUserIdentityFacebookCustomAudienceId;
            break;
            
        case MPJSIdentityTypeOther:
            localIdentity = MPUserIdentityOther;
            break;
            
        case MPJSIdentityTypeOther2:
            localIdentity = MPUserIdentityOther2;
            break;
            
        case MPJSIdentityTypeOther3:
            localIdentity = MPUserIdentityOther3;
            break;
            
        case MPJSIdentityTypeOther4:
            localIdentity = MPUserIdentityOther4;
            break;
            
        default:
            return NO;
            break;
    }
    
    *identity = localIdentity;
    return YES;
}

+ (MPIdentityApiRequest *)MPIdentityApiRequest:(NSDictionary *)json {
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
    
    if (userIdentities.count) {
        
        __block BOOL allSuccess = YES;
        
        [userIdentities enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull identityDictionary, NSUInteger idx, BOOL * _Nonnull stop) {
            
            NSString *identity = identityDictionary[@"Identity"];
            
            NSNumber *identityTypeNumber = identityDictionary[@"Type"];
            MPUserIdentity identityType;
        
            BOOL success = [MPConvertJS MPUserIdentity:identityTypeNumber identity:&identityType];
            
            if (!success) {
                allSuccess = NO;
                *stop = YES;
                return;
            }
            
            [request setUserIdentity:identity identityType:identityType];
        }];
        
        if (!allSuccess) {
            return nil;
        }
    }
    
    NSString *identity = json[@"Identity"];
    NSNumber *identityTypeNumber = json[@"Type"];
    MPUserIdentity identityType;
        
    BOOL success = [MPConvertJS MPUserIdentity:identityTypeNumber identity:&identityType];
        
    if (success) {
        [request setUserIdentity:identity identityType:identityType];
    }
    
    return request;
}

@end
