//
//  MPKitContainer.mm
//
//  Copyright 2016 mParticle, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "MPKitContainer.h"
#include <map>
#include "MPBracket.h"
#import "MPCommerceEvent.h"
#import "MPCommerceEvent+Dictionary.h"
#import "MPConsumerInfo.h"
#import "MPEnums.h"
#import "MPEvent.h"
#import "MPForwardQueueItem.h"
#import "MPForwardQueueParameters.h"
#import "MPForwardRecord.h"
#include "MPHasher.h"
#import "MPILogger.h"
#import "MPKitConfiguration.h"
#import "MPKitDataTransformation.h"
#import "MPKitExecStatus.h"
#import "MPKitFilter.h"
#import "MPPersistenceController.h"
#import "MPStateMachine.h"
#import "NSUserDefaults+mParticle.h"

#define DEFAULT_ALLOCATION_FOR_KITS 2

NSString *const kitFileExtension = @"eks";
static NSMutableSet <id<MPExtensionKitProtocol>> *kitsRegistry;

@interface MPKitContainer() {
    dispatch_semaphore_t kitsSemaphore;
    std::map<NSNumber *, std::shared_ptr<mParticle::Bracket>> brackets;
}

@property (nonatomic, strong) MPKitDataTransformation *dataTransformation;
@property (nonatomic, strong) NSMutableArray<MPForwardQueueItem *> *forwardQueue;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, MPKitConfiguration *> *kitConfigurations;
@property (nonatomic, unsafe_unretained) BOOL kitsInitialized;

@end


@implementation MPKitContainer

+ (void)initialize {
    kitsRegistry = [[NSMutableSet alloc] initWithCapacity:DEFAULT_ALLOCATION_FOR_KITS];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _kitsInitialized = NO;
        kitsSemaphore = dispatch_semaphore_create(1);
        
        if (![MPStateMachine sharedInstance].optOut) {
            [self initializeKits];
        }
        
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self
                               selector:@selector(handleApplicationDidBecomeActive:)
                                   name:UIApplicationDidBecomeActiveNotification
                                 object:nil];
        
        [notificationCenter addObserver:self
                               selector:@selector(handleApplicationDidFinishLaunching:)
                                   name:UIApplicationDidFinishLaunchingNotification
                                 object:nil];
    }
    
    return self;
}

- (void)dealloc {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [notificationCenter removeObserver:self name:UIApplicationDidFinishLaunchingNotification object:nil];
}

#pragma mark Notification handlers
- (void)handleApplicationDidBecomeActive:(NSNotification *)notification {
    NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [self activeKitsRegistry];
    SEL didBecomeActiveSelector = @selector(didBecomeActive);
    
    for (id<MPExtensionKitProtocol>kitRegister in activeKitsRegistry) {
        if ([kitRegister.wrapperInstance respondsToSelector:didBecomeActiveSelector]) {
            [kitRegister.wrapperInstance didBecomeActive];
        }
    }
}

- (void)handleApplicationDidFinishLaunching:(NSNotification *)notification {
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    stateMachine.launchOptions = [notification userInfo];
    SEL launchOptionsSelector = @selector(setLaunchOptions:);
    SEL startSelector = @selector(start);
    
    for (id<MPExtensionKitProtocol>kitRegister in kitsRegistry) {
        id<MPKitProtocol> kitInstance = kitRegister.wrapperInstance;
        
        if (kitInstance && ![kitInstance started]) {
            if ([kitInstance respondsToSelector:launchOptionsSelector]) {
                [kitInstance setLaunchOptions:stateMachine.launchOptions];
            }
            
            if ([kitInstance respondsToSelector:startSelector]) {
                [kitInstance start];
            }
        }
    }
}

#pragma mark Private accessors
- (MPKitDataTransformation *)dataTransformation {
    if (!_dataTransformation) {
        _dataTransformation = [[MPKitDataTransformation alloc] init];
    }
    
    return _dataTransformation;
}

- (NSMutableArray<MPForwardQueueItem *> *)forwardQueue {
    if (!_forwardQueue) {
        _forwardQueue = [[NSMutableArray alloc] initWithCapacity:DEFAULT_ALLOCATION_FOR_KITS];
    }
    
    return _forwardQueue;
}

- (void)setKitsInitialized:(BOOL)kitsInitialized {
    _kitsInitialized = kitsInitialized;
    
    if (_kitsInitialized) {
        [self replayQueuedItems];
    }
}

