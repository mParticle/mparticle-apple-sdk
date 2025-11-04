#import <XCTest/XCTest.h>
#import "MPBaseProjection.h"
#import "MPAttributeProjection.h"
#import "MPEventProjection.h"
#import "MPBaseTestCase.h"

@interface MPBase_Attribute_Event_ProjectionTests : MPBaseTestCase

@end

@implementation MPBase_Attribute_Event_ProjectionTests

- (void)testBaseInstanceEvent {
    NSDictionary *configuration = @{@"action":@{@"projected_event_name":@"Projected Event"
                                                },
                                    @"id":@"314",
                                    @"matches":@[@{@"event":@"Non-projected event",
                                              @"event_match_type":@"String"
                                              }]
                                    };
    
    MPBaseProjection *baseProjection = [[MPBaseProjection alloc] initWithConfiguration:configuration projectionType:MPProjectionTypeEvent attributeIndex:0];
    XCTAssertNotNil(baseProjection, @"Should not have been nil");
    XCTAssertEqualObjects(baseProjection.name, @"Non-projected event", @"Should have been equal.");
    XCTAssertEqualObjects(baseProjection.projectedName, @"Projected Event", @"Should have been equal.");
    XCTAssertEqual(baseProjection.projectionId, 314, @"Should have been equal.");
    XCTAssertEqual(baseProjection.propertyKind, MPProjectionPropertyKindEventField, @"Should have been equal.");
    XCTAssertEqual(baseProjection.matchType, MPProjectionMatchTypeString, @"Should have been equal.");
}

- (void)testBaseInstanceAttribute {
    NSDictionary *configuration = @{@"action":@{@"attribute_maps":@[@{@"value":@"original attribute",
                                                                      @"projected_attribute_name":@"projected attribute",
                                                                      @"property":@"EventAttribute"
                                                                      }
                                                                    ]
                                                }
                                    };
    
    MPBaseProjection *baseProjection = [[MPBaseProjection alloc] initWithConfiguration:configuration projectionType:MPProjectionTypeAttribute attributeIndex:0];
    XCTAssertNotNil(baseProjection, @"Should not have been nil");
    XCTAssertEqualObjects(baseProjection.name, @"original attribute", @"Should have been equal.");
    XCTAssertEqualObjects(baseProjection.projectedName, @"projected attribute", @"Should have been equal.");
    XCTAssertEqual(baseProjection.propertyKind, MPProjectionPropertyKindEventAttribute, @"Should have been equal.");
    XCTAssertEqual(baseProjection.matchType, MPProjectionMatchTypeString, @"Should have been equal.");
}

- (void)testBaseCopyAndCoding {
    NSDictionary *configuration = @{@"action":@{@"projected_event_name":@"Projected Event"},
                                    @"id":@"314",
                                    @"matches":@[@{@"event":@"Non-projected event",
                                               @"event_match_type":@"String"}]};
    
    MPBaseProjection *baseProjection = [[MPBaseProjection alloc] initWithConfiguration:configuration projectionType:MPProjectionTypeEvent attributeIndex:0];
    MPBaseProjection *copyProjection = [baseProjection copy];
    XCTAssertNotNil(copyProjection, @"Should not have been nil.");
    XCTAssertEqualObjects(baseProjection, copyProjection, @"Should have been equal.");
    
    NSData *projectionData = [NSKeyedArchiver archivedDataWithRootObject:baseProjection];
    XCTAssertNotNil(projectionData, @"Should not have been nil.");

    MPBaseProjection *deserializedProjection = [NSKeyedUnarchiver unarchiveObjectWithData:projectionData];
    XCTAssertNotNil(deserializedProjection, @"Should not have been nil.");
    XCTAssertEqualObjects(baseProjection, deserializedProjection, @"Should have been equal.");
}

- (void)testInvalidConfiguration {
    NSDictionary *configuration = @{@"action":@{@"projected_event_name":@"Projected Event"
                                                },
                                    @"id":@"314",
                                    @"matches":@[@{@"event":@"Non-projected event",
                                               @"event_match_type":@"This is not even remotely valid",
                                               @"property":@"Same here, this is not valid"
                                                 }]
                                    };
    
    MPBaseProjection *baseProjection = [[MPBaseProjection alloc] initWithConfiguration:configuration projectionType:MPProjectionTypeEvent attributeIndex:0];
    XCTAssertEqual(baseProjection.matchType, MPProjectionMatchTypeString, @"Should have been equal.");
    XCTAssertEqual(baseProjection.propertyKind, MPProjectionPropertyKindEventField, @"Should have been equal.");
}

