//
//  MPMessageBuilderTests.m
//
//  Copyright 2015 mParticle, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <XCTest/XCTest.h>
#import "MPMessageBuilder.h"
#import "MPIConstants.h"
#import "MPSession.h"
#import "MPMessage.h"
#import "MPStandaloneMessage.h"
#import "MPMediaTrack.h"
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

@interface MPMessageBuilderTests : XCTestCase

@property (nonatomic, strong) MPSession *session;

@end

@implementation MPMessageBuilderTests

- (MPSession *)session {
    if (_session) {
        return _session;
    }
    
    _session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970]];
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
    XCTAssertFalse([message isKindOfClass:[MPMessage class]], @"Returning the wrong kind of class instance.");
}

- (void)testBuildStandaloneMessage {
    NSDictionary *messageInfo = @{@"ride_type":@"T-Rex"};
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeEvent
                                                                           session:nil
                                                                       messageInfo:messageInfo];
    
    XCTAssertNotNil(messageBuilder, @"Message builder should not have been nil.");
    MPStandaloneMessage *standaloneMessage = (MPStandaloneMessage *)[messageBuilder build];
    XCTAssertNotNil(standaloneMessage);
    XCTAssertTrue([standaloneMessage isKindOfClass:[MPStandaloneMessage class]], @"Returning the wrong kind of class instance.");
    
    messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeEvent
                                                         session:nil
                                                     messageInfo:nil];
    
    XCTAssertNotNil(messageBuilder, @"Message builder should not have been nil.");
    standaloneMessage = (MPStandaloneMessage *)[messageBuilder build];
    XCTAssertNotNil(standaloneMessage);
    XCTAssertTrue([standaloneMessage isKindOfClass:[MPStandaloneMessage class]], @"Returning the wrong kind of class instance.");
}

- (void)testBuildMediaTrackMessage {
    MPMediaTrack *mediaTrack = [[MPMediaTrack alloc] initWithChannel:@"Jurassic Park"];
    mediaTrack.format = MPMediaTrackFormatVideo;
    mediaTrack.quality = MPMediaTrackQualityMediumDefinition;
    mediaTrack.metadata = @{@"$Director":@[@"Steven Spielberg"],
                            @"$Cast":@[@"Sam Neill", @"Laura Dern", @"Jeff Goldblum"],
                            @"$Genre":@[@"Adventure", @"Sci-Fi"]};
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeEvent
                                                                           session:self.session
                                                                        mediaTrack:mediaTrack
                                                                       mediaAction:MPMediaActionPlay];
    
    XCTAssertNotNil(messageBuilder, @"Message builder should not have been nil.");
    XCTAssertEqualObjects(messageBuilder.messageType, @"e", @"Message type not being set properly.");
    
    MPMessage *message = (MPMessage *)[messageBuilder build];
    XCTAssertNotNil(message, @"MPMessage is not being built.");
    XCTAssertTrue([message isKindOfClass:[MPMessage class]], @"Returning the wrong kind of class instance.");
    XCTAssertNotNil(message.messageData, @"MPMessage has no data.");
    
    MPMediaTrack *nilTrack = nil;
    
    messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeEvent
                                                         session:self.session
                                                      mediaTrack:nilTrack
                                                     mediaAction:MPMediaActionPlay];
    
    XCTAssertNil(messageBuilder, @"Message builder should have been nil.");
}

- (void)testBuildCommerceEventProduct {
    MPProduct *product = [[MPProduct alloc] initWithName:@"DeLorean" sku:@"OutATime" quantity:@1 price:@4.32];
    product.brand = @"DLC";
    product.category = @"Time Machine";
    product.couponCode = @"88mph";
    product.position = 1;
    product.variant = @"It depends";
    product[@"key1"] = @"val1";
    product[@"key_number"] = @1;
    product[@"key_bool"] = @YES;
    
    MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionAddToCart product:product];
    commerceEvent.checkoutOptions = @"option 1";
    commerceEvent.screenName = @"Time Traveling";
    commerceEvent.checkoutStep = 1;
    commerceEvent[@"key_string"] = @"val_string";
    commerceEvent[@"key_number"] = @3.14;
    commerceEvent[@"key_date"] = [NSDate date];
    
    MPCart *cart = [MPCart sharedInstance];
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

@end
