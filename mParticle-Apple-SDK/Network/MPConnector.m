#import "MPConnector.h"
#import <dispatch/dispatch.h>
#import "MPIConstants.h"
#import "MPURLRequestBuilder.h"
#import "MPNetworkCommunication.h"
#import "MPILogger.h"
#import "mParticle.h"
#import "MPURL.h"

static NSArray *mpStoredCertificates = nil;

@implementation MPConnectorResponse

- (instancetype)init {
    self = [super init];
    if (self) {
        _data = nil;
        _error = nil;
        _downloadTime = 0;
        _httpResponse = nil;
    }
    return self;
}

@end

@interface MPConnector() <NSURLSessionDelegate, NSURLSessionTaskDelegate> {
    NSMutableData *receivedData;
    NSDate *requestStartTime;
    NSHTTPURLResponse *httpURLResponse;
}

@property (nonatomic, copy) void (^completionHandler)(NSData *data, NSError *error, NSTimeInterval downloadTime, NSHTTPURLResponse *httpResponse);
@property (nonatomic, strong) NSURLSessionDataTask *dataTask;
@property (nonatomic, strong) NSURLSession *urlSession;

@end

@implementation MPConnector

+ (void)initialize {
    if (self == [MPConnector class]) {
        mpStoredCertificates = @[
            @"MIIDxTCCAq2gAwIBAgIBADANBgkqhkiG9w0BAQsFADCBgzELMAkGA1UEBhMCVVMxEDAOBgNVBAgTB0FyaXpvbmExEzARBgNVBAcTClNjb3R0c2RhbGUxGjAYBgNVBAoTEUdvRGFkZHkuY29tLCBJbmMuMTEwLwYDVQQDEyhHbyBEYWRkeSBSb290IENlcnRpZmljYXRlIEF1dGhvcml0eSAtIEcyMB4XDTA5MDkwMTAwMDAwMFoXDTM3MTIzMTIzNTk1OVowgYMxCzAJBgNVBAYTAlVTMRAwDgYDVQQIEwdBcml6b25hMRMwEQYDVQQHEwpTY290dHNkYWxlMRowGAYDVQQKExFHb0RhZGR5LmNvbSwgSW5jLjExMC8GA1UEAxMoR28gRGFkZHkgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgLSBHMjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAL9xYgjx+lk09xvJGKP3gElY6SKDE6bFIEMBO4Tx5oVJnyfq9oQbTqC023CYxzIBsQU+B07u9PpPL1kwIuerGVZr4oAH/PMWdYA5UXvl+TW2dE6pjYIT5LY/qQOD+qK+ihVqf94Lw7YZFAXK6sOoBJQ7RnwyDfMAZiLIjWltNowRGLfTshxgtDj6AozO091GB94KPutdfMh8+7ArU6SSYmlRJQVhGkSBjCypQ5Yj36w6gZoOKcUcqeldHraenjAKOc7xiID7S13MMuyFYkMlNAJWJwGRtDtwKj9useiciAF9n9T521NtYJ2/LOdYq7hfRvzOxBsDPAnrSTFcaUaz4EcCAwEAAaNCMEAwDwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8EBAMCAQYwHQYDVR0OBBYEFDqahQcQZyi27/a9BUFuIMGU2g/eMA0GCSqGSIb3DQEBCwUAA4IBAQCZ21151fmXWWcDYfF+OwYxdS2hII5PZYe096acvNjpL9DbWu7PdIxztDhC2gV7+AJ1uP2lsdeu9tfeE8tTEH6KRtGX+rcuKxGrkLAngPnon1rpN5+r5N9ss4UXnT3ZJE95kTXWXwTrgIOrmgIttRD02JDHBHNA7XIloKmf7J6raBKZV8aPEjoJpL1E/QYVN8Gb5DKj7Tjo2GTzLH4U/ALqn83/B2gX2yKQOC16jdFU8WnjXzPKej17CuPKf1855eJ1usV2GDPOLPAvTK33sefOT6jEm0pUBsV/fdUID+Ic/n4XuKxe9tQWskMJDE32p2u0mYRlynqI4uJEvlz36hz1", //GoDaddy Class 2 Certification Authority Root Certificate - G2
            @"MIIEADCCAuigAwIBAgIBADANBgkqhkiG9w0BAQUFADBjMQswCQYDVQQGEwJVUzEhMB8GA1UEChMYVGhlIEdvIERhZGR5IEdyb3VwLCBJbmMuMTEwLwYDVQQLEyhHbyBEYWRkeSBDbGFzcyAyIENlcnRpZmljYXRpb24gQXV0aG9yaXR5MB4XDTA0MDYyOTE3MDYyMFoXDTM0MDYyOTE3MDYyMFowYzELMAkGA1UEBhMCVVMxITAfBgNVBAoTGFRoZSBHbyBEYWRkeSBHcm91cCwgSW5jLjExMC8GA1UECxMoR28gRGFkZHkgQ2xhc3MgMiBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTCCASAwDQYJKoZIhvcNAQEBBQADggENADCCAQgCggEBAN6d1+pXGEmhW+vXX0iG6r7d/+TvZxz0ZWizV3GgXne77ZtJ6XCAPVYYYwhv2vLM0D9/AlQiVBDYsoHUwHU9S3/Hd8M+eKsaA7Ugay9qK7HFiH7Eux6wwdhFJ2+qN1j3hybX2C32qRe3H3I2TqYXP2WYktsqbl2i/ojgC95/5Y0V4evLOtXiEqITLdiOr18SPaAIBQi2XKVlOARFmR6jYGB0xUGlcmIbYsUfb18aQr4CUWWoriMYavx4A6lNf4DD+qta/KFApMoZFv6yyO9ecw3ud72a9nmYvLEHZ6IVDd2gWMZEewo+YihfukEHU1jPEX44dMX4/7VpkI+EdOqXG68CAQOjgcAwgb0wHQYDVR0OBBYEFNLEsNKR1EwRcbNhyz2h/t2oatTjMIGNBgNVHSMEgYUwgYKAFNLEsNKR1EwRcbNhyz2h/t2oatTjoWekZTBjMQswCQYDVQQGEwJVUzEhMB8GA1UEChMYVGhlIEdvIERhZGR5IEdyb3VwLCBJbmMuMTEwLwYDVQQLEyhHbyBEYWRkeSBDbGFzcyAyIENlcnRpZmljYXRpb24gQXV0aG9yaXR5ggEAMAwGA1UdEwQFMAMBAf8wDQYJKoZIhvcNAQEFBQADggEBADJL87LKPpH8EsahB4yOd6AzBhRckB4Y9wimPQoZ+YeAEW5p5JYXMP80kWNyOO7MHAGjHZQopDH2esRU1/blMVgDoszOYtuURXO1v0XJJLXVggKtI3lpjbi2Tc7PTMozI+gciKqdi0FuFskg5YmezTvacPd+mSYgFFQlq25zheabIZ0KbIIOqPjCDPoQHmyW74cNxA9hi63ugyuV+I6ShHI56yDqg+2DzZduCLzrTia2cyvk0/ZM/iZx4mERdEr/VxqHD3VILs9RaRegAhJhldXRQLIQTO7ErBBDpqWeCtWVYpoNz4iCxTIM5CufReYNnyicsbkqWletNw+vHX/bvZ8=", //GoDaddy Class 2 Certification Authority Root Certificate
            @"MIIFazCCA1OgAwIBAgIRAIIQz7DSQONZRGPgu2OCiwAwDQYJKoZIhvcNAQELBQAwTzELMAkGA1UEBhMCVVMxKTAnBgNVBAoTIEludGVybmV0IFNlY3VyaXR5IFJlc2VhcmNoIEdyb3VwMRUwEwYDVQQDEwxJU1JHIFJvb3QgWDEwHhcNMTUwNjA0MTEwNDM4WhcNMzUwNjA0MTEwNDM4WjBPMQswCQYDVQQGEwJVUzEpMCcGA1UEChMgSW50ZXJuZXQgU2VjdXJpdHkgUmVzZWFyY2ggR3JvdXAxFTATBgNVBAMTDElTUkcgUm9vdCBYMTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAK3oJHP0FDfzm54rVygch77ct984kIxuPOZXoHj3dcKi/vVqbvYATyjb3miGbESTtrFj/RQSa78f0uoxmyF+0TM8ukj13Xnfs7j/EvEhmkvBioZxaUpmZmyPfjxwv60pIgbz5MDmgK7iS4+3mX6UA5/TR5d8mUgjU+g4rk8Kb4Mu0UlXjIB0ttov0DiNewNwIRt18jA8+o+u3dpjq+sWT8KOEUt+zwvo/7V3LvSye0rgTBIlDHCNAymg4VMk7BPZ7hm/ELNKjD+Jo2FR3qyHB5T0Y3HsLuJvW5iB4YlcNHlsdu87kGJ55tukmi8mxdAQ4Q7e2RCOFvu396j3x+UCB5iPNgiV5+I3lg02dZ77DnKxHZu8A/lJBdiB3QW0KtZB6awBdpUKD9jf1b0SHzUvKBds0pjBqAlkd25HN7rOrFleaJ1/ctaJxQZBKT5ZPt0m9STJEadao0xAH0ahmbWnOlFuhjuefXKnEgV4We0+UXgVCwOPjdAvBbI+e0ocS3MFEvzG6uBQE3xDk3SzynTnjh8BCNAw1FtxNrQHusEwMFxIt4I7mKZ9YIqioymCzLq9gwQbooMDQaHWBfEbwrbwqHyGO0aoSCqI3Haadr8faqU9GY/rOPNk3sgrDQoo//fb4hVC1CLQJ13hef4Y53CIrU7m2Ys6xt0nUW7/vGT1M0NPAgMBAAGjQjBAMA4GA1UdDwEB/wQEAwIBBjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBR5tFnme7bl5AFzgAiIyBpY9umbbjANBgkqhkiG9w0BAQsFAAOCAgEAVR9YqbyyqFDQDLHYGmkgJykIrGF1XIpu+ILlaS/V9lZLubhzEFnTIZd+50xx+7LSYK05qAvqFyFWhfFQDlnrzuBZ6brJFe+GnY+EgPbk6ZGQ3BebYhtF8GaV0nxvwuo77x/Py9auJ/GpsMiu/X1+mvoiBOv/2X/qkSsisRcOj/KKNFtY2PwByVS5uCbMiogziUwthDyC3+6WVwW6LLv3xLfHTjuCvjHIInNzktHCgKQ5ORAzI4JMPJ+GslWYHb4phowim57iaztXOoJwTdwJx4nLCgdNbOhdjsnvzqvHu7UrTkXWStAmzOVyyghqpZXjFaH3pO3JLF+l+/+sKAIuvtd7u+Nxe5AW0wdeRlN8NwdCjNPElpzVmbUq4JUagEiuTDkHzsxHpFKVK7q4+63SM1N95R1NbdWhscdCb+ZAJzVcoyi3B43njTOQ5yOf+1CceWxG1bQVs5ZufpsMljq4Ui0/1lvh+wjChP4kqKOJ2qxq4RgqsahDYVvTH9w7jXbyLeiNdd8XM2w9U/t7y0Ff/9yi0GE44Za4rF2LN9d11TPAmRGunUHBcnWEvgJBQl9nJEiU0Zsnvgc/ubhPgXRR4Xq37Z0j4r7g1SgEEzwxA57demyPxgcYxn/eR44/KJ4EBs+lVDR3veyJm+kXQ99b21/+jh5Xos1AnX5iItreGCc=", //ISRG Root X1 (self-signed)
            @"MIICGzCCAaGgAwIBAgIQQdKd0XLq7qeAwSxs6S+HUjAKBggqhkjOPQQDAzBPMQswCQYDVQQGEwJVUzEpMCcGA1UEChMgSW50ZXJuZXQgU2VjdXJpdHkgUmVzZWFyY2ggR3JvdXAxFTATBgNVBAMTDElTUkcgUm9vdCBYMjAeFw0yMDA5MDQwMDAwMDBaFw00MDA5MTcxNjAwMDBaME8xCzAJBgNVBAYTAlVTMSkwJwYDVQQKEyBJbnRlcm5ldCBTZWN1cml0eSBSZXNlYXJjaCBHcm91cDEVMBMGA1UEAxMMSVNSRyBSb290IFgyMHYwEAYHKoZIzj0CAQYFK4EEACIDYgAEzZvVn4CDCuwJSvMWSj5cz3es3mcFDR0HttwW+1qLFNvicWDEukWVEYmO6gbf9yoWHKS5xcUy4APgHoIYOIvXRdgKam7mAHf7AlF9ItgKbppbd9/w+kHsOdx1ymgHDB/qo0IwQDAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUfEKWrt5LSDv6kviejM9ti6lyN5UwCgYIKoZIzj0EAwMDaAAwZQIwe3lORlCEwkSHRhtFcP9Ymd70/aTSVaYgLXTWNLxBo1BfASdWtL4ndQavEi51mI38AjEAi/V3bNTIZargCyzuFJ0nN6T5U6VR5CmD1/iQMVtCnwr1/q4AaOeMSQ+2b1tbFfLn", //ISRG Root X2 (self-signed)
            @"MIIEYDCCAkigAwIBAgIQB55JKIY3b9QISMI/xjHkYzANBgkqhkiG9w0BAQsFADBPMQswCQYDVQQGEwJVUzEpMCcGA1UEChMgSW50ZXJuZXQgU2VjdXJpdHkgUmVzZWFyY2ggR3JvdXAxFTATBgNVBAMTDElTUkcgUm9vdCBYMTAeFw0yMDA5MDQwMDAwMDBaFw0yNTA5MTUxNjAwMDBaME8xCzAJBgNVBAYTAlVTMSkwJwYDVQQKEyBJbnRlcm5ldCBTZWN1cml0eSBSZXNlYXJjaCBHcm91cDEVMBMGA1UEAxMMSVNSRyBSb290IFgyMHYwEAYHKoZIzj0CAQYFK4EEACIDYgAEzZvVn4CDCuwJSvMWSj5cz3es3mcFDR0HttwW+1qLFNvicWDEukWVEYmO6gbf9yoWHKS5xcUy4APgHoIYOIvXRdgKam7mAHf7AlF9ItgKbppbd9/w+kHsOdx1ymgHDB/qo4HlMIHiMA4GA1UdDwEB/wQEAwIBBjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBR8Qpau3ktIO/qS+J6Mz22LqXI3lTAfBgNVHSMEGDAWgBR5tFnme7bl5AFzgAiIyBpY9umbbjAyBggrBgEFBQcBAQQmMCQwIgYIKwYBBQUHMAKGFmh0dHA6Ly94MS5pLmxlbmNyLm9yZy8wJwYDVR0fBCAwHjAcoBqgGIYWaHR0cDovL3gxLmMubGVuY3Iub3JnLzAiBgNVHSAEGzAZMAgGBmeBDAECATANBgsrBgEEAYLfEwEBATANBgkqhkiG9w0BAQsFAAOCAgEAG38lK5B6CHYAdxjhwy6KNkxBfr8XS+Mw11sMfpyWmG97sGjAJETM4vL80erb0p8B+RdNDJ1V/aWtbdIvP0tywC6uc8clFlfCPhWt4DHRCoSEbGJ4QjEiRhrtekC/lxaBRHfKbHtdIVwH8hGRIb/hL8Lvbv0FIOS093nzLbs3KvDGsaysUfUfs1oeZs5YBxg4f3GpPIO617yCnpp2D56wKf3L84kHSBv+q5MuFCENX6+Ot1SrXQ7UW0xx0JLqPaM2m3wf4DtVudhTU8yDZrtK3IEGABiL9LPXSLETQbnEtp7PLHeOQiALgH6fxatI27xvBI1sRikCDXCKHfESc7ZGJEKeKhcY46zHmMJyzG0tdm3dLCsmlqXPIQgb5dovy++fc5Ou+DZfR4+XKM6r4pgmmIv97igyIintTJUJxCD6B+GGLET2gUfA5GIy7R3YPEiIlsNekbave1mk7uOGnMeIWMooKmZVm4WAuR3YQCvJHBM8qevemcIWQPb1pK4qJWxSuscETLQyu/w4XKAMYXtX7HdOUM+vBqIPN4zhDtLTLxq9nHE+zOH40aijvQT2GcD5hq/1DhqqlWvvykdxS2McTZbbVSMKnQ+BdaDmQPVkRgNuzvpqfQbspDQGdNpT2Lm4xiN9qfgqLaSCpi4tEcrmzTFYeYXmchynn9NM0GbQp7s="]; //ISRG Root X2 (cross-signed)
    }
}