#pragma mark Private methods
// If kit is AppsFlyer, add the "af_customer_user_id" key and "customer_id" user identity value, if available, to the
// commerce event user defined attributes (prior to filtering and projections)
- (MPEventAbstract *)applyAppsFlyerAugmentationsToEvent:(MPEventAbstract *)event {
    MPEventAbstract *surrogateEvent = nil;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSArray *userIdentities = userDefaults[kMPUserIdentityArrayKey];
    
    for (NSDictionary *userIdentity in userIdentities) {
        MPUserIdentity identityType = (MPUserIdentity)[userIdentity[kMPUserIdentityTypeKey] intValue];
        
        if (identityType == MPUserIdentityCustomerId) {
            NSString *identityString = userIdentity[kMPUserIdentityIdKey];
            surrogateEvent = [event copy];
            
            if (event.kind == MPEventKindAppEvent) {
                NSMutableDictionary *eventInfo = [((MPEvent *)surrogateEvent).info mutableCopy];
                if (!eventInfo) {
                    eventInfo = [[NSMutableDictionary alloc] initWithCapacity:1];
                }
                
                eventInfo[@"af_customer_user_id"] = identityString;
                ((MPEvent *)surrogateEvent).info = eventInfo;
            } else if (event.kind == MPEventKindCommerceEvent) {
                NSString *identityString = userIdentity[kMPUserIdentityIdKey];
                ((MPCommerceEvent *)surrogateEvent).userDefinedAttributes[@"af_customer_user_id"] = identityString;
            }
            
            break;
        }
    }
    
    return surrogateEvent ? surrogateEvent : event;
}

- (const std::shared_ptr<mParticle::Bracket>)bracketForKit:(NSNumber *)kitCode {
    NSAssert(kitCode != nil, @"Required parameter. It cannot be nil.");
    
    std::map<NSNumber *, std::shared_ptr<mParticle::Bracket>>::iterator bracketIterator;
    bracketIterator = brackets.find(kitCode);
    
    shared_ptr<mParticle::Bracket> bracket = bracketIterator != brackets.end() ? bracketIterator->second : nullptr;
    return bracket;
}

- (void)freeKitRegister:(id<MPExtensionKitProtocol>)kitRegister {
    if (kitRegister.wrapperInstance) {
        if ([kitRegister.wrapperInstance respondsToSelector:@selector(deinit)]) {
            [kitRegister.wrapperInstance deinit];
        }
        
        kitRegister.wrapperInstance = nil;
    }
    
    NSString *stateMachineDirectoryPath = STATE_MACHINE_DIRECTORY_PATH;
    NSString *kitPath = [stateMachineDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"EmbeddedKit%@.%@", kitRegister.code, kitFileExtension]];
    
    [self removeKitConfigurationAtPath:kitPath];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *userInfo = @{mParticleKitInstanceKey:kitRegister.code};
        
        [[NSNotificationCenter defaultCenter] postNotificationName:mParticleKitDidBecomeInactiveNotification
                                                            object:nil
                                                          userInfo:userInfo];
    });
}

- (void)initializeKits {
    NSArray *directoryContents = [self fetchKitConfigurationFileNames];
    NSString *stateMachineDirectoryPath = STATE_MACHINE_DIRECTORY_PATH;
    BOOL initializedArchivedKits = NO;
    
    for (NSString *fileName in directoryContents) {
        NSString *kitPath = [stateMachineDirectoryPath stringByAppendingPathComponent:fileName];
        
        @try {
            id unarchivedObject = [NSKeyedUnarchiver unarchiveObjectWithFile:kitPath];
            
            if ([unarchivedObject isKindOfClass:[MPKitConfiguration class]]) {
                MPKitConfiguration *kitConfiguration = (MPKitConfiguration *)unarchivedObject;
                self.kitConfigurations[kitConfiguration.kitCode] = kitConfiguration;
                
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"code == %@", kitConfiguration.kitCode];
                id<MPExtensionKitProtocol>kitRegister = [[kitsRegistry filteredSetUsingPredicate:predicate] anyObject];
                
                [self startKitRegister:kitRegister configuration:kitConfiguration];

                initializedArchivedKits = YES;
            }
        } @catch (NSException *exception) {
            [self removeKitConfigurationAtPath:kitPath];
        }
    }
    
    if (initializedArchivedKits) {
        self.kitsInitialized = YES;
    }
    
    [self logIncludedKitsToConsole];
}

