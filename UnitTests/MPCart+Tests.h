@class MPCart;

@interface MPCart(Tests)

- (void)persistCart;
- (void)removePersistedCart;
- (MPCart *)retrieveCart;
- (void)addProducts:(NSArray *)products logEvent:(BOOL)logEvent updateProductList:(BOOL)updateProductList;
- (NSDictionary *)dictionaryRepresentation;
- (void)removeProducts:(NSArray *)products logEvent:(BOOL)logEvent updateProductList:(BOOL)updateProductList;

@end
