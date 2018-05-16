#import <XCTest/XCTest.h>
#import "MPMessageBuilder.h"
#import "MPIConstants.h"
#import "MPSession.h"
#import "MPMessage.h"
#import "MPProduct.h"
#import "MPProduct+Dictionary.h"
#import "MPPromotion.h"
#import "MPPromotion+Dictionary.h"
#import "MPTransactionAttributes.h"
#import "MPTransactionAttributes+Dictionary.h"
#import "MPCommerceEvent.h"
#import "MPCommerceEvent+Dictionary.h"
#import "MPCart.h"
#import "MPCart+Dictionary.h"
#import "NSDictionary+MPCaseInsensitive.h"
#import "MPUserAttributeChange.h"
#import "MPPersistenceController.h"
#import "MParticle.h"

@interface MPMessageBuilderTests : XCTestCase

@property (nonatomic, strong) MPSession *session;

@end

@implementation MPMessageBuilderTests

- (MPSession *)session {
    if (_session) {
        return _session;
    }
    
    _session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController mpId]];
    return _session;
}

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testBuildingMessage {
    NSDictionary *messageInfo = @{@"key1":@"value1",
                                  @"key2":@"value2",
                                  @"key3":@"value3"};
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeEvent
                                                                           session:self.session
                                                                       messageInfo:messageInfo];
    
    XCTAssertNotNil(messageBuilder, @"Message builder should not have been nil.");
    XCTAssertEqualObjects(messageBuilder.messageType, @"e", @"Message type not being set properly.");
    XCTAssertEqualObjects(messageBuilder.session, self.session, @"Message session differ from the one set.");
    
    BOOL containsDictionary = NO;
    NSArray *keys = [messageInfo allKeys];
    for (NSString *key in keys) {
        containsDictionary = [messageBuilder.messageInfo[key] isEqualToString:messageInfo[key]];
        
        if (!containsDictionary) {
            break;
        }
    }
    
    XCTAssertTrue(containsDictionary, @"Message info dictionary is not contained in the message's dictionary.");
    
    NSTimeInterval timestamp = messageBuilder.timestamp;
    messageBuilder = [messageBuilder withTimestamp:[[NSDate date] timeIntervalSince1970]];
    XCTAssertNotEqual(messageBuilder.timestamp, timestamp, @"Timestamp is not being updated.");
    
    MPMessage *message = (MPMessage *)[messageBuilder build];
    XCTAssertNotNil(message, @"MPMessage is not being built.");
    XCTAssertTrue([message isKindOfClass:[MPMessage class]], @"Returning the wrong kind of class instance.");
    XCTAssertNotNil(message.messageData, @"MPMessage has no data.");
    
    messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeEvent
                                                         session:nil
                                                     messageInfo:messageInfo];
    
    XCTAssertNotNil(messageBuilder, @"Message builder should not have been nil.");
    
    message = (MPMessage *)[messageBuilder build];
    XCTAssertTrue([message isKindOfClass:[MPMessage class]], @"Returning the wrong kind of class instance.");
}