- (BOOL)isDisabledByBracketConfiguration:(NSDictionary *)bracketConfiguration {
    if (!bracketConfiguration) {
        return NO;
    }
    
    NSString *const MPKitBracketLowKey = @"lo";
    NSString *const MPKitBracketHighKey = @"hi";
    
    long mpId = [[MPStateMachine sharedInstance].consumerInfo.mpId longValue];
    short low = [bracketConfiguration[MPKitBracketLowKey] shortValue];
    short high = [bracketConfiguration[MPKitBracketHighKey] shortValue];
    
    mParticle::Bracket localBracket(mpId, low, high);
    return !localBracket.shouldForward();
}

- (void)logIncludedKitsToConsole {
    if ([MPStateMachine sharedInstance].logLevel < MPILogLevelDebug) {
        return;
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSArray<NSNumber *> *supportedKits = [self supportedKits];
        
        if (supportedKits) {
            NSMutableString *listOfKits = [[NSMutableString alloc] initWithString:@"Included kits: {"];
            for (NSNumber *kitCode in supportedKits) {
                [listOfKits appendFormat:@"%@, ", [self nameForKitCode:kitCode]];
            }
            
            [listOfKits deleteCharactersInRange:NSMakeRange(listOfKits.length - 2, 2)];
            [listOfKits appendString:@"}"];
            
            MPILogDebug(@"%@", listOfKits);
        }
    });
}

- (nullable NSString *)nameForKitCode:(nonnull NSNumber *)kitCode {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"code == %@", kitCode];
    id<MPExtensionKitProtocol>kitRegister = [[kitsRegistry filteredSetUsingPredicate:predicate] anyObject];
    return kitRegister.name;
}

- (void)replayQueuedItems {
    if (!_forwardQueue) {
        return;
    }
    
    for (MPForwardQueueItem *forwardQueueItem in _forwardQueue) {
        switch (forwardQueueItem.queueItemType) {
            case MPQueueItemTypeAppEvent:
                [self forwardSDKCall:forwardQueueItem.selector event:(MPEventAbstract *)forwardQueueItem.queueParameters[0] messageType:forwardQueueItem.messageType userInfo:nil kitHandler:forwardQueueItem.completionHandler];
                break;
                
            case MPQueueItemTypeGeneralPurpose:
                [self forwardSDKCall:forwardQueueItem.selector parameters:forwardQueueItem.queueParameters messageType:forwardQueueItem.messageType kitHandler:forwardQueueItem.completionHandler];
                break;
        }
    }
    
    _forwardQueue = nil;
}

