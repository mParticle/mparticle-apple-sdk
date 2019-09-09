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
#import "MPBaseTestCase.h"
#import "MPStateMachine.h"
#import "OCMock.h"

NSString *const kMPStateInformationKey = @"cs";
NSString *const kMPStateDataConnectionKey = @"dct";

@interface MParticle ()

@property (nonatomic, strong) MPStateMachine *stateMachine;

@end

@interface MPStateMachine ()

@property (nonatomic, strong) MParticleReachability *reachability;

@end

@interface MPMessageBuilderTests : MPBaseTestCase

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
    
    [MParticle sharedInstance].stateMachine = [[MPStateMachine alloc] init];
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
    
    MPMessage *message = [messageBuilder build];
    XCTAssertNotNil(message, @"MPMessage is not being built.");
    XCTAssertTrue([message isKindOfClass:[MPMessage class]], @"Returning the wrong kind of class instance.");
    XCTAssertNotNil(message.messageData, @"MPMessage has no data.");
    
    messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeEvent
                                                         session:nil
                                                     messageInfo:messageInfo];
    
    XCTAssertNotNil(messageBuilder, @"Message builder should not have been nil.");
    
    message = [messageBuilder build];
    XCTAssertTrue([message isKindOfClass:[MPMessage class]], @"Returning the wrong kind of class instance.");
}

- (void)testMessageCurrentStateFields {
    NSDictionary *messageInfo = @{@"key1":@"value1",
                                  @"key2":@"value2",
                                  @"key3":@"value3"};
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeEvent
                                                                           session:self.session
                                                                       messageInfo:messageInfo];
    
    XCTAssertEqualObjects(@"offline", messageBuilder.messageInfo[kMPStateInformationKey][kMPStateDataConnectionKey]);
}

- (void)testMessageCurrentStateFieldsWWAN {
    MPStateMachine *stateMachine = [[MPStateMachine alloc] init];
    id mockStateMachine = OCMPartialMock(stateMachine);
    
    [[[mockStateMachine stub] andReturnValue:OCMOCK_VALUE(MParticleNetworkStatusReachableViaWAN)] networkStatus];

    MParticle *instance = [MParticle sharedInstance];
    id mockInstance = OCMPartialMock(instance);
    [[[mockInstance stub] andReturn:mockStateMachine] stateMachine];
    [[[mockInstance stub] andReturn:mockInstance] sharedInstance];
    
    NSDictionary *messageInfo = @{@"key1":@"value1",
                                  @"key2":@"value2",
                                  @"key3":@"value3"};
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeEvent
                                                                           session:self.session
                                                                       messageInfo:messageInfo];
    
    XCTAssertEqualObjects(@"mobile", messageBuilder.messageInfo[kMPStateInformationKey][kMPStateDataConnectionKey]);
    
    [mockStateMachine stopMocking];
    [mockInstance stopMocking];
}

- (void)testMessageCurrentStateFieldsWifi {
    MPStateMachine *stateMachine = [[MPStateMachine alloc] init];
    id mockStateMachine = OCMPartialMock(stateMachine);
    
    [[[mockStateMachine stub] andReturnValue:OCMOCK_VALUE(MParticleNetworkStatusReachableViaWiFi)] networkStatus];
    
    MParticle *instance = [MParticle sharedInstance];
    id mockInstance = OCMPartialMock(instance);
    [[[mockInstance stub] andReturn:mockStateMachine] stateMachine];
    [[[mockInstance stub] andReturn:mockInstance] sharedInstance];
    
    NSDictionary *messageInfo = @{@"key1":@"value1",
                                  @"key2":@"value2",
                                  @"key3":@"value3"};
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeEvent
                                                                           session:self.session
                                                                       messageInfo:messageInfo];
    
    XCTAssertEqualObjects(@"wifi", messageBuilder.messageInfo[kMPStateInformationKey][kMPStateDataConnectionKey]);
    
    [mockStateMachine stopMocking];
    [mockInstance stopMocking];
}

