//
//  MPIdentityDTO.h
//

#import <Foundation/Foundation.h>
#import "MPIConstants.h"
#import "MPIdentityApiRequest.h"
#import "MPAliasRequest.h"

@interface MPIdentityHTTPIdentities : NSObject

@property (nonatomic) NSString *advertiserId;
@property (nonatomic) NSString *vendorId;
@property (nonatomic) NSString *deviceApplicationStamp;
@property (nonatomic) NSString *pushToken;
@property (nonatomic) NSString *customerId;
@property (nonatomic) NSString *email;
@property (nonatomic) NSString *facebook;
@property (nonatomic) NSString *facebookCustomAudienceId;
@property (nonatomic) NSString *google;
@property (nonatomic) NSString *microsoft;
@property (nonatomic) NSString *other;
@property (nonatomic) NSString *twitter;
@property (nonatomic) NSString *yahoo;
@property (nonatomic) NSString *other2;
@property (nonatomic) NSString *other3;
@property (nonatomic) NSString *other4;
@property (nonatomic) NSString *other5;
@property (nonatomic) NSString *other6;
@property (nonatomic) NSString *other7;
@property (nonatomic) NSString *other8;
@property (nonatomic) NSString *other9;
@property (nonatomic) NSString *other10;
@property (nonatomic) NSString *mobileNumber;
@property (nonatomic) NSString *phoneNumber2;
@property (nonatomic) NSString *phoneNumber3;

- (NSDictionary *)dictionaryRepresentation;
- (instancetype)initWithIdentities:(NSDictionary *)identities;

+ (NSString *)stringForIdentityType:(MPIdentity)identityType;
+ (NSNumber *)identityTypeForString:(NSString *)identityString;

@end

@interface MPIdentityHTTPBaseRequest : NSObject

- (NSDictionary *)dictionaryRepresentation;

@end

@interface MPIdentifyHTTPRequest : MPIdentityHTTPBaseRequest

@property (nonatomic) NSString *previousMPID;
@property (nonatomic) MPIdentityHTTPIdentities *knownIdentities;

- (id)initWithIdentityApiRequest:(MPIdentityApiRequest *)request;

@end

@interface MPIdentityHTTPAliasRequest : MPIdentityHTTPBaseRequest

@property (nonatomic) NSNumber *sourceMPID;
@property (nonatomic) NSNumber *destinationMPID;
@property (nonatomic) NSDate *startTime;
@property (nonatomic) NSDate *endTime;

- (id)initWithIdentityApiAliasRequest:(MPAliasRequest *)aliasRequest;

@end

@interface MPIdentityHTTPModifyRequest : MPIdentityHTTPBaseRequest

@property (nonatomic) NSArray *identityChanges;

- (instancetype)initWithIdentityChanges:(NSArray *)identityChanges;

@end

@interface MPIdentityHTTPIdentityChange : NSObject

@property (nonatomic) NSString *oldValue;
@property (nonatomic) NSString *value;
@property (nonatomic) NSString *identityType;

- (instancetype)initWithOldValue:(NSString *)oldValue value:(NSString *)value identityType:(NSString *)identityType;
- (NSMutableDictionary *)dictionaryRepresentation;

@end