- (void)saveKitConfiguration:(MPKitConfiguration *)kitConfiguration forKitCode:(NSNumber *)kitCode {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *stateMachineDirectoryPath = STATE_MACHINE_DIRECTORY_PATH;

    if (![fileManager fileExistsAtPath:stateMachineDirectoryPath]) {
        [fileManager createDirectoryAtPath:stateMachineDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString *kitPath = [stateMachineDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"EmbeddedKit%@.%@", kitCode, kitFileExtension]];
    
    if ([fileManager fileExistsAtPath:kitPath]) {
        [fileManager removeItemAtPath:kitPath error:nil];
    }
    
    [NSKeyedArchiver archiveRootObject:kitConfiguration toFile:kitPath];
}

- (void)startKitRegister:(nonnull id<MPExtensionKitProtocol>)kitRegister configuration:(nonnull MPKitConfiguration *)kitConfiguration {
    BOOL disabled = [self isDisabledByBracketConfiguration:kitConfiguration.bracketConfiguration];
    NSDictionary *configuration = [self validateAndTransformToSafeConfiguration:kitConfiguration.configuration];

    if (disabled || !kitRegister || !configuration) {
        return;
    }

    // Instantiate and start kit
    id<MPKitProtocol> kitInstance = kitRegister.wrapperInstance;
    if (kitInstance) {
        if ([kitInstance respondsToSelector:@selector(setConfiguration:)]) {
            [kitInstance setConfiguration:kitConfiguration.configuration];
        }
    } else {
        kitRegister.wrapperInstance = [[NSClassFromString(kitRegister.className) alloc] initWithConfiguration:configuration startImmediately:kitRegister.startImmediately];
        kitInstance = kitRegister.wrapperInstance;
    }
    
    if (kitInstance) {
        if (![kitInstance started]) {
            if ([kitInstance respondsToSelector:@selector(setLaunchOptions:)]) {
                [kitInstance performSelector:@selector(setLaunchOptions:) withObject:[MPStateMachine sharedInstance].launchOptions];
            }
            
            if ([kitInstance respondsToSelector:@selector(start)]) {
                [kitInstance start];
            }
        }
        
        // Synchronizes user attributes
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSDictionary<NSString *, id> *userAttributes = userDefaults[kMPUserAttributeKey];
        [self syncUserAttributes:userAttributes withKitRegister:kitRegister];
        
        // Synchronizes user identities
        NSArray<NSDictionary<NSString *, id> *> *userIdentities = userDefaults[kMPUserIdentityArrayKey];
        [self syncUserIdentities:userIdentities withKitRegister:kitRegister];
    }
}

- (void)syncUserAttributes:(NSDictionary *)userAttributes withKitRegister:(id<MPExtensionKitProtocol>)kitRegister {
    id<MPKitProtocol> kitInstance = kitRegister.wrapperInstance;
    if (MPIsNull(userAttributes) || userAttributes.count == 0 || !kitInstance) {
        return;
    }
    
    __block MPKitFilter *kitFilter = nil;
    MPKitConfiguration *kitConfiguration = self.kitConfigurations[kitRegister.code];
    
    [self.dataTransformation filter:kitRegister
                   kitConfiguration:kitConfiguration
                  forUserAttributes:userAttributes
                  completionHandler:^(MPKitFilter * _Nonnull kitFilterTransformed, BOOL finished) {
                      kitFilter = kitFilterTransformed;
                  }];

    NSDictionary *filteredUserAttributes = nil;
    BOOL supportsUserAttributeLists = [kitInstance respondsToSelector:@selector(setUserAttribute:values:)];
    Class NSStringClass = [NSString class];
    Class NSNumberClass = [NSNumber class];
    Class NSArrayClass = [NSArray class];

    if (!kitFilter.shouldFilter) {
        filteredUserAttributes = userAttributes;
    } else if (kitFilter.shouldFilter && kitFilter.filteredAttributes.count > 0) {
        filteredUserAttributes = kitFilter.filteredAttributes;
    }

    BOOL kitInstanceRespondesToSetUserAttributeValue = [kitInstance respondsToSelector:@selector(setUserAttribute:value:)];
    BOOL kitInstanceRespondesToSetUserAttributeValues = [kitInstance respondsToSelector:@selector(setUserAttribute:values:)];
    
    [filteredUserAttributes enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
        id value = nil;
        
        if ([obj isKindOfClass:NSStringClass]) {
            value = obj;
        } else if ([obj isKindOfClass:NSArrayClass]) {
            if (supportsUserAttributeLists) {
                value = obj;
            } else {
                value = [obj componentsJoinedByString:@","];
            }
        } else if ([obj isKindOfClass:NSNumberClass]) {
            value = [obj stringValue];
        }
        
        if (value) {
            if (kitInstanceRespondesToSetUserAttributeValue && [value isKindOfClass:NSStringClass]) {
                [kitInstance setUserAttribute:key value:value];
            } else if (kitInstanceRespondesToSetUserAttributeValues && [value isKindOfClass:NSArrayClass]) {
                [kitInstance setUserAttribute:key values:value];
            }
        }
    }];
}

- (void)syncUserIdentities:(NSArray *)userIdentities withKitRegister:(id<MPExtensionKitProtocol>)kitRegister {
    id<MPKitProtocol> kitInstance = kitRegister.wrapperInstance;
    if (MPIsNull(userIdentities) || userIdentities.count == 0 || ![kitInstance respondsToSelector:@selector(setUserIdentity:identityType:)]) {
        return;
    }

    for (NSDictionary *userIdentity in userIdentities) {
        MPUserIdentity identityType = (MPUserIdentity)[userIdentity[kMPUserIdentityTypeKey] intValue];
        NSString *identityString = userIdentity[kMPUserIdentityIdKey];
        
        MPKitConfiguration *kitConfiguration = self.kitConfigurations[kitRegister.code];
        
        [self.dataTransformation filter:kitRegister
                       kitConfiguration:kitConfiguration
                     forUserIdentityKey:identityString
                           identityType:identityType
                      completionHandler:^(MPKitFilter * _Nonnull kitFilter, BOOL finished) {
                          if (!kitFilter.shouldFilter) {
                              [kitInstance setUserIdentity:identityString identityType:identityType];
                          }
                      }];
    }
}

- (NSDictionary *)validateAndTransformToSafeConfiguration:(NSDictionary *)configuration {
    if (configuration.count == 0) {
        return nil;
    }
    
    __block NSMutableDictionary *safeConfiguration = [[NSMutableDictionary alloc] initWithCapacity:configuration.count];
    __block BOOL configurationModified = NO;
    [configuration enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
        if ((NSNull *)obj != [NSNull null]) {
            safeConfiguration[key] = obj;
        } else {
            configurationModified = YES;
        }
    }];
    
    if (configurationModified) {
        return safeConfiguration.count > 0 ? (NSDictionary *)safeConfiguration : nil;
    } else {
        return configuration;
    }
}

