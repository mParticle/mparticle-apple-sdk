# mParticle Apple SDK Smoke Testing Plan

This document outlines the smoke testing procedures for validating core functionality of the mParticle Apple SDK. These tests should be executed against the Example app (`/Example/mParticleExample`) and verified both through the app UI and the mParticle Live Stream dashboard.

## Prerequisites

1. **mParticle Workspace Setup**
   - Valid mParticle API key and secret configured in `AppDelegate.m`
   - Access to mParticle dashboard with Live Stream enabled
   - Test workspace configured for development environment

2. **Development Environment**
   - Xcode installed with iOS Simulator
   - CocoaPods dependencies installed (`pod install` in Example directory)
   - Physical iOS device (optional, required for push notification and IDFA tests)

3. **Network Configuration**
   - Network connectivity to mParticle servers
   - Charles Proxy or similar tool (optional, for network inspection)

---

## Test Categories

### 1. SDK Initialization

| Test ID | Test Case | Steps | Expected Result |
|---------|-----------|-------|-----------------|
| INIT-01 | Basic SDK Initialization | 1. Launch app with valid API key/secret<br>2. Check console logs | SDK initializes without errors, "mParticle SDK started" appears in logs |
| INIT-02 | Initial Identify Request | 1. Configure `identifyRequest` in options<br>2. Set `onIdentifyComplete` callback<br>3. Launch app | Identify callback fires with valid user, no error |
| INIT-03 | Log Level Configuration | 1. Set `options.logLevel = MPILogLevelVerbose`<br>2. Launch app<br>3. Perform actions | Verbose logging appears in console |
| INIT-04 | Environment Detection | 1. Build in Debug mode<br>2. Check mParticle dashboard | Events show as "Development" environment |
| INIT-05 | Session Start | 1. Launch app<br>2. Check Live Stream | Session Start event appears |

**Reference Code (AppDelegate.m):**
```objc
MParticleOptions *options = [MParticleOptions optionsWithKey:@"YOUR_KEY"
                                                      secret:@"YOUR_SECRET"];
options.identifyRequest = identityRequest;
options.logLevel = MPILogLevelVerbose;
[[MParticle sharedInstance] startWithOptions:options];
```

---

### 2. Event Tracking

| Test ID | Test Case | Steps | Expected Result |
|---------|-----------|-------|-----------------|
| EVT-01 | Log Simple Event | 1. Tap "Log Simple Event"<br>2. Check Live Stream | Custom event with name "Simple Event Name" appears with custom attributes |
| EVT-02 | Log Event with Attributes | 1. Tap "Log Event"<br>2. Check Live Stream | Event "Event Name" appears with string, number, date, and dictionary attributes |
| EVT-03 | Log Event with Custom Flags | 1. Tap "Log Event"<br>2. Verify in Live Stream | Custom flags present in event payload but not forwarded to integrations |
| EVT-04 | Log Timed Event | 1. Tap "Log Timed Event"<br>2. Wait for completion<br>3. Check Live Stream | Timed event shows duration between 1-5 seconds |
| EVT-05 | Event Type Validation | 1. Log events with different `MPEventType` values | Events categorized correctly by type |

**Reference Code (ViewController.m):**
```objc
// Simple event
[[MParticle sharedInstance] logEvent:@"Simple Event Name"
                           eventType:MPEventTypeOther
                           eventInfo:@{@"SimpleKey":@"SimpleValue"}];

// Rich event with attributes
MPEvent *event = [[MPEvent alloc] initWithName:@"Event Name" type:MPEventTypeTransaction];
event.customAttributes = @{@"key": @"value"};
[[MParticle sharedInstance] logEvent:event];
```

---

### 3. Screen Tracking

| Test ID | Test Case | Steps | Expected Result |
|---------|-----------|-------|-----------------|
| SCR-01 | Log Screen View | 1. Tap "Log Screen"<br>2. Check Live Stream | Screen View event for "Home Screen" appears |
| SCR-02 | Screen with Attributes | 1. Log screen with eventInfo<br>2. Check Live Stream | Screen event includes custom attributes |

**Reference Code:**
```objc
[[MParticle sharedInstance] logScreen:@"Home Screen" eventInfo:nil];
```

---

### 4. Commerce Events

| Test ID | Test Case | Steps | Expected Result |
|---------|-----------|-------|-----------------|
| COM-01 | Log Purchase Event | 1. Tap "Log Commerce Event"<br>2. Check Live Stream | Purchase event appears with product details |
| COM-02 | Product Attributes | 1. Create product with all fields<br>2. Log commerce event | Product shows: name, sku, brand, category, coupon, position, custom attributes |
| COM-03 | Transaction Attributes | 1. Log purchase with transaction details | Transaction shows: affiliation, shipping, tax, revenue, transactionId |
| COM-04 | Multiple Products | 1. Add multiple products to commerce event<br>2. Log event | All products appear in the commerce event |

