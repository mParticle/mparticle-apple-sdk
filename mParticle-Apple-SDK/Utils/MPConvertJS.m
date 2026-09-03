#import "MPConvertJS.h"
#import "MPCommerceEvent+Dictionary.h"
#import "mParticle.h"
#import "MPILogger.h"
@import mParticle_Apple_SDK_Swift;

@implementation MPConvertJS_PRIVATE

+ (MPCommerceEventAction)commerceEventAction:(NSNumber *)json {
    NSNumber *action = [MPConvertJSFields commerceEventActionForJSValue:json];
    if (action == nil) {
        MPILogError(@"Invalid commerce event action received from webview: %@", json);
        return MPCommerceEventActionAddToCart;
    }

    return (MPCommerceEventAction)action.unsignedIntegerValue;
}

+ (MPCommerceEvent *)commerceEvent:(NSDictionary *)json {
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
    
    id eventAttributes = json[@"EventAttributes"];
    if ([eventAttributes isKindOfClass:[NSDictionary class]]) {
        commerceEvent.customAttributes = (NSDictionary *)eventAttributes;
    }
    
    id checkoutOptionsObj = json[@"CheckoutOptions"];
    if ([checkoutOptionsObj isKindOfClass:[NSString class]]) {
        commerceEvent.checkoutOptions = (NSString *)checkoutOptionsObj;
    }

    id productActionListNameObj = json[@"productActionListName"];
    if ([productActionListNameObj isKindOfClass:[NSString class]]) {
        commerceEvent.productListName = (NSString *)productActionListNameObj;
    }

    id productActionListSourceObj = json[@"productActionListSource"];
    if ([productActionListSourceObj isKindOfClass:[NSString class]]) {
        commerceEvent.productListSource = (NSString *)productActionListSourceObj;
    }

    id currencyCodeObj = json[@"CurrencyCode"];
    if ([currencyCodeObj isKindOfClass:[NSString class]]) {
        commerceEvent.currency = (NSString *)currencyCodeObj;
    }
    
    if (productAction != nil) {
        commerceEvent.transactionAttributes = [self transactionAttributes:productAction];
    }
    
    id checkoutStepObj = json[@"CheckoutStep"];
    if ([checkoutStepObj isKindOfClass:[NSNumber class]]) {
        commerceEvent.checkoutStep = [(NSNumber *)checkoutStepObj intValue];
    }
    
    id customFlagsObj = json[@"CustomFlags"];
    if ([customFlagsObj isKindOfClass:[NSDictionary class]]) {
        NSDictionary *customFlags = (NSDictionary *)customFlagsObj;

        for (id key in customFlags) {
            id value = customFlags[key];

            if ([value isKindOfClass:[NSArray class]]) {
                BOOL allStrings = YES;
                for (id item in (NSArray *)value) {
                    if (![item isKindOfClass:[NSString class]]) { allStrings = NO; break; }
                }
                if (allStrings && [key isKindOfClass:[NSString class]]) {
                    [commerceEvent addCustomFlags:(NSArray<NSString *> *)value withKey:(NSString *)key];
                }

            } else if ([value isKindOfClass:[NSString class]]) {
                if ([key isKindOfClass:[NSString class]]) {
                    [commerceEvent addCustomFlag:(NSString *)value withKey:(NSString *)key];
                }
            }
        }
    }

    id productListObj = productAction[@"ProductList"];
    if ([productListObj isKindOfClass:[NSArray class]]) {
        NSArray *jsonProducts = (NSArray *)productListObj;

        NSMutableArray<MPProduct *> *products = [NSMutableArray arrayWithCapacity:jsonProducts.count];
        for (id item in jsonProducts) {
            if (![item isKindOfClass:[NSDictionary class]]) { continue; }

            MPProduct *p = [self product:(NSDictionary *)item];
            if (p) { [products addObject:p]; }
        }
        [commerceEvent addProducts:products];
    }

    id impressionsObj = json[@"ProductImpressions"];
    if ([impressionsObj isKindOfClass:[NSArray class]]) {
        NSArray *jsonImpressions = (NSArray *)impressionsObj;

        for (id impressionItem in jsonImpressions) {
            if (![impressionItem isKindOfClass:[NSDictionary class]]) { continue; }

            NSDictionary *jsonImpression = (NSDictionary *)impressionItem;
            id listNameObj = jsonImpression[@"ProductImpressionList"];
            id impressionProductsObj = jsonImpression[@"ProductList"];

            if ([listNameObj isKindOfClass:[NSString class]] &&
                [impressionProductsObj isKindOfClass:[NSArray class]]) {

                NSString *listName = (NSString *)listNameObj;
                NSArray *impressionProducts = (NSArray *)impressionProductsObj;

                for (id prodItem in impressionProducts) {
                    if (![prodItem isKindOfClass:[NSDictionary class]]) { continue; }

                    MPProduct *product = [MPConvertJS_PRIVATE product:(NSDictionary *)prodItem];
                    [commerceEvent addImpression:product listName:listName];
                }
            }
        }
    }

    return commerceEvent;
}

