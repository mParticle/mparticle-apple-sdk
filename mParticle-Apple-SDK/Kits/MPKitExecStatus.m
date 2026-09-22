#import "MPKitExecStatus.h"
#import "MPIConstants.h"
#import "MPILogger.h"
#import "mParticle.h"
@import mParticle_Apple_SDK_Swift;

@implementation MPKitExecStatus

- (instancetype)init {
    self = [super init];
    if (self) {
        _returnCode = MPKitReturnCodeFail;
        _forwardCount = 0;
    }
    
    return self;
}

- (instancetype)initWithSDKCode:(NSNumber *)integrationId returnCode:(MPKitReturnCode)returnCode {
    return [self initWithSDKCode:integrationId returnCode:returnCode forwardCount:[MPKitExecStatusPRIVATE defaultForwardCountForReturnCode:(NSUInteger)returnCode]];
}

- (instancetype)initWithSDKCode:(NSNumber *)integrationId returnCode:(MPKitReturnCode)returnCode forwardCount:(NSUInteger)forwardCount {
    BOOL validReturnCode = [MPKitExecStatusPRIVATE isValidReturnCode:(NSUInteger)returnCode];
    if (!validReturnCode) {
        MPILogDebug(@"The 'returnCode': %lu variable is not valid.", (unsigned long)returnCode);
        return nil;
    }

    self = [self init];
    if (self) {
        _integrationId = integrationId;
        _returnCode = returnCode;
        _forwardCount = forwardCount;
    }
    
    return self;
}

#pragma mark Public accessors
- (BOOL)success {
    return [MPKitExecStatusPRIVATE isSuccess:(NSUInteger)_returnCode];
}

#pragma mark Public methods
- (void)incrementForwardCount {
    ++_forwardCount;
}

@end