**Reference Code:**
```objc
MPProduct *product = [[MPProduct alloc] initWithName:@"Awesome Book" 
                                                 sku:@"1234567890" 
                                            quantity:@1 
                                               price:@9.99];
product.brand = @"A Publisher";
product.category = @"Fiction";

MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] 
    initWithAction:MPCommerceEventActionPurchase product:product];

MPTransactionAttributes *transactionAttributes = [[MPTransactionAttributes alloc] init];
transactionAttributes.revenue = @12.09;
transactionAttributes.transactionId = @"zyx098";
commerceEvent.transactionAttributes = transactionAttributes;

[[MParticle sharedInstance] logEvent:commerceEvent];
```

---

### 5. Identity Management (IDSync)

| Test ID | Test Case | Steps | Expected Result |
|---------|-----------|-------|-----------------|
| ID-01 | Login | 1. Enter email and customer ID<br>2. Tap "Login"<br>3. Check console | Login success logged, user MPID updated |
| ID-02 | Logout | 1. Tap "Logout"<br>2. Check console | Logout success logged, new anonymous user created |
| ID-03 | Modify Identity | 1. Tap "Set IDFA"<br>2. Check Live Stream | Modify request sent, identity changes returned |
| ID-04 | Get Current User | 1. Access `identity.currentUser`<br>2. Verify user object | Valid MParticleUser returned with MPID |
| ID-05 | Get All Users | 1. Login/logout multiple times<br>2. Call `getAllUsers` | Returns array of known users ordered by last seen |
| ID-06 | User Persistence | 1. Login with credentials<br>2. Kill and restart app | User persists, same MPID on restart |

**Reference Code:**
```objc
// Login
MPIdentityApiRequest *identityRequest = [MPIdentityApiRequest requestWithEmptyUser];
identityRequest.email = @"user@example.com";
identityRequest.customerId = @"123456";
[[[MParticle sharedInstance] identity] login:identityRequest 
    completion:^(MPIdentityApiResult *apiResult, NSError *error) {
        if (!error) {
            NSLog(@"Login Successful");
        }
    }];

// Logout
MPIdentityApiRequest *logoutRequest = [MPIdentityApiRequest requestWithEmptyUser];
[[[MParticle sharedInstance] identity] logout:logoutRequest completion:nil];
```

---

### 6. User Attributes

| Test ID | Test Case | Steps | Expected Result |
|---------|-----------|-------|-----------------|
| UA-01 | Set User Attribute | 1. Tap "Set User Attribute"<br>2. Check Live Stream | Age, Gender, and custom attributes set on user |
| UA-02 | Increment User Attribute | 1. Set numeric attribute<br>2. Tap "Increment User Attribute"<br>3. Check value | Attribute value increased by specified amount |
| UA-03 | Reserved Attributes | 1. Set `mParticleUserAttributeAge`<br>2. Verify in dashboard | Reserved attribute names recognized |
| UA-04 | Array Attributes | 1. Set attribute with array value<br>2. Verify | Array stored and transmitted correctly |

**Reference Code:**
```objc
MParticle *mp = [MParticle sharedInstance];
[mp.identity.currentUser setUserAttribute:mParticleUserAttributeAge value:@"25"];
[mp.identity.currentUser setUserAttribute:@"Achieved Level" value:@4];
[mp.identity.currentUser incrementUserAttribute:@"Achieved Level" byValue:@1];
```

---

### 7. Session Management

| Test ID | Test Case | Steps | Expected Result |
|---------|-----------|-------|-----------------|
| SES-01 | Session Attributes | 1. Tap "Set Session Attribute"<br>2. Check Live Stream | Session attributes appear on events |
| SES-02 | Increment Session Attribute | 1. Set numeric session attribute<br>2. Tap "Increment Session Attribute" | Value increments correctly |
| SES-03 | Session Timeout | 1. Configure session timeout<br>2. Background app longer than timeout<br>3. Return to app | New session started |
| SES-04 | Manual Session Control | 1. Disable automatic session tracking<br>2. Call `beginSession`/`endSession` | Sessions controlled manually |

**Reference Code:**
```objc
[[MParticle sharedInstance] setSessionAttribute:@"Station" value:@"Classic Rock"];
[[MParticle sharedInstance] incrementSessionAttribute:@"Song Count" byValue:@1];
```

---

### 8. Consent Management