- (void)updateBracketsWithConfiguration:(NSDictionary *)configuration kitCode:(NSNumber *)kitCode {
    NSAssert(kitCode != nil, @"Required parameter. It cannot be nil.");
    
    std::map<NSNumber *, std::shared_ptr<mParticle::Bracket>>::iterator bracketIterator;
    bracketIterator = brackets.find(kitCode);

    if (!configuration) {
        if (bracketIterator != brackets.end()) {
            brackets.erase(bracketIterator);
        }
        
        return;
    }
    
    long mpId = [[MPStateMachine sharedInstance].consumerInfo.mpId longValue];
    short low = (short)[configuration[@"lo"] integerValue];
    short high = (short)[configuration[@"hi"] integerValue];
    
    shared_ptr<mParticle::Bracket> bracket;
    if (bracketIterator != brackets.end()) {
        bracket = bracketIterator->second;
        bracket->mpId = mpId;
        bracket->low = low;
        bracket->high = high;
    } else {
        brackets[kitCode] = make_shared<mParticle::Bracket>(mpId, low, high);
    }
}

#pragma mark Public class methods
+ (BOOL)registerKit:(nonnull id<MPExtensionKitProtocol>)kitRegister {
    NSAssert(kitRegister != nil, @"Required parameter. It cannot be nil.");
    
    [kitsRegistry addObject:kitRegister];
    return YES;
}

+ (nullable NSSet<id<MPExtensionKitProtocol>> *)registeredKits {
    return kitsRegistry.count > 0 ? kitsRegistry : nil;
}

+ (MPKitContainer *)sharedInstance {
    static MPKitContainer *sharedInstance = nil;
    static dispatch_once_t kitContainerPredicate;
    
    dispatch_once(&kitContainerPredicate, ^{
        sharedInstance = [[MPKitContainer alloc] init];
    });
    
    return sharedInstance;
}

#pragma mark Public accessors
- (NSMutableDictionary<NSNumber *, MPKitConfiguration *> *)kitConfigurations {
    if (!_kitConfigurations) {
        _kitConfigurations = [[NSMutableDictionary alloc] initWithCapacity:DEFAULT_ALLOCATION_FOR_KITS];
    }
    
    return _kitConfigurations;
}

#pragma mark Public methods
- (nullable NSArray<id<MPExtensionKitProtocol>> *)activeKitsRegistry {
    if (kitsRegistry.count == 0) {
        return nil;
    }
    
    NSMutableArray <id<MPExtensionKitProtocol>> *activeKitsRegistry = [[NSMutableArray alloc] initWithCapacity:kitsRegistry.count];
    
    for (id<MPExtensionKitProtocol>kitRegister in kitsRegistry) {
        BOOL active = kitRegister.wrapperInstance ? [kitRegister.wrapperInstance started] : NO;
        std::shared_ptr<mParticle::Bracket> bracket = [self bracketForKit:kitRegister.code];
        
        if (active && (bracket == nullptr || (bracket != nullptr && bracket->shouldForward()))) {
            [activeKitsRegistry addObject:kitRegister];
        }
    }
    
    return activeKitsRegistry.count > 0 ? activeKitsRegistry : nil;
}

