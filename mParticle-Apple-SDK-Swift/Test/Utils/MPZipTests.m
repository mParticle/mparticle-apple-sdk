#import <XCTest/XCTest.h>

@import mParticle_Apple_SDK_Swift;

@interface MPZipTests : XCTestCase

@end

@implementation MPZipTests

- (void)testSimpleCompressAndExpand {
    NSString *input = @"";
    for (int i=0; i<100; i++) {
        input = [NSString stringWithFormat:@"%@%@", input, @"A"];
    }
    NSData *originalData = [NSData dataWithBytes:input.UTF8String length:input.length];
    NSData *compressedData = [MPZipPRIVATE compressedDataFromData:originalData];
    
    const UInt8 *bytes = (const UInt8 *)compressedData.bytes;
    BOOL hasGzipHeader = (compressedData.length >= 2 && bytes[0] == 0x1f && bytes[1] == 0x8b);
    XCTAssertTrue(hasGzipHeader);
    XCTAssertLessThan(compressedData.length, originalData.length);
    
    NSData *expandedData = [MPZipPRIVATE decompressedDataFromData:compressedData];
    XCTAssertEqualObjects(originalData, expandedData);
}

- (void)testCompressAndExpand {
    NSString *originalString = @"The quick brown fox jumps over the lazy dog. 1234567890 <!@#$%^&*(){}[];:> œ∑´®†¥¨ˆøπ“‘«æ…¬˚∆˙©ƒ∂ßåΩ≈ç√∫˜µ≤≥÷. ⁄€‹›ﬁﬂ‡°·‚—±»’”∏Øˆ¨Áˇ‰´„ŒÅÍÎÏ˝ÓÔÒÚÆ¿˘¯Â˜ı◊Ç˛¸ Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc orci sapien, imperdiet eu condimentum at, consequat ut nisi. Duis sodales sapien eu congue cursus. Donec arcu lacus, congue sed vestibulum at, vulputate eget felis. Aenean faucibus metus et urna tempus volutpat. Phasellus ac lacus condimentum augue dictum laoreet vitae non mi. Phasellus arcu enim, sodales vel tristique laoreet, accumsan ac sem. Etiam vehicula mauris tristique egestas mollis. Maecenas molestie feugiat nulla quis fringilla. Nullam id turpis ante. Pellentesque neque sapien, viverra quis scelerisque et, consequat sit amet nibh. Duis sodales, mauris non vehicula fringilla, ligula lorem elementum velit, eu mattis.";
    NSData *originalData = [originalString dataUsingEncoding:NSUTF8StringEncoding];
    NSData *compressedData = [MPZipPRIVATE compressedDataFromData:originalData];
    XCTAssertNotNil(compressedData, @"Error compressing data.");
    XCTAssertGreaterThanOrEqual(originalData.length, compressedData.length, @"Compression is not being efficient.");
    
    NSData *expandedData = [MPZipPRIVATE decompressedDataFromData:compressedData];
    XCTAssertNotNil(expandedData, @"Error expanding data.");
    NSString *expandedString = [[NSString alloc] initWithData:expandedData encoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects(originalString, expandedString, @"Strings are not the same.");
}

- (void)testInefficientCompressionAndExpand {
    NSString *originalString = @"The quick brown fox jumps over the lazy dog.";
    NSData *originalData = [originalString dataUsingEncoding:NSUTF8StringEncoding];

    NSData *compressedData = [MPZipPRIVATE compressedDataFromData:originalData];
    XCTAssertNotNil(compressedData, @"Error compressing data.");
    XCTAssertLessThanOrEqual(originalData.length, compressedData.length, @"Compression is more efficient than expected.");

    NSData *expandedData = [MPZipPRIVATE decompressedDataFromData:compressedData];
    XCTAssertNotNil(expandedData, @"Error expanding data.");
    NSString *expandedString = [[NSString alloc] initWithData:expandedData encoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects(originalString, expandedString, @"Strings are not the same.");
}

- (void)testInvalidCompressAndExpand {
    NSData *originalData = nil;
    
    NSData *compressedData = [MPZipPRIVATE compressedDataFromData:originalData];
    XCTAssertNil(compressedData, @"Error compressing data.");
    
    NSData *expandedData = [MPZipPRIVATE decompressedDataFromData:compressedData];
    XCTAssertNil(expandedData, @"Error expanding data.");
}

@end