+ (MPPromotionContainer *)promotionContainer:(NSDictionary *)json {
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
    MPPromotion *promotion = [[MPPromotion alloc] init];
    MPPromotionFieldsJS *fields = [MPConvertJSFields promotionFieldsFromJSON:json];

    // Guarded, not unconditional: -attributes/-beautifiedAttributes are lazy and
    // allocate on first touch, including from a setter's nil-removal branch. An
    // unconditional assignment when every field is nil still allocates an empty
    // (non-nil) _attributes, which -dictionaryRepresentation returns as-is —
    // turning "no valid fields" into a promotion MPPromotionContainer no longer
    // skips, instead of leaving it nil as before this file moved to Swift.
    if (fields.creative) { promotion.creative = fields.creative; }
    if (fields.name) { promotion.name = fields.name; }
    if (fields.position) { promotion.position = fields.position; }
    if (fields.promotionId) { promotion.promotionId = fields.promotionId; }

    return promotion;
}

+ (MPTransactionAttributes *)transactionAttributes:(NSDictionary *)json {
    MPTransactionAttributes *transactionAttributes = [[MPTransactionAttributes alloc] init];
    MPTransactionAttributesFieldsJS *fields = [MPConvertJSFields transactionAttributesFieldsFromJSON:json];

    // Same guard, same reason: MPTransactionAttributes has the identical lazy
    // -attributes/-beautifiedAttributes pattern as MPPromotion.
    if (fields.affiliation) { transactionAttributes.affiliation = fields.affiliation; }
    if (fields.couponCode) { transactionAttributes.couponCode = fields.couponCode; }
    if (fields.shipping) { transactionAttributes.shipping = fields.shipping; }
    if (fields.tax) { transactionAttributes.tax = fields.tax; }
    if (fields.revenue) { transactionAttributes.revenue = fields.revenue; }
    if (fields.transactionId) { transactionAttributes.transactionId = fields.transactionId; }

    return transactionAttributes;
}

+ (MPProduct *)product:(NSDictionary *)json {
    MPProduct *product = [[MPProduct alloc] init];

    id brand = json[@"Brand"];
    if ([brand isKindOfClass:[NSString class]]) {
        product.brand = (NSString *)brand;
    }

    id category = json[@"Category"];
    if ([category isKindOfClass:[NSString class]]) {
        product.category = (NSString *)category;
    }

    id couponCode = json[@"CouponCode"];
    if ([couponCode isKindOfClass:[NSString class]]) {
        product.couponCode = (NSString *)couponCode;
    }

    id name = json[@"Name"];
    if ([name isKindOfClass:[NSString class]]) {
        product.name = (NSString *)name;
    }

    id price = json[@"Price"];
    if ([price isKindOfClass:[NSNumber class]]) {
        product.price = (NSNumber *)price;
    } else if ([price isKindOfClass:[NSString class]]) {
        product.price = @([(NSString *)price doubleValue]);
    }

    id sku = json[@"Sku"];
    if ([sku isKindOfClass:[NSString class]]) {
        product.sku = (NSString *)sku;
    }

    id variant = json[@"Variant"];
    if ([variant isKindOfClass:[NSString class]]) {
        product.variant = (NSString *)variant;
    }

    id position = json[@"Position"];
    if ([position isKindOfClass:[NSNumber class]]) {
        product.position = [(NSNumber *)position unsignedIntValue];
    }

    id quantity = json[@"Quantity"];
    if ([quantity isKindOfClass:[NSNumber class]]) {
        product.quantity = (NSNumber *)quantity;
    }

    id attributes = json[@"Attributes"];
    if ([attributes isKindOfClass:[NSDictionary class]]) {
        NSDictionary *jsonAttributes = (NSDictionary *)attributes;
        [jsonAttributes enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if ([key isKindOfClass:[NSString class]] && [obj isKindOfClass:[NSString class]]) {
                [product setValue:obj forKey:key];
            }
        }];
    }

    return product;
}

+ (MPIdentityApiRequest *)identityApiRequest:(NSDictionary *)json {
    MPIdentityApiRequest *request = [MPIdentityApiRequest requestWithEmptyUser];
    
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
            
            if (identityTypeNumber == nil || ![identityTypeNumber isKindOfClass:[NSNumber class]]) {
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