- (void)configureKits:(NSArray<NSDictionary *> *)kitConfigurations {
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    
    if (MPIsNull(kitConfigurations) || stateMachine.optOut) {
        for (id<MPExtensionKitProtocol>kitRegister in kitsRegistry) {
            [self freeKitRegister:kitRegister];
        }
        
        self.kitsInitialized = YES;
        
        return;
    }
    
    dispatch_semaphore_wait(kitsSemaphore, DISPATCH_TIME_FOREVER);
    
    NSArray<NSNumber *> *supportedKits = [self supportedKits];
    NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [self activeKitsRegistry];
    id<MPExtensionKitProtocol>kitRegister;

    // Adds all currently configured kits to a list
    vector<NSNumber *> deactivateKits;
    for (kitRegister in activeKitsRegistry) {
        deactivateKits.push_back(kitRegister.code);
    }
    
    // Configure kits according to server instructions
    for (NSDictionary *kitConfigurationDictionary in kitConfigurations) {
        NSNumber *kitCode = kitConfigurationDictionary[@"id"];
        BOOL isKitSupported = [supportedKits containsObject:kitCode];

        if (isKitSupported) {
            MPKitConfiguration *kitConfiguration = [[MPKitConfiguration alloc] initWithDictionary:kitConfigurationDictionary];
            [self updateBracketsWithConfiguration:kitConfiguration.bracketConfiguration kitCode:kitCode];
            [self saveKitConfiguration:kitConfiguration forKitCode:kitCode];
        } else {
            MPILogWarning(@"SDK is trying to configure a kit (code = %@). However, it is not currently registered with the core SDK.", kitCode);
        }
        
        if (!deactivateKits.empty()) {
            for (size_t i = 0; i < deactivateKits.size(); ++i) {
                if ([deactivateKits.at(i) isEqualToNumber:kitCode]) {
                    deactivateKits.erase(deactivateKits.begin() + i);
                    break;
                }
            }
        }
    }
    
    // Remove currently configured kits that were not in the instructions from the server
    if (!deactivateKits.empty()) {
        for (vector<NSNumber *>::iterator ekIterator = deactivateKits.begin(); ekIterator != deactivateKits.end(); ++ekIterator) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"code == %@", *ekIterator];
            kitRegister = [[kitsRegistry filteredSetUsingPredicate:predicate] anyObject];
            [self freeKitRegister:kitRegister];
        }
    }
    
    [self initializeKits];

    dispatch_semaphore_signal(kitsSemaphore);
}

- (NSArray<NSString *> *)fetchKitConfigurationFileNames {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *stateMachineDirectoryPath = STATE_MACHINE_DIRECTORY_PATH;
    NSArray<NSString *> *directoryContents = nil;
    
    if ([fileManager fileExistsAtPath:stateMachineDirectoryPath]) {
        directoryContents = [fileManager contentsOfDirectoryAtPath:stateMachineDirectoryPath error:nil];
        NSString *predicateFormat = [NSString stringWithFormat:@"pathExtension == '%@'", kitFileExtension];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateFormat];
        directoryContents = [directoryContents filteredArrayUsingPredicate:predicate];
        
        if (directoryContents.count == 0) {
            directoryContents = nil;
        }
    }
    
    return directoryContents;
}

- (void)removeKitConfigurationAtPath:(nonnull NSString *)kitPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:kitPath]) {
        [fileManager removeItemAtPath:kitPath error:nil];
        [[NSUserDefaults standardUserDefaults] removeMPObjectForKey:kMPHTTPETagHeaderKey];
    }
}

- (nullable NSArray<NSNumber *> *)supportedKits {
    if (kitsRegistry.count == 0) {
        return nil;
    }
    
    NSMutableArray<NSNumber *> *supportedKits = [[NSMutableArray alloc] initWithCapacity:kitsRegistry.count];
    for (id<MPExtensionKitProtocol>kitRegister in kitsRegistry) {
        [supportedKits addObject:kitRegister.code];
    }
    
    return supportedKits;
}

