//
//  MPIdentityTests.m
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "mParticle.h"
#import "MPIdentityDTO.h"
#import "MPNetworkCommunication.h"
#import "MPBaseTestCase.h"
#import "MPIdentityApi.h"
#import "MPIdentityApiManager.h"
#import "MPKitContainer.h"
#import "MPPersistenceController.h"
#import "MPStateMachine.h"

typedef NS_ENUM(NSUInteger, MPIdentityRequestType) {
    MPIdentityRequestIdentify = 0,
    MPIdentityRequestLogin = 1,
    MPIdentityRequestLogout = 2,
    MPIdentityRequestModify = 3
};

@interface MPIdentityTests : MPBaseTestCase {
    MPKitContainer_PRIVATE *kitContainer;
}

@end

@interface MParticleUser ()

- (void)setIdentitySync:(NSString *)identityString identityType:(MPIdentity)identityType;
- (void)setUserId:(NSNumber *)userId;
@end

@interface MPIdentityApi ()
@property (nonatomic, strong) MPIdentityApiManager *apiManager;
@property(nonatomic, strong, readwrite, nonnull) MParticleUser *currentUser;

- (void)onIdentityRequestComplete:(MPIdentityApiRequest *)request identityRequestType:(MPIdentityRequestType)identityRequestType httpResponse:(MPIdentityHTTPSuccessResponse *) httpResponse completion:(MPIdentityApiResultCallback)completion error: (NSError *) error;
- (void)onModifyRequestComplete:(MPIdentityApiRequest *)request httpResponse:(MPIdentityHTTPModifySuccessResponse *) httpResponse completion:(MPModifyApiResultCallback)completion error: (NSError *) error;
- (NSArray<MParticleUser *> *)sortedUserArrayByLastSeen:(NSMutableArray<MParticleUser *> *)userArray;
@end
    
@interface MPNetworkCommunication_PRIVATE ()
- (void)modifyWithIdentityChanges:(NSArray *)identityChanges blockOtherRequests:(BOOL)blockOtherRequests completion:(nullable MPIdentityApiManagerModifyCallback)completion;
- (void)identityApiRequestWithURL:(NSURL*)url identityRequest:(MPIdentityHTTPBaseRequest *_Nonnull)identityRequest blockOtherRequests: (BOOL) blockOtherRequests completion:(nullable MPIdentityApiManagerCallback)completion;
@end

#pragma mark - MPStateMachine category

@interface MPIdentityHTTPIdentities(Tests) 

- (instancetype)initWithIdentities:(NSDictionary *)identities;

@end

@interface MParticle ()

@property (nonatomic, strong) MPKitContainer_PRIVATE *kitContainer_PRIVATE;
@property (nonatomic, strong, readonly) MPPersistenceController_PRIVATE *persistenceController;

@end

@implementation MPIdentityTests

- (void)testConstructIdentityApiRequest {
    MPIdentityApiRequest *request = [[MPIdentityApiRequest alloc] init];
    [request setIdentity:@"other id" identityType:MPIdentityOther];
    [request setIdentity:@"other id 2" identityType:MPIdentityOther2];
    [request setIdentity:@"other id 3" identityType:MPIdentityOther3];
    [request setIdentity:@"other id 4" identityType:MPIdentityOther4];
    [request setIdentity:@"other id 5" identityType:MPIdentityOther5];
    [request setIdentity:@"other id 6" identityType:MPIdentityOther6];
    [request setIdentity:@"other id 7" identityType:MPIdentityOther7];
    [request setIdentity:@"other id 8" identityType:MPIdentityOther8];
    [request setIdentity:@"other id 9" identityType:MPIdentityOther9];
    [request setIdentity:@"other id 10" identityType:MPIdentityOther10];
    [request setIdentity:@"mobile number" identityType:MPIdentityMobileNumber];
    [request setIdentity:@"phone number 2" identityType:MPIdentityPhoneNumber2];
    [request setIdentity:@"phone number 3" identityType:MPIdentityPhoneNumber3];
    [request setIdentity:@"advertiser" identityType:MPIdentityIOSAdvertiserId];
    [request setIdentity:@"vendor" identityType:MPIdentityIOSVendorId];
    [request setIdentity:@"push token" identityType:MPIdentityPushToken];
    [request setIdentity:@"application stamp" identityType:MPIdentityDeviceApplicationStamp];
    [request setIdentity:@"customer id" identityType:MPIdentityCustomerId];
    [request setIdentity:@"email id" identityType:MPIdentityEmail];
    [request setIdentity:@"facebook id" identityType:MPIdentityFacebook];
    [request setIdentity:@"facebook audience id" identityType:MPIdentityFacebookCustomAudienceId];
    [request setIdentity:@"google id" identityType:MPIdentityGoogle];
    [request setIdentity:@"microsoft id" identityType:MPIdentityMicrosoft];
    [request setIdentity:@"yahoo id" identityType:MPIdentityYahoo];
    [request setIdentity:@"twitter id" identityType:MPIdentityTwitter];
    
    MPIdentityHTTPIdentities *httpIdentities = [[MPIdentityHTTPIdentities alloc] initWithIdentities:request.identities];
    
    XCTAssertEqual(@"other id", httpIdentities.other);
    XCTAssertEqual(@"other id 2", httpIdentities.other2);
    XCTAssertEqual(@"other id 3", httpIdentities.other3);
    XCTAssertEqual(@"other id 4", httpIdentities.other4);
    XCTAssertEqual(@"other id 5", httpIdentities.other5);
    XCTAssertEqual(@"other id 6", httpIdentities.other6);
    XCTAssertEqual(@"other id 7", httpIdentities.other7);
    XCTAssertEqual(@"other id 8", httpIdentities.other8);
    XCTAssertEqual(@"other id 9", httpIdentities.other9);
    XCTAssertEqual(@"other id 10", httpIdentities.other10);
    XCTAssertEqual(@"mobile number", httpIdentities.mobileNumber);
    XCTAssertEqual(@"phone number 2", httpIdentities.phoneNumber2);
    XCTAssertEqual(@"phone number 3", httpIdentities.phoneNumber3);
    XCTAssertEqual(@"advertiser", httpIdentities.advertiserId);
    XCTAssertEqual(@"vendor", httpIdentities.vendorId);
    XCTAssertEqual(@"push token", httpIdentities.pushToken);
    XCTAssertEqual(@"application stamp", httpIdentities.deviceApplicationStamp);
    XCTAssertEqual(@"customer id", httpIdentities.customerId);
    XCTAssertEqual(@"email id", httpIdentities.email);
    XCTAssertEqual(@"facebook id", httpIdentities.facebook);
    XCTAssertEqual(@"facebook audience id", httpIdentities.facebookCustomAudienceId);
    XCTAssertEqual(@"google id", httpIdentities.google);
    XCTAssertEqual(@"microsoft id", httpIdentities.microsoft);
    XCTAssertEqual(@"yahoo id", httpIdentities.yahoo);
    XCTAssertEqual(@"twitter id", httpIdentities.twitter);

    
    NSDictionary *identityDictionary = [httpIdentities dictionaryRepresentation];
    XCTAssertEqual(@"other id", identityDictionary[@"other"]);
    XCTAssertEqual(@"other id 2", identityDictionary[@"other2"]);
    XCTAssertEqual(@"other id 3", identityDictionary[@"other3"]);
    XCTAssertEqual(@"other id 4", identityDictionary[@"other4"]);
    XCTAssertEqual(@"other id 5", identityDictionary[@"other5"]);
    XCTAssertEqual(@"other id 6", identityDictionary[@"other6"]);
    XCTAssertEqual(@"other id 7", identityDictionary[@"other7"]);
    XCTAssertEqual(@"other id 8", identityDictionary[@"other8"]);
    XCTAssertEqual(@"other id 9", identityDictionary[@"other9"]);
    XCTAssertEqual(@"other id 10", identityDictionary[@"other10"]);
    XCTAssertEqual(@"mobile number", identityDictionary[@"mobile_number"]);
    XCTAssertEqual(@"phone number 2", identityDictionary[@"phone_number_2"]);
    XCTAssertEqual(@"phone number 3", identityDictionary[@"phone_number_3"]);
    XCTAssertEqual(@"advertiser", identityDictionary[@"ios_idfa"]);
    XCTAssertEqual(@"vendor", identityDictionary[@"ios_idfv"]);
#if TARGET_OS_IOS == 1
    XCTAssertEqual(@"push token", identityDictionary[@"push_token"]);
#endif
    XCTAssertEqual(@"application stamp", identityDictionary[@"device_application_stamp"]);
    XCTAssertEqual(@"customer id", identityDictionary[@"customerid"]);
    XCTAssertEqual(@"email id", identityDictionary[@"email"]);
    XCTAssertEqual(@"facebook id", identityDictionary[@"facebook"]);
    XCTAssertEqual(@"facebook audience id", identityDictionary[@"facebookcustomaudienceid"]);
    XCTAssertEqual(@"google id", identityDictionary[@"google"]);
    XCTAssertEqual(@"microsoft id", identityDictionary[@"microsoft"]);
    XCTAssertEqual(@"yahoo id", identityDictionary[@"yahoo"]);
    XCTAssertEqual(@"twitter id", identityDictionary[@"twitter"]);
}