- (void)testBaseDescription {
    NSDictionary *configuration = @{@"action":@{@"projected_event_name":@"Projected Event"
                                                },
                                    @"id":@"314",
                                    @"matches":@[@{@"event":@"Non-projected event",
                                               @"event_match_type":@"Hash",
                                               @"property":@"ProductField"
                                               }]
                                    };
    
    MPBaseProjection *baseProjection = [[MPBaseProjection alloc] initWithConfiguration:configuration projectionType:MPProjectionTypeEvent attributeIndex:0];
    NSString *description = [baseProjection description];
    XCTAssertNotNil(description, @"Should not have been nil.");
    
    configuration = @{@"action":@{@"attribute_maps":@[@{@"value":@"original attribute",
                                                        @"projected_attribute_name":@"projected attribute",
                                                        @"property":@"ProductAttribute",
                                                        @"match_type":@"Hash"
                                                        }
                                                      ]
                                  }
                      };
    
    baseProjection = [[MPBaseProjection alloc] initWithConfiguration:configuration projectionType:MPProjectionTypeAttribute attributeIndex:0];
    description = [baseProjection description];
    XCTAssertNotNil(description, @"Should not have been nil.");
}

- (void)testAttributeInstance {
    NSDictionary *configuration = @{@"action":@{@"attribute_maps":@[@{@"value":@"original attribute",
                                                                      @"projected_attribute_name":@"projected attribute",
                                                                      @"property":@"EventAttribute",
                                                                      @"data_type":@(MPDataTypeString),
                                                                      @"is_required":@YES
                                                                      }
                                                                    ]
                                                }
                                    };

    MPAttributeProjection *attributeProjection = [[MPAttributeProjection alloc] init];
    XCTAssertNil(attributeProjection, @"Should have been nil.");
    
    attributeProjection = [[MPAttributeProjection alloc] initWithConfiguration:configuration projectionType:MPProjectionTypeAttribute attributeIndex:0];
    XCTAssertNotNil(attributeProjection, @"Should not have been nil");
    XCTAssertEqualObjects(attributeProjection.name, @"original attribute", @"Should have been equal.");
    XCTAssertEqualObjects(attributeProjection.projectedName, @"projected attribute", @"Should have been equal.");
    XCTAssertEqual(attributeProjection.propertyKind, MPProjectionPropertyKindEventAttribute, @"Should have been equal.");
    XCTAssertEqual(attributeProjection.matchType, MPProjectionMatchTypeString, @"Should have been equal.");
    XCTAssertEqual(attributeProjection.dataType, MPDataTypeString, @"Should have been equal.");
    XCTAssertTrue(attributeProjection.required, @"Should have been true.");
    
    attributeProjection.dataType = (MPDataType)200;
    XCTAssertEqual(attributeProjection.dataType, MPDataTypeString, @"Should have been equal.");
    
    configuration = @{@"action":@{@"attribute_maps":@[@{@"value":@"original attribute",
                                                        @"projected_attribute_name":@"projected attribute",
                                                        @"property":@"EventAttribute",
                                                        @"data_type":[NSNull null],
                                                        @"is_required":[NSNull null]
                                                        }
                                                      ]
                                  }
                      };
    
    attributeProjection = [[MPAttributeProjection alloc] initWithConfiguration:configuration projectionType:MPProjectionTypeAttribute attributeIndex:0];
    XCTAssertNotNil(attributeProjection, @"Should not have been nil");
    XCTAssertEqual(attributeProjection.dataType, MPDataTypeString, @"Should have been equal.");
    XCTAssertFalse(attributeProjection.required, @"Should have been false.");
    
    attributeProjection = [[MPAttributeProjection alloc] initWithConfiguration:configuration projectionType:MPProjectionTypeAttribute attributeIndex:1];
    XCTAssertNil(attributeProjection, @"Should have been nil.");
}

