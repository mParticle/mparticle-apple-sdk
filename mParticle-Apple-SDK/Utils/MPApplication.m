#import "MPApplication.h"
#import <mach-o/ldsyms.h>
#import <dlfcn.h>
#import <mach-o/arch.h>
#import <mach-o/dyld.h>
#import <UIKit/UIKit.h>
#import "MPStateMachine.h"
#import <libkern/OSAtomic.h>
#import "mParticle.h"
#import "mParticleSwift.h"
#import "MPIConstants.h"

NSString *const kMPApplicationInformationKey = @"ai";
NSString *const kMPApplicationNameKey = @"an";
NSString *const kMPApplicationVersionKey = @"av";
NSString *const kMPAppPackageNameKey = @"apn";
NSString *const kMPAppInitialLaunchTimeKey = @"ict";
NSString *const kMPAppBuildNumberKey = @"abn";
NSString *const kMPAppBuildUUIDKey = @"bid";
NSString *const kMPAppArchitectureKey = @"arc";
NSString *const kMPAppPiratedKey = @"pir";
NSString *const kMPAppDeploymentTargetKey = @"tsv";
NSString *const kMPAppBuildSDKKey = @"bsv";
NSString *const kMPAppUpgradeDateKey = @"ud";
NSString *const kMPAppLaunchCountKey = @"lc";
NSString *const kMPAppLaunchCountSinceUpgradeKey = @"lcu";
NSString *const kMPAppLastUseDateKey = @"lud";
NSString *const kMPAppStoredVersionKey = @"asv";
NSString *const kMPAppStoredBuildKey = @"asb";
NSString *const kMPAppEnvironmentKey = @"env";
NSString *const kMPAppStoreReceiptKey = @"asr";
NSString *const kMPAppImageBaseAddressKey = @"iba";
NSString *const kMPAppImageSizeKey = @"is";
NSString *const kMPAppSideloadKitsCountKey = @"sideloaded_kits_count";

static NSString *kMPAppStoreReceiptString = nil;
static id mockUIApplication = nil;

typedef struct Binaryimage {
    struct Binaryimage *previous;
    struct Binaryimage *next;
    uintptr_t header;
    char *name;
} BinaryImage;

typedef struct BinaryImageList {
    BinaryImage *headBinaryImage;
    BinaryImage *tailBinaryImage;
    BinaryImage *free;
    int32_t referenceCount;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    OSSpinLock write_lock;
#pragma clang diagnostic pop
} BinaryImageList;

//
// C functions prototype declarations
//
static BinaryImageList sharedImageList = { 0 }; // Shared dyld image list
static void appendImageList(BinaryImageList *list, uintptr_t header, const char *name);
static void flagReadingImageList(BinaryImageList *list, bool enable);
static BinaryImage *nextImageList(BinaryImageList *list, BinaryImage *current);
static void addImageListCallback(const struct mach_header *mh, intptr_t vmaddr_slide);
static void processBinaryImage(const char *name, const void *header, struct uuid_command *out_uuid, uintptr_t *out_baseaddr, uintptr_t *out_cmdsize);

@interface MParticle ()

@property (nonatomic, strong, readonly) MPStateMachine_PRIVATE *stateMachine;
@property (nonatomic, strong, nonnull) MPBackendController_PRIVATE *backendController;

@end

@interface MPApplication_PRIVATE() {
    NSDictionary *appInfo;
    MPUserDefaults *userDefaults;
}

@end


@implementation MPApplication_PRIVATE

@synthesize architecture = _architecture;
@synthesize buildUUID = _buildUUID;
@synthesize environment = _environment;
@synthesize initialLaunchTime = _initialLaunchTime;
@synthesize pirated = _pirated;

+ (void)initialize {
    if (self == [MPApplication_PRIVATE class]) {
        _dyld_register_func_for_add_image(addImageListCallback);
    }
}

- (id)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];

    
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@", [self dictionaryRepresentation]];
}

#pragma mark Accessors
- (NSString *)architecture {
    if (_architecture) {
        return _architecture;
    }
    
    const struct mach_header *header = _dyld_get_image_header(0);
    const NXArchInfo *info = NXGetArchInfoFromCpuType(header->cputype, header->cpusubtype);
    
    _architecture = [[NSString alloc] initWithUTF8String:info->name];
    
    return _architecture;
}

- (NSString *)build {
    NSDictionary *bundleInfoDictionary = [[NSBundle mainBundle] infoDictionary];
    return bundleInfoDictionary[@"CFBundleVersion"];
}