#pragma mark Forward methods
- (void)forwardSDKCall:(SEL)selector event:(MPEventAbstract *)event messageType:(MPMessageType)messageType userInfo:(NSDictionary *)userInfo kitHandler:(void (^)(id<MPKitProtocol> kit, MPForwardQueueParameters * _Nullable forwardParameters, MPKitFilter * _Nullable forwardKitFilter, MPKitExecStatus **execStatus))kitHandler {
    if (!self.kitsInitialized && messageType != MPMessageTypeOptOut && messageType != MPMessageTypePushRegistration) {
        MPForwardQueueParameters *parameters = [[MPForwardQueueParameters alloc] init];
        [parameters addParameter:event];
        
        MPForwardQueueItem *forwardQueueItem = [[MPForwardQueueItem alloc] initWithSelector:selector parameters:parameters messageType:messageType completionHandler:kitHandler];
        
        if (forwardQueueItem) {
            forwardQueueItem.queueItemType = MPQueueItemTypeAppEvent;
            [self.forwardQueue addObject:forwardQueueItem];
        }
        
        return;
    }
    
    NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [self activeKitsRegistry];
    NSNumber *appsFlyerCode = @(MPKitInstanceAppsFlyer);
    __block NSNumber *previousKit = nil;
    SEL logEventSelector = @selector(logEvent:);
    
    for (id<MPExtensionKitProtocol>kitRegister in activeKitsRegistry) {
        previousKit = nil;
        
        if ([kitRegister.wrapperInstance respondsToSelector:selector] || (messageType == MPMessageTypeCommerceEvent && [kitRegister.wrapperInstance respondsToSelector:logEventSelector])) {
            MPKitConfiguration *kitConfiguration = self.kitConfigurations[kitRegister.code];
            
            MPEventAbstract *surrogateEvent = nil;
            if (event) {
                surrogateEvent = [kitRegister.code isEqualToNumber:appsFlyerCode] ? [self applyAppsFlyerAugmentationsToEvent:event] : event;
            }
            
            [self.dataTransformation filter:kitRegister
                           kitConfiguration:kitConfiguration
                                   forEvent:surrogateEvent
                                   selector:selector
                          completionHandler:^(MPKitFilter *kitFilter, BOOL finished) {
                              if (kitFilter.shouldFilter && !kitFilter.filteredAttributes) {
                                  return;
                              }
                              
                              MPKitExecStatus *execStatus = nil;
                              kitHandler(kitRegister.wrapperInstance, nil, kitFilter, &execStatus);
                              
                              if (kitFilter.forwardEvent || kitFilter.forwardCommerceEvent) {
                                  if (execStatus.success && ![previousKit isEqualToNumber:kitRegister.code] && messageType != MPMessageTypeUnknown) {
                                      previousKit = kitRegister.code;
                                      MPForwardRecord *forwardRecord = nil;
                                      
                                      if (messageType == MPMessageTypeOptOut || messageType == MPMessageTypePushRegistration) {
                                          forwardRecord = [[MPForwardRecord alloc] initWithMessageType:messageType
                                                                                            execStatus:execStatus
                                                                                             stateFlag:[userInfo[@"state"] boolValue]];
                                      } else {
                                          forwardRecord = [[MPForwardRecord alloc] initWithMessageType:messageType
                                                                                            execStatus:execStatus
                                                                                             kitFilter:kitFilter
                                                                                         originalEvent:event];
                                      }
                                      
                                      [[MPPersistenceController sharedInstance] saveForwardRecord:forwardRecord];
                                      
                                      MPILogDebug(@"Forwarded %@ call to kit: %@", NSStringFromSelector(selector), kitRegister.name);
                                  }
                              }
                          }];
        }
    }
}

- (void)forwardSDKCall:(SEL)selector userAttributeKey:(NSString *)key value:(id)value kitHandler:(void (^)(id<MPKitProtocol> kit))kitHandler {
    NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [self activeKitsRegistry];
    
    SEL setUserAttributeSelector = @selector(setUserAttribute:value:);
    SEL setUserAttributeListSelector = @selector(setUserAttribute:values:);
    SEL alternativeUserAttributeSelector = selector == setUserAttributeListSelector ? setUserAttributeSelector : setUserAttributeListSelector;
    
    for (id<MPExtensionKitProtocol>kitRegister in activeKitsRegistry) {
        if ([kitRegister.wrapperInstance respondsToSelector:selector] || [kitRegister.wrapperInstance respondsToSelector:alternativeUserAttributeSelector]) {
            MPKitConfiguration *kitConfiguration = self.kitConfigurations[kitRegister.code];
            
            [self.dataTransformation filter:kitRegister
                           kitConfiguration:kitConfiguration
                        forUserAttributeKey:key
                                      value:value
                          completionHandler:^(MPKitFilter * _Nonnull kitFilter, BOOL finished) {
                              if (!kitFilter.shouldFilter) {
                                  kitHandler(kitRegister.wrapperInstance);
                                  
                                  MPILogDebug(@"Forwarded user attribute key: %@ value: %@ to kit: %@", key, value, kitRegister.name);
                              }
                          }];
        }
    }
}

- (void)forwardSDKCall:(SEL)selector userAttributes:(NSDictionary *)userAttributes kitHandler:(void (^)(id<MPKitProtocol> kit, NSDictionary *forwardAttributes))kitHandler {
    NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [self activeKitsRegistry];
    
    for (id<MPExtensionKitProtocol>kitRegister in activeKitsRegistry) {
        if ([kitRegister.wrapperInstance respondsToSelector:selector]) {
            MPKitConfiguration *kitConfiguration = self.kitConfigurations[kitRegister.code];
            
            [self.dataTransformation filter:kitRegister
                           kitConfiguration:kitConfiguration
                          forUserAttributes:userAttributes
                          completionHandler:^(MPKitFilter * _Nonnull kitFilter, BOOL finished) {
                              kitHandler(kitRegister.wrapperInstance, kitFilter.filteredAttributes);
                              
                              MPILogDebug(@"Forwarded user attributes to kit: %@", kitRegister.name);
                          }];
        }
    }
}

