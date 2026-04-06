#import <Foundation/Foundation.h>
/**
 This class is used to describe a product used in a commerce event.
 Since this class behaves similarly to an NSMutableDictionary, custom key/value pairs can be specified, in addition to the
 ones listed as class properties.
 
 <b>For example:</b>
 
 <b>Swift</b>
 <pre><code>
 let product = MPProduct(name:"Product Name", sku:"s1k2u3", quantity:1, price:1.23)
 
 product["Custom Key"] = "Custom Value"
 </code></pre>
 
 <b>Objective-C</b>
 <pre><code>
 MPProduct *product = [[MPProduct alloc] initWithName:&#64;"Product Name" sku:&#64;"s1k2u3" quantity:&#64;1 price:&#64;1.23];
 
 product[&#64;"Custom Key"] = &#64;"Custom Value";
 </code></pre>
 */
@interface MPProduct : NSObject <NSCopying, NSSecureCoding>

/**
 The product brand
 */
@property (nonatomic, strong, nullable) NSString *brand;

/**
 A category to which the product belongs
 */
@property (nonatomic, strong, nullable) NSString *category;

/**
 The coupon associated with the product
 */
@property (nonatomic, strong, nullable) NSString *couponCode;

/**
 The name of the product
 */
@property (nonatomic, strong, nonnull) NSString *name;

/**
 The price of a product. If product is free or price is non-applicable use nil. Default value is nil
 */
@property (nonatomic, strong, nullable) NSNumber *price;

/**
 SKU of a product. This is the product id
 */
@property (nonatomic, strong, nonnull) NSString *sku;

/**
 The variant of the product
 */
@property (nonatomic, strong, nullable) NSString *variant;

/**
 The prosition of the product on the screen or impression list
 */
@property (nonatomic) NSUInteger position;

/**
 The quantity of the product. Default value is 1
 */
@property (nonatomic, strong, nonnull) NSNumber *quantity;

/**
 Initializes an instance of MPProduct.
 @param name The name of the product
 @param sku The SKU or Product Id
 @param quantity The quantity of the product. If non-applicable use 0
 @param price The unit price of the product. If the product is free or if non-applicable pass 0
 @returns An instance of MPProduct, or nil if it could not be created
 
 <b>Swift</b>
 <pre><code>
 let product = MPProduct(name:"Product Name", sku:"s1k2u3", quantity:1, price:1.23)
 </code></pre>
 
 <b>Objective-C</b>
 <pre><code>
 MPProduct *product = [[MPProduct alloc] initWithName:&#64;"Product Name" sku:&#64;"s1k2u3" quantity:&#64;1 price:&#64;1.23];
 </code></pre>
 */
- (nonnull instancetype)initWithName:(nonnull NSString *)name sku:(nonnull NSString *)sku quantity:(nonnull NSNumber *)quantity price:(nullable NSNumber *)price;

/**
 Returns an array with all keys in the MPProduct dictionary
 @returns An array with all dictionary keys
 */
- (nonnull NSArray *)allKeys;

/**
 Number of entries in the MPProduct dictionary
 @returns The number of entries in the dictionary
 */
- (NSUInteger)count;

- (nullable id)objectForKeyedSubscript:(nonnull NSString *const)key;
- (void)setObject:(nonnull id)obj forKeyedSubscript:(nonnull NSString *)key;

@end

// Internal
extern NSString * _Nonnull const kMPProductName;
extern NSString * _Nonnull const kMPProductSKU;
extern NSString * _Nonnull const kMPProductUnitPrice;
extern NSString * _Nonnull const kMPProductQuantity;
extern NSString * _Nonnull const kMPProductRevenue;
extern NSString * _Nonnull const kMPProductCategory;
extern NSString * _Nonnull const kMPProductTotalAmount;
extern NSString * _Nonnull const kMPProductTransactionId;
extern NSString * _Nonnull const kMPProductAffiliation;
extern NSString * _Nonnull const kMPProductCurrency;
extern NSString * _Nonnull const kMPProductTax;
extern NSString * _Nonnull const kMPProductShipping;

// Expanded
extern NSString * _Nonnull const kMPExpProductBrand;
extern NSString * _Nonnull const kMPExpProductName;
extern NSString * _Nonnull const kMPExpProductSKU;
extern NSString * _Nonnull const kMPExpProductUnitPrice;
extern NSString * _Nonnull const kMPExpProductQuantity;
extern NSString * _Nonnull const kMPExpProductCategory;
extern NSString * _Nonnull const kMPExpProductCouponCode;
extern NSString * _Nonnull const kMPExpProductVariant;
extern NSString * _Nonnull const kMPExpProductPosition;
extern NSString * _Nonnull const kMPExpProductTotalAmount;