- (id)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _dataTask = nil;
    requestStartTime = nil;
    _completionHandler = nil;
    httpURLResponse = nil;
    receivedData = nil;
    
    return self;
}

#pragma mark Private methods
- (NSURLSession *)urlSession {
    if (_urlSession) {
        return _urlSession;
    }
    
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    sessionConfiguration.timeoutIntervalForRequest = 30;
    sessionConfiguration.timeoutIntervalForResource = 30;
    _urlSession = [NSURLSession sessionWithConfiguration:sessionConfiguration
                                                delegate:self
                                           delegateQueue:nil];
    
    _urlSession.sessionDescription = [[NSUUID UUID] UUIDString];
    
    return _urlSession;
}

#pragma mark NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    _urlSession = nil;
}

#pragma mark NSURLSessionTaskDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    
    NSURLProtectionSpace *protectionSpace = [challenge protectionSpace];
    NSString *authenticationMethod = [protectionSpace authenticationMethod];
    NSString *host = [protectionSpace host];
    NSString *protocol = [protectionSpace protocol];
    __block SecTrustRef serverTrust = [protectionSpace serverTrust];
    MPNetworkOptions *networkOptions = [[MParticle sharedInstance] networkOptions];
    
    BOOL isPinningHost = [host rangeOfString:@"mparticle.com"].location != NSNotFound ||
                            (networkOptions.configHost.pathComponents.count > 0 && [host isEqualToString:networkOptions.configHost.pathComponents[0]]) ||
                            (networkOptions.identityHost.pathComponents.count > 0 && [host isEqualToString:networkOptions.identityHost.pathComponents[0]]) ||
                            (networkOptions.eventsHost.pathComponents.count > 0 && [host isEqualToString:networkOptions.eventsHost.pathComponents[0]]) ||
                            (networkOptions.aliasHost.pathComponents.count > 0 && [host isEqualToString:networkOptions.aliasHost.pathComponents[0]]);
    
    if ([authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust] &&
        isPinningHost &&
        [protocol isEqualToString:kMPURLScheme] &&
        [protectionSpace receivesCredentialSecurely] &&
        serverTrust)
    {
        SecTrustCallback evaluateResult = ^(SecTrustRef _Nonnull trustRef, SecTrustResultType trustResult) {
            BOOL trustChallenge = NO;
            
            if (trustResult == kSecTrustResultUnspecified || trustResult == kSecTrustResultProceed) {
                CFIndex certificateCount = SecTrustGetCertificateCount(trustRef);
                CFIndex certIdx = certificateCount - 1; //The Root Cert is always the last Cert in the chain
                
                SecCertificateRef certificate = SecTrustGetCertificateAtIndex(trustRef, certIdx);
                CFDataRef certificateDataRef = SecCertificateCopyData(certificate);
                
                if (certificateDataRef != NULL) {
                    NSData *certificateData = (__bridge NSData *)certificateDataRef;
                    
                    if (certificateData) {
                        NSString *certificateEncodedString = [certificateData base64EncodedStringWithOptions:0];
                        trustChallenge = [mpStoredCertificates containsObject:certificateEncodedString];
                        
                        if (!trustChallenge && networkOptions.certificates.count > 0) {
                            trustChallenge = [networkOptions.certificates containsObject:certificateData];
                        }
                    }
                    
                    CFRelease(certificateDataRef);
                }
            }
            
            BOOL shouldDisablePinning = (networkOptions.pinningDisabledInDevelopment && [MParticle sharedInstance].environment == MPEnvironmentDevelopment) || networkOptions.pinningDisabled;
            if (trustChallenge || shouldDisablePinning) {
                NSURLCredential *urlCredential = [NSURLCredential credentialForTrust:trustRef];
                completionHandler(NSURLSessionAuthChallengeUseCredential, urlCredential);
            } else {
                completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
            }
        };
        
        SecTrustEvaluateAsync(serverTrust, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), evaluateResult);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    
    httpURLResponse = (NSHTTPURLResponse *)response;
    NSInteger responseCode = [httpURLResponse statusCode];
    
    if (responseCode == HTTPStatusCodeSuccess || responseCode == HTTPStatusCodeAccepted) {
        if (httpURLResponse.expectedContentLength != NSURLResponseUnknownLength && httpURLResponse.expectedContentLength > 0) {
            receivedData = [[NSMutableData alloc] initWithCapacity:(NSUInteger)httpURLResponse.expectedContentLength];
        } else {
            receivedData = [[NSMutableData alloc] init];
        }
    } else {
        receivedData = nil;
    }
    
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [receivedData appendData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    
    if (!error) {
        NSDate *endTime = [NSDate date];
        NSTimeInterval downloadTime = [endTime timeIntervalSinceDate:requestStartTime];
        
        if (self.completionHandler != nil && self.completionHandler != NULL) {
            @try {
                self.completionHandler(receivedData, nil, downloadTime, httpURLResponse);
            } @catch (NSException *exception) {
                MPILogError(@"Error invoking the completion handler of a data download task.");
            }
        }
    } else {
        if (self.completionHandler != nil && self.completionHandler != NULL) {
            @try {
                self.completionHandler(nil, error, 0, nil);
            } @catch (NSException *exception) {
                MPILogError(@"Error invoking the completion handler of a data download task with error: %@.", [error localizedDescription]);
            }
        }
    }
    [_urlSession finishTasksAndInvalidate];
    _urlSession = nil;
}

