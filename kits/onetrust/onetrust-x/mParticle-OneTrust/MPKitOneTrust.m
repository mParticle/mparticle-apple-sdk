#import "MPKitOneTrust.h"
#if TARGET_OS_IOS
#import <OTPublishersHeadlessSDK/OTPublishersHeadlessSDK-Swift.h>
#else
#import <OTPublishersHeadlessSDKtvOS/OTPublishersHeadlessSDKtvOS-Swift.h>
#endif

@implementation MPKitOneTrust

/*
 mParticle will supply a unique kit code for you. Please contact our team
 */
+ (NSNumber *)kitCode {
    return @134;
}

+ (void)load {
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"OneTrust" className:@"MPKitOneTrust"];
    [MParticle registerExtension:kitRegister];
}

- (MPKitExecStatus *)execStatus:(MPKitReturnCode)returnCode {
    return [[MPKitExecStatus alloc] initWithSDKCode:self.class.kitCode returnCode:returnCode];
}

#pragma mark - MPKitInstanceProtocol methods

#pragma mark Kit instance and lifecycle
- (MPKitExecStatus *)didFinishLaunchingWithConfiguration:(NSDictionary *)configuration {
    NSString *apiKey = configuration[@"mobileConsentGroups"];
    if (!apiKey) {
        return [self execStatus:MPKitReturnCodeRequirementsNotMet];
    }
    
    _configuration = configuration;
    
    [self start];
    
    return [self execStatus:MPKitReturnCodeSuccess];
}

- (void)start {
    static dispatch_once_t kitPredicate;
    
    dispatch_once(&kitPredicate, ^{
        
        // Save Purpose mapping for use by OneTrust Mobile SDK
        NSString* purposeMappingDict = [self->_configuration valueForKey:@"mobileConsentGroups"];
        [[NSUserDefaults standardUserDefaults] setObject:purposeMappingDict forKey:@"OT_mP_Mapping"];
        
        NSString* vendorIABMappingDict = [self->_configuration valueForKey:@"vendorIABConsentGroups"];
        [[NSUserDefaults standardUserDefaults] setObject:vendorIABMappingDict forKey:@"OT_Vendor_IAB_mP_Mapping"];
        
        NSString* vendorGoogleMappingDict = [self->_configuration valueForKey:@"vendorGoogleConsentGroups"];
        [[NSUserDefaults standardUserDefaults] setObject:vendorGoogleMappingDict forKey:@"OT_Vendor_Google_mP_Mapping"];
        
        NSString* vendorGeneralMappingDict = [self->_configuration valueForKey:@"vendorGeneralConsentGroups"];
        [[NSUserDefaults standardUserDefaults] setObject:vendorGeneralMappingDict forKey:@"OT_Vendor_General_mP_Mapping"];
        
        self->_started = YES;
        
        // READ consent data mapping
        NSString *mpConsentMapping = [[NSUserDefaults standardUserDefaults] stringForKey:@"OT_mP_Mapping"];
        NSString *mpVendorIABConsentMapping = [[NSUserDefaults standardUserDefaults] stringForKey:@"OT_Vendor_IAB_mP_Mapping"];
        NSString *mpVendorGoogleConsentMapping = [[NSUserDefaults standardUserDefaults] stringForKey:@"OT_Vendor_Google_mP_Mapping"];
        NSString *mpVendorGeneralConsentMapping = [[NSUserDefaults standardUserDefaults] stringForKey:@"OT_Vendor_General_mP_Mapping"];

        self->_purposeConsentMapping = [self parseConsentMapping:mpConsentMapping];
        self->_venderIABConsentMapping = [self parseConsentMapping:mpVendorIABConsentMapping];
        self->_venderGoogleConsentMapping = [self parseConsentMapping:mpVendorGoogleConsentMapping];
        self->_venderGeneralConsentMapping = [self parseConsentMapping:mpVendorGeneralConsentMapping];

        [self updateAllConsentStates];
        
        //registering the observer
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(actionConsent:) name:@"OTConsentUpdated" object:nil];

        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *userInfo = @{mParticleKitInstanceKey:[[self class] kitCode]};
            
            [[NSNotificationCenter defaultCenter] postNotificationName:mParticleKitDidBecomeActiveNotification
                                                                object:nil
                                                              userInfo:userInfo];
        });
    });
}

// Listener for Consent Change dispatched by One Trust
-(void)actionConsent:(NSNotification*)notification {
    [self updateAllConsentStates];
}

