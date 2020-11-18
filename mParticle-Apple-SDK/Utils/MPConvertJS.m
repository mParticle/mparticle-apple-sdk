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
    MPJSIdentityTypeOther4,
    MPJSIdentityTypeOther5,
    MPJSIdentityTypeOther6,
    MPJSIdentityTypeOther7,
    MPJSIdentityTypeOther8,
    MPJSIdentityTypeOther9,
    MPJSIdentityTypeOther10,
    MPJSIdentityTypeMobileNumber,
    MPJSIdentityTypePhoneNumber2,
    MPJSIdentityTypePhoneNumber3,
    MPJSIdentityTypeIOSAdvertiserId,
    MPJSIdentityTypeIOSVendorId,
    MPJSIdentityTypePushToken,
    MPJSIdentityTypeDeviceApplicationStamp
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
    if ((NSNull *)json[@"ProductAction"] != [NSNull null]) {
        commerceEvent.transactionAttributes = [MPConvertJS MPTransactionAttributes:json[@"ProductAction"]];
    }
    if ([json[@"CheckoutStep"] isKindOfClass:[NSNumber class]]) {
        commerceEvent.checkoutStep = [json[@"CheckoutStep"] intValue];
    }

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

+ (MPTransactionAttributes *)MPTransactionAttributes:(NSDictionary *)json {
    if (!json || ![json isKindOfClass:[NSDictionary class]]) {
        MPILogError(@"Unexpected transaction attributes data received from webview");
        return nil;
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

+ (MPProduct *)MPProduct:(NSDictionary *)json {
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
        product.position = [json[@"Position"] intValue];
    }
    if (!json[@"Quantity"] || [json[@"Quantity"] isKindOfClass:[NSNumber class]]) {
        product.quantity = json[@"Quantity"];
    }

    NSDictionary *jsonAttributes = json[@"Attributes"];
    if ((NSNull *)jsonAttributes != [NSNull null]) {
        for (NSString *key in jsonAttributes) {
            NSString *value = jsonAttributes[key];
            if ((NSNull *)value != [NSNull null]) {
                [product setObject:value forKeyedSubscript:key];
            }
        }
    }
    return product;
}

+ (BOOL)MPIdentity:(NSNumber *)json identity:(MPIdentity *)identity {
    MPIdentity localIdentity;
    
    if (json == nil || ![json isKindOfClass:[NSNumber class]]) {
        return NO;
    }
    
    int identityInt = [json intValue];
    switch (identityInt) {
        case MPJSIdentityTypeCustomerId:
            localIdentity = MPIdentityCustomerId;
            break;
            
        case MPJSIdentityTypeFacebook:
            localIdentity = MPIdentityFacebook;
            break;
            
        case MPJSIdentityTypeTwitter:
            localIdentity = MPIdentityTwitter;
            break;
            
        case MPJSIdentityTypeGoogle:
            localIdentity = MPIdentityGoogle;
            break;
            
        case MPJSIdentityTypeMicrosoft:
            localIdentity = MPIdentityMicrosoft;
            break;
            
        case MPJSIdentityTypeYahoo:
            localIdentity = MPIdentityYahoo;
            break;
            
        case MPJSIdentityTypeEmail:
            localIdentity = MPIdentityEmail;
            break;
            
        case MPJSIdentityTypeAlias:
            localIdentity = MPIdentityAlias;
            break;
            
        case MPJSIdentityTypeFacebookCustomAudienceId:
            localIdentity = MPIdentityFacebookCustomAudienceId;
            break;
            
        case MPJSIdentityTypeOther:
            localIdentity = MPIdentityOther;
            break;
            
        case MPJSIdentityTypeOther2:
            localIdentity = MPIdentityOther2;
            break;
            
        case MPJSIdentityTypeOther3:
            localIdentity = MPIdentityOther3;
            break;
            
        case MPJSIdentityTypeOther4:
            localIdentity = MPIdentityOther4;
            break;
            
        case MPJSIdentityTypeOther5:
            localIdentity = MPIdentityOther5;
            break;
            
        case MPJSIdentityTypeOther6:
            localIdentity = MPIdentityOther6;
            break;
            
        case MPJSIdentityTypeOther7:
            localIdentity = MPIdentityOther7;
            break;
            
        case MPJSIdentityTypeOther8:
            localIdentity = MPIdentityOther8;
            break;
            
        case MPJSIdentityTypeOther9:
            localIdentity = MPIdentityOther9;
            break;
            
        case MPJSIdentityTypeOther10:
            localIdentity = MPIdentityOther10;
            break;
            
        case MPJSIdentityTypeMobileNumber:
            localIdentity = MPIdentityMobileNumber;
            break;
            
        case MPJSIdentityTypePhoneNumber2:
            localIdentity = MPIdentityPhoneNumber2;
            break;
            
        case MPJSIdentityTypePhoneNumber3:
            localIdentity = MPIdentityPhoneNumber3;
            break;
            
        case MPJSIdentityTypeIOSAdvertiserId:
            localIdentity = MPIdentityIOSAdvertiserId;
            break;
            
        case MPJSIdentityTypeIOSVendorId:
            localIdentity = MPIdentityIOSVendorId;
            break;
            
        case MPJSIdentityTypePushToken:
            localIdentity = MPIdentityPushToken;
            break;
            
        case MPJSIdentityTypeDeviceApplicationStamp:
            localIdentity = MPIdentityDeviceApplicationStamp;
            break;
            
        default:
            return NO;
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
            MPIdentity identityType;
        
            BOOL success = [MPConvertJS MPIdentity:identityTypeNumber identity:&identityType];
            
            if (!success) {
                allSuccess = NO;
                *stop = YES;
                return;
            }
            
            [request setIdentity:identity identityType:identityType];
        }];
        
        if (!allSuccess) {
            return nil;
        }
    }
    
    NSString *identity = json[@"Identity"];
    NSNumber *identityTypeNumber = json[@"Type"];
    MPIdentity identityType;
        
    BOOL success = [MPConvertJS MPIdentity:identityTypeNumber identity:&identityType];
        
    if (success) {
        [request setIdentity:identity identityType:identityType];
    }
    
    return request;
}

@end
