#import <XCTest/XCTest.h>
#import "MPDataPlanFilter.h"

@interface MPDataPlanFilterTests : XCTestCase {
    MPDataPlanFilter *adapter;
    MPDataPlanFilter *noBlockAdapter;
    MPDataPlanFilter *additionalAttrsAdapter;
}
@end

@implementation MPDataPlanFilterTests

- (void)setUp {
    [super setUp];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    NSDictionary *plan = @{@"version_document":@{@"data_points":@[@{@"match":@{@"type":@"custom_event",@"criteria":@{@"event_name":@"Email Bounces",@"custom_event_type":@"other"} }, @"validator":@{@"definition":@{@"properties":@{@"data":@{@"properties":@{@"custom_attributes":@{@"additionalProperties": @NO, @"properties":@{@"Campaign Name": @{}, @"Campaign Id": @{}}}}}}}}}]}};
    
    MPDataPlanOptions *dataplanOptions = [MPDataPlanOptions alloc];
    dataplanOptions.dataPlan = plan;
    dataplanOptions.blockEventAttributes = YES;
    dataplanOptions.blockEvents = YES;
    dataplanOptions.blockUserAttributes = YES;
    dataplanOptions.blockUserIdentities = YES;
    adapter = [[MPDataPlanFilter alloc] initWithDataPlanOptions:dataplanOptions];
    
    MPDataPlanOptions *noBlockDataplanOptions = [MPDataPlanOptions alloc];
    dataplanOptions.dataPlan = plan;
    noBlockDataplanOptions.blockEventAttributes = NO;
    noBlockDataplanOptions.blockEvents = NO;
    noBlockDataplanOptions.blockUserAttributes = NO;
    noBlockDataplanOptions.blockUserIdentities = NO;
    noBlockAdapter = [[MPDataPlanFilter alloc] initWithDataPlanOptions:noBlockDataplanOptions];
    
    MPDataPlanOptions *addAttrsDataplanOptions = [MPDataPlanOptions alloc];
    addAttrsDataplanOptions.dataPlan = plan;
    addAttrsDataplanOptions.blockEventAttributes = YES;
    addAttrsDataplanOptions.blockEvents = YES;
    addAttrsDataplanOptions.blockUserAttributes = YES;
    addAttrsDataplanOptions.blockUserIdentities = YES;
    additionalAttrsAdapter = [[MPDataPlanFilter alloc] initWithDataPlanOptions:addAttrsDataplanOptions];
}

#pragma mark - Malformed data plan documents