// Parses the raw consent mapping from the mParticle UI into simple map
- (NSDictionary*)parseConsentMapping:(NSString*)rawConsentMapping {
    NSMutableDictionary *consentMapping = [[NSMutableDictionary alloc] init];

    if (rawConsentMapping.length == 0 || rawConsentMapping == nil) {
        return consentMapping;
    }
    
    NSData *jsonData = [rawConsentMapping dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;

    id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];

        if (error) {
            NSLog(@"Error parsing JSON: %@", error);
        }
        else
        {
            if ([jsonObject isKindOfClass:[NSArray class]])
            {
                for (NSDictionary *element in jsonObject) {
                    if (element[@"value"] != nil && element[@"map"] != nil) {
                        NSString *purpose = element[@"map"];
                        NSString *regulation = @"gdpr";

                        if ([purpose isEqualToString: @"data_sale_opt_out"]) {
                            regulation = @"ccpa";
                        }

                        consentMapping[element[@"value"]] = @{ @"purpose": purpose, @"regulation": regulation};
                    } else {
                        NSLog(@"Warning: Invalid consent mapping - %@", element);
                    }
                }
            } else {
                NSLog(@"Warning: One Trust Integration initialized with invalid Consent Mapping.\n jsonDictionary - %@", jsonObject);
            }
        }
    return consentMapping;
}

// Creates an mParticle Consent Event
-(MPConsentState *)createConsentEvent:(NSString*)cookieName
                                     :(NSDictionary*)consentMapping
                                     :(NSNumber*)status
                                     :(MPConsentState *)consentState {
    NSString *purpose = consentMapping[cookieName][@"purpose"];
    NSString *regulation = consentMapping[cookieName][@"regulation"];
    BOOL consentBoolean = status.intValue == 1;

    if ([regulation isEqualToString:@"gdpr"]) {
        MPGDPRConsent *gdprConsent = [[MPGDPRConsent alloc] init];

        gdprConsent.consented = consentBoolean;
        gdprConsent.timestamp = [[NSDate alloc] init];

        [consentState addGDPRConsentState:gdprConsent purpose:purpose];
    } else if([regulation isEqualToString:@"ccpa"]) {
        MPCCPAConsent *ccpaConsent = [[MPCCPAConsent alloc] init];

        ccpaConsent.consented = consentBoolean;
        ccpaConsent.timestamp = [[NSDate alloc] init];

        [consentState setCCPAConsentState: ccpaConsent];
    } else {
        NSLog(@"Unknown Consent Regulation");
    }

    return consentState;
}

-(void)updateAllConsentStates {
    MParticleUser *user = [MParticle sharedInstance].identity.currentUser;
    MPConsentState *consentState = user.consentState;
    if (!consentState) {
        consentState = [[MPConsentState alloc] init];
    }
    
    for(NSString *consentKey in [self.purposeConsentMapping allKeys]) {
        // Fetch consent keys from one trust and pre-populate
        NSNumber *status = [[NSNumber alloc] initWithUnsignedChar:[OTPublishersHeadlessSDK.shared getConsentStatusForCategory:consentKey]];

        // Generate consents states for known events
        consentState = [self createConsentEvent:consentKey :self.purposeConsentMapping :status :consentState];
    }
    
    consentState = [self updateVendorConsents:self.venderIABConsentMapping :VendorListModeIab :consentState];
    consentState = [self updateVendorConsents:self.venderGoogleConsentMapping :VendorListModeGoogle :consentState];
    consentState = [self updateVendorConsents:self.venderGeneralConsentMapping :VendorListModeGeneral :consentState];
    
    [user setConsentState: consentState];
}

-(MPConsentState *)updateVendorConsents:(NSDictionary*)consentMapping
                                       :(VendorListMode)mode
                                       :(MPConsentState *)consentState {
    for(NSString *consentKey in [consentMapping allKeys]) {
        // Fetch consent keys from one trust and pre-populate
        NSNumber *status = [OTPublishersHeadlessSDK.shared getVendorDetailsWithVendorID:consentKey for:mode][@"consent"];
        consentState = [self createConsentEvent:consentKey :consentMapping :status :consentState];
    }
    return consentState;
}

- (id const)providerKitInstance {
    if (![self started]) {
        return nil;
    }
    
    /*
     If your company SDK instance is available and is applicable (Please return nil if your SDK is based on class methods)
     */
    BOOL kitInstanceAvailable = NO;
    if (kitInstanceAvailable) {
        /* Return an instance of your company's SDK (if applicable) */
        return nil;
    } else {
        return nil;
    }
}


#pragma mark Application
/*
 Implement this method if your SDK handles a user interacting with a remote notification action
 */
