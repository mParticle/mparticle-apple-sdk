//
//  MPMessageTests.m
//  mParticle_iOS_SDKTests
//
//  Created by Jason George on 3/23/21.
//  Copyright © 2021 mParticle, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MPMessage.h"

@interface MPMessageTests : XCTestCase

@end

@implementation MPMessageTests

- (void)testTruncateDataProperty {
    NSDictionary *messageDictionary = @{
        @"location": @"17 Cherry Tree Lane",
        @"hardwareId": @"IDFA:a5d934n0-232f-4afc-2e9a-3832d95zc702"
    };
    NSData *messageData = [NSJSONSerialization dataWithJSONObject:messageDictionary options:0 error:nil];
    MPMessage *message = [[MPMessage alloc] initWithSessionId:@17
                                    messageId:1
                                         UUID:@"uuid"
                                  messageType:@"test"
                                  messageData:messageData
                                    timestamp:[[NSDate date] timeIntervalSince1970]
                                 uploadStatus:MPUploadStatusBatch
                                       userId:@1
                                   dataPlanId:nil
                              dataPlanVersion:nil];
    
    [message truncateMessageDataProperty:@"hardwareId" toLength:5];
    
    NSMutableDictionary *messageDataDict = [NSJSONSerialization JSONObjectWithData:message.messageData options:0 error:nil];
    NSString *propertyValue = messageDataDict[@"hardwareId"];
    XCTAssertEqual(propertyValue.length, 5, @"Failed to truncate data property");
}

- (void)testTruncateDataPropertyNil {
    NSDictionary *messageDictionary = @{
        @"location": @"17 Cherry Tree Lane",
        @"hardwareId": @"IDFA:a5d934n0-232f-4afc-2e9a-3832d95zc702"
    };
    NSData *messageData = [NSJSONSerialization dataWithJSONObject:messageDictionary options:0 error:nil];
    MPMessage *message = [[MPMessage alloc] initWithSessionId:@17
                                    messageId:1
                                         UUID:@"uuid"
                                  messageType:@"test"
                                  messageData:messageData
                                    timestamp:[[NSDate date] timeIntervalSince1970]
                                 uploadStatus:MPUploadStatusBatch
                                       userId:@1
                                   dataPlanId:nil
                              dataPlanVersion:nil];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull" // suppress "null passed to callee that requires a non-null argument" warning for test
    [message truncateMessageDataProperty:nil toLength:5];
#pragma clang diagnostic pop
    
    NSMutableDictionary *messageDataDict = [NSJSONSerialization JSONObjectWithData:message.messageData options:0 error:nil];
    NSString *propertyValue = messageDataDict[@"hardwareId"];
    XCTAssertEqual(propertyValue.length, 41, @"Should not truncate on nil data property");
}

- (void)testTruncateDataPropertyNotFound {
    NSDictionary *messageDictionary = @{
        @"location": @"17 Cherry Tree Lane",
        @"hardwareId": @"IDFA:a5d934n0-232f-4afc-2e9a-3832d95zc702"
    };
    NSData *messageData = [NSJSONSerialization dataWithJSONObject:messageDictionary options:0 error:nil];
    MPMessage *message = [[MPMessage alloc] initWithSessionId:@17
                                    messageId:1
                                         UUID:@"uuid"
                                  messageType:@"test"
                                  messageData:messageData
                                    timestamp:[[NSDate date] timeIntervalSince1970]
                                 uploadStatus:MPUploadStatusBatch
                                       userId:@1
                                   dataPlanId:nil
                              dataPlanVersion:nil];
    
    [message truncateMessageDataProperty:@"notFound" toLength:5];
    
    NSMutableDictionary *messageDataDict = [NSJSONSerialization JSONObjectWithData:message.messageData options:0 error:nil];
    NSString *propertyValue = messageDataDict[@"hardwareId"];
    XCTAssertEqual(propertyValue.length, 41, @"Should not truncate for data property not found");
}

- (void)testTruncateDataPropertyLessThanLength {
    NSDictionary *messageDictionary = @{
        @"location": @"17 Cherry Tree Lane",
        @"hardwareId": @"IDFA:a5d934n0-232f-4afc-2e9a-3832d95zc702"
    };
    NSData *messageData = [NSJSONSerialization dataWithJSONObject:messageDictionary options:0 error:nil];
    MPMessage *message = [[MPMessage alloc] initWithSessionId:@17
                                    messageId:1
                                         UUID:@"uuid"
                                  messageType:@"test"
                                  messageData:messageData
                                    timestamp:[[NSDate date] timeIntervalSince1970]
                                 uploadStatus:MPUploadStatusBatch
                                       userId:@1
                                   dataPlanId:nil
                              dataPlanVersion:nil];
    
    [message truncateMessageDataProperty:@"hardwareId" toLength:100];
    
    NSMutableDictionary *messageDataDict = [NSJSONSerialization JSONObjectWithData:message.messageData options:0 error:nil];
    NSString *propertyValue = messageDataDict[@"hardwareId"];
    XCTAssertEqual(propertyValue.length, 41, @"Should not truncate data property that is less than specified length");
}

- (void)testTruncateDataPropertyToZero {
    NSDictionary *messageDictionary = @{
        @"location": @"17 Cherry Tree Lane",
        @"hardwareId": @"IDFA:a5d934n0-232f-4afc-2e9a-3832d95zc702"
    };
    NSData *messageData = [NSJSONSerialization dataWithJSONObject:messageDictionary options:0 error:nil];
    MPMessage *message = [[MPMessage alloc] initWithSessionId:@17
                                    messageId:1
                                         UUID:@"uuid"
                                  messageType:@"test"
                                  messageData:messageData
                                    timestamp:[[NSDate date] timeIntervalSince1970]
                                 uploadStatus:MPUploadStatusBatch
                                       userId:@1
                                   dataPlanId:nil
                              dataPlanVersion:nil];
    
    [message truncateMessageDataProperty:@"hardwareId" toLength:0];
    
    NSMutableDictionary *messageDataDict = [NSJSONSerialization JSONObjectWithData:message.messageData options:0 error:nil];
    NSString *propertyValue = messageDataDict[@"hardwareId"];
    XCTAssertEqual(propertyValue.length, 0, @"Should not truncate data property that is less than specified length");
}

- (void)testTruncateDataPropertyLessThanZero {
    NSDictionary *messageDictionary = @{
        @"location": @"17 Cherry Tree Lane",
        @"hardwareId": @"IDFA:a5d934n0-232f-4afc-2e9a-3832d95zc702"
    };
    NSData *messageData = [NSJSONSerialization dataWithJSONObject:messageDictionary options:0 error:nil];
    MPMessage *message = [[MPMessage alloc] initWithSessionId:@17
                                    messageId:1
                                         UUID:@"uuid"
                                  messageType:@"test"
                                  messageData:messageData
                                    timestamp:[[NSDate date] timeIntervalSince1970]
                                 uploadStatus:MPUploadStatusBatch
                                       userId:@1
                                   dataPlanId:nil
                              dataPlanVersion:nil];
    
    [message truncateMessageDataProperty:@"hardwareId" toLength:-1];
    
    NSMutableDictionary *messageDataDict = [NSJSONSerialization JSONObjectWithData:message.messageData options:0 error:nil];
    NSString *propertyValue = messageDataDict[@"hardwareId"];
    XCTAssertEqual(propertyValue.length, 41, @"Should not truncate data property on length less than zero");
}

@end