- (NSString *)buildUUID {
#if !TARGET_OS_SIMULATOR
    if (_buildUUID) {
        return _buildUUID;
    }
    
    const struct mach_header *machHeader = NULL;
    uint32_t i;
    
    for (i = 0; i < _dyld_image_count(); ++i) {
        const struct mach_header *header = _dyld_get_image_header(i);
        
        if (header->filetype == MH_EXECUTE) {
            machHeader = header;
            break;
        }
    }
    
    if (machHeader == NULL) {
        return nil;
    }
    
    BOOL is64bit = machHeader->magic == MH_MAGIC_64 || machHeader->magic == MH_CIGAM_64;
    uintptr_t cursor = (uintptr_t)machHeader + (is64bit ? sizeof(struct mach_header_64) : sizeof(struct mach_header));
    const struct segment_command *segmentCommand = NULL;
    for (i = 0; i < machHeader->ncmds; ++i, cursor += segmentCommand->cmdsize) {
        segmentCommand = (struct segment_command *)cursor;
        
        if (segmentCommand->cmd == LC_UUID) {
            const struct uuid_command *uuidCommand = (const struct uuid_command *)segmentCommand;
            _buildUUID = [[[NSUUID alloc] initWithUUIDBytes:uuidCommand->uuid] UUIDString];
            break;
        }
    }
    
    return _buildUUID;
#else
    return @"00000000-0000-0000-0000-000000000000";
#endif
}

- (NSString *)bundleIdentifier {
    NSDictionary *bundleInfoDictionary = [[NSBundle mainBundle] infoDictionary];
    return bundleInfoDictionary[@"CFBundleIdentifier"];
}

- (MPEnvironment)environment {
    return [MPStateMachine_PRIVATE environment];
}

- (NSNumber *)firstSeenInstallation {
    return [MParticle sharedInstance].stateMachine.firstSeenInstallation;
}

- (NSNumber *)initialLaunchTime {
    if (_initialLaunchTime != nil) {
        return _initialLaunchTime;
    }
    
    _initialLaunchTime = userDefaults[kMPAppInitialLaunchTimeKey];
    
    if (_initialLaunchTime == nil) {
        _initialLaunchTime = MPCurrentEpochInMilliseconds;
        userDefaults[kMPAppInitialLaunchTimeKey] = _initialLaunchTime;
    }
    
    return _initialLaunchTime;
}

- (NSString *)name {
    NSDictionary *bundleInfoDictionary = [[NSBundle mainBundle] infoDictionary];
    return bundleInfoDictionary[@"CFBundleDisplayName"];
}

- (NSNumber *)lastUseDate {
    NSNumber *lastUseDate = userDefaults[kMPAppLastUseDateKey];
    if (lastUseDate == nil) {
        lastUseDate = MPMilliseconds([[MParticle sharedInstance].stateMachine.launchDate timeIntervalSince1970]);
    }
    
    return lastUseDate;
}

- (void)setLastUseDate:(NSNumber *)lastUseDate {
    userDefaults[kMPAppLastUseDateKey] = lastUseDate;
}

- (NSNumber *)launchCount {
    NSNumber *launchCount = userDefaults[kMPAppLaunchCountKey];
    return launchCount;
}

- (void)setLaunchCount:(NSNumber *)launchCount {
    userDefaults[kMPAppLaunchCountKey] = launchCount;
}

- (NSNumber *)launchCountSinceUpgrade {
    NSNumber *launchCount = userDefaults[kMPAppLaunchCountSinceUpgradeKey];
    return launchCount;
}

- (void)setLaunchCountSinceUpgrade:(NSNumber *)launchCountSinceUpgrade {
    userDefaults[kMPAppLaunchCountSinceUpgradeKey] = launchCountSinceUpgrade;
}

- (NSNumber *)pirated {
    _pirated = @(NO);
    return _pirated;
}

- (NSString *)storedBuild {
    NSString *storedBuild = userDefaults[kMPAppStoredBuildKey];
    return storedBuild;
}

- (void)setStoredBuild:(NSString *)storedBuild {
    if (storedBuild) {
        userDefaults[kMPAppStoredBuildKey] = storedBuild;
    } else {
        [userDefaults removeMPObjectForKey:kMPAppStoredBuildKey];
    }
}

- (NSString *)storedVersion {
    NSString *storedBuild = userDefaults[kMPAppStoredVersionKey];
    return storedBuild;
}

