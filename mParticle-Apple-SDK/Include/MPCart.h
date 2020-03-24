#import <Foundation/Foundation.h>

@class MPProduct;

/**
 This class is used to keep the state of the shopping cart for a given user.
 E-commerce transactions logged using the MPCommerce class or the logCommerceEvent: method will keep the state of the respective products in here.

 Once products are added to the cart, its contents are persisted through the lifetime of the app. Therefore it is important that after completing an ecommerce transaction
 (purchase, refund, etc) that you call the cart's <b>clear</b> method to empty its content and remove whatever data was persisted.
 
 @see MPCommerce
 @see mParticle
 */
@interface MPCart : NSObject <NSSecureCoding>

/**
 Adds a product to the shopping cart. 
 Calling this method directly will create a <i>AddToCart</i>  <b> MPCommerceEvent</b> with <i>product</i> and invoke the <b>logCommerceEvent:</b> method on your behalf.

 <b>Swift</b>
 <pre><code>
 cart.addProduct(product)
 </code></pre>
 
 <b>Objective-C</b>
 <pre><code>
 [cart addProduct:product];
 </code></pre>
 
 @param product An instance of MPProduct
 
 @see MPCommerceEvent
 @see mParticle
 */
- (void)addProduct:(nonnull MPProduct *)product DEPRECATED_MSG_ATTRIBUTE("Create an MPCommerceEvent with the action `MPCommerceEventActionAddToCart`, add the product, fill in any relevant data, and pass it to LogEvent on the MParticle API");

/**
 Adds an array of products to the shopping cart.
 Optionally, this method will also log an event for each one.
 
 <b>Swift</b>
 <pre><code>
 cart.addAllProducts(products, shouldLogEvents:false)
 </code></pre>
 
 <b>Objective-C</b>
 <pre><code>
 [cart addAllProducts:products shouldLogEvents:NO];
 </code></pre>
 
 @param products An array of MPProduct instances
 @param shouldLogEvents Whether or not events should be logged for each product
 
 @see MPCommerceEvent
 @see mParticle
 */
- (void)addAllProducts:(nonnull NSArray<MPProduct *> *)products shouldLogEvents:(BOOL)shouldLogEvents DEPRECATED_MSG_ATTRIBUTE("Create an MPCommerceEvent with the action `MPCommerceEventActionAddToCart`, add the products, fill in any relevant data, and pass it to LogEvent on the MParticle API");

/**
 Empties the shopping cart. Removes all its contents and respective persisted data.
 
 <b>Swift</b>
 <pre><code>
 cart.clear()
 </code></pre>
 
 <b>Objective-C</b>
 <pre><code>
 [cart clear];
 </code></pre>
 */
- (void)clear DEPRECATED_MSG_ATTRIBUTE("Create an MPCommerceEvent with the action `MPCommerceEventActionRemoveFromCart`, add the products, fill in any relevant data, and pass it to LogEvent on the MParticle API");

/**
 Returns the collection of products in the shopping cart.
 @returns An array with products in the shopping cart or nil if the cart is empty.
 */
- (nullable NSArray<MPProduct *> *)products DEPRECATED_MSG_ATTRIBUTE("The SDK no longer supports tracking the contents of your Cart. Please implement your own cart functionality and send us CommerceEvents as it is updated.");

/**
 Removes a product from the shopping cart.
 Calling this method directly will create a <i>RemoveFromCart</i>  <b> MPCommerceEvent</b> with <i>product</i> and invoke the <b>logCommerceEvent:</b> method on your behalf.
 
 <b>Swift</b>
 
 <pre><code>
 cart.removeProduct(product)
 </code></pre>
 
 <b>Objective-C</b>
 
 <pre><code>
 [cart removeProduct:product];
 </code></pre>
 
 @param product An instance of MPProduct

 @see MPCommerceEvent
 @see mParticle
 */
- (void)removeProduct:(nonnull MPProduct *)product DEPRECATED_MSG_ATTRIBUTE("Create an MPCommerceEvent with the action `MPCommerceEventActionRemoveFromCart`, add the product, fill in any relevant data, and pass it to LogEvent on the MParticle API");

@end