- (void)testBuildCommerceEventProduct {
    MPProduct *product = [[MPProduct alloc] initWithName:@"DeLorean" sku:@"OutATime" quantity:@1 price:@4.32];
    product.brand = @"DLC";
    product.category = @"Time Machine";
    product.couponCode = @"88mph";
    product.position = 1;
    product.variant = @"It depends";
    product[@"key1"] = @"val1";
    product[@"key_number"] = @"1";
    product[@"key_bool"] = @"Y";
    
    MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionAddToCart product:product];
    commerceEvent.checkoutOptions = @"option 1";
    commerceEvent.screenName = @"Time Traveling";
    commerceEvent.checkoutStep = 1;
    commerceEvent[@"key_string"] = @"val_string";
    commerceEvent[@"key_number"] = @"3.14";
    commerceEvent[@"key_date"] = @"01/01/2000";
    
    MPCart *cart = [MParticle sharedInstance].identity.currentUser.cart;
    [cart clear];
    [cart addProducts:@[product] logEvent:NO updateProductList:YES];
    XCTAssertEqual(cart.products.count, 1, @"Incorrect product count.");
    
    product = [[MPProduct alloc] initWithName:@"Tardis" sku:@"trds" quantity:@1 price:@7.89];
    product.brand = @"Gallifrey Tardis";
    product.category = @"Time Machine";
    product.position = 2;
    product.variant = @"Police Box";
    
    [commerceEvent addProduct:product];
    [cart addProducts:@[product] logEvent:NO updateProductList:YES];
    XCTAssertEqual(cart.products.count, 2, @"Incorrect product count.");
    
    MPTransactionAttributes *transactionAttributes = [[MPTransactionAttributes alloc] init];
    transactionAttributes.affiliation = @"Doctor";
    transactionAttributes.shipping = @1.23;
    transactionAttributes.tax = @4.56;
    transactionAttributes.revenue = @18;
    transactionAttributes.transactionId = @"42";
    commerceEvent.transactionAttributes = transactionAttributes;
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeCommerceEvent
                                                                           session:self.session
                                                                     commerceEvent:commerceEvent];
    
    XCTAssertNotNil(messageBuilder, @"Message builder should not have been nil.");
    XCTAssertEqualObjects(messageBuilder.messageType, @"cm", @"Incorrect message type.");
    
    MPMessage *message = (MPMessage *)[messageBuilder build];
    XCTAssertNotNil(message, @"MPMessage is not being built.");
    XCTAssertTrue([message isKindOfClass:[MPMessage class]], @"Returning the wrong kind of class instance.");
    XCTAssertNotNil(message.messageData, @"MPMessage has no data.");
    
    [cart clear];
}

- (void)testBuildCommerceEventPromotion {
    MPPromotion *promotion = [[MPPromotion alloc] init];
    promotion.creative = @"ACME";
    promotion.name = @"Bird Seed";
    promotion.position = @"bottom";
    promotion.promotionId = @"catch_a_roadrunner";
    
    MPPromotionContainer *promotionContainer = [[MPPromotionContainer alloc] initWithAction:MPPromotionActionView promotion:promotion];
    
    MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithPromotionContainer:promotionContainer];
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeCommerceEvent
                                                                           session:self.session
                                                                     commerceEvent:commerceEvent];
    
    XCTAssertNotNil(messageBuilder, @"Message builder should not have been nil.");
    XCTAssertEqualObjects(messageBuilder.messageType, @"cm", @"Incorrect message type.");
    
    MPMessage *message = (MPMessage *)[messageBuilder build];
    XCTAssertNotNil(message, @"MPMessage is not being built.");
    XCTAssertTrue([message isKindOfClass:[MPMessage class]], @"Returning the wrong kind of class instance.");
    XCTAssertNotNil(message.messageData, @"MPMessage has no data.");
}

- (void)testCaseInsensitiveDictionary {
    NSDictionary *dictionary = @{@"Key1":@"Value1",
                                 @"kEY2":@"Value2"
                                 };
    
    NSString *key = [dictionary caseInsensitiveKey:@"kEy1"];
    XCTAssertNotNil(key, @"Should not have been nil.");
    XCTAssertEqualObjects(key, @"Key1", @"Should have been equal.");
    
    key = [dictionary caseInsensitiveKey:@"KeY2"];
    XCTAssertNotNil(key, @"Should not have been nil.");
    XCTAssertEqualObjects(key, @"kEY2", @"Should have been equal.");
    
    key = [dictionary caseInsensitiveKey:@"This key does not exist"];
    XCTAssertNotNil(key, @"Should not have been nil.");
    XCTAssertEqualObjects(key, @"This key does not exist", @"Should have been equal.");
    
    id value = [dictionary valueForCaseInsensitiveKey:@"keY1"];
    XCTAssertNotNil(value, @"Should not have been nil.");
    XCTAssertEqualObjects(value, @"Value1", @"Should have been equal.");
    
    value = [dictionary valueForCaseInsensitiveKey:@"kEy2"];
    XCTAssertNotNil(value, @"Should not have been nil.");
    XCTAssertEqualObjects(value, @"Value2", @"Should have been equal.");
    
    value = [dictionary valueForCaseInsensitiveKey:@"This key does not exist"];
    XCTAssertNil(value, @"Should have been nil.");
}

