//
//  ZipTests.mm
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
#import "Zip.h"

@interface ZipTests : XCTestCase

@end

@implementation ZipTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testCompressAndExpand {
    NSString *originalString = @"The quick brown fox jumps over the lazy dog. 1234567890 <!@#$%^&*(){}[];:> œ∑´®†¥¨ˆøπ“‘«æ…¬˚∆˙©ƒ∂ßåΩ≈ç√∫˜µ≤≥÷. ⁄€‹›ﬁﬂ‡°·‚—±»’”∏Øˆ¨Áˇ‰´„ŒÅÍÎÏ˝ÓÔÒÚÆ¿˘¯Â˜ı◊Ç˛¸ Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc orci sapien, imperdiet eu condimentum at, consequat ut nisi. Duis sodales sapien eu congue cursus. Donec arcu lacus, congue sed vestibulum at, vulputate eget felis. Aenean faucibus metus et urna tempus volutpat. Phasellus ac lacus condimentum augue dictum laoreet vitae non mi. Phasellus arcu enim, sodales vel tristique laoreet, accumsan ac sem. Etiam vehicula mauris tristique egestas mollis. Maecenas molestie feugiat nulla quis fringilla. Nullam id turpis ante. Pellentesque neque sapien, viverra quis scelerisque et, consequat sit amet nibh. Duis sodales, mauris non vehicula fringilla, ligula lorem elementum velit, eu mattis.";
    NSData *originalData = [originalString dataUsingEncoding:NSUTF8StringEncoding];
    NSData *compressedData = nil;
    
    std::tuple<unsigned char *, unsigned int> zipData = mParticle::Zip::compress((const unsigned char *)[originalData bytes], (unsigned int)[originalData length]);
    if (get<0>(zipData) != nullptr) {
        compressedData = [[NSData alloc] initWithBytes:get<0>(zipData) length:get<1>(zipData)];
        delete [] get<0>(zipData);
    } else {
        XCTAssertNotEqual(get<0>(zipData), nullptr, @"Error compressing data.");
    }
    
    XCTAssertTrue(originalData.length >= compressedData.length, @"Compression is not being efficient.");
    
    zipData = mParticle::Zip::expand((const unsigned char *)[compressedData bytes], (unsigned int)[compressedData length]);
    NSData *expandedData = nil;
    
    if (get<0>(zipData) != nullptr) {
        expandedData = [[NSData alloc] initWithBytes:get<0>(zipData) length:get<1>(zipData)];
        delete [] get<0>(zipData);
    } else {
        XCTAssertNotEqual(get<0>(zipData), nullptr, @"Error expanding data.");
    }
    
    NSString *expandedString = [[NSString alloc] initWithData:expandedData encoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects(originalString, expandedString, @"Strings are not the same.");
}

- (void)testInefficientCompressionAndExpand {
    NSString *originalString = @"The quick brown fox jumps over the lazy dog.";
    NSData *originalData = [originalString dataUsingEncoding:NSUTF8StringEncoding];
    NSData *compressedData = nil;
    
    std::tuple<unsigned char *, unsigned int> zipData = mParticle::Zip::compress((const unsigned char *)[originalData bytes], (unsigned int)[originalData length]);
    if (get<0>(zipData) != nullptr) {
        compressedData = [[NSData alloc] initWithBytes:get<0>(zipData) length:get<1>(zipData)];
        delete [] get<0>(zipData);
    } else {
        XCTAssertNotEqual(get<0>(zipData), nullptr, @"Error compressing data.");
    }
    
    XCTAssertTrue(originalData.length < compressedData.length, @"Compression is more efficient than expected.");
    
    zipData = mParticle::Zip::expand((const unsigned char *)[compressedData bytes], (unsigned int)[compressedData length]);
    NSData *expandedData = nil;
    
    if (get<0>(zipData) != nullptr) {
        expandedData = [[NSData alloc] initWithBytes:get<0>(zipData) length:get<1>(zipData)];
        delete [] get<0>(zipData);
    } else {
        XCTAssertNotEqual(get<0>(zipData), nullptr, @"Error expanding data.");
    }
    
    NSString *expandedString = [[NSString alloc] initWithData:expandedData encoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects(originalString, expandedString, @"Strings are not the same.");
}

@end
