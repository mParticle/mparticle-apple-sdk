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
    MPCommerceEventFieldsJS *fields = [MPConvertJSFields commerceEventFieldsFromJSON:json];

    switch (fields.outcome) {
        case MPCommerceEventOutcomeJSMalformedProductAction:
            MPILogError(@"Unexpected commerce event data received from webview");
            return nil;
        case MPCommerceEventOutcomeJSInvalidPayload:
            MPILogError(@"Invalid commerce event dictionary received from webview: %@", json);
            return nil;
        case MPCommerceEventOutcomeJSMalformedProductActionType:
            MPILogError(@"Unexpected product action type received from webview");
            return nil;
        case MPCommerceEventOutcomeJSOk:
            break;
    }

    MPCommerceEvent *commerceEvent = nil;
    switch (fields.kind) {
        case MPCommerceEventKindJSProductAction: {
            MPCommerceEventAction action = [MPConvertJS_PRIVATE commerceEventAction:fields.productActionType];
            commerceEvent = [[MPCommerceEvent alloc] initWithAction:action];
            break;
        }
        case MPCommerceEventKindJSPromotion: {
            MPPromotionContainer *promotionContainer = [MPConvertJS_PRIVATE promotionContainer:json];
            commerceEvent = [[MPCommerceEvent alloc] initWithPromotionContainer:promotionContainer];
            break;
        }
        case MPCommerceEventKindJSImpression:
        case MPCommerceEventKindJSNone:
            commerceEvent = [[MPCommerceEvent alloc] initWithImpressionName:nil product:nil];
            break;
    }

    if (fields.customAttributes) { commerceEvent.customAttributes = fields.customAttributes; }
    if (fields.checkoutOptions) { commerceEvent.checkoutOptions = fields.checkoutOptions; }
    if (fields.productListName) { commerceEvent.productListName = fields.productListName; }
    if (fields.productListSource) { commerceEvent.productListSource = fields.productListSource; }
    if (fields.currency) { commerceEvent.currency = fields.currency; }

    // Gated on ProductAction being a dictionary, as it was.
    if (fields.productAction != nil) {
        commerceEvent.transactionAttributes = [self transactionAttributes:fields.productAction];
    }

    // checkoutStep is a scalar, so it is only written when the payload had one.
    if (fields.checkoutStep) { commerceEvent.checkoutStep = fields.checkoutStep.intValue; }

    for (MPCommerceFlagJS *flag in fields.customFlags) {
        [commerceEvent addCustomFlags:flag.values withKey:flag.key];
    }

    if (fields.products.count > 0) {
        NSMutableArray<MPProduct *> *products = [NSMutableArray arrayWithCapacity:fields.products.count];
        for (NSDictionary *productJson in fields.products) {
            MPProduct *product = [self product:productJson];
            if (product) { [products addObject:product]; }
        }
        [commerceEvent addProducts:products];
    }

    for (MPCommerceImpressionJS *impression in fields.impressions) {
        for (NSDictionary *productJson in impression.products) {
            MPProduct *product = [MPConvertJS_PRIVATE product:productJson];
            [commerceEvent addImpression:product listName:impression.listName];
        }
    }

    return commerceEvent;
}

+ (MPPromotionContainer *)promotionContainer:(NSDictionary *)json {
    MPPromotionContainerFieldsJS *fields = [MPConvertJSFields promotionContainerFieldsFromJSON:json];

    switch (fields.outcome) {
        case MPPromotionContainerOutcomeJSMissingAction:
            MPILogError(@"Unexpected promotion container action data received from webview");
            return nil;
        case MPPromotionContainerOutcomeJSMissingActionType:
            MPILogError(@"Unexpected promotion container action type data received from webview");
            return nil;
        case MPPromotionContainerOutcomeJSMissingList:
            MPILogError(@"Unexpected promotion container list data received from webview");
            return nil;
        case MPPromotionContainerOutcomeJSOk:
            break;
    }

    MPPromotionAction promotionAction = fields.isViewAction ? MPPromotionActionView : MPPromotionActionClick;
    MPPromotionContainer *promotionContainer = [[MPPromotionContainer alloc] initWithAction:promotionAction
                                                                                  promotion:nil];

    for (NSDictionary *promotionJson in fields.promotions) {
        [promotionContainer addPromotion:[MPConvertJS_PRIVATE promotion:promotionJson]];
    }

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
    if (fields.shipping != nil) { transactionAttributes.shipping = fields.shipping; }
    if (fields.tax != nil) { transactionAttributes.tax = fields.tax; }
    if (fields.revenue != nil) { transactionAttributes.revenue = fields.revenue; }
    if (fields.transactionId) { transactionAttributes.transactionId = fields.transactionId; }

    return transactionAttributes;
}

+ (MPProduct *)product:(NSDictionary *)json {
    MPProduct *product = [[MPProduct alloc] init];
    MPProductFieldsJS *fields = [MPConvertJSFields productFieldsFromJSON:json];

    // Guarded rather than assigned straight through: name, sku and quantity are
    // nonnull and position is a scalar, so "absent" is not the same as nil here.
    if (fields.brand) { product.brand = fields.brand; }
    if (fields.category) { product.category = fields.category; }
    if (fields.couponCode) { product.couponCode = fields.couponCode; }
    if (fields.name) { product.name = fields.name; }
    if (fields.price != nil) { product.price = fields.price; }
    if (fields.sku) { product.sku = fields.sku; }
    if (fields.variant) { product.variant = fields.variant; }
    if (fields.position != nil) { product.position = fields.position.unsignedIntValue; }
    if (fields.quantity != nil) { product.quantity = fields.quantity; }

    [fields.attributes enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, __unused BOOL *stop) {
        [product setValue:value forKey:key];
    }];

    return product;
}

+ (MPIdentityApiRequest *)identityApiRequest:(NSDictionary *)json {
    // Built before validating, as it was before, in case requestWithEmptyUser
    // ever does more than allocate.
    MPIdentityApiRequest *request = [MPIdentityApiRequest requestWithEmptyUser];
    MPWebviewIdentityRequestJS *parsed = [MPConvertJSFields identityRequestFromJSON:json];

    if (parsed.outcome == MPWebviewIdentityOutcomeJSMissingUserIdentities) {
        MPILogError(@"Unexpected user identity data received from webview");
        return nil;
    }

    // A malformed entry abandoned the whole request without logging.
    if (parsed.outcome != MPWebviewIdentityOutcomeJSOk) {
        return nil;
    }

    for (MPWebviewIdentityPairJS *pair in parsed.pairs) {
        [request setIdentity:pair.identity identityType:(MPIdentity)pair.identityType];
    }

    return request;
}

@end
