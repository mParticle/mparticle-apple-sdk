#import <XCTest/XCTest.h>
#import "MPBaseTestCase.h"
#import "zlib.h"
#import "MParticleSwift.h"

@interface MPZipTestHelper : NSObject

+ (NSData *)inflatedDataFromData:(NSData *)data;

@end

@implementation MPZipTestHelper

+ (NSData *)inflatedDataFromData:(NSData *)data {
    
    if (data.length == 0) {
        return data;
    }
    
    z_stream stream;
    stream.next_in = (Bytef *)data.bytes;
    stream.avail_in = (uint)data.length;
    stream.total_out = 0;
    stream.zalloc = Z_NULL;
    stream.zfree = Z_NULL;
    
    if (inflateInit2(&stream, (15+32)) != Z_OK) {
        return nil;
    }
    
    unsigned long full_length = data.length;
    unsigned long half_length = data.length / 2;
    unsigned long initialBufferSize = full_length + half_length;
    
    NSMutableData *output = [NSMutableData dataWithCapacity:initialBufferSize];
    
    bool done = false;
    while (!done) {
        // Make sure we have enough room and reset the lengths.
        if (stream.total_out >= output.length) {
            output.length += half_length;
        }
        
        stream.next_out = (uint8_t *)output.mutableBytes + stream.total_out;
        stream.avail_out = (uInt)(output.length - stream.total_out);
        
        // Inflate another chunk.
        int status = inflate(&stream, Z_SYNC_FLUSH);
        
        if (status == Z_STREAM_END) {
            done = true;
        } else if (status != Z_OK) {
            break;
        }
    }
    
    if (inflateEnd(&stream) != Z_OK) {
        return nil;
    }
    
    if (!done) {
        return nil;
    }
    
    output.length = stream.total_out;
    return output;
}

@end

@interface MPZipTests : MPBaseTestCase

@end

@implementation MPZipTests

- (void)testSimpleCompressAndExpand {
    NSString *input = @"";
    for (int i=0; i<100; i++) {
        input = [NSString stringWithFormat:@"%@%@", input, @"A"];
    }
    NSData *originalData = [NSData dataWithBytes:input.UTF8String length:input.length];
    NSData *compressedData = [MPZip_PRIVATE compressedDataFromData:originalData];
    
    const UInt8 *bytes = (const UInt8 *)compressedData.bytes;
    BOOL hasGzipHeader = (compressedData.length >= 2 && bytes[0] == 0x1f && bytes[1] == 0x8b);
    XCTAssertTrue(hasGzipHeader);
    XCTAssertLessThan(compressedData.length, originalData.length);
    
    NSData *expandedData = [MPZipTestHelper inflatedDataFromData:compressedData];
    XCTAssertEqualObjects(originalData, expandedData);
}

- (void)testCompressAndExpand {
    NSString *originalString = @"The quick brown fox jumps over the lazy dog. 1234567890 <!@#$%^&*(){}[];:> œ∑´®†¥¨ˆøπ“‘«æ…¬˚∆˙©ƒ∂ßåΩ≈ç√∫˜µ≤≥÷. ⁄€‹›ﬁﬂ‡°·‚—±»’”∏Øˆ¨Áˇ‰´„ŒÅÍÎÏ˝ÓÔÒÚÆ¿˘¯Â˜ı◊Ç˛¸ Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc orci sapien, imperdiet eu condimentum at, consequat ut nisi. Duis sodales sapien eu congue cursus. Donec arcu lacus, congue sed vestibulum at, vulputate eget felis. Aenean faucibus metus et urna tempus volutpat. Phasellus ac lacus condimentum augue dictum laoreet vitae non mi. Phasellus arcu enim, sodales vel tristique laoreet, accumsan ac sem. Etiam vehicula mauris tristique egestas mollis. Maecenas molestie feugiat nulla quis fringilla. Nullam id turpis ante. Pellentesque neque sapien, viverra quis scelerisque et, consequat sit amet nibh. Duis sodales, mauris non vehicula fringilla, ligula lorem elementum velit, eu mattis.";
    NSData *originalData = [originalString dataUsingEncoding:NSUTF8StringEncoding];
    NSData *compressedData = [MPZip_PRIVATE compressedDataFromData:originalData];
    XCTAssertNotNil(compressedData, @"Error compressing data.");
    XCTAssertGreaterThanOrEqual(originalData.length, compressedData.length, @"Compression is not being efficient.");
    
    NSData *expandedData = [MPZipTestHelper inflatedDataFromData:compressedData];
    XCTAssertNotNil(expandedData, @"Error expanding data.");
    NSString *expandedString = [[NSString alloc] initWithData:expandedData encoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects(originalString, expandedString, @"Strings are not the same.");
}

- (void)testInefficientCompressionAndExpand {
    NSString *originalString = @"The quick brown fox jumps over the lazy dog.";
    NSData *originalData = [originalString dataUsingEncoding:NSUTF8StringEncoding];

    NSData *compressedData = [MPZip_PRIVATE compressedDataFromData:originalData];
    XCTAssertNotNil(compressedData, @"Error compressing data.");
    XCTAssertLessThanOrEqual(originalData.length, compressedData.length, @"Compression is more efficient than expected.");

    NSData *expandedData = [MPZipTestHelper inflatedDataFromData:compressedData];
    XCTAssertNotNil(expandedData, @"Error expanding data.");
    NSString *expandedString = [[NSString alloc] initWithData:expandedData encoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects(originalString, expandedString, @"Strings are not the same.");
}

- (void)testInvalidCompressAndExpand {
    NSData *originalData = nil;
    
    NSData *compressedData = [MPZip_PRIVATE compressedDataFromData:originalData];
    XCTAssertNil(compressedData, @"Error compressing data.");
    
    NSData *expandedData = [MPZipTestHelper inflatedDataFromData:compressedData];
    XCTAssertNil(expandedData, @"Error expanding data.");
}

@end