- (void)testAttributeEquality {
    NSDictionary *configuration = @{@"action":@{@"attribute_maps":@[@{@"value":@"original attribute",
                                                                      @"projected_attribute_name":@"projected attribute",
                                                                      @"property":@"EventAttribute",
                                                                      @"data_type":@(MPDataTypeString),
                                                                      @"is_required":@YES
                                                                      }
                                                                    ]
                                                }
                                    };
    
    MPAttributeProjection *attributeProjection1 = [[MPAttributeProjection alloc] initWithConfiguration:configuration projectionType:MPProjectionTypeAttribute attributeIndex:0];
    MPAttributeProjection *attributeProjection2 = [[MPAttributeProjection alloc] initWithConfiguration:configuration projectionType:MPProjectionTypeAttribute attributeIndex:0];
    XCTAssertNotNil(attributeProjection1, @"Should not have been nil");
    XCTAssertNotNil(attributeProjection2, @"Should not have been nil");
    XCTAssertEqualObjects(attributeProjection1, attributeProjection2, @"Should have been equal.");
    
    attributeProjection2.required = NO;
    XCTAssertNotEqualObjects(attributeProjection1, attributeProjection2, @"Should not have been equal.");
    
    attributeProjection2 = nil;
    XCTAssertNotEqualObjects(attributeProjection1, attributeProjection2, @"Should not have been equal.");
    XCTAssertNotEqualObjects(attributeProjection2, attributeProjection1, @"Should not have been equal.");
    
    attributeProjection2 = (MPAttributeProjection *)[NSNull null];
    XCTAssertNotEqualObjects(attributeProjection1, attributeProjection2, @"Should not have been equal.");
    XCTAssertNotEqualObjects(attributeProjection2, attributeProjection1, @"Should not have been equal.");
}

- (void)testAttributeCopyAndCoding {
    NSDictionary *configuration = @{@"action":@{@"attribute_maps":@[@{@"value":@"original attribute",
                                                                      @"projected_attribute_name":@"projected attribute",
                                                                      @"property":@"EventAttribute",
                                                                      @"data_type":@(MPDataTypeString),
                                                                      @"is_required":@YES
                                                                      }
                                                                    ]
                                                }
                                    };
    
    MPAttributeProjection *attributeProjection = [[MPAttributeProjection alloc] initWithConfiguration:configuration projectionType:MPProjectionTypeAttribute attributeIndex:0];
    MPAttributeProjection *copyAttributeProjection = [attributeProjection copy];
    XCTAssertEqualObjects(attributeProjection, copyAttributeProjection, @"Should have been equal.");
    
    NSData *attributeProjectionData = [NSKeyedArchiver archivedDataWithRootObject:attributeProjection];
    XCTAssertNotNil(attributeProjectionData, @"Should not have been nil.");
    MPAttributeProjection *deserializedAttributeProjection = [NSKeyedUnarchiver unarchiveObjectWithData:attributeProjectionData];
    XCTAssertEqualObjects(deserializedAttributeProjection, copyAttributeProjection, @"Should have been equal.");
}

- (void)testEventProjection {
    NSDictionary *configuration = @{@"action":@{@"projected_event_name":@"Projected Event",
                                                @"outbound_message_type":@"4"
                                                },
                                    @"id":@"314",
                                    @"matches":@[@{@"event":@"52",
                                               @"event_match_type":@"String",
                                               @"attribute_key":@"aKey",
                                               @"attribute_values":@[@"aValue"]
                                               }],
                                    @"behavior":@{@"append_unmapped_as_is":@YES,
                                                  @"is_default":@NO,
                                                  @"max_custom_params":@42
                                                 }
                                    };
    
    MPEventProjection *eventProjection = [[MPEventProjection alloc] initWithConfiguration:configuration];
    XCTAssertNotNil(eventProjection, @"Should not have been nil");
    XCTAssertEqual(eventProjection.eventType, MPEventTypeTransaction, @"Should have been equal.");
    XCTAssertEqual(eventProjection.messageType, MPMessageTypeEvent, @"Should have been equal.");
    XCTAssertEqual(eventProjection.maxCustomParameters, 42, @"Should have been equal.");
    MPProjectionMatch *projectionMatch = eventProjection.projectionMatches[0];
    XCTAssertEqualObjects(projectionMatch.attributeKey, @"aKey", @"Should have been equal.");
    XCTAssertEqualObjects(projectionMatch.attributeValues[0], @"aValue", @"Should have been equal.");
    XCTAssertTrue(eventProjection.appendAsIs, @"Should have been true.");
    XCTAssertFalse(eventProjection.isDefault, @"Should have been false.");
    
    MPEventProjection *eventProjectionCopy = [eventProjection copy];
    XCTAssertNotNil(eventProjectionCopy, @"Should not have been nil");
    XCTAssertEqualObjects(eventProjection, eventProjectionCopy, @"Should have been equal.");
    MPProjectionMatch *secondProjectionMatch = [[MPProjectionMatch alloc] init];
    secondProjectionMatch.attributeValues = @[@"New value"];
    eventProjectionCopy.projectionMatches = @[secondProjectionMatch];
    XCTAssertNotEqualObjects(eventProjection, eventProjectionCopy, @"Should not have been equal.");
    
    NSData *eventProjectionData = [NSKeyedArchiver archivedDataWithRootObject:eventProjection];
    XCTAssertNotNil(eventProjectionData, @"Should not have been nil");
    MPEventProjection *deserializedEventProjection = [NSKeyedUnarchiver unarchiveObjectWithData:eventProjectionData];
    XCTAssertNotNil(deserializedEventProjection, @"Should not have been nil");
    XCTAssertEqualObjects(eventProjection, deserializedEventProjection, @"Should have been equal.");
    
    eventProjection = [[MPEventProjection alloc] init];
    XCTAssertNil(eventProjection, @"Should have been nil");
}

