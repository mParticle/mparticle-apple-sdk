#import "ViewController.h"
#import <mParticle_Apple_SDK/mParticle.h>
#import <mParticle_Apple_Media_SDK-Swift.h>
#import <AdSupport/AdSupport.h>
#import "AdSupport/ASIdentifierManager.h"
#if TARGET_OS_IOS == 1 && __IPHONE_OS_VERSION_MAX_ALLOWED >= 140000
    #import <AppTrackingTransparency/AppTrackingTransparency.h>
#endif


@interface ViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSArray<NSString *> *sectionTitles;
@property (nonatomic, strong) NSArray<NSArray<NSString *> *> *sectionCellTitles;
@property (nonatomic, strong) NSArray<NSArray<NSString *> *> *sectionSelectorNames;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UITextField *emailField;
@property (nonatomic, strong) UITextField *customerIDField;
@property (nonatomic, strong) MPRoktEmbeddedView *roktView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self setupUI:0];
    
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    self.title = @"mParticle Example";
}

- (void)setupUI:(CGFloat)roktHeight {
    for (UIView *subview in [self.view subviews]) {
        [subview removeFromSuperview];
    }
    
    CGRect emailFrame = self.view.frame;
    emailFrame.origin.y = emailFrame.origin.y + 50;
    emailFrame.origin.x = emailFrame.origin.x + 20;
    emailFrame.size.height = 40;
    _emailField = [[UITextField alloc] initWithFrame:emailFrame];
    _emailField.placeholder = @"Email";
    [self.view addSubview:_emailField];

    CGRect customerIDFrame = self.view.frame;
    customerIDFrame.origin.y = emailFrame.origin.y + emailFrame.size.height;
    customerIDFrame.origin.x = customerIDFrame.origin.x + 20;
    customerIDFrame.size.height = 40;
    _customerIDField = [[UITextField alloc] initWithFrame:customerIDFrame];
    _customerIDField.placeholder = @"Customer ID";
    [self.view addSubview:_customerIDField];
    
    CGRect roktFrame = self.view.frame;
    roktFrame.origin.y = customerIDFrame.origin.y + customerIDFrame.size.height;
    roktFrame.size.height = roktHeight;
    if (self.roktView) {
        self.roktView.frame = roktFrame;
    } else {
        self.roktView = [[MPRoktEmbeddedView alloc] initWithFrame:roktFrame];
    }
    [self.view addSubview:_roktView];
    
    CGRect screenFrame = self.view.frame;
    screenFrame.origin.y = roktFrame.origin.y + roktFrame.size.height;
    screenFrame.size.height = screenFrame.size.height - screenFrame.origin.y;
    _tableView = [[UITableView alloc] initWithFrame:screenFrame style:UITableViewStyleInsetGrouped];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self.view addSubview:_tableView];
}

#pragma mark Private accessors