| Test ID | Test Case | Steps | Expected Result |
|---------|-----------|-------|-----------------|
| CON-01 | Set GDPR Consent | 1. Tap "Toggle GDPR Consent"<br>2. Check Live Stream | GDPR consent state appears in events |
| CON-02 | Set CCPA Consent | 1. Tap "Toggle CCPA Consent"<br>2. Check Live Stream | CCPA consent state appears in events |
| CON-03 | Multiple GDPR Purposes | 1. Add multiple GDPR purposes<br>2. Verify | All purposes transmitted correctly |
| CON-04 | Consent Persistence | 1. Set consent state<br>2. Restart app | Consent state persists |
| CON-05 | Consent with Metadata | 1. Set consent with document, timestamp, location, hardwareId<br>2. Verify | All metadata transmitted |

**Reference Code:**
```objc
MPGDPRConsent *consent = [[MPGDPRConsent alloc] init];
consent.consented = YES;
consent.document = @"agreement_v1";
consent.timestamp = [[NSDate alloc] init];
consent.location = @"17 Cherry Tree Lane";

MPConsentState *consentState = [[MPConsentState alloc] init];
[consentState addGDPRConsentState:consent purpose:@"Marketing"];
[MParticle sharedInstance].identity.currentUser.consentState = consentState;
```

---

### 9. Error and Exception Logging

| Test ID | Test Case | Steps | Expected Result |
|---------|-----------|-------|-----------------|
| ERR-01 | Log Error | 1. Tap "Log Error"<br>2. Check Live Stream | Error event appears with message and attributes |
| ERR-02 | Log Exception | 1. Tap "Log Exception"<br>2. Check Live Stream | Exception event appears with stack trace info |

**Reference Code:**
```objc
[[MParticle sharedInstance] logError:@"Oops" eventInfo:@{@"cause":@"slippery floor"}];

@try {
    // Code that throws exception
} @catch (NSException *exception) {
    [[MParticle sharedInstance] logException:exception topmostContext:self];
}
```

---

### 10. Network and Upload Behavior

| Test ID | Test Case | Steps | Expected Result |
|---------|-----------|-------|-----------------|
| NET-01 | Event Upload | 1. Log multiple events<br>2. Monitor network<br>3. Check Live Stream | Events batch uploaded within upload interval |
| NET-02 | Upload Interval - Decrease | 1. Tap "Decrease Upload Timer"<br>2. Log event<br>3. Monitor upload timing | Events upload within ~1 second |
| NET-03 | Upload Interval - Increase | 1. Tap "Increase Upload Timer"<br>2. Log event<br>3. Monitor | Events batch until 20 min or app background |
| NET-04 | Offline Queueing | 1. Enable airplane mode<br>2. Log events<br>3. Disable airplane mode | Events queued offline, uploaded when connected |
| NET-05 | Config Fetch | 1. Launch app<br>2. Monitor network | Config fetched from mParticle servers on start |

---

### 11. App Tracking Transparency (ATT) / IDFA

| Test ID | Test Case | Steps | Expected Result |
|---------|-----------|-------|-----------------|
| ATT-01 | Request ATT Permission | 1. Tap "Request & Set IDFA"<br>2. Respond to prompt | ATT status set correctly based on user response |
| ATT-02 | IDFA with Authorization | 1. Authorize tracking<br>2. Check events | IDFA included in device info |
| ATT-03 | IDFA Denied | 1. Deny tracking<br>2. Check events | IDFA excluded, ATT status = "denied" |
| ATT-04 | Set ATT Status Programmatically | 1. Call `setATTStatus:withATTStatusTimestampMillis:`<br>2. Check events | ATT status and timestamp present |

**Reference Code:**
```objc
[[MParticle sharedInstance] setATTStatus:MPATTAuthorizationStatusAuthorized 
            withATTStatusTimestampMillis:nil];
```

**Note:** IDFA tests require a physical device (not simulator).

---

### 12. Push Notifications

| Test ID | Test Case | Steps | Expected Result |
|---------|-----------|-------|-----------------|
| PUSH-01 | Register for Remote Notifications | 1. Tap "Register Remote"<br>2. Accept notification permission | Device token received and sent to mParticle |
| PUSH-02 | Push Token in Events | 1. Register for push<br>2. Check event payloads | Push token appears in device info |

**Note:** Push notification tests require a physical device.

---

### 13. Audience Membership

| Test ID | Test Case | Steps | Expected Result |
|---------|-----------|-------|-----------------|
| AUD-01 | Get User Audiences | 1. Tap "Get Audience"<br>2. Check console logs | Audience membership returned (or empty array if none) |
| AUD-02 | Audience Error Handling | 1. Call with invalid config<br>2. Check error | Error callback invoked with details |

**Reference Code:**
```objc
[mParticle.identity.currentUser getUserAudiencesWithCompletionHandler:
    ^(NSArray<MPAudience *> *audiences, NSError *error) {
        if (!error) {
            NSLog(@"Audiences: %@", audiences);
        }
    }];
```