- (void)setStoredVersion:(NSString *)storedVersion {
    if (storedVersion) {
        userDefaults[kMPAppStoredVersionKey] = storedVersion;
    } else {
        [userDefaults removeMPObjectForKey:kMPAppStoredVersionKey];
    }
}

- (NSNumber *)upgradeDate {
    NSNumber *upgradeDate = userDefaults[kMPAppUpgradeDateKey];
    return upgradeDate;
}

- (void)setUpgradeDate:(NSNumber *)upgradeDate {
    userDefaults[kMPAppUpgradeDateKey] = upgradeDate;
}

- (NSString *)version {
    NSDictionary *bundleInfoDictionary = [[NSBundle mainBundle] infoDictionary];
    return bundleInfoDictionary[@"CFBundleShortVersionString"];
}

- (NSNumber *)sideloadedKitsCount {
    NSNumber *sideloadedKitsCount = @([[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] sideloadedKitsCount]);
    return sideloadedKitsCount;
}

+ (void)setMockApplication:(id)mockApplication {
    mockUIApplication = mockApplication;
}

+ (UIApplication *)sharedUIApplication {
    if (mockUIApplication) return mockUIApplication;
    if ([[UIApplication class] respondsToSelector:@selector(sharedApplication)]) {
        return [[UIApplication class] performSelector:@selector(sharedApplication)];
    }
    return nil;
}

- (NSDictionary *)searchAdsAttribution {
    return MParticle.sharedInstance.stateMachine.searchAdsInfo;
}

#pragma mark NSCopying
- (instancetype)copyWithZone:(NSZone *)zone {
    MPApplication_PRIVATE *copyObject = [[[self class] alloc] init];
    
    if (copyObject) {
        copyObject->_architecture = [_architecture copy];
        copyObject->_buildUUID = [_buildUUID copy];
        copyObject->_initialLaunchTime = [_initialLaunchTime copy];
        copyObject->_pirated = [_pirated copy];
    }
    
    return copyObject;
}

#pragma mark Class methods
+ (NSString *)appStoreReceipt {
    if (MPIsNull(kMPAppStoreReceiptString)) {
        NSURL *url = [[NSBundle mainBundle] appStoreReceiptURL];
        NSData *appStoreReceiptData = [NSData dataWithContentsOfURL:url];
        
        if (appStoreReceiptData) {
            kMPAppStoreReceiptString = [appStoreReceiptData base64EncodedStringWithOptions:0];
        }
    }
    
    return kMPAppStoreReceiptString;
}

+ (void)markInitialLaunchTime {
    MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
    NSNumber *initialLaunchTime = userDefaults[kMPAppInitialLaunchTimeKey];
    
    if (initialLaunchTime == nil) {
        initialLaunchTime = MPCurrentEpochInMilliseconds;
        userDefaults[kMPAppInitialLaunchTimeKey] = initialLaunchTime;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [userDefaults synchronize];
        });
    }
}

+ (void)updateLastUseDate:(NSDate *)date {
    MPApplication_PRIVATE *application = [[MPApplication_PRIVATE alloc] init];
    application.lastUseDate = MPMilliseconds([date timeIntervalSince1970]);
}

+ (void)updateLaunchCountsAndDates {
    MPApplication_PRIVATE *application = [[MPApplication_PRIVATE alloc] init];
    
    application.launchCount = @([application.launchCount integerValue] + 1);
    
    if (![application.version isEqualToString:application.storedVersion] || ![application.build isEqualToString:application.storedBuild]) {
        application.launchCountSinceUpgrade = @1;
        application.upgradeDate = MPCurrentEpochInMilliseconds;
    } else {
        application.launchCountSinceUpgrade = @([application.launchCountSinceUpgrade integerValue] + 1);
    }
}

+ (void)updateStoredVersionAndBuildNumbers {
    MPApplication_PRIVATE *application = [[MPApplication_PRIVATE alloc] init];
    application.storedVersion = application.version;
    application.storedBuild = application.build;
}

+ (NSDictionary *)appImageInfo {
    struct uuid_command uuid = {0};
    uintptr_t baseaddr = 0;
    uintptr_t cmdsize = 0;
    uintptr_t imageBaseAddress = 0;
    unsigned long long imageSize = 0;
    
    flagReadingImageList(&sharedImageList, true);
    
    BinaryImage *image = NULL;
    while ((image = nextImageList(&sharedImageList, image)) != NULL) {
        processBinaryImage(image->name, (const void *)(image->header), &uuid, &baseaddr, &cmdsize);
        
        if (imageBaseAddress == 0) {
            imageBaseAddress = baseaddr;
        }
        
        imageSize += cmdsize;
    }
    
    NSDictionary *appImageInfo = @{kMPAppImageBaseAddressKey:@(imageBaseAddress),
                                   kMPAppImageSizeKey:@(imageSize)};
    
    return appImageInfo;
}