// Every one of these shapes reaches a subscript or a boolValue/length send in the document
// traversal, so each has to be skipped rather than messaged.
- (NSArray *)malformedDataPlans {
    return @[
             @"Not a dictionary.",
             @5,
             @{@"version_document":@"Not a dictionary."},
             @{@"version_document":@[]},
             @{@"version_document":@{@"data_points":@"Not an array."}},
             @{@"version_document":@{@"data_points":@{@"a":@"b"}}},
             @{@"version_document":@{@"data_points":@[@1, @"Not a dictionary.", [NSNull null], @[]]}},
             @{@"version_document":@{@"data_points":@[@{@"match":@"Not a dictionary."}]}},
             @{@"version_document":@{@"data_points":@[@{@"match":@[]}]}},
             @{@"version_document":@{@"data_points":@[@{@"match":@{@"type":@"custom_event", @"criteria":@"Not a dictionary."}}]}},
             @{@"version_document":@{@"data_points":@[@{@"match":@{@"type":@"custom_event", @"criteria":@{@"event_name":@5, @"custom_event_type":@7}}}]}},
             @{@"version_document":@{@"data_points":@[@{@"match":@{@"type":@"screen_view", @"criteria":@{@"screen_name":@5}}}]}},
             @{@"version_document":@{@"data_points":@[@{@"match":@{@"type":@"product_action", @"criteria":@{@"action":@[]}}}]}},
             @{@"version_document":@{@"data_points":@[@{@"match":@{@"type":@"promotion_action", @"criteria":@{@"action":[NSNull null]}}}]}},
             @{@"version_document":@{@"data_points":@[@{@"match":@{@"type":@"user_attributes"}, @"validator":@"Not a dictionary."}]}},
             @{@"version_document":@{@"data_points":@[@{@"match":@{@"type":@"user_attributes"}, @"validator":@{@"definition":@"Not a dictionary."}}]}},
             @{@"version_document":@{@"data_points":@[@{@"match":@{@"type":@"user_identities"}, @"validator":@{@"definition":@"Not a dictionary."}}]}},
             @{@"version_document":@{@"data_points":@[@{@"match":@{@"type":@"user_identities"}, @"validator":@{@"definition":@{@"properties":@"Not a dictionary."}}}]}},
             @{@"version_document":@{@"data_points":@[@{@"match":@{@"type":@"user_attributes"}, @"validator":@{@"definition":@{@"additionalProperties":@[], @"properties":@{@"a":@{}}}}}]}},
             @{@"version_document":@{@"data_points":@[@{@"match":@{@"type":@"user_attributes"}, @"validator":@{@"definition":@{@"additionalProperties":[NSNull null], @"properties":@{@"a":@{}}}}}]}},
             @{@"version_document":@{@"data_points":@[@{@"match":@{@"type":@"custom_event", @"criteria":@{@"event_name":@"Email Bounces", @"custom_event_type":@"other"}}, @"validator":@{@"definition":@{@"properties":@{@"data":@"Not a dictionary."}}}}]}},
             @{@"version_document":@{@"data_points":@[@{@"match":@{@"type":@"product_impression"}, @"validator":@{@"definition":@{@"properties":@{@"data":@{@"properties":@{@"product_impressions":@{@"items":@"Not a dictionary."}}}}}}}]}},
             @{@"version_document":@{@"data_points":@[@{@"match":@{@"type":@"product_action"}, @"validator":@{@"definition":@{@"properties":@{@"data":@{@"properties":@{@"product_action":@{@"properties":@{@"products":@{@"items":@5}}}}}}}}}]}}
             ];
}

- (MPDataPlanFilter *)blockingFilterForDataPlan:(id)plan {
    MPDataPlanOptions *options = [[MPDataPlanOptions alloc] init];
    options.dataPlan = plan;
    options.blockEvents = YES;
    options.blockEventAttributes = YES;
    options.blockUserAttributes = YES;
    options.blockUserIdentities = YES;
    return [[MPDataPlanFilter alloc] initWithDataPlanOptions:options];
}

- (void)testMalformedDataPlanDoesNotThrowWhileParsing {
    for (id plan in [self malformedDataPlans]) {
        MPDataPlanFilter *filter = nil;
        XCTAssertNoThrow(filter = [self blockingFilterForDataPlan:plan], @"Threw while parsing %@.", plan);
        XCTAssertNotNil(filter, @"Should not have been nil.");
    }
}

// A shape skipped during parsing must not leave a sentinel behind that raises on first use.
- (void)testMalformedDataPlanDoesNotThrowWhileFiltering {
    for (id plan in [self malformedDataPlans]) {
        MPDataPlanFilter *filter = [self blockingFilterForDataPlan:plan];
        
        XCTAssertNoThrow([filter isBlockedUserAttributeKey:@"Campaign Name"], @"Threw for %@.", plan);
        XCTAssertNoThrow([filter isBlockedUserIdentityType:MPIdentityCustomerId], @"Threw for %@.", plan);
        
        MPEvent *event = [[MPEvent alloc] initWithName:@"Email Bounces" type:MPEventTypeOther];
        event.customAttributes = @{@"Campaign Name":@"Test"};
        XCTAssertNoThrow([filter transformEventForEvent:event], @"Threw for %@.", plan);
        
        MPEvent *screenEvent = [[MPEvent alloc] initWithName:@"Screen" type:MPEventTypeNavigation];
        XCTAssertNoThrow([filter transformEventForScreenEvent:screenEvent], @"Threw for %@.", plan);
    }
}

// No attribute custom event tests
- (void)testNoBlockPlannedCustomEventNameType {
    MPEvent *plannedEvent = [[MPEvent alloc] initWithName:@"Email Bounces" type:MPEventTypeOther];
    XCTAssertEqualObjects([adapter transformEventForEvent:plannedEvent], plannedEvent);
}