- (void)testConstructIdentityApiRequestWithNotDeterminedATTStatus {
    [[MParticle sharedInstance] setATTStatus:MPATTAuthorizationStatusNotDetermined withATTStatusTimestampMillis:nil];
    MPIdentityApiRequest *request = [[MPIdentityApiRequest alloc] init];
    [request setIdentity:@"other id" identityType:MPIdentityOther];
    [request setIdentity:@"other id 2" identityType:MPIdentityOther2];
    [request setIdentity:@"other id 3" identityType:MPIdentityOther3];
    [request setIdentity:@"other id 4" identityType:MPIdentityOther4];
    [request setIdentity:@"other id 5" identityType:MPIdentityOther5];
    [request setIdentity:@"other id 6" identityType:MPIdentityOther6];
    [request setIdentity:@"other id 7" identityType:MPIdentityOther7];
    [request setIdentity:@"other id 8" identityType:MPIdentityOther8];
    [request setIdentity:@"other id 9" identityType:MPIdentityOther9];
    [request setIdentity:@"other id 10" identityType:MPIdentityOther10];
    [request setIdentity:@"mobile number" identityType:MPIdentityMobileNumber];
    [request setIdentity:@"phone number 2" identityType:MPIdentityPhoneNumber2];
    [request setIdentity:@"phone number 3" identityType:MPIdentityPhoneNumber3];
    [request setIdentity:@"advertiser" identityType:MPIdentityIOSAdvertiserId];
    [request setIdentity:@"vendor" identityType:MPIdentityIOSVendorId];
    [request setIdentity:@"push token" identityType:MPIdentityPushToken];
    [request setIdentity:@"application stamp" identityType:MPIdentityDeviceApplicationStamp];
    [request setIdentity:@"customer id" identityType:MPIdentityCustomerId];
    [request setIdentity:@"email id" identityType:MPIdentityEmail];
    [request setIdentity:@"facebook id" identityType:MPIdentityFacebook];
    [request setIdentity:@"facebook audience id" identityType:MPIdentityFacebookCustomAudienceId];
    [request setIdentity:@"google id" identityType:MPIdentityGoogle];
    [request setIdentity:@"microsoft id" identityType:MPIdentityMicrosoft];
    [request setIdentity:@"yahoo id" identityType:MPIdentityYahoo];
    [request setIdentity:@"twitter id" identityType:MPIdentityTwitter];
    
    MPIdentityHTTPIdentities *httpIdentities = [[MPIdentityHTTPIdentities alloc] initWithIdentities:request.identities];
    
    XCTAssertEqual(@"other id", httpIdentities.other);
    XCTAssertEqual(@"other id 2", httpIdentities.other2);
    XCTAssertEqual(@"other id 3", httpIdentities.other3);
    XCTAssertEqual(@"other id 4", httpIdentities.other4);
    XCTAssertEqual(@"other id 5", httpIdentities.other5);
    XCTAssertEqual(@"other id 6", httpIdentities.other6);
    XCTAssertEqual(@"other id 7", httpIdentities.other7);
    XCTAssertEqual(@"other id 8", httpIdentities.other8);
    XCTAssertEqual(@"other id 9", httpIdentities.other9);
    XCTAssertEqual(@"other id 10", httpIdentities.other10);
    XCTAssertEqual(@"mobile number", httpIdentities.mobileNumber);
    XCTAssertEqual(@"phone number 2", httpIdentities.phoneNumber2);
    XCTAssertEqual(@"phone number 3", httpIdentities.phoneNumber3);
    XCTAssertNil(httpIdentities.advertiserId);
    XCTAssertEqual(@"vendor", httpIdentities.vendorId);
    XCTAssertEqual(@"push token", httpIdentities.pushToken);
    XCTAssertEqual(@"application stamp", httpIdentities.deviceApplicationStamp);
    XCTAssertEqual(@"customer id", httpIdentities.customerId);
    XCTAssertEqual(@"email id", httpIdentities.email);
    XCTAssertEqual(@"facebook id", httpIdentities.facebook);
    XCTAssertEqual(@"facebook audience id", httpIdentities.facebookCustomAudienceId);
    XCTAssertEqual(@"google id", httpIdentities.google);
    XCTAssertEqual(@"microsoft id", httpIdentities.microsoft);
    XCTAssertEqual(@"yahoo id", httpIdentities.yahoo);
    XCTAssertEqual(@"twitter id", httpIdentities.twitter);
    
    NSDictionary *identityDictionary = [httpIdentities dictionaryRepresentation];
    XCTAssertEqual(@"other id", identityDictionary[@"other"]);
    XCTAssertEqual(@"other id 2", identityDictionary[@"other2"]);
    XCTAssertEqual(@"other id 3", identityDictionary[@"other3"]);
    XCTAssertEqual(@"other id 4", identityDictionary[@"other4"]);
    XCTAssertEqual(@"other id 5", identityDictionary[@"other5"]);
    XCTAssertEqual(@"other id 6", identityDictionary[@"other6"]);
    XCTAssertEqual(@"other id 7", identityDictionary[@"other7"]);
    XCTAssertEqual(@"other id 8", identityDictionary[@"other8"]);
    XCTAssertEqual(@"other id 9", identityDictionary[@"other9"]);
    XCTAssertEqual(@"other id 10", identityDictionary[@"other10"]);
    XCTAssertEqual(@"mobile number", identityDictionary[@"mobile_number"]);
    XCTAssertEqual(@"phone number 2", identityDictionary[@"phone_number_2"]);
    XCTAssertEqual(@"phone number 3", identityDictionary[@"phone_number_3"]);
    XCTAssertNil(identityDictionary[@"ios_idfa"]);
    XCTAssertEqual(@"vendor", identityDictionary[@"ios_idfv"]);
#if TARGET_OS_IOS == 1
    XCTAssertEqual(@"push token", identityDictionary[@"push_token"]);
#endif
    XCTAssertEqual(@"application stamp", identityDictionary[@"device_application_stamp"]);
    XCTAssertEqual(@"customer id", identityDictionary[@"customerid"]);
    XCTAssertEqual(@"email id", identityDictionary[@"email"]);
    XCTAssertEqual(@"facebook id", identityDictionary[@"facebook"]);
    XCTAssertEqual(@"facebook audience id", identityDictionary[@"facebookcustomaudienceid"]);
    XCTAssertEqual(@"google id", identityDictionary[@"google"]);
    XCTAssertEqual(@"microsoft id", identityDictionary[@"microsoft"]);
    XCTAssertEqual(@"yahoo id", identityDictionary[@"yahoo"]);
    XCTAssertEqual(@"twitter id", identityDictionary[@"twitter"]);
}

