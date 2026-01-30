#import <Foundation/Foundation.h>

@class MPCommerceEvent;
@class MPPromotionContainer;
@class MPPromotion;
@class MPTransactionAttributes;
@class MPProduct;
@class MPIdentityApiRequest;

typedef NS_ENUM(NSUInteger, MPJSCommerceEventAction) {
    MPJSCommerceEventActionUnknown = 0,
    MPJSCommerceEventActionAddToCart,
    MPJSCommerceEventActionRemoveFromCart,
    MPJSCommerceEventActionCheckout,
    MPJSCommerceEventActionCheckoutOptions,
    MPJSCommerceEventActionClick,
    MPJSCommerceEventActionViewDetail,
    MPJSCommerceEventActionPurchase,
    MPJSCommerceEventActionRefund,
    MPJSCommerceEventActionAddToWishList,
    MPJSCommerceEventActionRemoveFromWishlist
};

@interface MPConvertJS_PRIVATE : NSObject

+ (MPCommerceEvent *)commerceEvent:(NSDictionary *)json;
+ (MPPromotionContainer *)promotionContainer:(NSDictionary *)json;
+ (MPPromotion *)promotion:(NSDictionary *)json;
+ (MPTransactionAttributes *)transactionAttributes:(NSDictionary *)json;
+ (MPProduct *)product:(NSDictionary *)json;
+ (MPIdentityApiRequest *)identityApiRequest:(NSDictionary *)json;

@end
