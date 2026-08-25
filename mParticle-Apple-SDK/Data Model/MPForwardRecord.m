#import "MPForwardRecord.h"
#import "MPIConstants.h"
#import "MPILogger.h"
#import "MPKitFilter.h"
#import "MPEvent.h"
#import "MPCommerceEvent.h"
#import "MPCommerceEvent+Dictionary.h"
#import "MPEventProjection.h"
#import "MPKitExecStatus.h"
#import "MPPersistenceController.h"
#import "mParticle.h"
@import mParticle_Apple_SDK_Swift;

NSString *const kMPFRModuleId = @"mid";
NSString *const kMPFRProjections = @"proj";
NSString *const kMPFRProjectionId = @"pid";
NSString *const kMPFRProjectionName = @"name";
NSString *const kMPFRPushRegistrationState = @"r";
NSString *const kMPFROptOutState = @"s";

@interface MPForwardRecord ()
@property (nonatomic, strong) MPForwardRecordPRIVATE *implementation;
@end

@implementation MPForwardRecord

- (instancetype)initWithId:(int64_t)forwardRecordId dataDictionary:(NSDictionary *)dataDictionary mpid:(NSNumber *)mpid {
    self = [super init];
    if (!self) {
        return nil;
    }

    _implementation = [[MPForwardRecordPRIVATE alloc] initWithId:forwardRecordId dataDictionary:dataDictionary mpid:mpid];
    return self;
}

- (instancetype)initWithId:(int64_t)forwardRecordId data:(NSData *)data mpid:(NSNumber *)mpid {
    MPForwardRecordPRIVATE *implementation = [[MPForwardRecordPRIVATE alloc] initWithId:forwardRecordId data:data mpid:mpid];
    if (!implementation) {
        return nil;
    }

    self = [super init];
    if (!self) {
        return nil;
    }

    _implementation = implementation;
    return self;
}

- (instancetype)initWithMessageType:(MPMessageType)messageType execStatus:(MPKitExecStatus *)execStatus {
    return [self initWithMessageType:messageType execStatus:execStatus kitFilter:nil originalEvent:nil];
}

- (instancetype)initWithMessageType:(MPMessageType)messageType execStatus:(MPKitExecStatus *)execStatus stateFlag:(BOOL)stateFlag {
    self = [self initWithMessageType:messageType execStatus:execStatus kitFilter:nil originalEvent:nil];
    
    if (messageType == MPMessageTypePushRegistration) {
        self.dataDictionary[kMPFRPushRegistrationState] = @(stateFlag);
    } else if (messageType == MPMessageTypeOptOut) {
        self.dataDictionary[kMPFROptOutState] = @(stateFlag);
    }
    
    return self;
}