- (void)setupSectionData {
    if (_sectionTitles) {
        return;
    }
    
    _sectionTitles = @[
        @"Events",
        @"User Attributes",
        @"Session Attributes",
        @"Identity",
        @"Consent",
        @"Other",
        @"Debug & Info",
        @"Rokt"
    ];
    
    _sectionCellTitles = @[
        // Events
        @[@"Log Simple Event", @"Log Event", @"Log Screen", @"Log Commerce Event", @"Log Timed Event",
          @"Log Error", @"Log Exception"],
        // User Attributes
        @[@"Set User Attribute", @"Increment User Attribute", @"Set User Attribute List", @"Remove User Attribute"],
        // Session Attributes
        @[@"Set Session Attribute", @"Increment Session Attribute"],
        // Identity
        @[@"Login", @"Logout", @"Set IDFA", @"Request & Set IDFA"],
        // Consent
        @[@"Toggle CCPA Consent", @"Toggle GDPR Consent"],
        // Other
        @[@"Register Remote", @"Get Audience", @"Log Media Events", @"Decrease Upload Timer", @"Increase Upload Timer"],
        // Debug & Info
        @[@"Display Current User", @"Force Upload", @"Check Kit Status"],
        // Rokt
        @[@"Display Rokt Overlay Placement", @"Display Rokt Dark Mode Overlay", @"Display Rokt Embedded Placement", @"Display Rokt Overlay (auto close)"]
    ];
    
    _sectionSelectorNames = @[
        // Events
        @[@"logSimpleEvent", @"logEvent", @"logScreen", @"logCommerceEvent", @"logTimedEvent",
          @"logError", @"logException"],
        // User Attributes
        @[@"setUserAttribute", @"incrementUserAttribute", @"setUserAttributeList", @"removeUserAttribute"],
        // Session Attributes
        @[@"setSessionAttribute", @"incrementSessionAttribute"],
        // Identity
        @[@"login", @"logout", @"modify", @"requestIDFA"],
        // Consent
        @[@"toggleCCPAConsent", @"toggleGDPRConsent"],
        // Other
        @[@"registerRemote", @"getAudience", @"logCustomMediaEvents", @"decreaseUploadInterval", @"increaseUploadInterval"],
        // Debug & Info
        @[@"displayCurrentUser", @"forceUpload", @"checkKitStatus"],
        // Rokt
        @[@"selectOverlayPlacement", @"selectDarkOverlayPlacement", @"selectEmbeddedPlacement", @"selectOverlayPlacementAutoClose"]
    ];
}

#pragma mark UITableViewDataSource and UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    [self setupSectionData];
    return self.sectionTitles.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    [self setupSectionData];
    return self.sectionCellTitles[section].count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    [self setupSectionData];
    return self.sectionTitles[section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    [self setupSectionData];
    
    static NSString *cellIdentifier = @"mParticleCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    
    cell.textLabel.minimumScaleFactor = 0.5;
    cell.textLabel.text = self.sectionCellTitles[indexPath.section][indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self setupSectionData];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    NSString *selectorName = self.sectionSelectorNames[indexPath.section][indexPath.row];
    SEL selector = NSSelectorFromString(selectorName);
    [self performSelector:selector];
#pragma clang diagnostic pop
}

#pragma mark Examples
- (void)logSimpleEvent {
    
    [[MParticle sharedInstance] logEvent:@"Simple Event Name"
                               eventType:MPEventTypeOther
                               eventInfo:@{@"SimpleKey":@"SimpleValue"}];
}

- (void)logEvent {
    // Creates an event object
    MPEvent *event = [[MPEvent alloc] initWithName:@"Event Name" type:MPEventTypeTransaction];
    
    // Add attributes to an event
    NSDate *currentDate = [NSDate dateWithTimeIntervalSinceNow:0];
    event.customAttributes = @{@"A_String_Key":@"A String Value",
                                      @"A Number Key":@(42),
                                      @"A Date Key":[NSDate date],
                               @"test Dictionary": @{@"test1": @"test", @"test2": @2, @"test3": currentDate}};
    
    // Custom flags are attributes sent to mParticle, but not forwarded to other providers
    [event addCustomFlag:@"Top Secret" withKey:@"Not_forwarded_to_providers"];
    
    // Logs an event
    [[MParticle sharedInstance] logEvent:event];
}

- (void)logScreen {
    [[MParticle sharedInstance] logScreen:@"Home Screen" eventInfo:nil];
}