- (void)testMessageCurrentStateFieldsOffline {
    MPStateMachine *stateMachine = [[MPStateMachine alloc] init];
    id mockStateMachine = OCMPartialMock(stateMachine);
    
    [[[mockStateMachine stub] andReturnValue:OCMOCK_VALUE(MParticleNetworkStatusNotReachable)] networkStatus];
    
    MParticle *instance = [MParticle sharedInstance];
    id mockInstance = OCMPartialMock(instance);
    [[[mockInstance stub] andReturn:mockStateMachine] stateMachine];
    [[[mockInstance stub] andReturn:mockInstance] sharedInstance];
    
    NSDictionary *messageInfo = @{@"key1":@"value1",
                                  @"key2":@"value2",
                                  @"key3":@"value3"};
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeEvent
                                                                           session:self.session
                                                                       messageInfo:messageInfo];
    
    XCTAssertEqualObjects(@"offline", messageBuilder.messageInfo[kMPStateInformationKey][kMPStateDataConnectionKey]);
    
    [mockStateMachine stopMocking];
    [mockInstance stopMocking];
}

- (void)testEncodingandDecodingMessage {
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
    
    MPMessage *message = [messageBuilder build];
    XCTAssertNotNil(message, @"MPMessage is not being built.");
    XCTAssertTrue([message isKindOfClass:[MPMessage class]], @"Returning the wrong kind of class instance.");
    XCTAssertNotNil(message.messageData, @"MPMessage has no data.");
    
    messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeEvent
                                                         session:nil
                                                     messageInfo:messageInfo];
    
    XCTAssertNotNil(messageBuilder, @"Message builder should not have been nil.");
    
    message = [messageBuilder build];
    XCTAssertTrue([message isKindOfClass:[MPMessage class]], @"Returning the wrong kind of class instance.");
    
    NSData *messageData = [NSKeyedArchiver archivedDataWithRootObject:message];
    MPMessage *messageFromData = [NSKeyedUnarchiver unarchiveObjectWithData:messageData];
    
    XCTAssertEqualObjects(message.sessionId, messageFromData.sessionId);
    XCTAssertEqualObjects(message.messageType, messageFromData.messageType);
    XCTAssertEqualObjects(message.messageData, messageFromData.messageData);
    XCTAssertEqual(message.timestamp, messageFromData.timestamp);
    XCTAssertEqual(message.messageId, messageFromData.messageId);
    XCTAssertEqualObjects(message.userId, messageFromData.userId);
    XCTAssertEqual(message.uploadStatus, messageFromData.uploadStatus);
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
    commerceEvent.customAttributes = @{@"key_string": @"val_string", @"key_number": @"3.14", @"key_date": @"01/01/2000"};
    
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
                                                                     messageInfo:commerceEvent.customAttributes];
    
    XCTAssertNotNil(messageBuilder, @"Message builder should not have been nil.");
    XCTAssertEqualObjects(messageBuilder.messageType, @"cm", @"Incorrect message type.");
    
    MPMessage *message = [messageBuilder build];
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
                                                                     messageInfo:commerceEvent.customAttributes];
    
    XCTAssertNotNil(messageBuilder, @"Message builder should not have been nil.");
    XCTAssertEqualObjects(messageBuilder.messageType, @"cm", @"Incorrect message type.");
    
    MPMessage *message = [messageBuilder build];
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
    MPMessage *message = [messageBuilder build];
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
    message = [messageBuilder build];
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
    message = [messageBuilder build];
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
    message = [messageBuilder build];
    XCTAssertNotNil(message);
    
    messageDictionary = [message dictionaryRepresentation];
    XCTAssertEqualObjects(@"uac", messageDictionary[@"dt"]);
    XCTAssertEqualObjects([NSNull null], messageDictionary[@"ov"]);
    XCTAssertEqualObjects([NSNull null], messageDictionary[@"nv"]);
    XCTAssertEqualObjects(@"VIP", messageDictionary[@"n"]);
    XCTAssertEqualObjects(@NO, messageDictionary[@"d"]);
    XCTAssertEqualObjects(@YES, messageDictionary[@"na"]);
}

- (void)testMessageTypeNameConversions {
    
    for (int i = 0; i < MPMessageTypeUserIdentityChange; i++) {
        
        MPMessageType expectedType = (MPMessageType)i;
        
        if (expectedType == MPMessageTypePreAttribution) {
            expectedType = MPMessageTypeUnknown;
        }
        
        XCTAssertEqual(expectedType, [MPMessageBuilder messageTypeForString:[MPMessageBuilder stringForMessageType:(MPMessageType)i]]);
        
    }
    
}

@end