// - (MPKitExecStatus *)handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo {
//     /*  Your code goes here.
//         If the execution is not successful, please use a code other than MPKitReturnCodeSuccess for the execution status.
//         Please see MPKitExecStatus.h for all exec status codes
//      */
//
//     return [self execStatus:MPKitReturnCodeSuccess];
// }

/*
 Implement this method if your SDK receives and handles remote notifications
 */
// - (MPKitExecStatus *)receivedUserNotification:(NSDictionary *)userInfo {
//     /*  Your code goes here.
//         If the execution is not successful, please use a code other than MPKitReturnCodeSuccess for the execution status.
//         Please see MPKitExecStatus.h for all exec status codes
//      */
//
//     return [self execStatus:MPKitReturnCodeSuccess];
// }

/*
 Implement this method if your SDK registers the device token for remote notifications
 */
// - (MPKitExecStatus *)setDeviceToken:(NSData *)deviceToken {
//     /*  Your code goes here.
//         If the execution is not successful, please use a code other than MPKitReturnCodeSuccess for the execution status.
//         Please see MPKitExecStatus.h for all exec status codes
//      */
//
//     return [self execStatus:MPKitReturnCodeSuccess];
// }

/*
 Implement this method if your SDK handles continueUserActivity method from the App Delegate
 */
// - (nonnull MPKitExecStatus *)continueUserActivity:(nonnull NSUserActivity *)userActivity restorationHandler:(void(^ _Nonnull)(NSArray * _Nullable restorableObjects))restorationHandler {
//     /*  Your code goes here.
//         If the execution is not successful, please use a code other than MPKitReturnCodeSuccess for the execution status.
//         Please see MPKitExecStatus.h for all exec status codes
//      */
//
//     return [self execStatus:MPKitReturnCodeSuccess];
// }

/*
 Implement this method if your SDK handles the iOS 9 and above App Delegate method to open URL with options
 */
// - (nonnull MPKitExecStatus *)openURL:(nonnull NSURL *)url options:(nullable NSDictionary<NSString *, id> *)options {
//     /*  Your code goes here.
//         If the execution is not successful, please use a code other than MPKitReturnCodeSuccess for the execution status.
//         Please see MPKitExecStatus.h for all exec status codes
//      */
//
//     return [self execStatus:MPKitReturnCodeSuccess];
// }

/*
 Implement this method if your SDK handles the iOS 8 and below App Delegate method open URL
 */
// - (nonnull MPKitExecStatus *)openURL:(nonnull NSURL *)url sourceApplication:(nullable NSString *)sourceApplication annotation:(nullable id)annotation {
//     /*  Your code goes here.
//         If the execution is not successful, please use a code other than MPKitReturnCodeSuccess for the execution status.
//         Please see MPKitExecStatus.h for all exec status codes
//      */
//
//     return [self execStatus:MPKitReturnCodeSuccess];
// }

#pragma mark User attributes
/*
 Implement this method if your SDK allows for incrementing numeric user attributes.
 */
//- (MPKitExecStatus *)onIncrementUserAttribute:(FilteredMParticleUser *)user {
//     /*  Your code goes here.
//         If the execution is not successful, please use a code other than MPKitReturnCodeSuccess for the execution status.
//         Please see MPKitExecStatus.h for all exec status codes
//      */
//
//     return [self execStatus:MPKitReturnCodeSuccess];
//}

/*
 Implement this method if your SDK resets user attributes.
 */
//- (MPKitExecStatus *)onRemoveUserAttribute:(FilteredMParticleUser *)user {
//     /*  Your code goes here.
//         If the execution is not successful, please use a code other than MPKitReturnCodeSuccess for the execution status.
//         Please see MPKitExecStatus.h for all exec status codes
//      */
//
//     return [self execStatus:MPKitReturnCodeSuccess];
//}

/*
 Implement this method if your SDK sets user attributes.
 */
//- (MPKitExecStatus *)onSetUserAttribute:(FilteredMParticleUser *)user {
//     /*  Your code goes here.
//         If the execution is not successful, please use a code other than MPKitReturnCodeSuccess for the execution status.
//         Please see MPKitExecStatus.h for all exec status codes
//      */
//
//     return [self execStatus:MPKitReturnCodeSuccess];
//}

/*
 Implement this method if your SDK supports setting value-less attributes
 */
//- (MPKitExecStatus *)onSetUserTag:(FilteredMParticleUser *)user {
//     /*  Your code goes here.
//         If the execution is not successful, please use a code other than MPKitReturnCodeSuccess for the execution status.
//         Please see MPKitExecStatus.h for all exec status codes
//      */
//
//     return [self execStatus:MPKitReturnCodeSuccess];
//}