- (void)logCommerceEvent {
    // Creates a product object
    MPProduct *product = [[MPProduct alloc] initWithName:@"Awesome Book" sku:@"1234567890" quantity:@1 price:@9.99];
    product.brand = @"A Publisher";
    product.category = @"Fiction";
    product.couponCode = @"XYZ123";
    product.position = 1;
    product[@"custom key"] = @"custom value"; // A product may contain custom key/value pairs
    
    // Creates a commerce event object
    MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionPurchase product:product];
    commerceEvent.checkoutOptions = @"Credit Card";
    commerceEvent.screenName = @"Timeless Books";
    commerceEvent.checkoutStep = 4;
    commerceEvent.customAttributes = @{@"an_extra_key": @"an_extra_value"}; // A commerce event may contain custom key/value pairs
    
    // Creates a transaction attribute object
    MPTransactionAttributes *transactionAttributes = [[MPTransactionAttributes alloc] init];
    transactionAttributes.affiliation = @"Book seller";
    transactionAttributes.shipping = @1.23;
    transactionAttributes.tax = @0.87;
    transactionAttributes.revenue = @12.09;
    transactionAttributes.transactionId = @"zyx098";
    commerceEvent.transactionAttributes = transactionAttributes;
    
    // Logs a commerce event
    [[MParticle sharedInstance] logEvent:commerceEvent];
}

- (void)selectOverlayPlacement {
    // Rokt Placement
    NSDictionary<NSString *, NSString *> *customAttributes = @{@"email": @"j.smit@example.com",
                                                               @"firstname": @"Jenny",
                                                               @"lastname": @"Smith",
                                                               @"sandbox": @"true",
                                                               @"mobile": @"(555)867-5309"
    };

    [[MParticle sharedInstance].rokt selectPlacements:@"RoktLayout" attributes:customAttributes];
}

- (void)selectDarkOverlayPlacement {
    // Rokt Placement
    NSDictionary<NSString *, NSString *> *customAttributes = @{@"email": @"j.smit@example.com",
                                                               @"firstname": @"Jenny",
                                                               @"lastname": @"Smith",
                                                               @"sandbox": @"true",
                                                               @"mobile": @"(555)867-5309"
    };

    MPRoktConfig *roktConfig = [[MPRoktConfig alloc] init];
    roktConfig.colorMode = MPColorModeDark;
    [[MParticle sharedInstance].rokt selectPlacements:@"RoktLayout"
                                           attributes:customAttributes
                                        embeddedViews:nil
                                               config:roktConfig
                                            callbacks:nil];
}

- (void)selectEmbeddedPlacement {
    // Rokt Placement
    NSDictionary<NSString *, NSString *> *customAttributes = @{@"email": @"j.smit@example.com",
                                                               @"firstname": @"Jenny",
                                                               @"lastname": @"Smith",
                                                               @"sandbox": @"true",
                                                               @"mobile": @"(555)867-5309"
    };
    
    MPRoktEventCallback *callbacks = [[MPRoktEventCallback alloc] init];
    callbacks.onLoad = ^{
        // Optional callback for when the Rokt placement loads
    };
    callbacks.onUnLoad = ^{
        // Optional callback for when the Rokt placement unloads
    };
    callbacks.onShouldShowLoadingIndicator = ^{
        // Optional callback to show a loading indicator
    };
    callbacks.onShouldHideLoadingIndicator = ^{
        // Optional callback to hide a loading indicator
    };
    callbacks.onEmbeddedSizeChange = ^(NSString *placement, CGFloat size) {
        [self setupUI:size];
    };
    
    NSDictionary *embeddedViews = @{@"Location1": self.roktView};

    [[MParticle sharedInstance].rokt selectPlacements:@"testiOS" attributes:customAttributes embeddedViews:embeddedViews config:nil callbacks:callbacks];
}

- (void)selectOverlayPlacementAutoClose {
    // Rokt Placement
    [self selectOverlayPlacement];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[MParticle sharedInstance].rokt close];
    });
}

- (void)getAudience {
    MParticle *mParticle = [MParticle sharedInstance];
    
    [mParticle.identity.currentUser getUserAudiencesWithCompletionHandler:^(NSArray<MPAudience *> * _Nonnull currentAudiences, NSError *_Nullable error) {
        if (error) {
            NSLog(@"Failed to retrieve Audience: %@", error);
        } else {
            NSLog(@"Successfully retrieved Audience for user: %@ with audiences: %@", mParticle.identity.currentUser.userId, currentAudiences);
        }
    }];
}