- (void)testConstructIdentityApiRequestWithRestrictedATTStatus {
    [[MParticle sharedInstance] setATTStatus:MPATTAuthorizationStatusRestricted withATTStatusTimestampMillis:nil];
    MPIdentityApiRequest *request = [[MPIdentityApiRequest alloc] init];
    [request setIdentity:@"other id" identityType:MPIdentityOther];
    [request setIdentity:@"other id 2" identityType:MPIdentityOther2];
    [request setIdentity:@"other id 3" identityType:MPIdentityOther3];
    [request setIdentity:@"other id 4" identityType:MPIdentityOther4];
    [request setIdentity:@"other id 5" identityType:MPIdentityOther5];
    [request setIdentity:@"other id 6" identityType:MPIdentityOther6];
    [request setIdentity:@"other id 7" identityType:MPIdentityOther7];
    [request setIdentity:@"other id 8" identityType:MPIdentityOther8];
    [request setIdentity:@"other id 9" identityType:MPIdentityOther9];
    [request setIdentity:@"other id 10" identityType:MPIdentityOther10];
    [request setIdentity:@"mobile number" identityType:MPIdentityMobileNumber];
    [request setIdentity:@"phone number 2" identityType:MPIdentityPhoneNumber2];
    [request setIdentity:@"phone number 3" identityType:MPIdentityPhoneNumber3];
    [request setIdentity:@"advertiser" identityType:MPIdentityIOSAdvertiserId];
    [request setIdentity:@"vendor" identityType:MPIdentityIOSVendorId];
    [request setIdentity:@"push token" identityType:MPIdentityPushToken];
    [request setIdentity:@"application stamp" identityType:MPIdentityDeviceApplicationStamp];
    [request setIdentity:@"customer id" identityType:MPIdentityCustomerId];
    [request setIdentity:@"email id" identityType:MPIdentityEmail];
    [request setIdentity:@"facebook id" identityType:MPIdentityFacebook];
    [request setIdentity:@"facebook audience id" identityType:MPIdentityFacebookCustomAudienceId];
    [request setIdentity:@"google id" identityType:MPIdentityGoogle];
    [request setIdentity:@"microsoft id" identityType:MPIdentityMicrosoft];
    [request setIdentity:@"yahoo id" identityType:MPIdentityYahoo];
    [request setIdentity:@"twitter id" identityType:MPIdentityTwitter];
    
    MPIdentityHTTPIdentities *httpIdentities = [[MPIdentityHTTPIdentities alloc] initWithIdentities:request.identities];
    
    XCTAssertEqual(@"other id", httpIdentities.other);
    XCTAssertEqual(@"other id 2", httpIdentities.other2);
    XCTAssertEqual(@"other id 3", httpIdentities.other3);
    XCTAssertEqual(@"other id 4", httpIdentities.other4);
    XCTAssertEqual(@"other id 5", httpIdentities.other5);
    XCTAssertEqual(@"other id 6", httpIdentities.other6);
    XCTAssertEqual(@"other id 7", httpIdentities.other7);
    XCTAssertEqual(@"other id 8", httpIdentities.other8);
    XCTAssertEqual(@"other id 9", httpIdentities.other9);
    XCTAssertEqual(@"other id 10", httpIdentities.other10);
    XCTAssertEqual(@"mobile number", httpIdentities.mobileNumber);
    XCTAssertEqual(@"phone number 2", httpIdentities.phoneNumber2);
    XCTAssertEqual(@"phone number 3", httpIdentities.phoneNumber3);
    XCTAssertNil(httpIdentities.advertiserId);
    XCTAssertEqual(@"vendor", httpIdentities.vendorId);
    XCTAssertEqual(@"push token", httpIdentities.pushToken);
    XCTAssertEqual(@"application stamp", httpIdentities.deviceApplicationStamp);
    XCTAssertEqual(@"customer id", httpIdentities.customerId);
    XCTAssertEqual(@"email id", httpIdentities.email);
    XCTAssertEqual(@"facebook id", httpIdentities.facebook);
    XCTAssertEqual(@"facebook audience id", httpIdentities.facebookCustomAudienceId);
    XCTAssertEqual(@"google id", httpIdentities.google);
    XCTAssertEqual(@"microsoft id", httpIdentities.microsoft);
    XCTAssertEqual(@"yahoo id", httpIdentities.yahoo);
    XCTAssertEqual(@"twitter id", httpIdentities.twitter);
    
    NSDictionary *identityDictionary = [httpIdentities dictionaryRepresentation];
    XCTAssertEqual(@"other id", identityDictionary[@"other"]);
    XCTAssertEqual(@"other id 2", identityDictionary[@"other2"]);
    XCTAssertEqual(@"other id 3", identityDictionary[@"other3"]);
    XCTAssertEqual(@"other id 4", identityDictionary[@"other4"]);
    XCTAssertEqual(@"other id 5", identityDictionary[@"other5"]);
    XCTAssertEqual(@"other id 6", identityDictionary[@"other6"]);
    XCTAssertEqual(@"other id 7", identityDictionary[@"other7"]);
    XCTAssertEqual(@"other id 8", identityDictionary[@"other8"]);
    XCTAssertEqual(@"other id 9", identityDictionary[@"other9"]);
    XCTAssertEqual(@"other id 10", identityDictionary[@"other10"]);
    XCTAssertEqual(@"mobile number", identityDictionary[@"mobile_number"]);
    XCTAssertEqual(@"phone number 2", identityDictionary[@"phone_number_2"]);
    XCTAssertEqual(@"phone number 3", identityDictionary[@"phone_number_3"]);
    XCTAssertNil(identityDictionary[@"ios_idfa"]);
    XCTAssertEqual(@"vendor", identityDictionary[@"ios_idfv"]);
#if TARGET_OS_IOS == 1
    XCTAssertEqual(@"push token", identityDictionary[@"push_token"]);
#endif
    XCTAssertEqual(@"application stamp", identityDictionary[@"device_application_stamp"]);
    XCTAssertEqual(@"customer id", identityDictionary[@"customerid"]);
    XCTAssertEqual(@"email id", identityDictionary[@"email"]);
    XCTAssertEqual(@"facebook id", identityDictionary[@"facebook"]);
    XCTAssertEqual(@"facebook audience id", identityDictionary[@"facebookcustomaudienceid"]);
    XCTAssertEqual(@"google id", identityDictionary[@"google"]);
    XCTAssertEqual(@"microsoft id", identityDictionary[@"microsoft"]);
    XCTAssertEqual(@"yahoo id", identityDictionary[@"yahoo"]);
    XCTAssertEqual(@"twitter id", identityDictionary[@"twitter"]);
}