#pragma mark Identity
/*
 Implement this method if your SDK should be notified any time the mParticle ID (MPID) changes. This will occur on initial install of the app, and potentially after a login or logout.
 */
//- (MPKitExecStatus *)onIdentifyComplete:(FilteredMParticleUser *)user request:(FilteredMPIdentityApiRequest *)request {
//     /*  Your code goes here.
//         If the execution is not successful, please use a code other than MPKitReturnCodeSuccess for the execution status.
//         Please see MPKitExecStatus.h for all exec status codes
//      */
//
//     return [self execStatus:MPKitReturnCodeSuccess];
//}

/*
 Implement this method if your SDK should be notified when the user logs in
 */
//- (MPKitExecStatus *)onLoginComplete:(FilteredMParticleUser *)user request:(FilteredMPIdentityApiRequest *)request {
//     /*  Your code goes here.
//         If the execution is not successful, please use a code other than MPKitReturnCodeSuccess for the execution status.
//         Please see MPKitExecStatus.h for all exec status codes
//      */
//
//     return [self execStatus:MPKitReturnCodeSuccess];
//}

/*
 Implement this method if your SDK should be notified when the user logs out
 */
//- (MPKitExecStatus *)onLogoutComplete:(FilteredMParticleUser *)user request:(FilteredMPIdentityApiRequest *)request {
//     /*  Your code goes here.
//         If the execution is not successful, please use a code other than MPKitReturnCodeSuccess for the execution status.
//         Please see MPKitExecStatus.h for all exec status codes
//      */
//
//     return [self execStatus:MPKitReturnCodeSuccess];
//}

/*
 Implement this method if your SDK should be notified when user identities change
 */
//- (MPKitExecStatus *)onModifyComplete:(FilteredMParticleUser *)user request:(FilteredMPIdentityApiRequest *)request {
//     /*  Your code goes here.
//         If the execution is not successful, please use a code other than MPKitReturnCodeSuccess for the execution status.
//         Please see MPKitExecStatus.h for all exec status codes
//      */
//
//     return [self execStatus:MPKitReturnCodeSuccess];
//}

#pragma mark e-Commerce
/*
 Implement this method if your SDK supports commerce events.
 If your SDK does support commerce event, but does not support all commerce event actions available in the mParticle SDK,
 expand the received commerce event into regular events and log them accordingly (see sample code below)
 Please see MPCommerceEvent.h > MPCommerceEventAction for complete list
 */
// - (MPKitExecStatus *)logCommerceEvent:(MPCommerceEvent *)commerceEvent {
//     MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess forwardCount:0];
//
//     // In this example, this SDK only supports the 'Purchase' commerce event action
//     if (commerceEvent.action == MPCommerceEventActionPurchase) {
//             /* Your code goes here. */
//
//             [execStatus incrementForwardCount];
//         }
//     } else { // Other commerce events are expanded and logged as regular events
//         NSArray *expandedInstructions = [commerceEvent expandedInstructions];
//
//         for (MPCommerceEventInstruction *commerceEventInstruction in expandedInstructions) {
//             [self logEvent:commerceEventInstruction.event];
//             [execStatus incrementForwardCount];
//         }
//     }
//
//     return execStatus;
// }

#pragma mark Events
/*
 Implement this method if your SDK logs user events.
 Please see MPEvent.h
 */
// - (MPKitExecStatus *)logEvent:(MPEvent *)event {
//     /*  Your code goes here.
//         If the execution is not successful, please use a code other than MPKitReturnCodeSuccess for the execution status.
//         Please see MPKitExecStatus.h for all exec status codes
//      */
//
//     return [self execStatus:MPKitReturnCodeSuccess];
// }

/*
 Implement this method if your SDK logs screen events
 Please see MPEvent.h
 */
// - (MPKitExecStatus *)logScreen:(MPEvent *)event {
//     /*  Your code goes here.
//         If the execution is not successful, please use a code other than MPKitReturnCodeSuccess for the execution status.
//         Please see MPKitExecStatus.h for all exec status codes
//      */
//
//     return [self execStatus:MPKitReturnCodeSuccess];
// }

#pragma mark Assorted
/*
 Implement this method if your SDK implements an opt out mechanism for users.
 */
// - (MPKitExecStatus *)setOptOut:(BOOL)optOut {
//     /*  Your code goes here.
//         If the execution is not successful, please use a code other than MPKitReturnCodeSuccess for the execution status.
//         Please see MPKitExecStatus.h for all exec status codes
//      */
//
//     return [self execStatus:MPKitReturnCodeSuccess];
// }

@end