---

### 14. Media SDK Integration

| Test ID | Test Case | Steps | Expected Result |
|---------|-----------|-------|-----------------|
| MED-01 | Media Session Lifecycle | 1. Tap "Log Media Events"<br>2. Check Live Stream | Media session start, play, content end, session end events appear |
| MED-02 | Media Content Metadata | 1. Create media session with all metadata<br>2. Log events | Content ID, title, duration, content type, stream type present |

**Reference Code:**
```objc
MPMediaSession *mediaSession = [[MPMediaSession alloc]
    initWithCoreSDK:[MParticle sharedInstance]
    mediaContentId:@"1234567"
    title:@"Sample App Video"
    duration:[NSNumber numberWithInt:120000]
    contentType:MPMediaContentTypeVideo
    streamType:MPMediaStreamTypeOnDemand];

[mediaSession logMediaSessionStartWithOptions:nil];
[mediaSession logPlayWithOptions:nil];
[mediaSession logMediaContentEndWithOptions:nil];
[mediaSession logMediaSessionEndWithOptions:nil];
```

---

### 15. Rokt Integration

| Test ID | Test Case | Steps | Expected Result |
|---------|-----------|-------|-----------------|
| ROKT-01 | Overlay Placement | 1. Tap "Display Rokt Overlay Placement"<br>2. Observe UI | Rokt overlay appears |
| ROKT-02 | Embedded Placement | 1. Tap "Display Rokt Embedded Placement"<br>2. Observe UI | Rokt embedded view appears in scrollable area |
| ROKT-03 | Dark Mode Placement | 1. Tap "Display Rokt Dark Mode Overlay"<br>2. Observe UI | Rokt overlay appears with dark theme |
| ROKT-04 | Auto Close | 1. Tap "Display Rokt Overlay (auto close)"<br>2. Wait 5 seconds | Overlay automatically dismisses |
| ROKT-05 | Rokt Callbacks | 1. Display embedded placement<br>2. Check callback invocations | onLoad, onUnLoad, onShouldShowLoadingIndicator, onEmbeddedSizeChange callbacks fire |

**Note:** Rokt tests require valid Rokt configuration in your mParticle workspace.

---

## Smoke Test Execution Checklist

### Pre-Release Smoke Test (Minimum)

Execute these tests before any SDK release:

- [ ] INIT-01: Basic SDK Initialization
- [ ] INIT-02: Initial Identify Request
- [ ] EVT-01: Log Simple Event
- [ ] SCR-01: Log Screen View
- [ ] COM-01: Log Purchase Event
- [ ] ID-01: Login
- [ ] ID-02: Logout
- [ ] UA-01: Set User Attribute
- [ ] SES-01: Session Attributes
- [ ] CON-01: Set GDPR Consent
- [ ] ERR-01: Log Error
- [ ] NET-01: Event Upload

### Full Smoke Test

Execute all tests in this document for major releases or when significant changes are made.

---

## Test Environment Matrix

| Platform | iOS Version | Device Type | Priority |
|----------|-------------|-------------|----------|
| iOS | 17.x | iPhone Simulator | High |
| iOS | 16.x | iPhone Simulator | Medium |
| iOS | 15.x | iPhone Simulator | Medium |
| iOS | 17.x | Physical iPhone | High (for ATT/Push) |
| tvOS | 17.x | tvOS Simulator | Medium |

---

## Verification Methods

1. **Console Logs**: Enable `MPILogLevelVerbose` and monitor Xcode console
2. **Live Stream**: Use mParticle dashboard Live Stream to verify events in real-time
3. **Network Inspection**: Use Charles Proxy to inspect HTTP requests/responses
4. **User Activity**: Check User Activity view in mParticle dashboard
5. **Integration Tests**: Run existing integration tests in `/IntegrationTests` directory

---

## Common Issues and Troubleshooting

| Issue | Possible Cause | Resolution |
|-------|----------------|------------|
| Events not appearing in Live Stream | Invalid API key/secret | Verify credentials in AppDelegate |
| Events delayed | Upload interval too long | Decrease upload interval for testing |
| Identity callback not firing | Network timeout | Check network connectivity |
| IDFA always nil | Running on simulator | Use physical device |
| Consent not persisting | User logged out | Consent tied to user MPID |

---

## References

- [mParticle iOS SDK Documentation](https://docs.mparticle.com/developers/client-sdks/ios/initialization/)
- [IDSync Documentation](https://docs.mparticle.com/guides/idsync/)
- [Commerce Event Documentation](https://docs.mparticle.com/developers/client-sdks/ios/commerce-events/)
- [iOS 14 ATT Guide](https://docs.mparticle.com/developers/client-sdks/ios/ios-14-guide/)