- (void)testConstructIdentityApiRequestWithDeniedATTStatus {
    [[MParticle sharedInstance] setATTStatus:MPATTAuthorizationStatusDenied withATTStatusTimestampMillis:nil];
    MPIdentityApiRequest *request = [[MPIdentityApiRequest alloc] init];
    [request setIdentity:@"other id" identityType:MPIdentityOther];
    [request setIdentity:@"other id 2" identityType:MPIdentityOther2];
    [request setIdentity:@"other id 3" identityType:MPIdentityOther3];
    [request setIdentity:@"other id 4" identityType:MPIdentityOther4];
    [request setIdentity:@"other id 5" identityType:MPIdentityOther5];
    [request setIdentity:@"other id 6" identityType:MPIdentityOther6];
    [request setIdentity:@"other id 7" identityType:MPIdentityOther7];
    [request setIdentity:@"other id 8" identityType:MPIdentityOther8];
    [request setIdentity:@"other id 9" identityType:MPIdentityOther9];
    [request setIdentity:@"other id 10" identityType:MPIdentityOther10];
    [request setIdentity:@"mobile number" identityType:MPIdentityMobileNumber];
    [request setIdentity:@"phone number 2" identityType:MPIdentityPhoneNumber2];
    [request setIdentity:@"phone number 3" identityType:MPIdentityPhoneNumber3];
    [request setIdentity:@"advertiser" identityType:MPIdentityIOSAdvertiserId];
    [request setIdentity:@"vendor" identityType:MPIdentityIOSVendorId];
    [request setIdentity:@"push token" identityType:MPIdentityPushToken];
    [request setIdentity:@"application stamp" identityType:MPIdentityDeviceApplicationStamp];
    [request setIdentity:@"customer id" identityType:MPIdentityCustomerId];
    [request setIdentity:@"email id" identityType:MPIdentityEmail];
    [request setIdentity:@"facebook id" identityType:MPIdentityFacebook];
    [request setIdentity:@"facebook audience id" identityType:MPIdentityFacebookCustomAudienceId];
    [request setIdentity:@"google id" identityType:MPIdentityGoogle];
    [request setIdentity:@"microsoft id" identityType:MPIdentityMicrosoft];
    [request setIdentity:@"yahoo id" identityType:MPIdentityYahoo];
    [request setIdentity:@"twitter id" identityType:MPIdentityTwitter];
    
    MPIdentityHTTPIdentities *httpIdentities = [[MPIdentityHTTPIdentities alloc] initWithIdentities:request.identities];
    
    XCTAssertEqual(@"other id", httpIdentities.other);
    XCTAssertEqual(@"other id 2", httpIdentities.other2);
    XCTAssertEqual(@"other id 3", httpIdentities.other3);
    XCTAssertEqual(@"other id 4", httpIdentities.other4);
    XCTAssertEqual(@"other id 5", httpIdentities.other5);
    XCTAssertEqual(@"other id 6", httpIdentities.other6);
    XCTAssertEqual(@"other id 7", httpIdentities.other7);
    XCTAssertEqual(@"other id 8", httpIdentities.other8);
    XCTAssertEqual(@"other id 9", httpIdentities.other9);
    XCTAssertEqual(@"other id 10", httpIdentities.other10);
    XCTAssertEqual(@"mobile number", httpIdentities.mobileNumber);
    XCTAssertEqual(@"phone number 2", httpIdentities.phoneNumber2);
    XCTAssertEqual(@"phone number 3", httpIdentities.phoneNumber3);
    XCTAssertNil(httpIdentities.advertiserId);
    XCTAssertEqual(@"vendor", httpIdentities.vendorId);
    XCTAssertEqual(@"push token", httpIdentities.pushToken);
    XCTAssertEqual(@"application stamp", httpIdentities.deviceApplicationStamp);
    XCTAssertEqual(@"customer id", httpIdentities.customerId);
    XCTAssertEqual(@"email id", httpIdentities.email);
    XCTAssertEqual(@"facebook id", httpIdentities.facebook);
    XCTAssertEqual(@"facebook audience id", httpIdentities.facebookCustomAudienceId);
    XCTAssertEqual(@"google id", httpIdentities.google);
    XCTAssertEqual(@"microsoft id", httpIdentities.microsoft);
    XCTAssertEqual(@"yahoo id", httpIdentities.yahoo);
    XCTAssertEqual(@"twitter id", httpIdentities.twitter);
    
    NSDictionary *identityDictionary = [httpIdentities dictionaryRepresentation];
    XCTAssertEqual(@"other id", identityDictionary[@"other"]);
    XCTAssertEqual(@"other id 2", identityDictionary[@"other2"]);
    XCTAssertEqual(@"other id 3", identityDictionary[@"other3"]);
    XCTAssertEqual(@"other id 4", identityDictionary[@"other4"]);
    XCTAssertEqual(@"other id 5", identityDictionary[@"other5"]);
    XCTAssertEqual(@"other id 6", identityDictionary[@"other6"]);
    XCTAssertEqual(@"other id 7", identityDictionary[@"other7"]);
    XCTAssertEqual(@"other id 8", identityDictionary[@"other8"]);
    XCTAssertEqual(@"other id 9", identityDictionary[@"other9"]);
    XCTAssertEqual(@"other id 10", identityDictionary[@"other10"]);
    XCTAssertEqual(@"mobile number", identityDictionary[@"mobile_number"]);
    XCTAssertEqual(@"phone number 2", identityDictionary[@"phone_number_2"]);
    XCTAssertEqual(@"phone number 3", identityDictionary[@"phone_number_3"]);
    XCTAssertNil(identityDictionary[@"ios_idfa"]);
    XCTAssertEqual(@"vendor", identityDictionary[@"ios_idfv"]);
#if TARGET_OS_IOS == 1
    XCTAssertEqual(@"push token", identityDictionary[@"push_token"]);
#endif
    XCTAssertEqual(@"application stamp", identityDictionary[@"device_application_stamp"]);
    XCTAssertEqual(@"customer id", identityDictionary[@"customerid"]);
    XCTAssertEqual(@"email id", identityDictionary[@"email"]);
    XCTAssertEqual(@"facebook id", identityDictionary[@"facebook"]);
    XCTAssertEqual(@"facebook audience id", identityDictionary[@"facebookcustomaudienceid"]);
    XCTAssertEqual(@"google id", identityDictionary[@"google"]);
    XCTAssertEqual(@"microsoft id", identityDictionary[@"microsoft"]);
    XCTAssertEqual(@"yahoo id", identityDictionary[@"yahoo"]);
    XCTAssertEqual(@"twitter id", identityDictionary[@"twitter"]);
}

- (void)testConstructIdentityApiRequestWithAuthorizedATTStatus {
    [[MParticle sharedInstance] setATTStatus:MPATTAuthorizationStatusAuthorized withATTStatusTimestampMillis:nil];
    MPIdentityApiRequest *request = [[MPIdentityApiRequest alloc] init];
    [request setIdentity:@"other id" identityType:MPIdentityOther];
    [request setIdentity:@"other id 2" identityType:MPIdentityOther2];
    [request setIdentity:@"other id 3" identityType:MPIdentityOther3];
    [request setIdentity:@"other id 4" identityType:MPIdentityOther4];
    [request setIdentity:@"other id 5" identityType:MPIdentityOther5];
    [request setIdentity:@"other id 6" identityType:MPIdentityOther6];
    [request setIdentity:@"other id 7" identityType:MPIdentityOther7];
    [request setIdentity:@"other id 8" identityType:MPIdentityOther8];
    [request setIdentity:@"other id 9" identityType:MPIdentityOther9];
    [request setIdentity:@"other id 10" identityType:MPIdentityOther10];
    [request setIdentity:@"mobile number" identityType:MPIdentityMobileNumber];
    [request setIdentity:@"phone number 2" identityType:MPIdentityPhoneNumber2];
    [request setIdentity:@"phone number 3" identityType:MPIdentityPhoneNumber3];
    [request setIdentity:@"advertiser" identityType:MPIdentityIOSAdvertiserId];
    [request setIdentity:@"vendor" identityType:MPIdentityIOSVendorId];
    [request setIdentity:@"push token" identityType:MPIdentityPushToken];
    [request setIdentity:@"application stamp" identityType:MPIdentityDeviceApplicationStamp];
    [request setIdentity:@"customer id" identityType:MPIdentityCustomerId];
    [request setIdentity:@"email id" identityType:MPIdentityEmail];
    [request setIdentity:@"facebook id" identityType:MPIdentityFacebook];
    [request setIdentity:@"facebook audience id" identityType:MPIdentityFacebookCustomAudienceId];
    [request setIdentity:@"google id" identityType:MPIdentityGoogle];
    [request setIdentity:@"microsoft id" identityType:MPIdentityMicrosoft];
    [request setIdentity:@"yahoo id" identityType:MPIdentityYahoo];
    [request setIdentity:@"twitter id" identityType:MPIdentityTwitter];
    
    MPIdentityHTTPIdentities *httpIdentities = [[MPIdentityHTTPIdentities alloc] initWithIdentities:request.identities];
    
    XCTAssertEqual(@"other id", httpIdentities.other);
    XCTAssertEqual(@"other id 2", httpIdentities.other2);
    XCTAssertEqual(@"other id 3", httpIdentities.other3);
    XCTAssertEqual(@"other id 4", httpIdentities.other4);
    XCTAssertEqual(@"other id 5", httpIdentities.other5);
    XCTAssertEqual(@"other id 6", httpIdentities.other6);
    XCTAssertEqual(@"other id 7", httpIdentities.other7);
    XCTAssertEqual(@"other id 8", httpIdentities.other8);
    XCTAssertEqual(@"other id 9", httpIdentities.other9);
    XCTAssertEqual(@"other id 10", httpIdentities.other10);
    XCTAssertEqual(@"mobile number", httpIdentities.mobileNumber);
    XCTAssertEqual(@"phone number 2", httpIdentities.phoneNumber2);
    XCTAssertEqual(@"phone number 3", httpIdentities.phoneNumber3);
    XCTAssertEqual(@"advertiser", httpIdentities.advertiserId);
    XCTAssertEqual(@"vendor", httpIdentities.vendorId);
    XCTAssertEqual(@"push token", httpIdentities.pushToken);
    XCTAssertEqual(@"application stamp", httpIdentities.deviceApplicationStamp);
    XCTAssertEqual(@"customer id", httpIdentities.customerId);
    XCTAssertEqual(@"email id", httpIdentities.email);
    XCTAssertEqual(@"facebook id", httpIdentities.facebook);
    XCTAssertEqual(@"facebook audience id", httpIdentities.facebookCustomAudienceId);
    XCTAssertEqual(@"google id", httpIdentities.google);
    XCTAssertEqual(@"microsoft id", httpIdentities.microsoft);
    XCTAssertEqual(@"yahoo id", httpIdentities.yahoo);
    XCTAssertEqual(@"twitter id", httpIdentities.twitter);

    
    NSDictionary *identityDictionary = [httpIdentities dictionaryRepresentation];
    XCTAssertEqual(@"other id", identityDictionary[@"other"]);
    XCTAssertEqual(@"other id 2", identityDictionary[@"other2"]);
    XCTAssertEqual(@"other id 3", identityDictionary[@"other3"]);
    XCTAssertEqual(@"other id 4", identityDictionary[@"other4"]);
    XCTAssertEqual(@"other id 5", identityDictionary[@"other5"]);
    XCTAssertEqual(@"other id 6", identityDictionary[@"other6"]);
    XCTAssertEqual(@"other id 7", identityDictionary[@"other7"]);
    XCTAssertEqual(@"other id 8", identityDictionary[@"other8"]);
    XCTAssertEqual(@"other id 9", identityDictionary[@"other9"]);
    XCTAssertEqual(@"other id 10", identityDictionary[@"other10"]);
    XCTAssertEqual(@"mobile number", identityDictionary[@"mobile_number"]);
    XCTAssertEqual(@"phone number 2", identityDictionary[@"phone_number_2"]);
    XCTAssertEqual(@"phone number 3", identityDictionary[@"phone_number_3"]);
    XCTAssertEqual(@"advertiser", identityDictionary[@"ios_idfa"]);
    XCTAssertEqual(@"vendor", identityDictionary[@"ios_idfv"]);
#if TARGET_OS_IOS == 1
    XCTAssertEqual(@"push token", identityDictionary[@"push_token"]);
#endif
    XCTAssertEqual(@"application stamp", identityDictionary[@"device_application_stamp"]);
    XCTAssertEqual(@"customer id", identityDictionary[@"customerid"]);
    XCTAssertEqual(@"email id", identityDictionary[@"email"]);
    XCTAssertEqual(@"facebook id", identityDictionary[@"facebook"]);
    XCTAssertEqual(@"facebook audience id", identityDictionary[@"facebookcustomaudienceid"]);
    XCTAssertEqual(@"google id", identityDictionary[@"google"]);
    XCTAssertEqual(@"microsoft id", identityDictionary[@"microsoft"]);
    XCTAssertEqual(@"yahoo id", identityDictionary[@"yahoo"]);
    XCTAssertEqual(@"twitter id", identityDictionary[@"twitter"]);
}