- (instancetype)initWithMessageType:(MPMessageType)messageType execStatus:(MPKitExecStatus *)execStatus kitFilter:(MPKitFilter *)kitFilter originalEvent:(MPBaseEvent *)originalEvent {
    self = [super init];
    
    BOOL validMessageType = messageType > MPMessageTypeUnknown && messageType <= MPMessageTypeCommerceEvent;
    NSAssert(validMessageType, @"The 'messageType' variable is not valid.");
    
    BOOL validExecStatus = !MPIsNull(execStatus) && [execStatus isKindOfClass:[MPKitExecStatus class]];
    NSAssert(validExecStatus, @"The 'execStatus' variable is not valid.");
    
    BOOL validKitFilter = MPIsNull(kitFilter) || [kitFilter isKindOfClass:[MPKitFilter class]];
    NSAssert(validKitFilter, @"The 'kitFilter' variable is not valid.");
    
    BOOL validOriginalEvent = MPIsNull(originalEvent) || [originalEvent isKindOfClass:[MPEvent class]] || [originalEvent isKindOfClass:[MPCommerceEvent class]] || [originalEvent isKindOfClass:[MPBaseEvent class]];
    NSAssert(validOriginalEvent, @"The 'originalEvent' variable is not valid.");
    
    if (!self || !validMessageType || !validExecStatus || !validKitFilter || !validOriginalEvent) {
        return nil;
    }
    
    NSNumber *mpid = [MPPersistenceController_PRIVATE mpId];
    NSMutableDictionary *dataDictionary = [[NSMutableDictionary alloc] init];
    dataDictionary[kMPFRModuleId] = execStatus.integrationId;
    dataDictionary[kMPTimestampKey] = MPCurrentEpochInMilliseconds;
    dataDictionary[kMPMessageTypeKey] = NSStringFromMessageType(messageType);

    if (!kitFilter) {
        _implementation = [[MPForwardRecordPRIVATE alloc] initWithId:0 dataDictionary:dataDictionary mpid:mpid];
        return self;
    }
    
    if (messageType == MPMessageTypeCommerceEvent || messageType == MPMessageTypeEvent) {
        NSString *eventTypeString = nil;
        if ([originalEvent isKindOfClass:[MPEvent class]]) {
            eventTypeString = ((MPEvent *)originalEvent).typeName;
        } else if ([originalEvent isKindOfClass:[MPCommerceEvent class]]) {
            eventTypeString = NSStringFromEventType([((MPCommerceEvent *)originalEvent) type]);
        }
        
        if (eventTypeString) {
            dataDictionary[kMPEventTypeKey] = eventTypeString;
        }
    }
    if ([originalEvent isKindOfClass:[MPEvent class]] && (messageType == MPMessageTypeScreenView || messageType == MPMessageTypeEvent)) {
        dataDictionary[kMPEventNameKey] = ((MPEvent *)originalEvent).name;
    }
    
    if (kitFilter.appliedProjections.count > 0) {
        NSMutableArray *projections = [[NSMutableArray alloc] initWithCapacity:kitFilter.appliedProjections.count];
        NSMutableDictionary *projectionDictionary;
        NSString *currentProjectionName;
        if ([kitFilter.originalEvent isKindOfClass:[MPEvent class]]) {
            currentProjectionName = ((MPEvent *)kitFilter.originalEvent).name;
        }
        
        for (MPEventProjection *eventProjection in kitFilter.appliedProjections) {
            if ([eventProjection.projectedName isEqual:currentProjectionName]) {
                projectionDictionary = [[NSMutableDictionary alloc] initWithCapacity:4];
                projectionDictionary[kMPFRProjectionId] = @(eventProjection.projectionId);
                projectionDictionary[kMPMessageTypeKey] = NSStringFromMessageType(messageType);
                
                projectionDictionary[kMPEventTypeKey] = NSStringFromEventType(eventProjection.eventType);
                
                if (eventProjection.projectedName) {
                    projectionDictionary[kMPFRProjectionName] = eventProjection.projectedName;
                }
                
                [projections addObject:projectionDictionary];
            }
        }
        
        dataDictionary[kMPFRProjections] = projections;
    }

    _implementation = [[MPForwardRecordPRIVATE alloc] initWithId:0 dataDictionary:dataDictionary mpid:mpid];
    return self;
}

- (uint64_t)forwardRecordId {
    return self.implementation.forwardRecordId;
}

- (void)setForwardRecordId:(uint64_t)forwardRecordId {
    self.implementation.forwardRecordId = forwardRecordId;
}

- (NSMutableDictionary *)dataDictionary {
    return self.implementation.dataDictionary;
}

- (void)setDataDictionary:(NSMutableDictionary *)dataDictionary {
    self.implementation.dataDictionary = dataDictionary;
}

- (NSNumber *)mpid {
    return self.implementation.mpid;
}

- (void)setMpid:(NSNumber *)mpid {
    self.implementation.mpid = mpid;
}

- (NSNumber *)timestamp {
    return self.implementation.timestamp;
}

- (void)setTimestamp:(NSNumber *)timestamp {
    self.implementation.timestamp = timestamp;
}

- (NSString *)description {
    NSMutableString *description = [[NSMutableString alloc] initWithString:@"MPForwardRecord {\n"];
    [description appendFormat:@"  forwardRecordId: %llu\n", self.forwardRecordId];
    [description appendFormat:@"  dataDictionary: %@\n", self.dataDictionary];
    [description appendFormat:@"  mpid: %@\n", self.mpid];
    [description appendString:@"}"];
    
    return description;
}

- (BOOL)isEqual:(id)object {
    if (MPIsNull(object) || ![object isKindOfClass:[MPForwardRecord class]]) {
        return NO;
    }
    return [self.implementation isEqualToRecord:((MPForwardRecord *)object).implementation];
}

- (NSUInteger)hash {
    return (NSUInteger)self.implementation.hash;
}

#pragma mark Public methods
- (NSData *)dataRepresentation {
    return [self.implementation dataRepresentation];
}

@end