- (void)testUserAttributeChange {
    NSDictionary<NSString *, id> *userAttributes = @{@"membership_status":@"Gold",
                                                     @"seat_preference":@"Window"};
    
    // Add a new user attribute
    MPUserAttributeChange *userAttributeChange = [[MPUserAttributeChange alloc] initWithUserAttributes:userAttributes key:@"meal_restrictions" value:@"Peanuts"];
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeUserAttributeChange
                                                                           session:self.session
                                                               userAttributeChange:userAttributeChange];
    XCTAssertNotNil(messageBuilder);
    MPMessage *message = (MPMessage *)[messageBuilder build];
    XCTAssertNotNil(message);
    
    NSDictionary *messageDictionary = [message dictionaryRepresentation];
    XCTAssertEqualObjects(@"uac", messageDictionary[@"dt"]);
    XCTAssertEqualObjects([NSNull null], messageDictionary[@"ov"]);
    XCTAssertEqualObjects(@"Peanuts", messageDictionary[@"nv"]);
    XCTAssertEqualObjects(@"meal_restrictions", messageDictionary[@"n"]);
    XCTAssertEqualObjects(@NO, messageDictionary[@"d"]);
    XCTAssertEqualObjects(@YES, messageDictionary[@"na"]);
    
    // Remove an existing user attribute
    userAttributeChange = [[MPUserAttributeChange alloc] initWithUserAttributes:userAttributes key:@"membership_status" value:nil];
    userAttributeChange.deleted = YES;
    
    messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeUserAttributeChange
                                                         session:self.session
                                             userAttributeChange:userAttributeChange];

    XCTAssertNotNil(messageBuilder);
    message = (MPMessage *)[messageBuilder build];
    XCTAssertNotNil(message);
    
    messageDictionary = [message dictionaryRepresentation];
    XCTAssertEqualObjects(@"uac", messageDictionary[@"dt"]);
    XCTAssertEqualObjects(@"Gold", messageDictionary[@"ov"]);
    XCTAssertEqualObjects([NSNull null], messageDictionary[@"nv"]);
    XCTAssertEqualObjects(@"membership_status", messageDictionary[@"n"]);
    XCTAssertEqualObjects(@YES, messageDictionary[@"d"]);
    XCTAssertEqualObjects(@NO, messageDictionary[@"na"]);

    // Update an existing user attribute
    NSArray<NSString *> *seatPreference = @[@"Window", @"Aisle"];
    userAttributeChange = [[MPUserAttributeChange alloc] initWithUserAttributes:userAttributes key:@"seat_preference" value:seatPreference];
    
    messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeUserAttributeChange
                                                         session:self.session
                                             userAttributeChange:userAttributeChange];

    XCTAssertNotNil(messageBuilder);
    message = (MPMessage *)[messageBuilder build];
    XCTAssertNotNil(message);
    
    messageDictionary = [message dictionaryRepresentation];
    XCTAssertEqualObjects(@"uac", messageDictionary[@"dt"]);
    XCTAssertEqualObjects(@"Window", messageDictionary[@"ov"]);
    XCTAssertEqualObjects(seatPreference, messageDictionary[@"nv"]);
    XCTAssertEqualObjects(@"seat_preference", messageDictionary[@"n"]);
    XCTAssertEqualObjects(@NO, messageDictionary[@"d"]);
    XCTAssertEqualObjects(@NO, messageDictionary[@"na"]);
    
    // User attribute tag
    userAttributeChange = [[MPUserAttributeChange alloc] initWithUserAttributes:userAttributes key:@"VIP" value:[NSNull null]];
    
    messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeUserAttributeChange
                                                         session:self.session
                                             userAttributeChange:userAttributeChange];

    XCTAssertNotNil(messageBuilder);
    message = (MPMessage *)[messageBuilder build];
    XCTAssertNotNil(message);
    
    messageDictionary = [message dictionaryRepresentation];
    XCTAssertEqualObjects(@"uac", messageDictionary[@"dt"]);
    XCTAssertEqualObjects([NSNull null], messageDictionary[@"ov"]);
    XCTAssertEqualObjects([NSNull null], messageDictionary[@"nv"]);
    XCTAssertEqualObjects(@"VIP", messageDictionary[@"n"]);
    XCTAssertEqualObjects(@NO, messageDictionary[@"d"]);
    XCTAssertEqualObjects(@YES, messageDictionary[@"na"]);
}

@end