- (void)testNoEmptyModifyRequests {
    MPNetworkCommunication_PRIVATE *network = [[MPNetworkCommunication_PRIVATE alloc] init];
    
    id partialMock = OCMPartialMock(network);
    
    [[[partialMock reject] ignoringNonObjectArgs] identityApiRequestWithURL:[OCMArg any] identityRequest:[OCMArg any] blockOtherRequests:[OCMArg any] completion:[OCMArg any]];
    
    [partialMock modifyWithIdentityChanges:nil blockOtherRequests:YES completion:^(MPIdentityHTTPModifySuccessResponse * _Nullable httpResponse, NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertNotNil(httpResponse);
        XCTAssert([httpResponse isKindOfClass:[MPIdentityHTTPModifySuccessResponse class]]);
    }];

    [partialMock modifyWithIdentityChanges:@[] blockOtherRequests:YES completion:^(MPIdentityHTTPModifySuccessResponse * _Nullable httpResponse, NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertNotNil(httpResponse);
        XCTAssert([httpResponse isKindOfClass:[MPIdentityHTTPModifySuccessResponse class]]);
    }];
}

- (void)testModifyChangeResultsResponse {
    NSDictionary *responseDictionary = @{
                                   @"client_sdk":@{
                                           @"platform":@"ios", @"sdk_version":@"7.8.6", @"sdk_vendor":@"mparticle"
                                           },
                                   @"environment":@"development",
                                   @"request_timestamp_ms":@1551205524000,
                                   @"request_id":@"04B0B49E-B2F1-48B5-81E6-A9F9FDB529F5",
                                   @"identity_changes":@[@{@"new_value":@"bar-id",@"old_value":@0,@"identity_type":@"other"},@{@"new_value":@"foo@example.com",@"old_value":@"user@thisappisawesomewhyhaventithoughtaboutbuildingit.com",@"identity_type":@"email"},@{@"new_value":@"123456",@"old_value":@0,@"identity_type":@"customerid"}],
                               @"change_results":@[@{@"identity_type":@"email",@"modified_mpid":@"123"},@{@"identity_type":@"customerid",@"modified_mpid":@"456"}]
                                   };
    NSArray *changeArray = @[
  @{@"identity_type":@"email",@"modified_mpid":@"123"},
  @{@"identity_type":@"customerid",@"modified_mpid":@"456"}
  ];
    
    MPIdentityHTTPModifySuccessResponse *successResponse = [[MPIdentityHTTPModifySuccessResponse alloc] initWithJsonObject:responseDictionary];
    
    XCTAssertEqualObjects(successResponse.changeResults, changeArray);
}

- (void)testModifyChange {
    NSDictionary *responseDictionary = @{
                                         @"client_sdk":@{
                                                 @"platform":@"ios", @"sdk_version":@"7.8.6", @"sdk_vendor":@"mparticle"
                                                 },
                                         @"environment":@"development",
                                         @"request_timestamp_ms":@1551205524000,
                                         @"request_id":@"04B0B49E-B2F1-48B5-81E6-A9F9FDB529F5",
                                         @"identity_changes":@[@{@"new_value":@"bar-id",@"old_value":@0,@"identity_type":@"other"},@{@"new_value":@"foo@example.com",@"old_value":@"user@thisappisawesomewhyhaventithoughtaboutbuildingit.com",@"identity_type":@"email"},@{@"new_value":@"123456",@"old_value":@0,@"identity_type":@"customerid"}],
                                         @"change_results":@[@{@"identity_type":@"email",@"modified_mpid":@"123"},@{@"identity_type":@"customerid",@"modified_mpid":@"456"}]
                                         };
    MPIdentityChange *change1 = [[MPIdentityChange alloc] init];
    MParticleUser *changedUser1 = [[MParticleUser alloc] init];
    changedUser1.userId = @123;
    change1.changedUser = changedUser1;
    change1.changedIdentity = MPIdentityEmail;
    
    MPIdentityChange *change2 = [[MPIdentityChange alloc] init];
    MParticleUser *changedUser2 = [[MParticleUser alloc] init];
    changedUser2.userId = @456;
    change2.changedUser = changedUser2;
    change2.changedIdentity = MPIdentityCustomerId;
    
    NSArray<MPIdentityChange *> *changeArray = @[change1, change2];
    
    MPIdentityHTTPModifySuccessResponse *successResponse = [[MPIdentityHTTPModifySuccessResponse alloc] initWithJsonObject:responseDictionary];
    
    MPIdentityApi *identity = [[MPIdentityApi alloc] init];
    MPIdentityApiRequest *request = [MPIdentityApiRequest requestWithEmptyUser];
    NSError *error;
    
    MPModifyApiResultCallback completion = ^(MPModifyApiResult *_Nullable apiResult, NSError *_Nullable error) {
        for (int x = 0; x<apiResult.identityChanges.count; x++) {
            XCTAssertEqual(apiResult.identityChanges[x].changedUser.userId.integerValue, changeArray[x].changedUser.userId.integerValue);
            XCTAssertEqual(apiResult.identityChanges[x].changedIdentity, changeArray[x].changedIdentity);
        }
    };
    
    [identity onModifyRequestComplete:request httpResponse:successResponse completion:completion error:error];
}

- (void)testIdentityRequestComplete {
    id mockUser = OCMClassMock([MParticleUser class]);

    MPIdentityApi *identity = [[MPIdentityApi alloc] init];
    MPIdentityApi *identityMock = OCMPartialMock(identity);
    OCMStub([identityMock currentUser]).andReturn(mockUser);
    
    MPIdentityApiRequest *request = [[MPIdentityApiRequest alloc] init];
    [request setIdentity:@"1234" identityType:MPIdentityCustomerId];
    [request setIdentity:@"me@gmail.com" identityType:MPIdentityEmail];
    [request setIdentity:@"other id 3" identityType:MPIdentityOther3];
    
    NSError *error;
    MPIdentityHTTPSuccessResponse *httpResponse = [[MPIdentityHTTPSuccessResponse alloc] init];
    
    [mockUser setExpectationOrderMatters:YES];
    [[mockUser expect] setIdentitySync:@"1234" identityType:MPIdentityCustomerId];
    [[mockUser expect] setIdentitySync:@"me@gmail.com" identityType:MPIdentityEmail];
    [[mockUser expect] setIdentitySync:@"other id 3" identityType:MPIdentityOther3];
    [[mockUser reject] setIdentitySync:@"other id 4" identityType:MPIdentityOther4];
    
    [identityMock onIdentityRequestComplete:request identityRequestType:MPIdentityRequestLogin httpResponse:httpResponse completion:nil error:error];

    [mockUser verify];
}

