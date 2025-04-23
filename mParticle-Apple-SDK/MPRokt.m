//
//  MPRokt.m
//  mParticle-Apple-SDK
//
//  Created by Brandon Stalnaker on 4/22/25.
//

#import "MPRokt.h"
#import "mParticle.h"
#import "MPForwardQueueParameters.h"
#import "MPILogger.h"

@implementation MPRoktEventCallback
@end

@implementation MPRoktEmbeddedView
@end

@implementation MPRokt

- (void)selectPlacements:(NSString *)identifier
              attributes:(NSDictionary<NSString *, NSString *> * _Nullable)attributes {
    [self selectPlacements:identifier attributes:attributes placements:nil callbacks:nil];
}

- (void)selectPlacements:(NSString *)identifier
              attributes:(NSDictionary<NSString *, NSString *> * _Nullable)attributes
              placements:(NSDictionary<NSString *, MPRoktEmbeddedView *> * _Nullable)placements
               callbacks:(MPRoktEventCallback *)callbacks {
    NSArray<NSDictionary<NSString *, NSString *> *> *attributeMap = [self getRoktPlacementAttributes];
    
    // If attributeMap is nil the kit hasn't been initialized
    if (attributeMap) {
        NSMutableDictionary *mappedAttributes = attributes.mutableCopy;
        for (NSDictionary<NSString *, NSString *> *map in attributeMap) {
            NSString *mapFrom = map[@"map"];
            NSString *mapTo = map[@"value"];
            if (mappedAttributes[mapFrom]) {
                NSString * value = mappedAttributes[mapFrom];
                [mappedAttributes removeObjectForKey:mapFrom];
                mappedAttributes[mapTo] = value;
            }
        }
        for (NSString *key in mappedAttributes) {
            [[MParticle sharedInstance].identity.currentUser setUserAttribute:key value:mappedAttributes[key]];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // Forwarding call to kits
            MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
            [queueParameters addParameter:identifier];
            [queueParameters addParameter:[self confirmSandboxAttribute:mappedAttributes]];
            [queueParameters addParameter:placements];
            [queueParameters addParameter:callbacks];
            
            SEL roktSelector = @selector(executeWithViewName:attributes:placements:callbacks:filteredUser:);
            [[MParticle sharedInstance].kitContainer_PRIVATE forwardSDKCall:roktSelector
                                                                      event:nil
                                                                 parameters:queueParameters
                                                                messageType:MPMessageTypeEvent
                                                                   userInfo:nil
            ];
        });
    } else {
        MPILogVerbose(@"[MParticle.Rokt selectPlacements: not performed since Kit not configured");
    }
}

- (NSArray<NSDictionary<NSString *, NSString *> *> *)getRoktPlacementAttributes {
    NSArray<NSDictionary<NSString *, NSString *> *> *attributeMap = nil;
    
    // Get the kit configuration
    NSArray<NSDictionary *> *kitConfigs = [MParticle sharedInstance].kitContainer_PRIVATE.originalConfig.copy;
    NSDictionary *roktKitConfig;
    for (NSDictionary *kitConfig in kitConfigs) {
        if (kitConfig[@"id"] != nil && [kitConfig[@"id"] integerValue] == 181) {
            roktKitConfig = kitConfig;
        }
    }
    
    // Get the placement attributes map
    NSString *strAttributeMap;
    NSData *dataAttributeMap;
    if (roktKitConfig != nil) {
        // Rokt Kit is available though there may not be an attribute map
        attributeMap = @[];
        if (roktKitConfig[@"placementAttributes"] != [NSNull null]) {
            strAttributeMap = [roktKitConfig[@"placementAttributes"] stringByRemovingPercentEncoding];
            dataAttributeMap = [strAttributeMap dataUsingEncoding:NSUTF8StringEncoding];
        }
    }
    
    if (dataAttributeMap != nil) {
        // Convert it to an array of dictionaries
        NSError *error = nil;
        
        @try {
            attributeMap = [NSJSONSerialization JSONObjectWithData:dataAttributeMap options:kNilOptions error:&error];
        } @catch (NSException *exception) {
        }
        
        if (attributeMap && !error) {
            NSLog(@"%@", attributeMap);
        } else {
            NSLog(@"%@", error);
        }
    }
    
    return attributeMap;
}

- (NSDictionary<NSString *, NSString *> *)confirmSandboxAttribute:(NSDictionary<NSString *, NSString *> * _Nullable)attributes {
    NSMutableDictionary<NSString *, NSString *> *finalAttributes = attributes.mutableCopy;
    NSString *sandboxKey = @"sandbox";
    
    // Determine the value of the sandbox attribute based off the current environment
    NSString *sandboxValue = ([[MParticle sharedInstance] environment] == MPEnvironmentDevelopment) ? @"true" : @"false";
    
    if (finalAttributes != nil) {
        // Only set sandbox if it`s not set by the client
        if (![finalAttributes.allKeys containsObject:sandboxKey]) {
            finalAttributes[sandboxKey] = sandboxValue;
        }
    } else {
        finalAttributes = [[NSMutableDictionary alloc] initWithDictionary:@{sandboxKey: sandboxValue}];
    }
    
    return finalAttributes;
}

@end
