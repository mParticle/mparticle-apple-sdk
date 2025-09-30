#ifndef MPConnectorResponseProtocol_h
#define MPConnectorResponseProtocol_h
@protocol MPConnectorResponseProtocol<NSObject>

@property (nonatomic, nullable) NSData *data;
@property (nonatomic, nullable) NSError *error;
@property (nonatomic) NSTimeInterval downloadTime;
@property (nonatomic, nullable) NSHTTPURLResponse *httpResponse;

@end

#endif /* MPConnectorResponseProtocol_h */
