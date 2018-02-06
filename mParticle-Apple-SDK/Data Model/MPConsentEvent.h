#import <Foundation/Foundation.h>
#import "MPEnums.h"

@interface MPConsentEvent : NSObject

@property (nonatomic, assign) MPConsentRegulation regulation;
@property (nonatomic) NSDate *timestamp;
@property (nonatomic) NSString *document;
@property (nonatomic) NSString *consentLocation;
@property (nonatomic) NSString *hardwareId;
@property (nonatomic, assign) MPConsentCategory category;
@property (nonatomic) NSString *purpose;
@property (nonatomic, assign) MPConsentEventType type;
@property (nonatomic) NSDictionary *customAttributes;

- (NSDictionary *)dictionaryRepresentation;

@end