- (void)testCommerceEventProjection {
    NSDictionary *configuration = @{@"action":@{@"projected_event_name":@"Projected Event",
                                                @"outbound_message_type":@"16"
                                                },
                                    @"id":@"314",
                                    @"matches":@[@{@"event":@"1567",
                                               @"event_match_type":@"String",
                                               @"property_name":@"pName",
                                               @"property_value":@[@"pValue"],
                                               @"message_type":@"16"
                                               }],
                                    @"behavior":@{@"append_unmapped_as_is":@YES,
                                                  @"is_default":@NO,
                                                  @"max_custom_params":@42
                                                  }
                                    };
    
    MPEventProjection *eventProjection = [[MPEventProjection alloc] initWithConfiguration:configuration];
    XCTAssertNotNil(eventProjection, @"Should not have been nil");
    XCTAssertEqual(eventProjection.eventType, MPEventTypeAddToCart, @"Should have been equal.");
    XCTAssertEqual(eventProjection.messageType, MPMessageTypeCommerceEvent, @"Should have been equal.");
    XCTAssertEqual(eventProjection.maxCustomParameters, 42, @"Should have been equal.");
    MPProjectionMatch *firstMatch = eventProjection.projectionMatches[0];
    XCTAssertEqualObjects(firstMatch.attributeKey, @"pName", @"Should have been equal.");
    XCTAssertEqualObjects(firstMatch.attributeValues[0], @"pValue", @"Should have been equal.");
    XCTAssertTrue(eventProjection.appendAsIs, @"Should have been true.");
    XCTAssertFalse(eventProjection.isDefault, @"Should have been false.");
    
    MPEventProjection *eventProjectionCopy = [eventProjection copy];
    XCTAssertNotNil(eventProjectionCopy, @"Should not have been nil");
    XCTAssertEqualObjects(eventProjection, eventProjectionCopy, @"Should have been equal.");
    MPProjectionMatch *match = [[MPProjectionMatch alloc] init];
    match.attributeValues = @[@"New value"];
    eventProjectionCopy.projectionMatches = @[match];
    XCTAssertNotEqualObjects(eventProjection, eventProjectionCopy, @"Should not have been equal.");
    
    NSData *eventProjectionData = [NSKeyedArchiver archivedDataWithRootObject:eventProjection];
    XCTAssertNotNil(eventProjectionData, @"Should not have been nil");
    MPEventProjection *deserializedEventProjection = [NSKeyedUnarchiver unarchiveObjectWithData:eventProjectionData];
    XCTAssertNotNil(deserializedEventProjection, @"Should not have been nil");
    XCTAssertEqualObjects(eventProjection, deserializedEventProjection, @"Should have been equal.");
    
    eventProjection = [[MPEventProjection alloc] init];
    XCTAssertNil(eventProjection, @"Should have been nil");
}