- (void)testIdentifyIdentityRequestCompleteWithKits {
    id mockPersistenceController = OCMClassMock([MPPersistenceController_PRIVATE class]);
    [[[mockPersistenceController stub] andReturn:@"42"] mpId];
    
    id mockInstance = OCMClassMock([MParticle class]);
    id mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[mockInstance stub] andReturn:mockContainer] kitContainer_PRIVATE];
    [[[mockInstance stub] andReturn:mockInstance] sharedInstance];
    
    id mockUser = OCMClassMock([MParticleUser class]);
    
    MPIdentityApi *identity = [[MPIdentityApi alloc] init];
    id identityMock = OCMPartialMock(identity);
    [[[identityMock stub] andReturn:mockUser] currentUser];
    
    
    MPIdentityApiRequest *request = [[MPIdentityApiRequest alloc] init];
    [request setIdentity:@"1234" identityType:MPIdentityCustomerId];
    [request setIdentity:@"me@gmail.com" identityType:MPIdentityEmail];
    [request setIdentity:@"other id 3" identityType:MPIdentityOther3];
    
    NSError *error;
    MPIdentityHTTPSuccessResponse *httpResponse = [[MPIdentityHTTPSuccessResponse alloc] init];
    httpResponse.mpid = @892;
    
    [[mockContainer expect] forwardIdentitySDKCall:[OCMArg anySelector] kitHandler:OCMOCK_ANY];
    
    [identityMock onIdentityRequestComplete:request identityRequestType:MPIdentityRequestIdentify httpResponse:httpResponse completion:nil error:error];
    
    [mockContainer verifyWithDelay:0.2];
}

- (void)testLoginIdentityRequestCompleteWithKits {
    id mockPersistenceController = OCMClassMock([MPPersistenceController_PRIVATE class]);
    [[[mockPersistenceController stub] andReturn:@"42"] mpId];
    
    id mockInstance = OCMClassMock([MParticle class]);
    id mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[mockInstance stub] andReturn:mockContainer] kitContainer_PRIVATE];
    [[[mockInstance stub] andReturn:mockInstance] sharedInstance];
        
    id mockUser = OCMClassMock([MParticleUser class]);
    
    MPIdentityApi *identity = [[MPIdentityApi alloc] init];
    id identityMock = OCMPartialMock(identity);
    [[[identityMock stub] andReturn:mockUser] currentUser];

    
    MPIdentityApiRequest *request = [[MPIdentityApiRequest alloc] init];
    [request setIdentity:@"1234" identityType:MPIdentityCustomerId];
    [request setIdentity:@"me@gmail.com" identityType:MPIdentityEmail];
    [request setIdentity:@"other id 3" identityType:MPIdentityOther3];
    
    NSError *error;
    MPIdentityHTTPSuccessResponse *httpResponse = [[MPIdentityHTTPSuccessResponse alloc] init];
    httpResponse.mpid = @892;

    [[mockContainer expect] forwardIdentitySDKCall:[OCMArg anySelector] kitHandler:OCMOCK_ANY];
    
    [identityMock onIdentityRequestComplete:request identityRequestType:MPIdentityRequestLogin httpResponse:httpResponse completion:nil error:error];
    
    [mockContainer verifyWithDelay:0.2];
}

- (void)testLogoutIdentityRequestCompleteWithKits {
    id mockPersistenceController = OCMClassMock([MPPersistenceController_PRIVATE class]);
    [[[mockPersistenceController stub] andReturn:@"42"] mpId];
    
    id mockInstance = OCMClassMock([MParticle class]);
    id mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[mockInstance stub] andReturn:mockContainer] kitContainer_PRIVATE];
    [[[mockInstance stub] andReturn:mockInstance] sharedInstance];
    
    id mockUser = OCMClassMock([MParticleUser class]);
    
    MPIdentityApi *identity = [[MPIdentityApi alloc] init];
    id identityMock = OCMPartialMock(identity);
    [[[identityMock stub] andReturn:mockUser] currentUser];
    
    MPIdentityApiRequest *request = [MPIdentityApiRequest requestWithUser:mockUser];
    
    NSError *error;
    MPIdentityHTTPSuccessResponse *httpResponse = [[MPIdentityHTTPSuccessResponse alloc] init];
    httpResponse.mpid = @892;

    [[mockContainer expect] forwardIdentitySDKCall:[OCMArg anySelector] kitHandler:OCMOCK_ANY];
    
    [identityMock onIdentityRequestComplete:request identityRequestType:MPIdentityRequestLogout httpResponse:httpResponse completion:nil error:error];
    
    [mockContainer verifyWithDelay:0.2];
}

- (void)testIdentifyIdentityRequestCompleteWithKitsAndNoUserChange {
    id mockPersistenceController = OCMClassMock([MPPersistenceController_PRIVATE class]);
    [[[mockPersistenceController stub] andReturn:@"42"] mpId];
    
    id mockInstance = OCMClassMock([MParticle class]);
    id mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[mockInstance stub] andReturn:mockContainer] kitContainer_PRIVATE];
    [[[mockInstance stub] andReturn:mockInstance] sharedInstance];
    
    id mockUser = OCMClassMock([MParticleUser class]);
    
    MPIdentityApi *identity = [[MPIdentityApi alloc] init];
    id identityMock = OCMPartialMock(identity);
    [[[identityMock stub] andReturn:mockUser] currentUser];
    
    
    MPIdentityApiRequest *request = [[MPIdentityApiRequest alloc] init];
    [request setIdentity:@"1234" identityType:MPIdentityCustomerId];
    [request setIdentity:@"me@gmail.com" identityType:MPIdentityEmail];
    [request setIdentity:@"other id 3" identityType:MPIdentityOther3];
    
    NSError *error;
    MPIdentityHTTPSuccessResponse *httpResponse = [[MPIdentityHTTPSuccessResponse alloc] init];
    httpResponse.mpid = @42;
    
    [[mockContainer expect] forwardIdentitySDKCall:[OCMArg anySelector] kitHandler:OCMOCK_ANY];
    
    [identityMock onIdentityRequestComplete:request identityRequestType:MPIdentityRequestIdentify httpResponse:httpResponse completion:nil error:error];
    
    [mockContainer verifyWithDelay:0.2];
}

- (void)testLoginIdentityRequestCompleteWithKitsAndNoUserChange {
    id mockPersistenceController = OCMClassMock([MPPersistenceController_PRIVATE class]);
    [[[mockPersistenceController stub] andReturn:@"42"] mpId];
    
    id mockInstance = OCMClassMock([MParticle class]);
    id mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[mockInstance stub] andReturn:mockContainer] kitContainer_PRIVATE];
    [[[mockInstance stub] andReturn:mockInstance] sharedInstance];
    
    id mockUser = OCMClassMock([MParticleUser class]);
    
    MPIdentityApi *identity = [[MPIdentityApi alloc] init];
    id identityMock = OCMPartialMock(identity);
    [[[identityMock stub] andReturn:mockUser] currentUser];
    
    
    MPIdentityApiRequest *request = [[MPIdentityApiRequest alloc] init];
    [request setIdentity:@"1234" identityType:MPIdentityCustomerId];
    [request setIdentity:@"me@gmail.com" identityType:MPIdentityEmail];
    [request setIdentity:@"other id 3" identityType:MPIdentityOther3];
    
    NSError *error;
    MPIdentityHTTPSuccessResponse *httpResponse = [[MPIdentityHTTPSuccessResponse alloc] init];
    httpResponse.mpid = @42;
    
    [[mockContainer expect] forwardIdentitySDKCall:[OCMArg anySelector] kitHandler:OCMOCK_ANY];
    
    [identityMock onIdentityRequestComplete:request identityRequestType:MPIdentityRequestLogin httpResponse:httpResponse completion:nil error:error];
    
    [mockContainer verifyWithDelay:0.2];
}

