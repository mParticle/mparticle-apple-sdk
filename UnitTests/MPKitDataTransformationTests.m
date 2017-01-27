//
//  MPKitDataTransformationTests.m
//
//  Copyright 2017 mParticle, Inc.
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
#import "MPIConstants.h"
#import "MPKitDataTransformation.h"

@interface MPKitDataTransformation()

- (id)transformValue:(NSString *)originalValue dataType:(MPDataType)dataType;

- (NSDictionary *)methodMessageTypeMapping;

@end


@interface MPKitDataTransformationTests : XCTestCase

@property (nonatomic, strong) MPKitDataTransformation *dataTransformation;

@end


@implementation MPKitDataTransformationTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    _dataTransformation = nil;
    
    [super tearDown];
}

- (MPKitDataTransformation *)dataTransformation {
    if (!_dataTransformation) {
        _dataTransformation = [[MPKitDataTransformation alloc] init];
    }
    
    return _dataTransformation;
}

- (void)testAssortedItems {
    NSDictionary *mapping = [self.dataTransformation methodMessageTypeMapping];
    XCTAssertNotNil(mapping);
}


- (void)testValueTransformation {
    id transformedValue;
    
    // String
    transformedValue = [self.dataTransformation transformValue:@"The quick brown fox jumped over the lazy dog" dataType:MPDataTypeString];
    XCTAssertEqual(transformedValue, @"The quick brown fox jumped over the lazy dog");
    XCTAssertTrue([transformedValue isKindOfClass:[NSString class]]);
    
    // Boolean
    transformedValue = [self.dataTransformation transformValue:@"TRue" dataType:MPDataTypeBool];
    XCTAssertEqualObjects(transformedValue, @YES);
    XCTAssertTrue([transformedValue isKindOfClass:[NSNumber class]]);
    
    transformedValue = [self.dataTransformation transformValue:@"FaLSe" dataType:MPDataTypeBool];
    XCTAssertEqualObjects(transformedValue, @NO);
    XCTAssertTrue([transformedValue isKindOfClass:[NSNumber class]]);
    
    transformedValue = [self.dataTransformation transformValue:@"Just a String" dataType:MPDataTypeBool];
    XCTAssertEqualObjects(transformedValue, @NO);
    XCTAssertTrue([transformedValue isKindOfClass:[NSNumber class]]);
    
    // Integer
    transformedValue = [self.dataTransformation transformValue:@"1618033" dataType:MPDataTypeInt];
    XCTAssertEqualObjects(transformedValue, @1618033);
    XCTAssertTrue([transformedValue isKindOfClass:[NSNumber class]]);
    
    transformedValue = [self.dataTransformation transformValue:@"1.618033" dataType:MPDataTypeInt];
    XCTAssertEqualObjects(transformedValue, @1);
    XCTAssertTrue([transformedValue isKindOfClass:[NSNumber class]]);
    
    transformedValue = [self.dataTransformation transformValue:@"An Int string" dataType:MPDataTypeInt];
    XCTAssertEqualObjects(transformedValue, nil);
    
    // Long
    transformedValue = [self.dataTransformation transformValue:@"161803398875" dataType:MPDataTypeLong];
    XCTAssertEqualObjects(transformedValue, @161803398875);
    XCTAssertTrue([transformedValue isKindOfClass:[NSNumber class]]);
    
    transformedValue = [self.dataTransformation transformValue:@"1.618033" dataType:MPDataTypeInt];
    XCTAssertEqualObjects(transformedValue, @1);
    XCTAssertTrue([transformedValue isKindOfClass:[NSNumber class]]);
    
    transformedValue = [self.dataTransformation transformValue:@"A Long string" dataType:MPDataTypeLong];
    XCTAssertEqualObjects(transformedValue, nil);
    
    // Float
    transformedValue = [self.dataTransformation transformValue:@"1.5" dataType:MPDataTypeFloat];
    XCTAssertEqualObjects(transformedValue, @1.5);
    XCTAssertTrue([transformedValue isKindOfClass:[NSNumber class]]);
    
    transformedValue = [self.dataTransformation transformValue:@"A Float string" dataType:MPDataTypeLong];
    XCTAssertEqualObjects(transformedValue, nil);
    
    // Invalid values
    transformedValue = [self.dataTransformation transformValue:nil dataType:MPDataTypeString];
    XCTAssertEqualObjects(transformedValue, nil);
    
    transformedValue = [self.dataTransformation transformValue:(NSString *)[NSNull null] dataType:MPDataTypeString];
    XCTAssertEqualObjects(transformedValue, nil);
    
    transformedValue = [self.dataTransformation transformValue:nil dataType:MPDataTypeBool];
    XCTAssertEqualObjects(transformedValue, @NO);
    XCTAssertTrue([transformedValue isKindOfClass:[NSNumber class]]);
    
    transformedValue = [self.dataTransformation transformValue:(NSString *)[NSNull null] dataType:MPDataTypeBool];
    XCTAssertEqualObjects(transformedValue, @NO);
    XCTAssertTrue([transformedValue isKindOfClass:[NSNumber class]]);
    
    transformedValue = [self.dataTransformation transformValue:nil dataType:MPDataTypeInt];
    XCTAssertEqualObjects(transformedValue, @0);
    XCTAssertTrue([transformedValue isKindOfClass:[NSNumber class]]);
    
    transformedValue = [self.dataTransformation transformValue:(NSString *)[NSNull null] dataType:MPDataTypeInt];
    XCTAssertEqualObjects(transformedValue, @0);
    XCTAssertTrue([transformedValue isKindOfClass:[NSNumber class]]);
    
    transformedValue = [self.dataTransformation transformValue:nil dataType:MPDataTypeLong];
    XCTAssertEqualObjects(transformedValue, @0);
    XCTAssertTrue([transformedValue isKindOfClass:[NSNumber class]]);
    
    transformedValue = [self.dataTransformation transformValue:(NSString *)[NSNull null] dataType:MPDataTypeLong];
    XCTAssertEqualObjects(transformedValue, @0);
    XCTAssertTrue([transformedValue isKindOfClass:[NSNumber class]]);
    
    transformedValue = [self.dataTransformation transformValue:nil dataType:MPDataTypeFloat];
    XCTAssertEqualObjects(transformedValue, @0);
    XCTAssertTrue([transformedValue isKindOfClass:[NSNumber class]]);
    
    transformedValue = [self.dataTransformation transformValue:(NSString *)[NSNull null] dataType:MPDataTypeFloat];
    XCTAssertEqualObjects(transformedValue, @0);
    XCTAssertTrue([transformedValue isKindOfClass:[NSNumber class]]);
}

@end