- (void)forwardSDKCall:(SEL)selector userIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType kitHandler:(void (^)(id<MPKitProtocol> kit))kitHandler {
    NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [self activeKitsRegistry];
    
    for (id<MPExtensionKitProtocol>kitRegister in activeKitsRegistry) {
        if ([kitRegister.wrapperInstance respondsToSelector:selector]) {
            MPKitConfiguration *kitConfiguration = self.kitConfigurations[kitRegister.code];

            [self.dataTransformation filter:kitRegister
                           kitConfiguration:kitConfiguration
                         forUserIdentityKey:identityString
                               identityType:identityType
                          completionHandler:^(MPKitFilter * _Nonnull kitFilter, BOOL finished) {
                              if (!kitFilter.shouldFilter) {
                                  kitHandler(kitRegister.wrapperInstance);
                                  
                                  MPILogDebug(@"Forwarded setting user identity: %@ to kit: %@", identityString, kitRegister.name);
                              }
                          }];
        }
    }
}

- (void)forwardSDKCall:(SEL)selector errorMessage:(NSString *)errorMessage exception:(NSException *)exception eventInfo:(NSDictionary *)eventInfo kitHandler:(void (^)(id<MPKitProtocol> kit, MPKitExecStatus **execStatus))kitHandler {
    NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [self activeKitsRegistry];
    
    for (id<MPExtensionKitProtocol>kitRegister in activeKitsRegistry) {
        if ([kitRegister.wrapperInstance respondsToSelector:selector]) {
            MPKitFilter *kitFilter = [[MPKitFilter alloc] initWithFilter:NO filteredAttributes:nil];
            
            if (!kitFilter.shouldFilter) {
                MPKitExecStatus *execStatus = nil;
                
                kitHandler(kitRegister.wrapperInstance, &execStatus);
                
                MPILogDebug(@"Forwarded %@ call to kit: %@", NSStringFromSelector(selector), kitRegister.name);
            }
        }
    }
}

- (void)forwardSDKCall:(SEL)selector parameters:(MPForwardQueueParameters *)parameters messageType:(MPMessageType)messageType kitHandler:(void (^)(id<MPKitProtocol> kit, MPForwardQueueParameters *forwardParameters, MPKitFilter * _Nullable kitFilter, MPKitExecStatus **execStatus))kitHandler {
    if (!self.kitsInitialized) {
        MPForwardQueueItem *forwardQueueItem = [[MPForwardQueueItem alloc] initWithSelector:selector parameters:parameters messageType:messageType completionHandler:kitHandler];
        
        if (forwardQueueItem) {
            [self.forwardQueue addObject:forwardQueueItem];
        }
        
        return;
    }
    
    NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [self activeKitsRegistry];
    
    for (id<MPExtensionKitProtocol>kitRegister in activeKitsRegistry) {
        __block NSNumber *lastKit = nil;
        
        if ([kitRegister.wrapperInstance respondsToSelector:selector]) {
            @try {
                MPKitExecStatus *execStatus = nil;
                NSNumber *currentKit = kitRegister.code;
                
                kitHandler(kitRegister.wrapperInstance, parameters, nil, &execStatus);
                
                if (execStatus.success && ![lastKit isEqualToNumber:currentKit]) {
                    lastKit = currentKit;
                    
                    if (messageType != MPMessageTypeUnknown) {
                        MPForwardRecord *forwardRecord = nil;
                        
                        if (messageType == MPMessageTypePushRegistration) {
                            BOOL stateFlag = NO;
                            
                            if (selector == @selector(failedToRegisterForUserNotifications:)) {
                                stateFlag = NO;
                            } else if (selector == @selector(setDeviceToken:)) {
                                stateFlag = parameters[0] != nil;
                            }
                            
                            forwardRecord = [[MPForwardRecord alloc] initWithMessageType:messageType execStatus:execStatus stateFlag:stateFlag];
                        } else {
                            forwardRecord = [[MPForwardRecord alloc] initWithMessageType:messageType execStatus:execStatus];
                        }
                        
                        if (forwardRecord) {
                            [[MPPersistenceController sharedInstance] saveForwardRecord:forwardRecord];
                        }
                    }
                    
                    MPILogDebug(@"Forwarded %@ call to kit: %@", NSStringFromSelector(selector), kitRegister.name);
                }
            } @catch (NSException *exception) {
                MPILogError(@"An exception happened forwarding %@ to kit: %@\n  reason: %@", NSStringFromSelector(selector), kitRegister.name, [exception reason]);
            }
        }
    }
}

@end