- (void)logCustomMediaEvents {
    MPMediaSession *mediaSession = [[MPMediaSession alloc]
                                    initWithCoreSDK:[MParticle sharedInstance]
                                    mediaContentId:@"1234567"
                                    title:@"Sample App Video"
                                    duration:[NSNumber numberWithInt:120000]
                                    contentType:MPMediaContentTypeVideo
                                    streamType:MPMediaStreamTypeOnDemand
                                    excludeAdBreaksFromContentTime: false];
    
    [mediaSession logMediaSessionStartWithOptions:nil];
    [mediaSession logPlayWithOptions:nil];
    [mediaSession logMediaContentEndWithOptions:nil];
    [mediaSession logMediaSessionEndWithOptions:nil];
}

- (void)logTimedEvent {
    MParticle *mParticle = [MParticle sharedInstance];
    
    // Begins a timed event
    NSString *eventName = @"Timed Event";
    MPEvent *timedEvent = [[MPEvent alloc] initWithName:eventName type:MPEventTypeTransaction];
    [mParticle beginTimedEvent:timedEvent];
    
    // Dispatches a block after a random time between 1 and 5 seconds
    double delay = arc4random_uniform(4000.0) / 1000.0 + 1.0;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // Retrieves a timed event by event name
        MPEvent *retrievedTimedEvent = [mParticle eventWithName:eventName];
        
        if (retrievedTimedEvent) {
            // Logs a timed event
            [mParticle endTimedEvent:retrievedTimedEvent];
        }
    });
}

- (void)logError {
    NSDictionary *eventInfo = @{@"cause":@"slippery floor"};
    
    [[MParticle sharedInstance] logError:@"Oops" eventInfo:eventInfo];
}

- (void)logException {
    @try {
        // Invokes a non-existing method
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        SEL crashSelector = NSSelectorFromString(@"someMethodThatDoesNotExist");
        [self performSelector:crashSelector withObject:nil];
#pragma clang diagnostic pop
    } @catch (NSException *exception) {
        // Logs an exception and informs the view controller where it happened
        [[MParticle sharedInstance] logException:exception topmostContext:self];
    }
}

- (void)setUserAttribute {
    MParticle *mParticle = [MParticle sharedInstance];
    
    // Sets 'Age' as a user attribute utilizing one of the pre-defined mParticle constants
    NSString *age = [@(21 + arc4random_uniform(80)) stringValue];
    [mParticle.identity.currentUser setUserAttribute:mParticleUserAttributeAge value:age];
    
    // Sets 'Gender' as a user attribute utilizing one of the pre-defined mParticle constants
    NSString *gender = arc4random_uniform(2) ? @"m" : @"f";
    [mParticle.identity.currentUser setUserAttribute:mParticleUserAttributeGender value:gender];
    
    // Sets a numeric user attribute using a custom key
    [mParticle.identity.currentUser setUserAttribute:@"Achieved Level" value:@4];
}

- (void)incrementUserAttribute {
    // Increments the value of a numeric user attribute
    [[MParticle sharedInstance].identity.currentUser incrementUserAttribute:@"Achieved Level" byValue:@1];
}

- (void)setUserAttributeList {
    MParticle *mParticle = [MParticle sharedInstance];
    
    // Set a user attribute with an array/list value
    NSArray *favoriteColors = @[@"Blue", @"Green", @"Red"];
    [mParticle.identity.currentUser setUserAttributeList:@"Favorite Colors" values:favoriteColors];
    
    // Set another list attribute
    NSArray *interests = @[@"Gaming", @"Music", @"Travel", @"Technology"];
    [mParticle.identity.currentUser setUserAttributeList:@"Interests" values:interests];
    
    NSLog(@"Set user attribute lists: Favorite Colors and Interests");
}

- (void)removeUserAttribute {
    MParticle *mParticle = [MParticle sharedInstance];
    
    // Remove a specific user attribute
    [mParticle.identity.currentUser removeUserAttribute:@"Achieved Level"];
    
    NSLog(@"Removed user attribute: Achieved Level");
}