#pragma mark Public methods
- (nonnull NSObject<MPConnectorResponseProtocol> *)responseFromGetRequestToURL:(nonnull MPURL *)url {
    MPConnectorResponse *response = [[MPConnectorResponse alloc] init];
    
    NSMutableURLRequest *urlRequest = [[MPURLRequestBuilder newBuilderWithURL:url message:nil httpMethod:kMPHTTPMethodGet] build];
    
    if (urlRequest) {
        requestStartTime = [NSDate date];
        dispatch_semaphore_t requestSemaphore = dispatch_semaphore_create(0);
        __block NSData *completionData = nil;
        __block NSError *completionError = nil;
        __block NSTimeInterval completionDownloadTime = 0;
        __block NSHTTPURLResponse *completionHttpResponse = nil;
        self.completionHandler = ^(NSData *data, NSError *error, NSTimeInterval downloadTime, NSHTTPURLResponse *httpResponse) {
            completionData = data;
            completionError = error;
            completionDownloadTime = downloadTime;
            completionHttpResponse = httpResponse;
            dispatch_semaphore_signal(requestSemaphore);
        };
        
        self.dataTask = [self.urlSession dataTaskWithRequest:urlRequest];
        [_dataTask resume];
        long exitCode = dispatch_semaphore_wait(requestSemaphore, dispatch_time(DISPATCH_TIME_NOW, (NETWORK_REQUEST_MAX_WAIT_SECONDS + 1) * NSEC_PER_SEC));
        if (exitCode == 0) {
            response.data = completionData;
            response.error = completionError;
            response.downloadTime = completionDownloadTime;
            response.httpResponse = completionHttpResponse;
        } else {
            response.error = [NSError errorWithDomain:@"com.mparticle" code:0 userInfo:@{@"mParticle Error":@"Semaphore wait timed out"}];
            [_urlSession invalidateAndCancel];
        }
        
    } else {
        response.error = [NSError errorWithDomain:@"MPConnector" code:1 userInfo:nil];
    }
    
    return response;
}

