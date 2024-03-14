#import <XCTest/XCTest.h>
#import "MPIntegrationAttributes.h"
#import "MPEnums.h"
#import "MPBaseTestCase.h"

@interface MPIntegrationAttributesTest : MPBaseTestCase

@end


@implementation MPIntegrationAttributesTest

- (void)testInstance {
    NSNumber *integrationId = @(MPKitInstanceUrbanAirship);
    NSDictionary<NSString *, NSString *> *attributes = @{@"key":@"value"};
    MPIntegrationAttributes *integrationAttributes = [[MPIntegrationAttributes alloc] initWithIntegrationId:integrationId attributes:attributes];
    XCTAssertNotNil(integrationAttributes);
    XCTAssertEqualObjects(integrationAttributes.integrationId, @(MPKitInstanceUrbanAirship));
    XCTAssertEqualObjects(integrationAttributes.attributes, @{@"key":@"value"});
}

- (void)testDataInstance {
    NSNumber *integrationId = @(MPKitInstanceUrbanAirship);
    NSDictionary<NSString *, NSString *> *attributes = @{@"key":@"value"};
    MPIntegrationAttributes *integrationAttributes = [[MPIntegrationAttributes alloc] initWithIntegrationId:integrationId attributes:attributes];
    NSData *attributesData = [NSJSONSerialization dataWithJSONObject:integrationAttributes.attributes options:0 error:nil];
    
    MPIntegrationAttributes *integrationAttributes2 = [[MPIntegrationAttributes alloc] initWithIntegrationId:integrationId attributesData:attributesData];
    XCTAssertNotNil(integrationAttributes2);
    
    attributesData = nil;
    integrationAttributes2 = [[MPIntegrationAttributes alloc] initWithIntegrationId:integrationId attributesData:attributesData];
    XCTAssertNil(integrationAttributes2);
    
    attributesData = (NSData *)[NSNull null];
    integrationAttributes2 = [[MPIntegrationAttributes alloc] initWithIntegrationId:integrationId attributesData:attributesData];
    XCTAssertNil(integrationAttributes2);
}

- (void)testNonKitInstance {
    NSNumber *integrationId = @(9999);
    NSDictionary<NSString *, NSString *> *attributes = @{@"key":@"value"};
    MPIntegrationAttributes *integrationAttributes = [[MPIntegrationAttributes alloc] initWithIntegrationId:integrationId attributes:attributes];
    XCTAssertNotNil(integrationAttributes);
}
- (void)testInvalidInstance {
    NSNumber *integrationId = nil;
    NSDictionary<NSString *, NSString *> *attributes = @{@"key":@"value"};
    MPIntegrationAttributes *integrationAttributes = [[MPIntegrationAttributes alloc] initWithIntegrationId:integrationId attributes:attributes];
    XCTAssertNil(integrationAttributes);
    
    integrationId = (NSNumber *)@"This is not a number";
    integrationAttributes = [[MPIntegrationAttributes alloc] initWithIntegrationId:integrationId attributes:attributes];
    XCTAssertNil(integrationAttributes);
    
    integrationId = @(MPKitInstanceUrbanAirship);
    attributes = nil;
    integrationAttributes = [[MPIntegrationAttributes alloc] initWithIntegrationId:integrationId attributes:attributes];
    XCTAssertNil(integrationAttributes);
    
    attributes = @{@"pi":(NSString *)@314};
    integrationAttributes = [[MPIntegrationAttributes alloc] initWithIntegrationId:integrationId attributes:attributes];
    XCTAssertNil(integrationAttributes);
    
    attributes = @{(NSString *)@628:@"tau"};
    integrationAttributes = [[MPIntegrationAttributes alloc] initWithIntegrationId:integrationId attributes:attributes];
    XCTAssertNil(integrationAttributes);
    
    attributes = (NSDictionary *)[NSNull null];
    integrationAttributes = [[MPIntegrationAttributes alloc] initWithIntegrationId:integrationId attributes:attributes];
    XCTAssertNil(integrationAttributes);
}

- (void)testDictionaryRepresentation {
    NSNumber *integrationId = @(MPKitInstanceUrbanAirship);
    NSDictionary<NSString *, NSString *> *attributes = @{@"key":@"value"};
    MPIntegrationAttributes *integrationAttributes = [[MPIntegrationAttributes alloc] initWithIntegrationId:integrationId attributes:attributes];
    NSDictionary *dictionaryRepresentation = [integrationAttributes dictionaryRepresentation];
    XCTAssertNotNil(dictionaryRepresentation);
    
    NSDictionary *referenceDictionary = @{[@(MPKitInstanceUrbanAirship) stringValue]:@{@"key":@"value"}};
    XCTAssertEqualObjects(dictionaryRepresentation, referenceDictionary);
}

- (void)testSerialization {
    NSNumber *integrationId = @(MPKitInstanceUrbanAirship);
    NSDictionary<NSString *, NSString *> *attributes = @{@"key":@"value"};
    MPIntegrationAttributes *integrationAttributes = [[MPIntegrationAttributes alloc] initWithIntegrationId:integrationId attributes:attributes];
    NSString *serializedString = [integrationAttributes serializedString];
    XCTAssertNotNil(serializedString);
}

@end