- (void)setSessionAttribute {
    MParticle *mParticle = [MParticle sharedInstance];
    
    // Sets session attributes
    [mParticle setSessionAttribute:@"Station" value:@"Classic Rock"];
    [mParticle setSessionAttribute:@"Song Count" value:@1];
}

- (void)incrementSessionAttribute {
    // Increments a numeric session attribute
    [[MParticle sharedInstance] incrementSessionAttribute:@"Song Count" byValue:@1];
}

- (void)registerRemote {
    [[UIApplication sharedApplication] registerForRemoteNotifications];
}

- (void)toggleCCPAConsent {
    MPCCPAConsent *consentState = [[MParticle sharedInstance].identity.currentUser.consentState.ccpaConsentState copy];
    if (consentState.consented) {
        MPCCPAConsent *ccpaConsent = [[MPCCPAConsent alloc] init];
        ccpaConsent.consented = NO;
        ccpaConsent.document = @"ccpa_consent_agreement_v3";
        ccpaConsent.timestamp = [[NSDate alloc] init];
        ccpaConsent.location = @"17 Cherry Tree Lane";
        ccpaConsent.hardwareId = @"IDFA:a5d934n0-232f-4afc-2e9a-3832d95zc702";
        
        MPConsentState *newConsentState = [[MPConsentState alloc] init];
        [newConsentState setCCPAConsentState:ccpaConsent];
        [newConsentState setGDPRConsentState:[MParticle sharedInstance].identity.currentUser.consentState.gdprConsentState];
        
        [MParticle sharedInstance].identity.currentUser.consentState = newConsentState;
    } else {
        MPCCPAConsent *ccpaConsent = [[MPCCPAConsent alloc] init];
        ccpaConsent.consented = YES;
        ccpaConsent.document = @"ccpa_consent_agreement_v3";
        ccpaConsent.timestamp = [[NSDate alloc] init];
        ccpaConsent.location = @"17 Cherry Tree Lane";
        ccpaConsent.hardwareId = @"IDFA:a5d934n0-232f-4afc-2e9a-3832d95zc702";
        
        MPConsentState *newConsentState = [[MPConsentState alloc] init];
        [newConsentState setCCPAConsentState:ccpaConsent];
        [newConsentState setGDPRConsentState:[MParticle sharedInstance].identity.currentUser.consentState.gdprConsentState];

        [MParticle sharedInstance].identity.currentUser.consentState = newConsentState;
    }
}

- (void)toggleGDPRConsent {
    NSDictionary<NSString *, MPGDPRConsent *> *gdprState = [[MParticle sharedInstance].identity.currentUser.consentState.gdprConsentState copy];
    if (gdprState != nil && gdprState[@"my gdpr purpose"].consented) {
        
        MPGDPRConsent *locationCollectionConsent = [[MPGDPRConsent alloc] init];
        locationCollectionConsent.consented = NO;
        locationCollectionConsent.document = @"location_collection_agreement_v4";
        locationCollectionConsent.timestamp = [[NSDate alloc] init];
        locationCollectionConsent.location = @"17 Cherry Tree Lane";
        locationCollectionConsent.hardwareId = @"IDFA:a5d934n0-232f-4afc-2e9a-3832d95zc702";
        
        MPConsentState *newConsentState = [[MPConsentState alloc] init];
        [newConsentState addGDPRConsentState:locationCollectionConsent purpose:@"My GDPR Purpose"];
        [newConsentState setCCPAConsentState:[MParticle sharedInstance].identity.currentUser.consentState.ccpaConsentState];
        [MParticle sharedInstance].identity.currentUser.consentState = newConsentState;
    } else {
        MPGDPRConsent *locationCollectionConsent = [[MPGDPRConsent alloc] init];
        locationCollectionConsent.consented = YES;
        locationCollectionConsent.document = @"location_collection_agreement_v4";
        locationCollectionConsent.timestamp = [[NSDate alloc] init];
        locationCollectionConsent.location = @"17 Cherry Tree Lane";
        locationCollectionConsent.hardwareId = @"IDFA:a5d934n0-232f-4afc-2e9a-3832d95zc702";
        
        MPConsentState *newConsentState = [[MPConsentState alloc] init];
        [newConsentState addGDPRConsentState:locationCollectionConsent purpose:@"My GDPR Purpose"];
        [newConsentState setCCPAConsentState:[MParticle sharedInstance].identity.currentUser.consentState.ccpaConsentState];
        [MParticle sharedInstance].identity.currentUser.consentState = newConsentState;
    }
}
    