- (void)testLogoutIdentityRequestCompleteWithKitsAndNoUserChange {
    id mockPersistenceController = OCMClassMock([MPPersistenceController_PRIVATE class]);
    [[[mockPersistenceController stub] andReturn:@"42"] mpId];
    
    id mockInstance = OCMClassMock([MParticle class]);
    id mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[mockInstance stub] andReturn:mockContainer] kitContainer_PRIVATE];
    [[[mockInstance stub] andReturn:mockInstance] sharedInstance];
    
    id mockUser = OCMClassMock([MParticleUser class]);
    
    MPIdentityApi *identity = [[MPIdentityApi alloc] init];
    id identityMock = OCMPartialMock(identity);
    [[[identityMock stub] andReturn:mockUser] currentUser];
    
    MPIdentityApiRequest *request = [MPIdentityApiRequest requestWithUser:mockUser];
    
    NSError *error;
    MPIdentityHTTPSuccessResponse *httpResponse = [[MPIdentityHTTPSuccessResponse alloc] init];
    httpResponse.mpid = @42;
    
    [[mockContainer expect] forwardIdentitySDKCall:[OCMArg anySelector] kitHandler:OCMOCK_ANY];
    
    [identityMock onIdentityRequestComplete:request identityRequestType:MPIdentityRequestLogout httpResponse:httpResponse completion:nil error:error];
    
    [mockContainer verifyWithDelay:0.2];
}

- (void)testMPIdZeroToMPId {
    id mockPersistenceController = OCMClassMock([MPPersistenceController_PRIVATE class]);
    [[[mockPersistenceController stub] andReturn:@"0"] mpId];
    
    id mockInstance = OCMClassMock([MParticle class]);
    id mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[mockInstance stub] andReturn:mockContainer] kitContainer_PRIVATE];
    [[[mockInstance stub] andReturn:mockPersistenceController] persistenceController];
    [[[mockInstance stub] andReturn:mockInstance] sharedInstance];
    
    id mockUser = OCMClassMock([MParticleUser class]);
    
    MPIdentityApi *identity = [[MPIdentityApi alloc] init];
    id identityMock = OCMPartialMock(identity);
    [[[identityMock stub] andReturn:mockUser] currentUser];
    
    
    MPIdentityApiRequest *request = [[MPIdentityApiRequest alloc] init];
    [request setIdentity:@"1234" identityType:MPIdentityCustomerId];
    [request setIdentity:@"me@gmail.com" identityType:MPIdentityEmail];
    [request setIdentity:@"other id 3" identityType:MPIdentityOther3];
    
    NSError *error;
    MPIdentityHTTPSuccessResponse *httpResponse = [[MPIdentityHTTPSuccessResponse alloc] init];
    httpResponse.mpid = @42;
    
    [[mockPersistenceController expect] moveContentFromMpidZeroToMpid:@42];
    [[mockPersistenceController reject] moveContentFromMpidZeroToMpid:@60];
    
    [identityMock onIdentityRequestComplete:request identityRequestType:MPIdentityRequestLogin httpResponse:httpResponse completion:nil error:error];
    
    [mockPersistenceController verifyWithDelay:0.2];
}

- (void)testModifyRequestComplete {
    id mockUser = OCMClassMock([MParticleUser class]);
    
    MPIdentityApi *identity = [[MPIdentityApi alloc] init];
    MPIdentityApi *identityMock = OCMPartialMock(identity);
    OCMStub([identityMock currentUser]).andReturn(mockUser);
    
    MPIdentityApiRequest *request = [[MPIdentityApiRequest alloc] init];
    [request setIdentity:@"5678" identityType:MPIdentityCustomerId];
    [request setIdentity:@"me@gmail.com" identityType:MPIdentityEmail];
    [request setIdentity:@"other id 3" identityType:MPIdentityOther3];
    
    NSError *error;
    MPIdentityHTTPModifySuccessResponse *httpResponse = [[MPIdentityHTTPModifySuccessResponse alloc] init];
    
    [mockUser setExpectationOrderMatters:YES];
    [[mockUser expect] setIdentitySync:@"5678" identityType:MPIdentityCustomerId];
    [[mockUser expect] setIdentitySync:@"me@gmail.com" identityType:MPIdentityEmail];
    [[mockUser expect] setIdentitySync:@"other id 3" identityType:MPIdentityOther3];
    [[mockUser reject] setIdentitySync:@"other id 4" identityType:MPIdentityOther4];
    
    [identityMock onModifyRequestComplete:request httpResponse:httpResponse completion:nil error:error];
    
    [mockUser verify];
}

- (void)testModifyRequestCompleteWithKits {
    id mockInstance = OCMClassMock([MParticle class]);
    id mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[mockInstance stub] andReturn:mockContainer] kitContainer_PRIVATE];
    [[[mockInstance stub] andReturn:mockInstance] sharedInstance];
    
    id mockUser = OCMClassMock([MParticleUser class]);
    
    MPIdentityApi *identity = [[MPIdentityApi alloc] init];
    id identityMock = OCMPartialMock(identity);
    OCMStub([identityMock currentUser]).andReturn(mockUser);
    
    MPIdentityApiRequest *request = [[MPIdentityApiRequest alloc] init];
    [request setIdentity:@"5678" identityType:MPIdentityCustomerId];
    [request setIdentity:@"me@gmail.com" identityType:MPIdentityEmail];
    [request setIdentity:@"other id 3" identityType:MPIdentityOther3];
    
    NSError *error;
    MPIdentityHTTPModifySuccessResponse *httpResponse = [[MPIdentityHTTPModifySuccessResponse alloc] init];

    [[mockContainer expect] forwardIdentitySDKCall:[OCMArg anySelector] kitHandler:OCMOCK_ANY];
    [identityMock onModifyRequestComplete:request httpResponse:httpResponse completion:nil error:error];
    
    [mockContainer verifyWithDelay:0.2];
}

- (void)testIdentify {
    id mockManager = OCMClassMock([MPIdentityApiManager class]);
    
    MPIdentityApi *identity = [[MPIdentityApi alloc] init];
    MPIdentityApi *identityMock = OCMPartialMock(identity);
    OCMStub([identityMock apiManager]).andReturn(mockManager);
    
    MPIdentityApiRequest *request = [[MPIdentityApiRequest alloc] init];
    [request setIdentity:@"5678" identityType:MPIdentityCustomerId];
    [request setIdentity:@"me@gmail.com" identityType:MPIdentityEmail];
    [request setIdentity:@"other id 3" identityType:MPIdentityOther3];
    
    [[mockManager expect] identify:request completion:OCMOCK_ANY];
    
    [identityMock identify:request completion:nil];
    
    [mockManager verifyWithDelay:0.2];
}

- (void)testLogin {
    id mockManager = OCMClassMock([MPIdentityApiManager class]);
    
    MPIdentityApi *identity = [[MPIdentityApi alloc] init];
    MPIdentityApi *identityMock = OCMPartialMock(identity);
    OCMStub([identityMock apiManager]).andReturn(mockManager);
    
    MPIdentityApiRequest *request = [[MPIdentityApiRequest alloc] init];
    [request setIdentity:@"5678" identityType:MPIdentityCustomerId];
    [request setIdentity:@"me@gmail.com" identityType:MPIdentityEmail];
    [request setIdentity:@"other id 3" identityType:MPIdentityOther3];
    
    [[mockManager expect] loginRequest:request completion:OCMOCK_ANY];
    
    [identityMock login:request completion:nil];
    
    [mockManager verifyWithDelay:0.2];
}

- (void)testLogout {
    id mockManager = OCMClassMock([MPIdentityApiManager class]);
    
    MPIdentityApi *identity = [[MPIdentityApi alloc] init];
    MPIdentityApi *identityMock = OCMPartialMock(identity);
    OCMStub([identityMock apiManager]).andReturn(mockManager);
    
    MPIdentityApiRequest *request = [[MPIdentityApiRequest alloc] init];
    [request setIdentity:@"5678" identityType:MPIdentityCustomerId];
    [request setIdentity:@"me@gmail.com" identityType:MPIdentityEmail];
    [request setIdentity:@"other id 3" identityType:MPIdentityOther3];
    
    [[mockManager expect] logout:request completion:OCMOCK_ANY];
    
    [identityMock logout:request completion:nil];
    
    [mockManager verifyWithDelay:0.2];
}

- (void)testModify {
    id mockManager = OCMClassMock([MPIdentityApiManager class]);
    
    MPIdentityApi *identity = [[MPIdentityApi alloc] init];
    MPIdentityApi *identityMock = OCMPartialMock(identity);
    OCMStub([identityMock apiManager]).andReturn(mockManager);
    
    MPIdentityApiRequest *request = [[MPIdentityApiRequest alloc] init];
    [request setIdentity:@"5678" identityType:MPIdentityCustomerId];
    [request setIdentity:@"me@gmail.com" identityType:MPIdentityEmail];
    [request setIdentity:@"other id 3" identityType:MPIdentityOther3];
    
    [[mockManager expect] modify:request completion:OCMOCK_ANY];
    
    [identityMock modify:request completion:nil];
    
    [mockManager verifyWithDelay:0.2];
}