- (void)testBlockUnplannedCustomEventName {
    MPEvent *unplannedNameEvent = [[MPEvent alloc] initWithName:@"Email Bounced" type:MPEventTypeOther];
    XCTAssertNil([adapter transformEventForEvent:unplannedNameEvent]);
}

- (void)testDisableBlockUnplannedCustomEventName {
    MPEvent *unplannedNameEvent = [[MPEvent alloc] initWithName:@"Email Bounced" type:MPEventTypeOther];
    XCTAssertEqualObjects([noBlockAdapter transformEventForEvent:unplannedNameEvent], unplannedNameEvent);
}

- (void)testBlockUnplannedCustomEventType {
    MPEvent *unplannedTypeEvent = [[MPEvent alloc] initWithName:@"Email Bounces" type:MPEventTypeSearch];
    XCTAssertNil([adapter transformEventForEvent:unplannedTypeEvent]);
}

- (void)testDisableBlockUnplannedCustomEventType {
    MPEvent *unplannedTypeEvent = [[MPEvent alloc] initWithName:@"Email Bounces" type:MPEventTypeSearch];
    XCTAssertEqualObjects([noBlockAdapter transformEventForEvent:unplannedTypeEvent], unplannedTypeEvent);
}

// Attribute custom event tests
- (void)testNoBlockPlannedCustomEventAttrs {
    NSDictionary *plannedAttributes = @{@"Campaign Name":@"foo",@"Campaign Id":@"bar"};
    MPEvent *plannedEvent = [[MPEvent alloc] initWithName:@"Email Bounces" type:MPEventTypeOther];
    plannedEvent.customAttributes = plannedAttributes;
    XCTAssertEqualObjects([adapter transformEventForEvent:plannedEvent], plannedEvent);
}

- (void)testBlockUnplannedCustomEventAttrs {
    NSDictionary *partlyUnplannedAttributes = @{@"Campaign Name":@"foo",@"Champain Id":@"bar"};
    MPEvent *partlyUnplannedAttrEvent = [[MPEvent alloc] initWithName:@"Email Bounces" type:MPEventTypeOther];
    partlyUnplannedAttrEvent.customAttributes = partlyUnplannedAttributes;
    
    MPEvent *expectedResultEvent = [[MPEvent alloc] initWithName:@"Email Bounces" type:MPEventTypeOther];
    expectedResultEvent.customAttributes = @{@"Campaign Name":@"foo"};
    XCTAssertEqualObjects([adapter transformEventForEvent:partlyUnplannedAttrEvent], expectedResultEvent);
}

- (void)testDisableBlockUnplannedCustomEventAttrs {
    NSDictionary *partlyUnplannedAttributes = @{@"Campaign Name":@"foo",@"Champain Id":@"bar"};
    MPEvent *partlyUnplannedAttrEvent = [[MPEvent alloc] initWithName:@"Email Bounces" type:MPEventTypeOther];
    partlyUnplannedAttrEvent.customAttributes = partlyUnplannedAttributes;
    XCTAssertEqualObjects([noBlockAdapter transformEventForEvent:partlyUnplannedAttrEvent], partlyUnplannedAttrEvent);
}

- (void)testDisableBlockUnplannedCustomEventAttrsAdditionalAttrs {
    NSDictionary *partlyUnplannedAttributes = @{@"Campaign Name":@"foo",@"Champain Id":@"bar"};
    MPEvent *partlyUnplannedAttrEvent = [[MPEvent alloc] initWithName:@"Email Bounces" type:MPEventTypeOther];
    partlyUnplannedAttrEvent.customAttributes = partlyUnplannedAttributes;
    XCTAssertEqualObjects([additionalAttrsAdapter transformEventForEvent:partlyUnplannedAttrEvent], partlyUnplannedAttrEvent);
}

#pragma mark Unconstrained user points

