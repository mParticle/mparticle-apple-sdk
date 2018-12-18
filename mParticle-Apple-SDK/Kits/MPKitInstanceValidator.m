#import "MPKitInstanceValidator.h"
#import "MPEnums.h"
#import "MPIConstants.h"

static NSMutableArray<NSNumber *> *validKitCodes;

@implementation MPKitInstanceValidator

+ (void)initialize {
    NSArray<NSNumber *> *integrationIds = @[@(MPKitInstanceAppboy),
                                      @(MPKitInstanceTune),
                                      @(MPKitInstanceKochava),
                                      @(MPKitInstanceComScore),
                                      @(MPKitInstanceOptimizely),
                                      @(MPKitInstanceKahuna),
                                      @(MPKitInstanceNielsen),
                                      @(MPKitInstanceForesee),
                                      @(MPKitInstanceAdjust),
                                      @(MPKitInstanceBranchMetrics),
                                      @(MPKitInstanceFlurry),
                                      @(MPKitInstanceLocalytics),
                                      @(MPKitInstanceApteligent),
                                      @(MPKitInstanceWootric),
                                      @(MPKitInstanceAppsFlyer),
                                      @(MPKitInstanceApptentive),
                                      @(MPKitInstanceLeanplum),
                                      @(MPKitInstancePrimer),
                                      @(MPKitInstanceResponsys),
                                      @(MPKitInstanceUrbanAirship),
                                      @(MPKitInstanceApptimize),
                                      @(MPKitInstanceButton),
                                      @(MPKitInstanceRevealMobile),
                                      @(MPKitInstanceRadar),
                                      @(MPKitInstanceSkyhook),
                                      @(MPKitInstanceIterable),
                                      @(MPKitInstanceSingular),
                                      @(MPKitInstanceAdobe),
                                      @(MPKitInstanceInstabot),
                                      @(MPKitInstanceCarnival),
                                      @(MPKitInstanceAppsee),
                                      @(MPKitInstanceTaplytics),
                                      @(MPKitInstanceCleverTap),
                                      ];
    
    validKitCodes = [[NSMutableArray alloc] initWithCapacity:integrationIds.count];
    
    for (NSNumber *integrationId in integrationIds) {
        MPKitInstance kitInstance = (MPKitInstance)[integrationId integerValue];
        
        // There should be no default clause in this switch statement
        // In case a new kit is added and we forget to add it to the list above, the code below
        // will generate warning on the next compilation
        switch (kitInstance) {
            case MPKitInstanceAppboy:
            case MPKitInstanceTune:
            case MPKitInstanceKochava:
            case MPKitInstanceComScore:
            case MPKitInstanceOptimizely:
            case MPKitInstanceKahuna:
            case MPKitInstanceNielsen:
            case MPKitInstanceForesee:
            case MPKitInstanceAdjust:
            case MPKitInstanceBranchMetrics:
            case MPKitInstanceFlurry:
            case MPKitInstanceLocalytics:
            case MPKitInstanceApteligent:
            case MPKitInstanceWootric:
            case MPKitInstanceAppsFlyer:
            case MPKitInstanceApptentive:
            case MPKitInstanceLeanplum:
            case MPKitInstancePrimer:
            case MPKitInstanceResponsys:
            case MPKitInstanceUrbanAirship:
            case MPKitInstanceApptimize:
            case MPKitInstanceButton:
            case MPKitInstanceRevealMobile:
            case MPKitInstanceRadar:
            case MPKitInstanceSkyhook:
            case MPKitInstanceIterable:
            case MPKitInstanceSingular:
            case MPKitInstanceAdobe:
            case MPKitInstanceInstabot:
            case MPKitInstanceCarnival:
            case MPKitInstanceAppsee:
            case MPKitInstanceTaplytics:
            case MPKitInstanceCleverTap:
                [validKitCodes addObject:integrationId];
                break;
        }
    }
}

+ (BOOL)isValidKitCode:(NSNumber *)integrationId {
    if (MPIsNull(integrationId) || ![integrationId isKindOfClass:[NSNumber class]]) {
        return NO;
    }
    
    return [validKitCodes containsObject:integrationId];
}

+ (void)includeUnitTestKits:(NSArray<NSNumber *> *)integrationIds {
    if (MPIsNull(integrationIds)) {
        return;
    }
    
    for (NSNumber *integrationId in integrationIds) {
        if (![validKitCodes containsObject:integrationId]) {
            [validKitCodes addObject:integrationId];
        }
    }
}

@end