- (void)testLastSeenSorting {
    MParticleUser *user1 = [[MParticleUser alloc] init];
    MParticleUser *user2 = [[MParticleUser alloc] init];
    MParticleUser *user3 = [[MParticleUser alloc] init];
    MParticleUser *userMock1 = OCMPartialMock(user1);
    MParticleUser *userMock2 = OCMPartialMock(user2);
    MParticleUser *userMock3 = OCMPartialMock(user3);
    
    OCMStub([userMock1 lastSeen]).andReturn([NSDate dateWithTimeIntervalSinceNow:-20]);
    OCMStub([userMock2 lastSeen]).andReturn([NSDate dateWithTimeIntervalSinceNow:-30]);
    OCMStub([userMock3 lastSeen]).andReturn([NSDate dateWithTimeIntervalSinceNow:-10]);
    
    MPIdentityApi *identity = [[MPIdentityApi alloc] init];
    NSMutableArray<MParticleUser *> *userArray = @[userMock1, userMock2, userMock3].mutableCopy;
    NSArray<MParticleUser *> *resultArray = [identity sortedUserArrayByLastSeen:userArray];
    NSArray<MParticleUser *> *expectedResult = @[userMock3, userMock1, userMock2];
    XCTAssertEqualObjects(resultArray, expectedResult);
}

- (void)testAliasNullUsers {
    MPAliasRequest *request = [MPAliasRequest requestWithSourceUser:(id _Nonnull)nil destinationUser:(id _Nonnull)nil];
    BOOL result = [MParticle.sharedInstance.identity aliasUsers:request];
    XCTAssertFalse(result);
}

- (void)testAliasOneNullUser {
    MParticleUser *user = [[MParticleUser alloc] init];
    MPAliasRequest *request = [MPAliasRequest requestWithSourceUser:user destinationUser:(id _Nonnull)nil];
    BOOL result = [MParticle.sharedInstance.identity aliasUsers:request];
    XCTAssertFalse(result);
    
    request = [MPAliasRequest requestWithSourceUser:(id _Nonnull)nil destinationUser:user];
    result = [MParticle.sharedInstance.identity aliasUsers:request];
    XCTAssertFalse(result);
}

- (void)testAliasZeroUserId {
    MParticleUser *user = [[MParticleUser alloc] init];
    user.userId = @0;
    MParticleUser *user2 = [[MParticleUser alloc] init];
    user2.userId = @0;
    MPAliasRequest *request = [MPAliasRequest requestWithSourceUser:user destinationUser:user2];
    BOOL result = [MParticle.sharedInstance.identity aliasUsers:request];
    XCTAssertFalse(result);
}

- (void)testAliasAlternateBadUserIds {
    NSNumber *mpid1 = nil;
    NSNumber *mpid2 = nil;
    NSDate *startTime = [NSDate dateWithTimeIntervalSinceNow:-30];
    NSDate *endTime = [NSDate date];
    MPAliasRequest *request = [MPAliasRequest requestWithSourceMPID:mpid1 destinationMPID:mpid2 startTime:startTime endTime:endTime];
    BOOL result = [MParticle.sharedInstance.identity aliasUsers:request];
    XCTAssertFalse(result);
    
    mpid1 = @0;
    mpid2 = @0;
    request = [MPAliasRequest requestWithSourceMPID:mpid1 destinationMPID:mpid2 startTime:startTime endTime:endTime];
    result = [MParticle.sharedInstance.identity aliasUsers:request];
    XCTAssertFalse(result);
}

- (void)testAliasNilDates {
    NSNumber *mpid1 = @1;
    NSNumber *mpid2 = @2;
    NSDate *startTime = nil;
    NSDate *endTime = nil;
    MPAliasRequest *request = [MPAliasRequest requestWithSourceMPID:mpid1 destinationMPID:mpid2 startTime:startTime endTime:endTime];
    XCTAssertEqual(request.sourceMPID, mpid1);
    XCTAssertEqual(request.destinationMPID, mpid2);
    XCTAssertFalse(request.startTime);
    XCTAssertFalse(request.endTime);

    BOOL result = [MParticle.sharedInstance.identity aliasUsers:request];
    
    XCTAssertTrue(request.startTime);
    XCTAssertTrue(request.endTime);
    XCTAssertTrue([request.startTime compare:request.endTime] == NSOrderedAscending);
    XCTAssertTrue(result);
}

- (void)testAliasDatesReversed {
    NSNumber *mpid1 = @1;
    NSNumber *mpid2 = @2;
    NSDate *startTime = [NSDate dateWithTimeIntervalSince1970:200];
    NSDate *endTime = [NSDate dateWithTimeIntervalSince1970:100];
    MPAliasRequest *request = [MPAliasRequest requestWithSourceMPID:mpid1 destinationMPID:mpid2 startTime:startTime endTime:endTime];
    XCTAssertEqual(request.sourceMPID, mpid1);
    XCTAssertEqual(request.destinationMPID, mpid2);
    XCTAssertEqual(request.startTime, startTime);
    XCTAssertEqual(request.endTime, endTime);
    XCTAssertTrue([request.startTime compare:request.endTime] != NSOrderedAscending);
    
    BOOL result = [MParticle.sharedInstance.identity aliasUsers:request];
    
    XCTAssertEqual(request.sourceMPID, mpid1);
    XCTAssertEqual(request.destinationMPID, mpid2);
    XCTAssertEqual(request.startTime, startTime);
    XCTAssertEqual(request.endTime, endTime);
    XCTAssertTrue([request.startTime compare:request.endTime] != NSOrderedAscending);
    XCTAssertTrue(result);
}

- (void)testAliasValidData {
    NSNumber *mpid1 = @1;
    NSNumber *mpid2 = @2;
    NSDate *startTime = [NSDate dateWithTimeIntervalSince1970:100];
    NSDate *endTime = [NSDate dateWithTimeIntervalSince1970:200];
    MPAliasRequest *request = [MPAliasRequest requestWithSourceMPID:mpid1 destinationMPID:mpid2 startTime:startTime endTime:endTime];
    XCTAssertEqual(request.sourceMPID, mpid1);
    XCTAssertEqual(request.destinationMPID, mpid2);
    XCTAssertEqual(request.startTime, startTime);
    XCTAssertEqual(request.endTime, endTime);
    XCTAssertTrue([request.startTime compare:request.endTime] == NSOrderedAscending);
    
    BOOL result = [MParticle.sharedInstance.identity aliasUsers:request];
    
    XCTAssertEqual(request.sourceMPID, mpid1);
    XCTAssertEqual(request.destinationMPID, mpid2);
    XCTAssertEqual(request.startTime, startTime);
    XCTAssertEqual(request.endTime, endTime);
    XCTAssertTrue([request.startTime compare:request.endTime] == NSOrderedAscending);
    XCTAssertTrue(result);
}

- (void)testAliasHTTPRepresentation {
    NSNumber *mpid1 = @1;
    NSNumber *mpid2 = @2;
    NSDate *startTime = [NSDate dateWithTimeIntervalSince1970:100];
    NSDate *endTime = [NSDate dateWithTimeIntervalSince1970:200];
    MPAliasRequest *request = [MPAliasRequest requestWithSourceMPID:mpid1 destinationMPID:mpid2 startTime:startTime endTime:endTime];
    MPIdentityHTTPAliasRequest *httpRequest = [[MPIdentityHTTPAliasRequest alloc] initWithIdentityApiAliasRequest:request];
    NSDictionary *dictionary = httpRequest.dictionaryRepresentation;
    XCTAssertNil(dictionary[@"client_sdk"]);
    XCTAssertNil(dictionary[@"request_timestamp_ms"]);
    XCTAssertEqualObjects(dictionary[@"request_type"], @"alias");
    XCTAssertEqualObjects(dictionary[@"data"][@"source_mpid"], @1);
    XCTAssertEqualObjects(dictionary[@"data"][@"destination_mpid"], @2);
    XCTAssertEqualObjects(dictionary[@"data"][@"start_unixtime_ms"], @100000);
    XCTAssertEqualObjects(dictionary[@"data"][@"end_unixtime_ms"], @200000);
    XCTAssertNotNil(dictionary[@"request_id"]);
}

@end