- (nonnull NSObject<MPConnectorResponseProtocol> *)responseFromPostRequestToURL:(nonnull MPURL *)url message:(nullable NSString *)message serializedParams:(nullable NSData *)serializedParams secret:(nullable NSString *)secret {
    MPConnectorResponse *response = [[MPConnectorResponse alloc] init];
    
    NSMutableURLRequest *urlRequest = [[[[MPURLRequestBuilder newBuilderWithURL:url message:message httpMethod:kMPHTTPMethodPost] withPostData:serializedParams] withSecret:secret] build];
    
    if (urlRequest) {
        requestStartTime = [NSDate date];
        dispatch_semaphore_t requestSemaphore = dispatch_semaphore_create(0);
        __block NSData *completionData = nil;
        __block NSError *completionError = nil;
        __block NSTimeInterval completionDownloadTime = 0;
        __block NSHTTPURLResponse *completionHttpResponse = nil;
        self.completionHandler = ^(NSData *data, NSError *error, NSTimeInterval downloadTime, NSHTTPURLResponse *httpResponse) {
            completionData = data;
            completionError = error;
            completionDownloadTime = downloadTime;
            completionHttpResponse = httpResponse;
            dispatch_semaphore_signal(requestSemaphore);
        };
        self.dataTask = [self.urlSession dataTaskWithRequest:urlRequest];
        [_dataTask resume];
        long exitCode = dispatch_semaphore_wait(requestSemaphore, dispatch_time(DISPATCH_TIME_NOW, (NETWORK_REQUEST_MAX_WAIT_SECONDS + 1) * NSEC_PER_SEC));
        if (exitCode == 0) {
            response.data = completionData;
            response.error = completionError;
            response.downloadTime = completionDownloadTime;
            response.httpResponse = completionHttpResponse;
        } else {
            response.error = [NSError errorWithDomain:@"com.mparticle" code:0 userInfo:@{@"mParticle Error":@"Semaphore wait timed out"}];
            [_urlSession invalidateAndCancel];
        }
    } else {
        response.error = [NSError errorWithDomain:@"MPConnector" code:1 userInfo:nil];
    }
    return response;
}
@end
