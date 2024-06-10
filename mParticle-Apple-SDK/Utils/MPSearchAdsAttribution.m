#import <Foundation/Foundation.h>

#if TARGET_OS_IOS == 1
#import "MPSearchAdsAttribution.h"
#import "mParticle.h"
#import "MPStateMachine.h"
#import "MPIConstants.h"
#import "MPILogger.h"
#import <AdServices/AAAttribution.h>

@interface MParticle ()

+ (dispatch_queue_t)messageQueue;
@property (nonatomic, strong) MPStateMachine *stateMachine;

@end

@implementation MPSearchAdsAttribution 

- (void)requestAttributionDetailsWithBlock:(void (^ _Nonnull)(void))completionHandler requestsCompleted:(int)requestsCompleted {
    NSError *error;
    if (@available(iOS 14.3, *)) {
        NSString *attributionToken = [AAAttribution attributionTokenWithError:&error];
        if (!attributionToken) {
            completionHandler();
            return;
        }
        
        if (attributionToken) {
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://api-adservices.apple.com/api/v1/"]];
            [request setHTTPMethod:@"POST"];
            [request setValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];
            [request setHTTPBody:[attributionToken dataUsingEncoding:NSUTF8StringEncoding]];
            
            NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
            sessionConfiguration.timeoutIntervalForRequest = 30;
            sessionConfiguration.timeoutIntervalForResource = 30;
            NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:sessionConfiguration
                                                        delegate:nil
                                                   delegateQueue:nil];
            dispatch_async([MParticle messageQueue], ^{
                [urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *urlResponse, NSError *error) {
                    if (error) {
                        MPILogError(@"Failed requesting Ads Attribution with error: %@.", [error localizedDescription]);
                        if (error.code == 1 /* ADClientErrorLimitAdTracking */) {
                            completionHandler();
                        } else if ((requestsCompleted + 1) > SEARCH_ADS_ATTRIBUTION_MAX_RETRIES) {
                            completionHandler();
                        } else {
                            // Per Apple docs, "Handle any errors you receive and re-poll for data, if required"
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(SEARCH_ADS_ATTRIBUTION_DELAY_BEFORE_RETRY * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                [self requestAttributionDetailsWithBlock:completionHandler requestsCompleted:(requestsCompleted + 1)];
                            });
                        }
                    } else {
                        NSDictionary *adAttributionDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                        // Convert the dictionary to the prior format expected by our backend
                        NSDictionary *finalAttributionDictionary = @{
                            @"Version4.0": @{
                                @"iad-attribution": adAttributionDictionary[@"attribution"],
                                @"iad-org-id": [adAttributionDictionary[@"orgId"] stringValue],
                                @"iad-campaign-id": [adAttributionDictionary[@"campaignId"] stringValue],
                                @"iad-conversion-type": adAttributionDictionary[@"conversionType"],
                                @"iad-click-date": adAttributionDictionary[@"clickDate"],
                                @"iad-adgroup-id": [adAttributionDictionary[@"adGroupId"] stringValue],
                                @"iad-country-or-region": adAttributionDictionary[@"countryOrRegion"],
                                @"iad-keyword-id": [adAttributionDictionary[@"keywordId"] stringValue],
                                @"iad-ad-id": [adAttributionDictionary[@"adId"] stringValue],
                            }
                        };
                        [MParticle sharedInstance].stateMachine.searchAdsInfo = [[finalAttributionDictionary mutableCopy] copy];
                        completionHandler();
                    }
                }];
            });
        }
    }
}

@end
#endif