#pragma mark Public methods
- (NSDictionary<NSString *, id> *)dictionaryRepresentation {
    if (appInfo) {
        NSMutableDictionary<NSString *, id> *mutableAppInfo = [appInfo mutableCopy];
        
        NSDictionary *auxDictionary = self.searchAdsAttribution;
        if (auxDictionary) {
            mutableAppInfo[kMPAppSearchAdsAttributionKey] = auxDictionary;
        }
        return [mutableAppInfo copy];
    }
    
    NSMutableDictionary<NSString *, id> *applicationInfo;
    NSString *auxString;
    
    applicationInfo = [@{kMPAppPiratedKey:self.pirated,
                         kMPAppInitialLaunchTimeKey:self.initialLaunchTime,
                         kMPAppDeploymentTargetKey:[NSString stringWithFormat:@"%i", __IPHONE_OS_VERSION_MIN_REQUIRED],
                         kMPAppBuildSDKKey:[NSString stringWithFormat:@"%i", __IPHONE_OS_VERSION_MAX_ALLOWED],
                         kMPAppEnvironmentKey:@(self.environment),
                         kMPAppFirstSeenInstallationKey:@(self.firstSeenInstallation.boolValue),
                         kMPAppSideloadKitsCountKey:self.sideloadedKitsCount
                         }
                       mutableCopy];
    
    NSDictionary *auxDictionary = self.searchAdsAttribution;
    if (auxDictionary) {
        applicationInfo[kMPAppSearchAdsAttributionKey] = auxDictionary;
    }
    
    auxString = self.bundleIdentifier;
    if (auxString) {
        applicationInfo[kMPAppPackageNameKey] = auxString;
    }
    
    auxString = self.buildUUID;
    if (auxString) {
        applicationInfo[kMPAppBuildUUIDKey] = auxString;
    }
    
    auxString = self.architecture;
    if (auxString) {
        applicationInfo[kMPAppArchitectureKey] = auxString;
    }
    
    auxString = self.name;
    if (auxString) {
        applicationInfo[kMPApplicationNameKey] = auxString;
    }
    
    NSNumber *auxNumber = self.upgradeDate;
    if (auxNumber != nil) {
        applicationInfo[kMPAppUpgradeDateKey] = auxNumber;
    }
    
    auxNumber = self.launchCount;
    if (auxNumber != nil) {
        applicationInfo[kMPAppLaunchCountKey] = auxNumber;
    }
    
    auxNumber = self.launchCountSinceUpgrade;
    if (auxNumber != nil) {
        applicationInfo[kMPAppLaunchCountSinceUpgradeKey] = auxNumber;
    }
    
    auxNumber = self.lastUseDate;
    if (auxNumber != nil) {
        applicationInfo[kMPAppLastUseDateKey] = auxNumber;
    }
    
    auxString = self.version;
    if (auxString) {
        applicationInfo[kMPApplicationVersionKey] = auxString;
    }
    
    auxString = self.build;
    if (auxString) {
        applicationInfo[kMPAppBuildNumberKey] = auxString;
    }
    
    if ([MParticle sharedInstance].stateMachine.allowASR && [MPApplication_PRIVATE appStoreReceipt]) {
        applicationInfo[kMPAppStoreReceiptKey] = [MPApplication_PRIVATE appStoreReceipt];
    }
    
    appInfo = (NSDictionary *)applicationInfo;
    
    return appInfo;
}

@end

/**
 @internal
 
 Maintains a linked list of binary images with support for async-safe iteration. Writing may occur concurrently with
 async-safe reading, but is not async-safe.
 
 Atomic compare and swap is used to ensure a consistent view of the list for readers. To simplify implementation, a
 write mutex is held for all updates; the implementation is not designed for efficiency in the face of contention
 between readers and writers, and it's assumed that no contention should realistically occur.
 */

/**
 Append a new binary image record to @a list.
 
 @param list The list to which the image record should be appended.
 @param header The image's header address.
 @param name The image's name.
 */
