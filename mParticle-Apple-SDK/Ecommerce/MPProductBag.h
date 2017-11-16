#import <Foundation/Foundation.h>

@class MPProduct;

@interface MPProductBag : NSObject

@property (nonatomic, strong, nonnull) NSString *name;
@property (nonatomic, strong, nonnull) NSMutableArray<MPProduct *> *products;

- (nonnull instancetype)initWithName:(nonnull NSString *)name;
- (nonnull instancetype)initWithName:(nonnull NSString *)name product:(nullable MPProduct *)product;
- (nonnull NSDictionary<NSString *, NSDictionary *> *)dictionaryRepresentation;

@end
