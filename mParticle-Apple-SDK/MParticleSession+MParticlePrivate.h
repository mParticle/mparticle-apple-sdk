@interface MParticleSession ()

- (instancetype)initWithUUID:(NSString *)uuid;
@property(nonatomic, readwrite) NSNumber *sessionID;
@property(nonatomic, readwrite) NSString *UUID;
@property(nonatomic, readwrite) NSNumber *startTime;

@end