- (MPDataPlanFilter *)filterWithUnconstrainedUserPointsBlocking:(BOOL)blocking {
    NSDictionary *plan = @{@"version_document":@{@"data_points":@[
        @{@"match":@{@"type":@"user_attributes"},
          @"validator":@{@"definition":@{@"additionalProperties":@YES,
                                         @"properties":@{@"planned attribute":@{}}}}},
        @{@"match":@{@"type":@"user_identities"},
          @"validator":@{@"definition":@{@"additionalProperties":@YES,
                                         @"properties":@{@"7":@{}}}}}
    ]}};

    MPDataPlanOptions *options = [[MPDataPlanOptions alloc] init];
    options.dataPlan = plan;
    options.blockUserAttributes = blocking;
    options.blockUserIdentities = blocking;

    return [[MPDataPlanFilter alloc] initWithDataPlanOptions:options];
}

- (void)testUnconstrainedUserPointsAreStoredAsTheNullSentinel {
    NSDictionary *pointInfo = [[self filterWithUnconstrainedUserPointsBlocking:YES] getPointInfo];

    XCTAssertTrue((NSNull *)pointInfo[@"user_attributes"] == [NSNull null]);
    XCTAssertTrue((NSNull *)pointInfo[@"user_identities"] == [NSNull null]);
}

- (void)testUnconstrainedUserPointsBlockNothingWhenBlockingIsOff {
    MPDataPlanFilter *filter = [self filterWithUnconstrainedUserPointsBlocking:NO];

    XCTAssertFalse([filter isBlockedUserAttributeKey:@"any attribute"]);
    XCTAssertFalse([filter isBlockedUserIdentityType:MPIdentityEmail]);
}

- (void)testUnconstrainedUserPointsBlockNothingWhenBlockingIsOn {
    MPDataPlanFilter *filter = [self filterWithUnconstrainedUserPointsBlocking:YES];

    XCTAssertFalse([filter isBlockedUserAttributeKey:@"any attribute"]);
    XCTAssertFalse([filter isBlockedUserIdentityType:MPIdentityEmail]);
}

@end



@interface MPKDataPlanFilterCommonTests : XCTestCase {
    MPDataPlanOptions *dataplanOptions;
}
@end

@implementation MPKDataPlanFilterCommonTests

-(void)setUp {
    [super setUp];
    
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"sample_dataplan2" ofType:@"json"];
    NSString *jsonString = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    NSData * jsonData = [jsonString dataUsingEncoding:0];
    NSError * error = nil;
    NSDictionary *dataplan = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];
    dataplanOptions = [MPDataPlanOptions alloc];
    dataplanOptions.dataPlan = dataplan;
    dataplanOptions.blockEventAttributes = YES;
    dataplanOptions.blockEvents = YES;
    dataplanOptions.blockUserIdentities = YES;
    dataplanOptions.blockUserAttributes = YES;
}