static void appendImageList(BinaryImageList *list, uintptr_t header, const char *name) {
    // Initialize the new entry.
    BinaryImage *new = calloc(1, sizeof(BinaryImage));
    if (!new) {
        return;
    }
    new->header = header;
    new->name = strdup(name);
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    // Update the image record and issue a memory barrier to ensure a consistent view.
    OSMemoryBarrier();
    
    /* Lock the list from other writers. */
    OSSpinLockLock(&list->write_lock); {
        /* If this is the first entry, initialize the list. */
        if (list->tailBinaryImage == NULL) {
            // Update the list tail. This need not be done atomically, as tail is never accessed by a lockless reader
            list->tailBinaryImage = new;
            
            // Atomically update the list head; this will be iterated upon by lockless readers
            if (!OSAtomicCompareAndSwapPtrBarrier(NULL, new, (void **) (&list->headBinaryImage))) {
                NSLog(@"An async image head was set with tail == NULL despite holding lock.");
            }
        } else {
            // Atomically slot the new record into place; this may be iterated on by a lockless reader
            if (!OSAtomicCompareAndSwapPtrBarrier(NULL, new, (void **) (&list->tailBinaryImage->next))) {
                NSLog(@"Failed to append to image list despite holding lock");
            }
            
            // Update the previous and tail pointers. This is never accessed without a lock, so no additional barrier is required here
            new->previous = list->tailBinaryImage;
            list->tailBinaryImage = new;
        }
    } OSSpinLockUnlock(&list->write_lock);
#pragma clang diagnostic pop
}

/**
 Retain or release the list for reading. This method is async-safe.
 
 This must be issued prior to attempting to iterate the list, and must called again once reads have completed.
 
 @param list The list to be be retained or released for reading.
 @param enable If true, the list will be retained. If false, released.
 */
static void flagReadingImageList(BinaryImageList *list, bool enable) {
    if (enable) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        // Increment and issue a barrier. Once issued, no items will be deallocated while a reference is held
        OSAtomicIncrement32Barrier(&list->referenceCount);
    } else {
        // Increment and issue a barrier. Once issued, items may again be deallocated
        OSAtomicDecrement32Barrier(&list->referenceCount);
    }
#pragma clang diagnostic pop
}

/**
 Returns the next image record. This method is async-safe. If no additional images are available, will return NULL.
 
 @param list The list to be iterated.
 @param current The current image record, or NULL to start iteration.
 */
static BinaryImage *nextImageList(BinaryImageList *list, BinaryImage *current) {
    if (current != NULL)
        return current->next;
    
    return list->headBinaryImage;
}

static void addImageListCallback(const struct mach_header *mh, intptr_t vmaddr_slide) {
    Dl_info info;
    
    // Look up the image info
    if (dladdr(mh, &info) == 0) {
        NSLog(@"%s: dladdr(%p, ...) failed", __FUNCTION__, mh);
        return;
    }
    
    appendImageList(&sharedImageList, (uintptr_t) mh, info.dli_fname);
}

static void processBinaryImage(const char *name, const void *header, struct uuid_command *out_uuid, uintptr_t *out_baseaddr, uintptr_t *out_cmdsize) {
    uint32_t ncmds;
    const struct mach_header *header32 = (const struct mach_header *)header;
    const struct mach_header_64 *header64 = (const struct mach_header_64 *)header;
    
    struct load_command *cmd;
    uintptr_t cmd_size;
    
    // Check for headers and extract required values
    switch (header32->magic) {
        // 32-bit
        case MH_MAGIC:
        case MH_CIGAM:
            ncmds = header32->ncmds;
            cmd = (struct load_command *)(header32 + 1);
            cmd_size = header32->sizeofcmds;
            break;
            
        // 64-bit
        case MH_MAGIC_64:
        case MH_CIGAM_64:
            ncmds = header64->ncmds;
            cmd = (struct load_command *)(header64 + 1);
            cmd_size = header64->sizeofcmds;
            break;
            
        default:
            NSLog(@"Invalid Mach-O header magic value: %x", header32->magic);
            return;
    }
    
    // Compute the image size and search for a UUID
    struct uuid_command *uuid = NULL;
    for (uint32_t i = 0; cmd != NULL && i < ncmds; ++i) {
        // DWARF dSYM UUID
        if (cmd->cmd == LC_UUID && cmd->cmdsize == sizeof(struct uuid_command)) {
            uuid = (struct uuid_command *)cmd;
        }
        
        cmd = (struct load_command *)((uint8_t *) cmd + cmd->cmdsize);
    }
    
    uintptr_t base_addr = (uintptr_t)header;
    *out_baseaddr = base_addr;
    *out_cmdsize = cmd_size;
    
    if (out_uuid && uuid) {
        memcpy(out_uuid, uuid, sizeof(struct uuid_command));
    }
}
