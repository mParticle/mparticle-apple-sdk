//
//  MPIdentityDTO.h
//

#import <Foundation/Foundation.h>
#import "MPIConstants.h"
#import "MPIdentityApiRequest.h"

@interface MPIdentities : NSObject

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

@interface MPIdentityClientSDK : NSObject

+ (NSDictionary *)clientSDKDictionaryWithVersion:(NSString *)mParticleVersion;

@end

@interface MPIdentityBaseRequest : NSObject

- (NSDictionary *)dictionaryRepresentation;

@end


@interface MPIdentifyRequest : MPIdentityBaseRequest

@property (nonatomic) NSString *previousMPID;
@property (nonatomic) MPIdentities *knownIdentities;

- (id)initWithIdentityApiRequest:(MPIdentityApiRequest *)request;
- (NSDictionary *)dictionaryRepresentation;

@end

@interface MPIdentityModifyRequest : MPIdentityBaseRequest

@property (nonatomic) NSArray *identityChanges;
@property (nonatomic) NSString *mpid;

@end

@interface MPIdentityRequest : NSObject

@end

@protocol MPIdentityRequesting <NSObject>

- (NSDictionary *)dictionaryRepresentation;

@end

@protocol MPIdentityResponding <NSObject>

- (NSDictionary *)initWithJson:(id)json;

@end

@interface MPIdentityChange : NSObject

@property (nonatomic) NSString *oldValue;
@property (nonatomic) NSString *value;
@property (nonatomic) NSString *identityType;

- (instancetype)initWithOldValue:(NSString *)oldValue value:(NSString *)value identityType:(NSString *)identityType;
- (NSMutableDictionary *)dictionaryRepresentation;

@end

@interface MPIdentityErrorItem : NSObject

- (instancetype)initWithJsonDictionary:(NSDictionary *)dictionary;

@property (nonatomic) NSString *code;
@property (nonatomic) NSString *message;

@end

@interface MPIdentityErrorResponse : NSObject

@property (nonatomic) NSMutableArray<MPIdentityErrorItem *> *items;

@end

@interface MPIdentitySuccessResponse : NSObject

- (instancetype)initWithJsonObject:(NSDictionary *)dictionary;

@property (nonatomic) NSString *context;
@property (nonatomic) NSNumber *mpid;

@end