-(void)testParsing {
    MPDataPlanFilter *adapter = [[MPDataPlanFilter alloc]initWithDataPlanOptions:dataplanOptions];
    NSDictionary<NSString *, NSArray<NSString *> *> *pointInfo = adapter.getPointInfo;
    NSArray<NSString *> *array;
    XCTAssertEqual(27, pointInfo.count);
    XCTAssertTrue((NSArray *)[NSNull null] == pointInfo[@"custom_event.Search Event.search"]);
    array = [[NSArray alloc] initWithObjects:@"foo", @"foo foo", @"foo number", nil];
    [self XCTAssertEqualUnorderedLists:array other:(NSArray *)pointInfo[@"custom_event.locationEvent.location"]];
    array = [[NSArray alloc] initWithObjects:
             @"attributeNumMinMax",
             @"attributeEmail",
             @"attributeNumEnum",
             @"attributeStringAlpha",
             @"attributeBoolean",
             nil];
    [self XCTAssertEqualUnorderedLists:array other:pointInfo[@"product_action.addtocart"]];
    XCTAssertTrue((NSArray *)[NSNull null] == pointInfo[@"product_action.addtocart.product_action_product"]);
    XCTAssertTrue((NSArray *)[NSNull null] == pointInfo[@"product_action.addtocart.product_impression_product"]);
    array = [[NSArray alloc] initWithObjects:@"not required", @"required", nil];
    [self XCTAssertEqualUnorderedLists:array other:pointInfo[@"promotion_action.view"]];
    XCTAssertTrue((NSArray *)[NSNull null] == pointInfo[@"promotion_action.view.product_action_product"]);
    XCTAssertTrue((NSArray *)[NSNull null] == pointInfo[@"promotion_action.view.product_impression_product"]);
    XCTAssertTrue((NSArray *)[NSNull null] == pointInfo[@"custom_event.TestEvent.navigation"]);
    XCTAssertTrue((NSArray *)[NSNull null] == pointInfo[@"screen_view.A New ScreenViewEvent"]);
            
    array = [[NSArray alloc] initWithObjects:@"test1key", @"test2key", nil];
    [self XCTAssertEqualUnorderedLists:array other:pointInfo[@"screen_view.my screeeen"]];
    
    XCTAssertTrue((NSArray *)[NSNull null] == pointInfo[@"custom_event.something something something.navigation"]);
                
    array = [[NSArray alloc] initWithObjects:@"my attribute", @"my other attribute", @"a third attribute", nil];
    [self XCTAssertEqualUnorderedLists:array other:pointInfo[@"user_attributes"]];
                
    XCTAssertTrue((NSArray *)[NSNull null] == pointInfo[@"user_identities"]);
                
    array = [[NSArray alloc] init];
    [self XCTAssertEqualUnorderedLists:array other:pointInfo[@"custom_event.SocialEvent.social"]];
                
    array = [[NSArray alloc] initWithObjects:@"eventAttribute1",@"eventAttribute2", nil];
    [self XCTAssertEqualUnorderedLists:array other:pointInfo[@"product_action.purchase"]];
               
    array = [[NSArray alloc] initWithObjects:@"plannedAttr1", @"plannedAttr2", nil];
    [self XCTAssertEqualUnorderedLists:array  other:pointInfo[@"product_action.purchase.product_action_product"]];
                
    XCTAssertTrue((NSArray *)[NSNull null] == pointInfo[@"product_action.purchase.product_impression_product"]);
                
    array = [[NSArray alloc] initWithObjects:@"eventAttribute1", @"eventAttribute2", nil];
    [self XCTAssertEqualUnorderedLists:array other:pointInfo[@"promotion_action.click"]];
                
    [self XCTAssertEqualUnorderedLists:[[NSArray alloc] init] other:pointInfo[@"promotion_action.click.product_action_product"]];
                
    XCTAssertTrue((NSArray *)[NSNull null] == pointInfo[@"promotion_action.click.product_impression_product"]);
                
    array = [[NSArray alloc] initWithObjects:@"thing1", nil];
    [self XCTAssertEqualUnorderedLists:array other:pointInfo[@"product_impression"]];
        
    XCTAssertTrue((NSArray *)[NSNull null] == pointInfo[@"product_impression.product_action_product"]);
    XCTAssertTrue((NSArray *)[NSNull null] == pointInfo[@"product_impression.product_impression_product"]);
    
    array = [[NSArray alloc] initWithObjects:@"com_attribute_1", @"com_attribute_2", nil];
    [self XCTAssertEqualUnorderedLists:array other:pointInfo[@"product_action.removefromwishlist"]];
    
    array = [[NSArray alloc] initWithObjects:@"impr_prod_attribute2", @"impr_prod_attribute1", nil];
    [self XCTAssertEqualUnorderedLists:array
                                 other:pointInfo[@"product_action.removefromwishlist.product_impression_product"]];
    array = [[NSArray alloc] initWithObjects:@"prodact_prod_attribute1", @"prodact_prod_attribute2", nil];
    [self XCTAssertEqualUnorderedLists:array
                                 other:pointInfo[@"product_action.removefromwishlist.product_action_product"]];
}

- (void) XCTAssertEqualUnorderedLists:(NSArray *)array other:(NSArray *)other {
    XCTAssertEqualObjects([array sortedArrayUsingSelector:@selector(compare:)], [other sortedArrayUsingSelector:@selector(compare:)]);
}
@end
