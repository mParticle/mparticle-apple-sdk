#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "mParticle.h"
#import "MPIConstants.h"
#import "MParticleSwift.h"
#if TARGET_OS_IOS == 1
    #import <CoreTelephony/CTTelephonyNetworkInfo.h>
    #import <CoreTelephony/CTCarrier.h>
#endif
@interface MParticle ()

@property (nonatomic, strong, readonly) MPStateMachine_PRIVATE *stateMachine;
@property (nonatomic, strong, nonnull) MPBackendController_PRIVATE *backendController;

@end

@interface MPDeviceTests : XCTestCase

@end

@implementation MPDeviceTests

- (void)testTelephonyRadioAccessTechnology {

}

- (void)testDictionaryDescription {
    
}

@end
