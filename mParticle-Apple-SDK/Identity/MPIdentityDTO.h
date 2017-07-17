//
//  MPIdentityDTO.h
//

#import <Foundation/Foundation.h>
#import "MPIConstants.h"
#import "MPIdentityApiRequest.h"

@interface MPIdentityHTTPIdentities : NSObject

@property (nonatomic) NSString *advertiserId;
@property (nonatomic) NSString *vendorId;
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

- (NSDictionary *)dictionaryRepresentation;
- (instancetype)initWithIdentities:(NSDictionary *)identities;

@end

@interface MPIdentityHTTPClientSDK : NSObject

+ (NSDictionary *)clientSDKDictionaryWithVersion:(NSString *)mParticleVersion;

@end

@interface MPIdentityHTTPBaseRequest : NSObject

- (NSDictionary *)dictionaryRepresentation;

@end


@interface MPIdentifyHTTPRequest : MPIdentityHTTPBaseRequest

@property (nonatomic) NSString *previousMPID;
@property (nonatomic) MPIdentityHTTPIdentities *knownIdentities;

- (id)initWithIdentityApiRequest:(MPIdentityApiRequest *)request;
- (NSDictionary *)dictionaryRepresentation;

@end

@interface MPIdentityHTTPModifyRequest : MPIdentityHTTPBaseRequest

@property (nonatomic) NSArray *identityChanges;
@property (nonatomic) NSString *mpid;

@end

@protocol MPIdentityRequesting <NSObject>

- (NSDictionary *)dictionaryRepresentation;

@end

@protocol MPIdentityResponding <NSObject>

- (NSDictionary *)initWithJson:(id)json;

@end

@interface MPIdentityHTTPIdentityChange : NSObject

@property (nonatomic) NSString *oldValue;
@property (nonatomic) NSString *value;
@property (nonatomic) NSString *identityType;

- (instancetype)initWithOldValue:(NSString *)oldValue value:(NSString *)value identityType:(NSString *)identityType;
- (NSMutableDictionary *)dictionaryRepresentation;

@end

@interface MPIdentityHTTPErrorItem : NSObject

- (instancetype)initWithJsonDictionary:(NSDictionary *)dictionary;

@property (nonatomic) NSString *code;
@property (nonatomic) NSString *message;

@end

@interface MPIdentityHTTPErrorResponse : NSObject

- (instancetype)initWithJsonObject:( NSDictionary *)dictionary httpCode:(NSInteger) httpCode;

@property (nonatomic) NSInteger httpCode;
@property (nonatomic) NSMutableArray<MPIdentityHTTPErrorItem *> *items;

@end

@interface MPIdentityHTTPSuccessResponse : NSObject

- (instancetype)initWithJsonObject:(NSDictionary *)dictionary;

@property (nonatomic) NSString *context;
@property (nonatomic) NSNumber *mpid;
@property (nonatomic) BOOL isEphemeral;

@end
