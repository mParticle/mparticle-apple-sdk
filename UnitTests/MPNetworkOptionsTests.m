#import <XCTest/XCTest.h>
#import "mParticle.h"
#import "MPBaseTestCase.h"

@interface MPNetworkOptionsTests : MPBaseTestCase

@end

@implementation MPNetworkOptionsTests

- (void)testInit {
    MPNetworkOptions *options = [[MPNetworkOptions alloc] init];
    XCTAssertNotNil(options);
    XCTAssertNil(options.configHost);
    XCTAssertNil(options.eventsHost);
    XCTAssertNil(options.identityHost);
    XCTAssertNil(options.certificates);
}

- (void)testProperties {
    MPNetworkOptions *options = [[MPNetworkOptions alloc] init];
    options.configHost = @"config.mpproxy.example.com";
    options.eventsHost = @"events.mpproxy.example.com";
    options.identityHost = @"identity.mpproxy.example.com";
    NSString *exampleCertificateString = @"MIIDBzCCAe+gAwIBAgIJAOtHW2a34yJpMA0GCSqGSIb3DQEBBQUAMBoxGDAWBgNV\n\
    BAMMD3d3dy5leGFtcGxlLmNvbTAeFw0xODAyMDcxNzQ0MjJaFw0yODAyMDUxNzQ0\n\
    MjJaMBoxGDAWBgNVBAMMD3d3dy5leGFtcGxlLmNvbTCCASIwDQYJKoZIhvcNAQEB\n\
    BQADggEPADCCAQoCggEBANjS//Jpjpj2kXC3ZJ9a+SGmytDMZXedFliJSRomTGxf\n\
    XS60f3VwvmBrsN36jUF1rHOWD3pFWp2kV4sIQDCtlptTt+/TnjF7l1WmVhLrCwjE\n\
    R6L+Szj2rjtSWKR+MEMg8/gyhhWX2OjfBJCRbKMzNPVVsT1YR9vKusqno5+KtUBL\n\
    DhHqfKlGdJDq4bUcddeKdrmS29+tHuh2C3Nh79pmV74VHk6W3MftFgZlcruV37sZ\n\
    4SDni9HIsZ660ZuBF8+IBlgI+lt07ghF5kohFC1GxYHrmwQnx6rbjkr05DvMzzlI\n\
    8qH1AQYGfWbrdGvsVBPGBb6UNMsS/jGH7ye0Oj5i9YcCAwEAAaNQME4wHQYDVR0O\n\
    BBYEFGEW29WOnjfLTrlsTzB7TD756kddMB8GA1UdIwQYMBaAFGEW29WOnjfLTrls\n\
    TzB7TD756kddMAwGA1UdEwQFMAMBAf8wDQYJKoZIhvcNAQEFBQADggEBAKQVfm1j\n\
    Tq0+5TCPksaBqe42EQVkuOUdSa8FUJztIXGwYtQrwrXPdup0jxdZtRjN9TEEpeuq\n\
    MKbmMmTdgfrM+ZCpvjdLwFwoCae9VmZ2+TJCPDGZkQnGdV1ae3a3wcnST9wz3SEl\n\
    6T3KS11R/6OkvCwOcrXdYdjY9hbej2R2/MW9J12Z456FOkrcHmcivZb52Z5ujmhb\n\
    UDibMKnIL7WKH4h88FOe7ujSR/wDCBPQUok064CPC0imeriQECD5lgQ01jEV+M3q\n\
    GDWLWFKh5RZYJ0x9jwej39z/PPDLTY1AkF9jo0oKjtheYljQKcWJQxukaYQYqrLC\n\
    RYq01/adll+fAvE=";
    NSData *exampleCertificateEncoded = [exampleCertificateString dataUsingEncoding:NSUTF8StringEncoding];
    NSData *exampleCertificateData = [[NSData alloc] initWithBase64EncodedData:exampleCertificateEncoded options:NSDataBase64DecodingIgnoreUnknownCharacters];
    options.certificates = @[exampleCertificateData];
    XCTAssertEqualObjects(options.configHost, @"config.mpproxy.example.com");
    XCTAssertEqualObjects(options.eventsHost, @"events.mpproxy.example.com");
    XCTAssertEqualObjects(options.identityHost, @"identity.mpproxy.example.com");
    XCTAssertEqualObjects(options.certificates, @[exampleCertificateData]);
}

@end