- (void)logIDFA:(NSString *) advertiserID {
    MParticleUser *currentUser = [[MParticle sharedInstance] identity].currentUser;
    MPIdentityApiRequest *identityRequest = [MPIdentityApiRequest requestWithUser:currentUser];
    [identityRequest setIdentity:advertiserID identityType:MPIdentityIOSAdvertiserId];
    [[[MParticle sharedInstance] identity] modify:identityRequest completion:^(MPModifyApiResult *_Nullable apiResult, NSError *_Nullable error) {
        if (error) {
            NSLog(@"Failed to update IDFA: %@", error);
        } else {
            NSLog(@"Update IDFA: %@", apiResult.identityChanges);
        }
    }];
}

- (void)requestIDFA {
    if (@available(iOS 14, *)) {
        #if TARGET_OS_IOS == 1 && __IPHONE_OS_VERSION_MAX_ALLOWED >= 140000
        [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler: ^(ATTrackingManagerAuthorizationStatus status){
            switch (status) {
                case ATTrackingManagerAuthorizationStatusAuthorized:
                    // Tracking authorization dialog was shown
                    // and we are authorized
                    NSLog(@"Authorized");
                    [[MParticle sharedInstance] setATTStatus:MPATTAuthorizationStatusAuthorized withATTStatusTimestampMillis:nil];
                    [self logIDFA:[[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString]];
                    break;
                    
                case ATTrackingManagerAuthorizationStatusDenied:
                    // Tracking authorization dialog was
                    // shown and permission is denied
                    [[MParticle sharedInstance] setATTStatus:MPATTAuthorizationStatusDenied withATTStatusTimestampMillis:nil];
                    NSLog(@"Denied");
                    break;
                    
                case ATTrackingManagerAuthorizationStatusNotDetermined:
                    // Tracking authorization dialog has not been shown
                    [[MParticle sharedInstance] setATTStatus:MPATTAuthorizationStatusNotDetermined withATTStatusTimestampMillis:nil];
                    NSLog(@"Not Determined");
                    break;
                    
                case ATTrackingManagerAuthorizationStatusRestricted:
                    // Tracking authorization dialog has not been shown
                    [[MParticle sharedInstance] setATTStatus:MPATTAuthorizationStatusRestricted withATTStatusTimestampMillis:nil];
                    NSLog(@"Restricted");
                    break;
                    
                default:
                    break;
            }
        }];
        #endif
    } else {
        // Fallback on earlier versions
        if ([[ASIdentifierManager sharedManager] isAdvertisingTrackingEnabled]) {
            [self logIDFA:[[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString]];
        }
    }
    
}


- (void)logout {
    MPIdentityApiRequest *identityRequest = [MPIdentityApiRequest requestWithEmptyUser];
    
    [[[MParticle sharedInstance] identity] logout:identityRequest completion:^(MPIdentityApiResult *_Nullable apiResult, NSError *_Nullable error) {
        if (error) {
            NSLog(@"Failed to logout: %@", error);
        } else {
            NSLog(@"Logout Successful");
        }
    }];
}

- (void)login {
    MPIdentityApiRequest *identityRequest = [MPIdentityApiRequest requestWithEmptyUser];
    if (_emailField.text.length > 0) {
        identityRequest.email = _emailField.text;
    }
    if (_customerIDField.text.length > 0) {
        identityRequest.customerId = _customerIDField.text;
    }
    
    [[[MParticle sharedInstance] identity] login:identityRequest completion:^(MPIdentityApiResult *_Nullable apiResult, NSError *_Nullable error) {
        if (error) {
            NSLog(@"Failed to login: %@", error);
        } else {
            NSLog(@"Login Successful");
        }
    }];
}

- (void)modify {
    [self logIDFA:@"C56A4180-65AA-42EC-A945-5FD21DEC0538"];
}

-(void)decreaseUploadInterval {
    [MParticle sharedInstance].uploadInterval = 1.0;
}

-(void)increaseUploadInterval {
    [MParticle sharedInstance].uploadInterval = 1200.0;
}

#pragma mark Debug & Info Actions

- (void)displayCurrentUser {
    MParticle *mParticle = [MParticle sharedInstance];
    MParticleUser *currentUser = mParticle.identity.currentUser;
    
    if (!currentUser) {
        [self showAlertWithTitle:@"Current User Info" message:@"No current user found"];
        return;
    }
    
    NSMutableString *info = [NSMutableString stringWithString:@"=== CURRENT USER INFO ===\n\n"];
    
    // MPID
    [info appendFormat:@"MPID: %@\n\n", currentUser.userId];
    
    // Device Application Stamp
    [info appendFormat:@"Device App Stamp: %@\n\n", mParticle.identity.deviceApplicationStamp];
    
    // User Identities
    [info appendString:@"--- IDENTITIES ---\n"];
    NSDictionary *identities = currentUser.identities;
    if (identities.count == 0) {
        [info appendString:@"(none)\n"];
    } else {
        for (NSNumber *typeNum in identities) {
            NSString *value = identities[typeNum];
            NSString *typeName = [self identityTypeNameForType:typeNum.unsignedIntegerValue];
            [info appendFormat:@"%@: %@\n", typeName, value];
        }
    }
    
    [info appendString:@"\n"];
    
    // User Attributes
    [info appendString:@"--- USER ATTRIBUTES ---\n"];
    NSDictionary *attributes = currentUser.userAttributes;
    if (attributes.count == 0) {
        [info appendString:@"(none)\n"];
    } else {
        NSArray *sortedKeys = [[attributes allKeys] sortedArrayUsingSelector:@selector(compare:)];
        for (NSString *key in sortedKeys) {
            id value = attributes[key];
            if ([value isKindOfClass:[NSArray class]]) {
                [info appendFormat:@"%@: %@\n", key, value];
            } else {
                [info appendFormat:@"%@: %@\n", key, value];
            }
        }
    }
    [info appendString:@"\n"];
    
    // Consent State
    [info appendString:@"--- CONSENT STATE ---\n"];
    MPConsentState *consentState = currentUser.consentState;
    if (consentState) {
        MPCCPAConsent *ccpa = consentState.ccpaConsentState;
        if (ccpa) {
            [info appendFormat:@"CCPA Consented: %@\n", ccpa.consented ? @"YES" : @"NO"];
        } else {
            [info appendString:@"CCPA: (not set)\n"];
        }
        
        NSDictionary *gdpr = consentState.gdprConsentState;
        if (gdpr && gdpr.count > 0) {
            for (NSString *purpose in gdpr) {
                MPGDPRConsent *consent = gdpr[purpose];
                [info appendFormat:@"GDPR [%@]: %@\n", purpose, consent.consented ? @"YES" : @"NO"];
            }
        } else {
            [info appendString:@"GDPR: (not set)\n"];
        }
    } else {
        [info appendString:@"(no consent state)\n"];
    }
    
    [self showAlertWithTitle:@"Current User Info" message:info];
}

- (NSString *)identityTypeNameForType:(MPIdentity)type {
    switch (type) {
        case MPIdentityOther: return @"Other";
        case MPIdentityCustomerId: return @"Customer ID";
        case MPIdentityFacebook: return @"Facebook";
        case MPIdentityTwitter: return @"Twitter";
        case MPIdentityGoogle: return @"Google";
        case MPIdentityMicrosoft: return @"Microsoft";
        case MPIdentityYahoo: return @"Yahoo";
        case MPIdentityEmail: return @"Email";
        case MPIdentityAlias: return @"Alias";
        case MPIdentityFacebookCustomAudienceId: return @"Facebook Custom Audience ID";
        case MPIdentityOther2: return @"Other 2";
        case MPIdentityOther3: return @"Other 3";
        case MPIdentityOther4: return @"Other 4";
        case MPIdentityOther5: return @"Other 5";
        case MPIdentityOther6: return @"Other 6";
        case MPIdentityOther7: return @"Other 7";
        case MPIdentityOther8: return @"Other 8";
        case MPIdentityOther9: return @"Other 9";
        case MPIdentityOther10: return @"Other 10";
        case MPIdentityMobileNumber: return @"Mobile Number";
        case MPIdentityPhoneNumber2: return @"Phone Number 2";
        case MPIdentityPhoneNumber3: return @"Phone Number 3";
        case MPIdentityIOSAdvertiserId: return @"iOS Advertiser ID (IDFA)";
        case MPIdentityIOSVendorId: return @"iOS Vendor ID (IDFV)";
        case MPIdentityPushToken: return @"Push Token";
        case MPIdentityDeviceApplicationStamp: return @"Device Application Stamp";
        default: return [NSString stringWithFormat:@"Unknown (%lu)", (unsigned long)type];
    }
}

- (void)forceUpload {
    [[MParticle sharedInstance] upload];
    NSLog(@"Force upload triggered");
}

- (void)checkKitStatus {
    MParticle *mParticle = [MParticle sharedInstance];
    
    NSMutableString *status = [NSMutableString stringWithString:@"=== KIT STATUS ===\n\n"];
    
    // Common kit codes
    NSArray *commonKits = @[
        @{@"code": @20, @"name": @"Adjust"},
        @{@"code": @119, @"name": @"Adobe Analytics"},
        @{@"code": @28, @"name": @"Appboy/Braze"},
        @{@"code": @92, @"name": @"AppsFlyer"},
        @{@"code": @31, @"name": @"Amplitude"},
        @{@"code": @39, @"name": @"Branch"},
        @{@"code": @134, @"name": @"Facebook"},
        @{@"code": @64, @"name": @"Firebase"},
        @{@"code": @160, @"name": @"Google Analytics 4"},
        @{@"code": @37, @"name": @"Kochava"},
        @{@"code": @49, @"name": @"Leanplum"},
        @{@"code": @128, @"name": @"Segment"},
        @{@"code": @170, @"name": @"Singular"},
    ];
    
    [status appendString:@"--- COMMON KITS ---\n"];
    NSMutableArray *activeKits = [NSMutableArray array];
    
    for (NSDictionary *kit in commonKits) {
        NSNumber *code = kit[@"code"];
        NSString *name = kit[@"name"];
        BOOL isActive = [mParticle isKitActive:code];
        NSString *statusEmoji = isActive ? @"✅" : @"❌";
        [status appendFormat:@"%@ %@ (%@): %@\n", statusEmoji, name, code, isActive ? @"Active" : @"Inactive"];
        
        if (isActive) {
            [activeKits addObject:name];
        }
    }
    
    [status appendString:@"\n--- ACTIVE KITS ---\n"];
    if (activeKits.count == 0) {
        [status appendString:@"(no kits currently active)\n"];
    } else {
        for (NSString *kitName in activeKits) {
            [status appendFormat:@"• %@\n", kitName];
        }
    }
    
    [status appendString:@"\n--- NOTE ---\n"];
    [status appendString:@"Kits become active after receiving\nconfiguration from mParticle server.\n"];
    [status appendString:@"Ensure you have kits enabled in\nyour mParticle workspace."];
    
    [self showAlertWithTitle:@"Kit Status" message:status];
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