- (void)testIncompleteEventProjections {
    NSDictionary *configuration = @{@"action":@{@"projected_event_name":@"Projected Event",
                                                @"outbound_message_type":@"16"
                                                },
                                    @"id":@"314",
                                    @"matches":[NSNull null],
                                    @"behavior":[NSNull null]
                                    };
    
    MPEventProjection *eventProjection = [[MPEventProjection alloc] initWithConfiguration:configuration];
    XCTAssertNotNil(eventProjection, @"Should not have been nil");
    XCTAssertEqual(eventProjection.eventType, MPEventTypeOther, @"Should have been equal.");
    XCTAssertEqual(eventProjection.messageType, MPMessageTypeEvent, @"Should have been equal.");
    XCTAssertEqual(eventProjection.maxCustomParameters, INT_MAX, @"Should have been equal.");
    XCTAssertNil(eventProjection.projectionMatches, @"Should have been nil.");
    XCTAssertTrue(eventProjection.appendAsIs, @"Should have been true.");
    XCTAssertFalse(eventProjection.isDefault, @"Should have been false.");
    
    configuration = @{@"action":@{@"projected_event_name":@"Projected Event",
                                  @"outbound_message_type":[NSNull null]
                                  },
                      @"id":@"314",
                      @"matches":@[@{@"event":@"1567",
                                 @"event_match_type":@"String",
                                 @"property_name":[NSNull null],
                                 @"property_value":[NSNull null],
                                 @"message_type":@"16"
                                 }],
                      @"behavior":@{@"append_unmapped_as_is":[NSNull null],
                                    @"is_default":[NSNull null],
                                    @"max_custom_params":[NSNull null]
                                    }
                      };
    
    eventProjection = [[MPEventProjection alloc] initWithConfiguration:configuration];
    XCTAssertNotNil(eventProjection, @"Should not have been nil");
    XCTAssertEqual(eventProjection.eventType, MPEventTypeAddToCart, @"Should have been equal.");
    XCTAssertEqual(eventProjection.messageType, MPMessageTypeCommerceEvent, @"Should have been equal.");
    XCTAssertEqual(eventProjection.outboundMessageType, MPMessageTypeEvent, @"Should have been equal.");
    XCTAssertEqual(eventProjection.maxCustomParameters, INT_MAX, @"Should have been equal.");
    XCTAssertNil(eventProjection.projectionMatches, @"Should have been nil.");
    XCTAssertTrue(eventProjection.appendAsIs, @"Should have been true.");
    XCTAssertFalse(eventProjection.isDefault, @"Should have been false.");
}

- (void)testBaseProjectionEncoding {
    NSDictionary *configuration = @{@"action":@{@"projected_event_name":@"Projected Event"
                                                },
                                    @"id":@"314",
                                    @"matches":@[@{@"event":@"Non-projected event",
                                                   @"event_match_type":@"String"
                                                   }]
                                    };
    
    MPBaseProjection *baseProjection = [[MPBaseProjection alloc] initWithConfiguration:configuration projectionType:MPProjectionTypeEvent attributeIndex:0];
    
    MPBaseProjection *persistedBaseProjection = [self attemptSecureEncodingwithClass:[MPBaseProjection class] Object:baseProjection];
    XCTAssertEqualObjects(baseProjection, persistedBaseProjection, @"Base Projection should have been a match.");
}

- (void)testEventProjectionEncoding {
    NSDictionary *configuration = @{@"action":@{@"projected_event_name":@"Projected Event",
                                                @"outbound_message_type":@"4"
                                                },
                                    @"id":@"314",
                                    @"matches":@[@{@"event":@"52",
                                                   @"event_match_type":@"String",
                                                   @"attribute_key":@"aKey",
                                                   @"attribute_values":@[@"aValue"]
                                                   }],
                                    @"behavior":@{@"append_unmapped_as_is":@YES,
                                                  @"is_default":@NO,
                                                  @"max_custom_params":@42
                                                  }
                                    };
    
    MPEventProjection *eventProjection = [[MPEventProjection alloc] initWithConfiguration:configuration];
    
    MPEventProjection *persistedEventProjection = [self attemptSecureEncodingwithClass:[MPEventProjection class] Object:eventProjection];
    XCTAssertEqualObjects(eventProjection, persistedEventProjection, @"Event Projection should have been a match.");
}

- (void)testAttributeProjectionEncoding {
    NSDictionary *configuration = @{@"action":@{@"attribute_maps":@[@{@"value":@"original attribute",
                                                                      @"projected_attribute_name":@"projected attribute",
                                                                      @"property":@"EventAttribute",
                                                                      @"data_type":@(MPDataTypeString),
                                                                      @"is_required":@YES
                                                                      }
                                                                    ]
                                                }
                                    };
    
    MPAttributeProjection *attributeProjection = [[MPAttributeProjection alloc] initWithConfiguration:configuration projectionType:MPProjectionTypeAttribute attributeIndex:0];
    
    MPAttributeProjection *persistedAttributeProjection = [self attemptSecureEncodingwithClass:[MPAttributeProjection class] Object:attributeProjection];
    XCTAssertEqualObjects(attributeProjection, persistedAttributeProjection, @"Attribute Projection should have been a match.");
}

@end
