#import "MPPersistenceController.h"
#import "MPMessage.h"
#import "MPSession.h"
#import <dispatch/dispatch.h>
#import "MPDatabaseMigrationController.h"
#import "MPBreadcrumb.h"
#import "MPStateMachine.h"
#import "MPUpload.h"
#import "MPILogger.h"
#import "MPConsumerInfo.h"
#import "MPForwardRecord.h"
#import "MPIntegrationAttributes.h"
#import "MPPersistenceController.h"
#import "mParticle.h"
#import "MPIConstants.h"
#import "MPConsentSerialization.h"
#import <sqlite3.h>
#import "MPListenerProtocol.h"
#import "MPKitFilter.h"
#import "MPApplication.h"
#import "MParticleSwift.h"
#import "MParticleUserNotification.h"
#import <string>
#import <vector>

using namespace std;

// Prototype declaration of the C functions
#ifdef __cplusplus
extern "C" {
#endif
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-function"
    static NSData * _Nullable dataValue(sqlite3_stmt * _Nonnull const preparedStatement, const int column);
    static bool bindDictionaryAsBlob(sqlite3_stmt * _Nonnull const preparedStatement, const int column, NSDictionary * _Nullable dict);
    static NSDictionary * _Nullable dictionaryRepresentation(sqlite3_stmt * _Nonnull const preparedStatement, const int column);
    static double doubleValue(sqlite3_stmt * _Nonnull const preparedStatement, const int column);
    static int intValue(sqlite3_stmt * _Nonnull const preparedStatement, const int column);
    static int64_t int64Value(sqlite3_stmt * _Nonnull const preparedStatement, const int column);
    static NSString * _Nullable stringValue(sqlite3_stmt * _Nonnull const preparedStatement, const int column);
#pragma clang diagnostic pop
    
#ifdef __cplusplus
}
#endif


typedef NS_ENUM(NSInteger, MPDatabaseState) {
    MPDatabaseStateCorrupted = 0,
    MPDatabaseStateOK
};

static const NSArray *databaseVersions;

const int MaxBreadcrumbs = 50;

@interface MParticle ()

@property (nonatomic, strong, readonly) MPPersistenceController_PRIVATE *persistenceController;
@property (nonatomic, strong, readonly) MPStateMachine_PRIVATE *stateMachine;
@property (nonatomic, strong, nonnull) MPBackendController_PRIVATE *backendController;

@end

@interface MPForwardRecord ()
- (nonnull instancetype)initWithMessageType:(MPMessageType)messageType execStatus:(nonnull MPKitExecStatus *)execStatus stateFlag:(BOOL)stateFlag;
- (nonnull instancetype)initWithMessageType:(MPMessageType)messageType execStatus:(nonnull MPKitExecStatus *)execStatus kitFilter:(nullable MPKitFilter *)kitFilter originalEvent:(nullable MPBaseEvent *)originalEvent;
- (nullable NSData *)dataRepresentation;
- (nonnull instancetype)initWithMessageType:(MPMessageType)messageType execStatus:(nonnull MPKitExecStatus *)execStatus;
- (nonnull instancetype)initWithId:(int64_t)forwardRecordId data:(nonnull NSData *)data mpid:(nonnull NSNumber *)mpid;
@end

@interface MPPersistenceController_PRIVATE() {
    BOOL databaseOpen;
    sqlite3 *mParticleDB;
}

@property (nonatomic, strong) NSString *databasePath;

@end

@implementation MPPersistenceController_PRIVATE

@synthesize databasePath = _databasePath;

+ (void)initialize {
    if (self == [MPPersistenceController_PRIVATE class]) {
        databaseVersions = @[@3, @4, @5, @6, @7, @8, @9, @10, @11, @12, @13, @14, @15, @16, @17, @18, @19, @20, @21, @22, @23, @24, @25, @26, @27, @28, @29, @30, @31];
    }
}

- (instancetype)init {
    self = [super init];
    if (self) {
        databaseOpen = NO;
        
        [self setupDatabase];
        [self migrateDatabaseIfNeeded];
        [self openDatabase];
    }
    
    return self;
}

#pragma mark Database version migration methods
- (void)migrateDatabaseIfNeeded {
    MPDatabaseMigrationController *migrationController = [[MPDatabaseMigrationController alloc] initWithDatabaseVersions:[databaseVersions copy]];
    
    NSNumber *migrateVersion = [migrationController needsMigration];
    if (migrateVersion != nil) {
        BOOL isDatabaseOpen = databaseOpen;
        [self closeDatabase];
        
        [migrationController migrateDatabaseFromVersion:migrateVersion];
        
        if (isDatabaseOpen) {
            [self openDatabase];
        }
    }
}

+ (NSNumber *)mpId {
    MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
    NSNumber *mpId = userDefaults[@"mpid"];
    if (mpId == nil) {
        mpId = @0;
    }
    
    return mpId;
}

+ (void)setMpid:(NSNumber *)mpId {
    MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
    userDefaults[@"mpid"] = mpId;
    [userDefaults synchronize];
}

+ (nullable MPConsentState *)consentStateForMpid:(nonnull NSNumber *)mpid {
    MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
    NSString *string = [userDefaults mpObjectForKey:kMPConsentStateKey userId:mpid];
    if (!string) {
        return nil;
    }
    
    MPConsentState *state = [MPConsentSerialization consentStateFromString:string];
    if (!state) {
        return nil;
    }
    
    return state;
}

+ (void)setConsentState:(nullable MPConsentState *)state forMpid:(nonnull NSNumber *)mpid {
    MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
    if (!state) {
        [userDefaults removeMPObjectForKey:kMPConsentStateKey userId:mpid];
        [userDefaults synchronize];
        return;
    }
    
    NSString *string = [MPConsentSerialization stringFromConsentState:state];
    if (!string) {
        return;
    }
    [userDefaults setMPObject:string forKey:kMPConsentStateKey userId:mpid];
    [userDefaults synchronize];
}

+ (NSInteger)maxBytesPerEvent:(NSString *)messageType {
    return [messageType isEqualToString:kMPMessageTypeStringCrashReport] ? MAX_BYTES_PER_EVENT_CRASH : MAX_BYTES_PER_EVENT;
}

+ (NSInteger)maxBytesPerBatch:(NSString *)messageType {
    return [messageType isEqualToString:kMPMessageTypeStringCrashReport] ? MAX_BYTES_PER_BATCH_CRASH : MAX_BYTES_PER_BATCH;
}

#pragma mark Accessors
- (NSString *)databasePath {
    if (_databasePath) {
        return _databasePath;
    }
    
    NSString *documentsDirectory;
#if TARGET_OS_IOS == 1
    documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
#elif TARGET_OS_TV == 1
    documentsDirectory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
#else
    documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
#endif
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:documentsDirectory]) {
        [fileManager createDirectoryAtPath:documentsDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSNumber *currentDatabaseVersion = [databaseVersions lastObject];
    NSString *databaseName = [NSString stringWithFormat:@"mParticle%@.db", currentDatabaseVersion];
    _databasePath = [documentsDirectory stringByAppendingPathComponent:databaseName];
    
    return _databasePath;
}

#pragma mark Private methods
- (void)deleteCookie:(MPCookie *)cookie {
    sqlite3_stmt *preparedStatement;
    const string sqlStatement = "DELETE FROM cookies WHERE _id = ?";
    
    if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
        sqlite3_bind_int64(preparedStatement, 1, cookie.cookieId);
        
        if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
            MPILogError(@"Error while deleting cookie: %s", sqlite3_errmsg(mParticleDB));
        }
        
        sqlite3_clear_bindings(preparedStatement);
    }
    
    sqlite3_finalize(preparedStatement);
}

- (void)deleteCookies {
    sqlite3_stmt *preparedStatement;
    const string sqlStatement = "DELETE FROM cookies";
    
    if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
        if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
            MPILogError(@"Error while deleting cookies: %s", sqlite3_errmsg(mParticleDB));
        }
    }
    
    sqlite3_finalize(preparedStatement);
}

- (BOOL)isDatabaseOpen {
    return databaseOpen;
}

- (void)removeDatabase {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:self.databasePath]) {
        [fileManager removeItemAtPath:self.databasePath error:nil];
        mParticleDB = NULL;
        _databasePath = nil;
        databaseOpen = NO;
    }
}

- (void)resetDatabase {
    [self closeDatabase];
    [self removeDatabase];
}

- (void)resetDatabaseForWorkspaceSwitching {
    [self openDatabase];
    
    // Delete all records except uploads
    vector<string> sqlStatements = {
        "DELETE FROM sessions",
        "DELETE FROM previous_session",
        "DELETE FROM messages",
        "DELETE FROM breadcrumbs",
        "DELETE FROM consumer_info",
        "DELETE FROM cookies",
        "DELETE FROM product_bags",
        "DELETE FROM forwarding_records",
        "DELETE FROM integration_attributes"
    };
    
    int status;
    char *errMsg;
    for (const auto &sqlStatement : sqlStatements) {
        status = sqlite3_exec(mParticleDB, sqlStatement.c_str(), NULL, NULL, &errMsg);
        
        if (status != SQLITE_OK) {
            MPILogError("Problem clearing table for workspace switching: %s\n", sqlStatement.c_str());
        }
    }
    
    [self closeDatabase];
}

- (void)saveCookie:(MPCookie *)cookie forConsumerInfo:(MPConsumerInfo *)consumerInfo {
    sqlite3_stmt *preparedStatement;
    
    vector<string> fields;
    vector<string> params;
    
    if (cookie.content) {
        fields.push_back("content");
        params.push_back("'" + string([cookie.content UTF8String]) + "'");
    }
    
    if (cookie.domain) {
        fields.push_back("domain");
        params.push_back("'" + string([cookie.domain UTF8String]) + "'");
    }
    
    if (cookie.expiration) {
        fields.push_back("expiration");
        params.push_back("'" + string([cookie.expiration UTF8String]) + "'");
    }
    
    fields.push_back("name");
    params.push_back("'" + string([cookie.name cStringUsingEncoding:NSUTF8StringEncoding]) + "'");
    
    fields.push_back("mpid");
    params.push_back("'" + string([[NSString stringWithFormat:@"%@", [MPPersistenceController_PRIVATE mpId]] cStringUsingEncoding:NSUTF8StringEncoding]) + "'");
    
    string sqlStatement = "INSERT INTO cookies (consumer_info_id";
    for (auto field : fields) {
        sqlStatement += ", " + field;
    }
    
    sqlStatement += ") VALUES (?";
    
    for (auto param : params) {
        sqlStatement += ", " + param;
    }
    
    sqlStatement += ")";
    
    if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
        sqlite3_bind_int64(preparedStatement, 1, consumerInfo.consumerInfoId);
        
        if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
            MPILogError(@"Error while storing cookie: %s", sqlite3_errmsg(mParticleDB));
            sqlite3_clear_bindings(preparedStatement);
            sqlite3_finalize(preparedStatement);
            return;
        }
        
        cookie.cookieId = sqlite3_last_insert_rowid(mParticleDB);
        
        sqlite3_clear_bindings(preparedStatement);
    }
    
    sqlite3_finalize(preparedStatement);
}

- (void)setupDatabase {
    if (sqlite3_open_v2([self.databasePath UTF8String], &mParticleDB, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FILEPROTECTION_NONE | SQLITE_OPEN_FULLMUTEX, NULL) != SQLITE_OK) {
        return;
    }
    
    MPDatabaseState databaseState = [self verifyDatabaseState];
    if (databaseState == MPDatabaseStateCorrupted) {
        [self removeDatabase];
        
        sqlite3_open_v2([self.databasePath UTF8String], &mParticleDB, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FILEPROTECTION_NONE | SQLITE_OPEN_FULLMUTEX, NULL);
    }
    
    string sqlStatement = "PRAGMA user_version";
    sqlite3_stmt *preparedStatement;
    int userDatabaseVersion = 0;
    
    if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
        while (sqlite3_step(preparedStatement) != SQLITE_DONE) {
            userDatabaseVersion = sqlite3_column_int(preparedStatement, 0);
        }
    }
    
    sqlite3_finalize(preparedStatement);
    
    const int latestDatabaseVersion = [[databaseVersions lastObject] intValue];
    if (userDatabaseVersion == latestDatabaseVersion) {
        sqlite3_close(mParticleDB);
        mParticleDB = NULL;
        
        return;
    }
    
    vector<string> sqlStatements = {
        "CREATE TABLE IF NOT EXISTS sessions ( \
            _id INTEGER PRIMARY KEY AUTOINCREMENT, \
            uuid TEXT NOT NULL, \
            start_time REAL, \
            end_time REAL, \
            background_time REAL, \
            attributes_data BLOB NOT NULL, \
            session_number INTEGER NOT NULL, \
            number_interruptions INTEGER, \
            event_count INTEGER, \
            suspend_time REAL, \
            length REAL, \
            mpid INTEGER NOT NULL, \
            session_user_ids TEXT NOT NULL, \
            app_info BLOB, \
            device_info BLOB \
        )",
        "CREATE TABLE IF NOT EXISTS previous_session ( \
            session_id INTEGER, \
            uuid TEXT, \
            start_time REAL, \
            end_time REAL, \
            background_time REAL, \
            attributes_data BLOB, \
            session_number INTEGER, \
            number_interruptions INTEGER, \
            event_count INTEGER, \
            suspend_time REAL, \
            length REAL, \
            mpid INTEGER NOT NULL, \
            session_user_ids TEXT NOT NULL \
        )",
        "CREATE TABLE IF NOT EXISTS messages ( \
            _id INTEGER PRIMARY KEY AUTOINCREMENT, \
            session_id INTEGER, \
            message_type TEXT NOT NULL, \
            uuid TEXT NOT NULL, \
            timestamp REAL NOT NULL, \
            message_data BLOB NOT NULL, \
            upload_status INTEGER, \
            data_plan_id TEXT, \
            data_plan_version INTEGER, \
            mpid INTEGER NOT NULL \
        )",
        "CREATE TABLE IF NOT EXISTS uploads ( \
            _id INTEGER PRIMARY KEY AUTOINCREMENT, \
            session_id INTEGER, \
            uuid TEXT NOT NULL, \
            message_data BLOB NOT NULL, \
            timestamp REAL NOT NULL, \
            upload_type INTEGER NOT NULL, \
            data_plan_id TEXT, \
            data_plan_version INTEGER, \
            upload_settings BLOB NOT NULL \
        )",
        "CREATE TABLE IF NOT EXISTS breadcrumbs ( \
            _id INTEGER PRIMARY KEY AUTOINCREMENT, \
            session_uuid TEXT NOT NULL, \
            uuid TEXT NOT NULL, \
            timestamp REAL NOT NULL, \
            breadcrumb_data BLOB NOT NULL, \
            session_number INTEGER NOT NULL, \
            mpid INTEGER NOT NULL \
        )",
        "CREATE TABLE IF NOT EXISTS consumer_info ( \
            _id INTEGER PRIMARY KEY AUTOINCREMENT, \
            mpid INTEGER, \
            unique_identifier TEXT \
        )",
        "CREATE TABLE IF NOT EXISTS cookies ( \
            _id INTEGER PRIMARY KEY AUTOINCREMENT, \
            consumer_info_id INTEGER NOT NULL, \
            content TEXT, \
            domain TEXT, \
            expiration TEXT, \
            name TEXT, \
            mpid INTEGER NOT NULL \
        )",
        "CREATE TABLE IF NOT EXISTS product_bags ( \
            _id INTEGER PRIMARY KEY AUTOINCREMENT, \
            name TEXT, \
            timestamp REAL NOT NULL, \
            product_data BLOB NOT NULL \
        )",
        "CREATE TABLE IF NOT EXISTS forwarding_records ( \
            _id INTEGER PRIMARY KEY AUTOINCREMENT, \
            forwarding_data BLOB NOT NULL, \
            mpid INTEGER NOT NULL \
        )",
        "CREATE TABLE IF NOT EXISTS integration_attributes ( \
            _id INTEGER PRIMARY KEY AUTOINCREMENT, \
            kit_code INTEGER NOT NULL, \
            attributes_data BLOB NOT NULL \
        )"
    };
    
    int tableCreationStatus;
    char *errMsg;
    for (const auto &sqlStatement : sqlStatements) {
        tableCreationStatus = sqlite3_exec(mParticleDB, sqlStatement.c_str(), NULL, NULL, &errMsg);
        
        if (tableCreationStatus != SQLITE_OK) {
            MPILogError("Problem creating table: %s\n", sqlStatement.c_str());
        }
    }
    
    sqlStatement = "PRAGMA user_version = " + to_string(latestDatabaseVersion);
    sqlite3_exec(mParticleDB, sqlStatement.c_str(), NULL, NULL, NULL);
    sqlite3_close(mParticleDB);
    mParticleDB = NULL;
}

- (void)updateCookie:(MPCookie *)cookie {
    if (!cookie.content && !cookie.domain && !cookie.expiration) {
        return;
    }
    
    sqlite3_stmt *preparedStatement;
    string sqlStatement = "UPDATE cookies SET ";
    
    if (cookie.content) {
        sqlStatement += "content = '" + string([cookie.content UTF8String]) + "'";
    }
    
    if (cookie.domain) {
        sqlStatement += ", domain = '" + string([cookie.domain UTF8String]) + "'";
    }
    
    if (cookie.expiration) {
        sqlStatement += ", expiration = '" + string([cookie.expiration UTF8String]) + "'";
    }
    
    sqlStatement += " WHERE _id = ?";
    
    if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
        sqlite3_bind_int64(preparedStatement, 1, cookie.cookieId);
        
        if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
            MPILogError(@"Error while updating cookie: %s", sqlite3_errmsg(mParticleDB));
        }
        
        sqlite3_clear_bindings(preparedStatement);
    }
    
    sqlite3_finalize(preparedStatement);
}

- (MPDatabaseState)verifyDatabaseState {
    MPDatabaseState databaseState = MPDatabaseStateCorrupted;
    
    @try {
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "PRAGMA integrity_check;";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            int integrityResult = sqlite3_step(preparedStatement);
            
            if (integrityResult == SQLITE_ROW) {
                string integrityString = string((const char *)sqlite3_column_text(preparedStatement, 0));
                databaseState = integrityString == "ok" ? MPDatabaseStateOK : MPDatabaseStateCorrupted;
            }
            
            if (databaseState == MPDatabaseStateCorrupted) {
                MPILogError(@"Database is corrupted.");
            }
            
            sqlite3_finalize(preparedStatement);
        }
    } @catch (NSException *exception) {
        MPILogError(@"Verifying database state - exception %@.", [exception reason]);
        return MPDatabaseStateCorrupted;
    }
    
    return databaseState;
}

#pragma mark Class methods

#pragma mark Public methods

- (nullable MPSession *)archiveSession:(nonnull MPSession *)session {
    MPSession *previousSession = [self fetchPreviousSession];
    if (previousSession) {
        if (session.sessionId == previousSession.sessionId && [session.uuid isEqualToString:previousSession.uuid]) {
            return nil;
        } else {
            [self deletePreviousSession];
        }
    }
    
    sqlite3_stmt *preparedStatement;
    const string sqlStatement = "INSERT INTO previous_session (session_id, uuid, start_time, end_time, background_time, attributes_data, session_number, number_interruptions, event_count, suspend_time, length, mpid, session_user_ids) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
    
    if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
        sqlite3_bind_int64(preparedStatement, 1, session.sessionId);
        
        string uuid = string([session.uuid UTF8String]);
        sqlite3_bind_text(preparedStatement, 2, uuid.c_str(), (int)uuid.size(), SQLITE_STATIC);
        
        sqlite3_bind_double(preparedStatement, 3, session.startTime);
        sqlite3_bind_double(preparedStatement, 4, session.endTime);
        sqlite3_bind_double(preparedStatement, 5, session.backgroundTime);
        
        NSData *attributesData = [NSJSONSerialization dataWithJSONObject:session.attributesDictionary options:0 error:nil];
        sqlite3_bind_blob(preparedStatement, 6, [attributesData bytes], (int)[attributesData length], SQLITE_STATIC);
        
        sqlite3_bind_int64(preparedStatement, 7, 0); //session_number Deprecated
        sqlite3_bind_int(preparedStatement, 8, session.numberOfInterruptions);
        sqlite3_bind_int(preparedStatement, 9, session.eventCounter);
        sqlite3_bind_double(preparedStatement, 10, session.suspendTime);
        sqlite3_bind_double(preparedStatement, 11, session.length);
        sqlite3_bind_int64(preparedStatement, 12, session.userId.longLongValue);
        sqlite3_bind_text(preparedStatement, 13, [session.sessionUserIds UTF8String], (int)session.sessionUserIds.length, SQLITE_STATIC);
        
        if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
            MPILogError(@"Error while archiving previous session: %s", sqlite3_errmsg(mParticleDB));
        }
        
        sqlite3_clear_bindings(preparedStatement);
    }
    
    sqlite3_finalize(preparedStatement);
    
    return session;
}

- (BOOL)closeDatabase {
    if (!databaseOpen) {
        return YES;
    }
    
    int statusCode = sqlite3_close(mParticleDB);
    
    BOOL databaseClosed = statusCode == SQLITE_OK;
    if (databaseClosed) {
        mParticleDB = NULL;
        _databasePath = nil;
        databaseOpen = NO;
    } else {
        MPILogError(@"Error closing database: %d - %s", statusCode, sqlite3_errmsg(mParticleDB));
    }
    
    return databaseClosed;
}

- (void)deleteConsumerInfo {
    [self deleteCookies];
    
    sqlite3_stmt *preparedStatement;
    const string sqlStatement = "DELETE FROM consumer_info";
    
    if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
        if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
            MPILogError(@"Error while deleting consumer info: %s", sqlite3_errmsg(mParticleDB));
        }
    }
    
    sqlite3_finalize(preparedStatement);
}

- (void)deleteForwardRecordsIds:(nonnull NSArray<NSNumber *> *)forwardRecordsIds {
    if (MPIsNull(forwardRecordsIds) || forwardRecordsIds.count == 0) {
        return;
    }
    sqlite3_stmt *preparedStatement;
    NSString *idsString = [NSString stringWithFormat:@"%@", [forwardRecordsIds componentsJoinedByString:@","]];
    NSString *sqlString = [NSString stringWithFormat:@"DELETE FROM forwarding_records WHERE _id IN (%@)", idsString];
    const string sqlStatement = string([sqlString UTF8String]);
    
    if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
        if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
            MPILogError(@"Error while deleting forwarding records: %s", sqlite3_errmsg(mParticleDB));
        }
    }
    
    sqlite3_finalize(preparedStatement);
}

- (void)deleteAllIntegrationAttributes {
    sqlite3_stmt *preparedStatement;
    const string sqlStatement = "DELETE FROM integration_attributes";
    
    if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
        if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
            MPILogError(@"Error while deleting integration attributes: %s", sqlite3_errmsg(mParticleDB));
        }
    }
    
    sqlite3_finalize(preparedStatement);
}

- (void)deleteIntegrationAttributesForIntegrationId:(nonnull NSNumber *)integrationId {
    if (MPIsNull(integrationId)) {
        return;
    }
    
    sqlite3_stmt *preparedStatement;
    const string sqlStatement = "DELETE FROM integration_attributes WHERE kit_code = ?";
    
    if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
        sqlite3_bind_int(preparedStatement, 1, [integrationId intValue]);
        
        if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
            MPILogError(@"Error while deleting integration attributes: %s", sqlite3_errmsg(mParticleDB));
        }
    }
    
    sqlite3_finalize(preparedStatement);
}

- (void)deleteMessages:(nonnull NSArray<MPMessage *> *)messages {
    if (messages.count == 0) {
        return;
    }
    
    NSMutableArray *messageIds = [[NSMutableArray alloc] initWithCapacity:messages.count];
    for (MPMessage *message in messages) {
        [messageIds addObject:@(message.messageId)];
    }
    
    NSString *idsString = [NSString stringWithFormat:@"%@", [messageIds componentsJoinedByString:@","]];
    NSString *sqlString = [NSString stringWithFormat:@"DELETE FROM messages WHERE _id IN (%@)", idsString];
    sqlite3_stmt *preparedStatement;
    const string sqlStatement = string([sqlString UTF8String]);
    
    if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
        if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
            MPILogError(@"Error while deleting messages: %s", sqlite3_errmsg(mParticleDB));
        }
    }
    
    sqlite3_finalize(preparedStatement);
}

- (void)deleteNetworkPerformanceMessages {
    sqlite3_stmt *preparedStatement;
    const string sqlStatement = "DELETE FROM messages WHERE message_type = '" + string([kMPMessageTypeNetworkPerformance UTF8String]) + "'";
    
    if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
        if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
            MPILogError(@"Error while deleting network messages from sessions");
        }
    }
    
    sqlite3_finalize(preparedStatement);
}

- (void)deletePreviousSession {
    sqlite3_stmt *preparedStatement;
    string sqlStatement = "DELETE FROM previous_session";
    
    if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
        if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
            MPILogError(@"Error while deleting previous session");
        }
    }
    
    sqlite3_finalize(preparedStatement);
}

- (void)deleteRecordsOlderThan:(NSTimeInterval)timestamp {
    char *errMsg;
    NSString *sqlStatement = @"BEGIN TRANSACTION";
    
    if (sqlite3_exec(mParticleDB, sqlStatement.UTF8String, NULL, NULL, &errMsg) != SQLITE_OK) {
        MPILogError("Problem Beginning SQL Transaction: %@\n", sqlStatement);
    }
    
    NSArray *statements = @[
                            @"DELETE FROM messages WHERE timestamp < ?",
                            @"DELETE FROM uploads WHERE timestamp < ?",
                            @"DELETE FROM sessions WHERE end_time < ?"
                            ];
    
    sqlite3_stmt *preparedStatement;
    for (NSString *sqlStatement in statements) {
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.UTF8String, (int)[sqlStatement length], &preparedStatement, NULL) == SQLITE_OK) {
            sqlite3_bind_double(preparedStatement, 1, timestamp);
            
            if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                MPILogError(@"Error while deleting old records: %s", sqlite3_errmsg(mParticleDB));
            }
            
            sqlite3_clear_bindings(preparedStatement);
        }
        sqlite3_finalize(preparedStatement);
    }
    
    sqlStatement = @"END TRANSACTION";
    
    if (sqlite3_exec(mParticleDB, sqlStatement.UTF8String, NULL, NULL, &errMsg) != SQLITE_OK) {
        MPILogError("Problem Ending SQL Transaction: %@\n", sqlStatement);
    }
}

- (void)deleteAllSessionsExcept:(nullable MPSession *)session {
    // Delete sessions
    sqlite3_stmt *preparedStatement;
    string sqlStatement = "DELETE FROM sessions WHERE _id != ?";
    
    if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
        sqlite3_bind_int64(preparedStatement, 1, session.sessionId);
        
        if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
            MPILogError(@"Error while deleting sessions: %s", sqlite3_errmsg(mParticleDB));
        }
        
        sqlite3_clear_bindings(preparedStatement);
    }
    
    sqlite3_finalize(preparedStatement);
}

- (void)deleteSession:(nonnull MPSession *)session {
    // Delete messages
    sqlite3_stmt *preparedStatement;
    string sqlStatement = "DELETE FROM messages WHERE session_id = ?";
    
    if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
        sqlite3_bind_int64(preparedStatement, 1, session.sessionId);
        
        if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
            MPILogError(@"Error while deleting messages: %s", sqlite3_errmsg(mParticleDB));
        }
        
        sqlite3_clear_bindings(preparedStatement);
    }
    
    sqlite3_finalize(preparedStatement);
    
    // Delete session
    sqlStatement = "DELETE FROM sessions WHERE _id = ?";
    
    if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
        sqlite3_bind_int64(preparedStatement, 1, session.sessionId);
        
        if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
            MPILogError(@"Error while deleting session: %s", sqlite3_errmsg(mParticleDB));
        }
        
        sqlite3_clear_bindings(preparedStatement);
    }
    
    sqlite3_finalize(preparedStatement);
}

- (void)deleteUpload:(MPUpload *)upload {
    if (!upload) {
        return;
    }
    [self deleteUploadId:upload.uploadId];
}

- (void)deleteUploadId:(int64_t)uploadId {
    sqlite3_stmt *preparedStatement;
    const string sqlStatement = "DELETE FROM uploads WHERE _id = ?";
    
    if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
        sqlite3_bind_int64(preparedStatement, 1, uploadId);
        
        if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
            MPILogError(@"Error while deleting upload: %s", sqlite3_errmsg(mParticleDB));
        }
        
        sqlite3_clear_bindings(preparedStatement);
    }
    
    sqlite3_finalize(preparedStatement);
}

- (nullable NSArray<MPBreadcrumb *> *)fetchBreadcrumbs {
    vector<MPBreadcrumb *> breadcrumbsVector;
    
    sqlite3_stmt *preparedStatement;
    const string sqlStatement = "SELECT _id, session_uuid, uuid, breadcrumb_data, timestamp FROM breadcrumbs WHERE mpid = ? ORDER BY _id";
    
    if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
        sqlite3_bind_int64(preparedStatement, 1, [[MPPersistenceController_PRIVATE mpId] longLongValue]);
        
        while (sqlite3_step(preparedStatement) == SQLITE_ROW) {
            MPBreadcrumb *breadcrumb = [[MPBreadcrumb alloc] initWithSessionUUID:stringValue(preparedStatement, 1)
                                                                    breadcrumbId:int64Value(preparedStatement, 0)
                                                                            UUID:stringValue(preparedStatement, 2)
                                                                  breadcrumbData:dataValue(preparedStatement, 3)
                                                                       timestamp:doubleValue(preparedStatement, 4)];
            
            breadcrumbsVector.push_back(breadcrumb);
        }
        
        sqlite3_clear_bindings(preparedStatement);
    }
    
    sqlite3_finalize(preparedStatement);
    
    if (breadcrumbsVector.empty()) {
        return nil;
    }
    
    NSArray<MPBreadcrumb *> *breadcrumbs = [NSArray arrayWithObjects:&breadcrumbsVector[0] count:breadcrumbsVector.size()];
    return breadcrumbs;
}

- (MPConsumerInfo *)fetchConsumerInfoForUserId:(NSNumber *)userId {
    MPConsumerInfo *consumerInfo = nil;
    
    NSArray<MPCookie *> *cookies = [self fetchCookiesForUserId:userId];
    if (cookies.count) {
        consumerInfo = [[MPConsumerInfo alloc] init];
        consumerInfo.cookies = cookies;
    }
    
    return consumerInfo;
}

- (nullable NSArray<MPCookie *> *)fetchCookiesForUserId:(NSNumber *)userId {
    vector<MPCookie *> cookiesVector;
    
    sqlite3_stmt *preparedStatement;
    const string sqlStatement = "SELECT _id, content, domain, expiration, name, mpid FROM cookies WHERE mpid = ?";
    
    if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
        sqlite3_bind_int64(preparedStatement, 1, [userId longLongValue]);
        
        while (sqlite3_step(preparedStatement) == SQLITE_ROW) {
            MPCookie *cookie = [[MPCookie alloc] init];
            cookie.cookieId = int64Value(preparedStatement, 0);
            
            unsigned char *columnText = (unsigned char *)sqlite3_column_text(preparedStatement, 1);
            if (columnText != NULL) {
                cookie.content = [NSString stringWithCString:(const char *)columnText encoding:NSUTF8StringEncoding];
            }
            
            columnText = (unsigned char *)sqlite3_column_text(preparedStatement, 2);
            if (columnText != NULL) {
                cookie.domain = [NSString stringWithCString:(const char *)columnText encoding:NSUTF8StringEncoding];
            }
            
            columnText = (unsigned char *)sqlite3_column_text(preparedStatement, 3);
            if (columnText != NULL) {
                cookie.expiration = [NSString stringWithCString:(const char *)columnText encoding:NSUTF8StringEncoding];
            }
            
            cookie.name = stringValue(preparedStatement, 4);
            
            cookiesVector.push_back(cookie);
        }
        
        sqlite3_clear_bindings(preparedStatement);
    }
    
    sqlite3_finalize(preparedStatement);
    
    if (cookiesVector.empty()) {
        return nil;
    }
    
    NSArray<MPCookie *> *cookies = [NSArray arrayWithObjects:&cookiesVector[0] count:cookiesVector.size()];
    return cookies;
}

- (nullable NSArray<MPForwardRecord *> *)fetchForwardRecords {
    vector<MPForwardRecord *> forwardRecordsVector;
    
    sqlite3_stmt *preparedStatement;
    const string sqlStatement = "SELECT _id, forwarding_data, mpid FROM forwarding_records ORDER BY _id";
    
    if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
        while (sqlite3_step(preparedStatement) == SQLITE_ROW) {
            MPForwardRecord *forwardRecord = [[MPForwardRecord alloc] initWithId:int64Value(preparedStatement, 0)
                                                                            data:dataValue(preparedStatement, 1)
                                                                            mpid:@(int64Value(preparedStatement, 2))];
            
            forwardRecordsVector.push_back(forwardRecord);
        }
    }
    
    sqlite3_finalize(preparedStatement);
    
    if (forwardRecordsVector.empty()) {
        return nil;
    }
    
    NSArray<MPForwardRecord *> *forwardRecords = [NSArray arrayWithObjects:&forwardRecordsVector[0] count:forwardRecordsVector.size()];
    return forwardRecords;
}

- (nullable NSArray<MPIntegrationAttributes *> *)fetchIntegrationAttributes {
    vector<MPIntegrationAttributes *> integrationAttributesVector;
    
    sqlite3_stmt *preparedStatement;
    const string sqlStatement = "SELECT kit_code, attributes_data FROM integration_attributes";
    
    if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
        while (sqlite3_step(preparedStatement) == SQLITE_ROW) {
            MPIntegrationAttributes *integrationAttributes = [[MPIntegrationAttributes alloc] initWithIntegrationId:@(intValue(preparedStatement, 0))
                                                                                               attributesData:dataValue(preparedStatement, 1)];
            
            if (integrationAttributes) {
                integrationAttributesVector.push_back(integrationAttributes);
            }
        }
    }
    
    sqlite3_finalize(preparedStatement);
    
    if (integrationAttributesVector.empty()) {
        return nil;
    }
    
    NSArray<MPIntegrationAttributes *> *integrationAttributesArray = [NSArray arrayWithObjects:&integrationAttributesVector[0] count:integrationAttributesVector.size()];
    return integrationAttributesArray;
}

- (nullable NSDictionary*)fetchIntegrationAttributesForId:(NSNumber *)integrationId {
    if (MPIsNull(integrationId)) {
        return nil;
    }
    MPIntegrationAttributes *integrationAttributes;
    sqlite3_stmt *preparedStatement;
    const string sqlStatement = "SELECT attributes_data FROM integration_attributes WHERE kit_code = ?";
    
    if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
        sqlite3_bind_int64(preparedStatement, 1, integrationId.intValue);
        if (sqlite3_step(preparedStatement) == SQLITE_ROW) {
            integrationAttributes = [[MPIntegrationAttributes alloc] initWithIntegrationId:integrationId
                                                                            attributesData:dataValue(preparedStatement, 0)];
        }
    }
    
    sqlite3_finalize(preparedStatement);
    return [integrationAttributes attributes];
}

- (NSMutableDictionary *)fetchMessagesForUploading {
    NSMutableDictionary *mpidMessages = [NSMutableDictionary dictionary];
    sqlite3_stmt *preparedStatement;
    const string sqlStatement = "SELECT _id, uuid, message_type, message_data, timestamp, upload_status, mpid, session_id, data_plan_id, data_plan_version FROM messages WHERE mpid != 0 AND (upload_status = ? OR upload_status = ?) ORDER BY timestamp, _id";
    
    if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
        sqlite3_bind_int(preparedStatement, 1, MPUploadStatusStream);
        sqlite3_bind_int(preparedStatement, 2, MPUploadStatusBatch);
        
        while (sqlite3_step(preparedStatement) == SQLITE_ROW) {
            MPMessage *message = [[MPMessage alloc] initWithSessionId:[NSNumber numberWithLongLong:int64Value(preparedStatement, 7)]
                                                            messageId:int64Value(preparedStatement, 0)
                                                                 UUID:stringValue(preparedStatement, 1)
                                                          messageType:stringValue(preparedStatement, 2)
                                                          messageData:dataValue(preparedStatement, 3)
                                                            timestamp:doubleValue(preparedStatement, 4)
                                                         uploadStatus:(MPUploadStatus)intValue(preparedStatement, 5)
                                                               userId:@(int64Value(preparedStatement, 6))
                                                           dataPlanId:stringValue(preparedStatement, 8)
                                                      dataPlanVersion:intValue(preparedStatement, 9) ? @(intValue(preparedStatement, 9)) : nil];
            if (message) {
                NSNumber *mpid = message.userId;
                NSNumber *sessionID = (message.sessionId != nil) ? message.sessionId : [NSNumber numberWithInteger:-1];
                NSString *dataPlanID = (message.dataPlanId != nil)  ? message.dataPlanId  : @"0";
                NSNumber *dataPlanVersion = (message.dataPlanVersion != nil) ? message.dataPlanVersion : @(0);
                
                if (![mpidMessages objectForKey:mpid]) {
                    mpidMessages[mpid] = [NSMutableDictionary dictionary];
                }
                if (![mpidMessages[mpid] objectForKey:sessionID]) {
                    mpidMessages[mpid][sessionID] = [NSMutableDictionary dictionary];
                }
                if (![mpidMessages[mpid][sessionID] objectForKey:dataPlanID]) {
                    mpidMessages[mpid][sessionID][dataPlanID] = [NSMutableDictionary dictionary];
                }
                if (![mpidMessages[mpid][sessionID][dataPlanID] objectForKey:dataPlanVersion]) {
                    mpidMessages[mpid][sessionID][dataPlanID][dataPlanVersion] = [NSMutableArray array];;
                }
                [mpidMessages[mpid][sessionID][dataPlanID][dataPlanVersion] addObject:message];
            }
            
        }
        
        sqlite3_clear_bindings(preparedStatement);
    }
    
    sqlite3_finalize(preparedStatement);
    
    if (mpidMessages.count == 0) {
        return nil;
    }
    
    return mpidMessages;
}

- (nullable NSArray<MPSession *> *)fetchPossibleSessionsFromCrash {
    vector<MPSession *> sessionsVector;
    
    sqlite3_stmt *preparedStatement;
    const string sqlStatement = "SELECT _id, uuid, background_time, start_time, end_time, attributes_data, session_number, number_interruptions, event_count, suspend_time, length, mpid, session_user_ids, app_info, device_info \
    FROM sessions \
    WHERE mpid = ? AND _id IN ((SELECT MAX(_id) FROM sessions WHERE mpid = ?), (SELECT (MAX(_id) - 1) FROM sessions WHERE mpid = ?)) \
    ORDER BY session_number";
    
    if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
        sqlite3_bind_int64(preparedStatement, 1, [[MPPersistenceController_PRIVATE mpId] longLongValue]);
        sqlite3_bind_int64(preparedStatement, 2, [[MPPersistenceController_PRIVATE mpId] longLongValue]);
        sqlite3_bind_int64(preparedStatement, 3, [[MPPersistenceController_PRIVATE mpId] longLongValue]);
        
        while (sqlite3_step(preparedStatement) == SQLITE_ROW) {
            MPSession *crashSession = [[MPSession alloc] initWithSessionId:int64Value(preparedStatement, 0)
                                                                      UUID:stringValue(preparedStatement, 1)
                                                            backgroundTime:doubleValue(preparedStatement, 2)
                                                                 startTime:doubleValue(preparedStatement, 3)
                                                                   endTime:doubleValue(preparedStatement, 4)
                                                                attributes:[dictionaryRepresentation(preparedStatement, 5) mutableCopy]
                                                     numberOfInterruptions:intValue(preparedStatement, 7)
                                                              eventCounter:intValue(preparedStatement, 8)
                                                               suspendTime:doubleValue(preparedStatement, 9)
                                                                    userId:@(int64Value(preparedStatement, 10))
                                                            sessionUserIds:stringValue(preparedStatement, 11)
                                                                   appInfo:dictionaryRepresentation(preparedStatement, 12)
                                                                deviceInfo:dictionaryRepresentation(preparedStatement, 13)];
            
            crashSession.length = doubleValue(preparedStatement, 10);
            
            sessionsVector.push_back(crashSession);
        }
        
        sqlite3_clear_bindings(preparedStatement);
    }
    
    sqlite3_finalize(preparedStatement);
    
    if (sessionsVector.empty()) {
        return nil;
    }
    
    NSArray<MPSession *> *sessions = [NSArray arrayWithObjects:&sessionsVector[0] count:sessionsVector.size()];
    return sessions;
}

- (nullable MPSession *)fetchPreviousSession {
    MPSession *previousSession = nil;
    
    sqlite3_stmt *preparedStatement;
    const string sqlStatement = "SELECT session_id, uuid, background_time, start_time, end_time, attributes_data, session_number, number_interruptions, event_count, suspend_time, length, mpid, session_user_ids FROM previous_session WHERE mpid = ?";
    
    if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
        sqlite3_bind_int64(preparedStatement, 1, [[MPPersistenceController_PRIVATE mpId] longLongValue]);
        
        if (sqlite3_step(preparedStatement) == SQLITE_ROW) {
            previousSession = [[MPSession alloc] initWithSessionId:int64Value(preparedStatement, 0)
                                                              UUID:stringValue(preparedStatement, 1)
                                                    backgroundTime:doubleValue(preparedStatement, 2)
                                                         startTime:doubleValue(preparedStatement, 3)
                                                           endTime:doubleValue(preparedStatement, 4)
                                                        attributes:[dictionaryRepresentation(preparedStatement, 5) mutableCopy]
                                             numberOfInterruptions:intValue(preparedStatement, 7)
                                                      eventCounter:intValue(preparedStatement, 8)
                                                       suspendTime:doubleValue(preparedStatement, 9)
                                                            userId:@(int64Value(preparedStatement, 10))
                                                    sessionUserIds:stringValue(preparedStatement, 11)
                                                           appInfo:nil
                                                        deviceInfo:nil];
            
            previousSession.length = doubleValue(preparedStatement, 10);
        }
        
        sqlite3_clear_bindings(preparedStatement);
    }
    
    sqlite3_finalize(preparedStatement);
    
    return previousSession;
}

- (MPMessage *)fetchSessionEndMessageInSession:(MPSession *)session {
    MPMessage *message = nil;
    
    sqlite3_stmt *preparedStatement;
    const string sqlStatement = "SELECT _id, uuid, message_type, message_data, timestamp, upload_status, mpid, data_plan_id, data_plan_version FROM messages WHERE session_id = ? AND message_type = ?";
    
    if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
        sqlite3_bind_int64(preparedStatement, 1, session.sessionId);
        const char *sessionEndMessageType = [NSStringFromMessageType(MPMessageTypeSessionEnd) UTF8String];
        sqlite3_bind_text(preparedStatement, 2, sessionEndMessageType, sizeof(sessionEndMessageType), SQLITE_STATIC);
        
        if (sqlite3_step(preparedStatement) == SQLITE_ROW) {
            message = [[MPMessage alloc] initWithSessionId:@(session.sessionId)
                                                 messageId:int64Value(preparedStatement, 0)
                                                      UUID:stringValue(preparedStatement, 1)
                                               messageType:stringValue(preparedStatement, 2)
                                               messageData:dataValue(preparedStatement, 3)
                                                 timestamp:doubleValue(preparedStatement, 4)
                                              uploadStatus:(MPUploadStatus)intValue(preparedStatement, 5)
                                                    userId:@(int64Value(preparedStatement, 6))
                                                dataPlanId:stringValue(preparedStatement, 7)
                                           dataPlanVersion:intValue(preparedStatement, 9) ? @(intValue(preparedStatement, 9)) : nil];
        }
        
        sqlite3_clear_bindings(preparedStatement);
    }
    
    sqlite3_finalize(preparedStatement);
    
    return message;
}

- (NSMutableArray<MPSession *> *)fetchSessions {
    sqlite3_stmt *preparedStatement;
    const string sqlStatement = "SELECT _id, uuid, background_time, start_time, end_time, attributes_data, session_number, number_interruptions, event_count, suspend_time, length, mpid, session_user_ids, app_info, device_info FROM sessions ORDER BY _id";
    
    NSMutableArray<MPSession *> *sessions = nil;
    
    if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
        sessions = [[NSMutableArray alloc] initWithCapacity:1];
        
        while (sqlite3_step(preparedStatement) == SQLITE_ROW) {
            MPSession *session = [[MPSession alloc] initWithSessionId:int64Value(preparedStatement, 0)
                                                                 UUID:stringValue(preparedStatement, 1)
                                                       backgroundTime:doubleValue(preparedStatement, 2)
                                                            startTime:doubleValue(preparedStatement, 3)
                                                              endTime:doubleValue(preparedStatement, 4)
                                                           attributes:[dictionaryRepresentation(preparedStatement, 5) mutableCopy]
                                                numberOfInterruptions:intValue(preparedStatement, 7)
                                                         eventCounter:intValue(preparedStatement, 8)
                                                          suspendTime:doubleValue(preparedStatement, 9)
                                                               userId:@(int64Value(preparedStatement, 11))
                                                       sessionUserIds:stringValue(preparedStatement, 12)
                                                              appInfo:dictionaryRepresentation(preparedStatement, 13)
                                                           deviceInfo:dictionaryRepresentation(preparedStatement, 14)];
            
            session.length = doubleValue(preparedStatement, 10);
            
            [sessions addObject:session];
        }
    }
    
    sqlite3_finalize(preparedStatement);
    
    if (sessions.count == 0) {
        sessions = nil;
    }
    
    return sessions;
}

- (nullable NSArray<MPMessage *> *)fetchUploadedMessagesInSession:(nonnull MPSession *)session {
    NSArray<MPMessage *> *messages = nil;
    
    sqlite3_stmt *preparedStatement;
    string sqlStatement = "SELECT _id, uuid, message_type, message_data, timestamp, upload_status, mpid, data_plan_id, data_plan_version FROM messages WHERE session_id = ? AND upload_status = ? AND mpid = ? ORDER BY timestamp";
    
    vector<MPMessage *> messagesVector;
    
    if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
        sqlite3_bind_int64(preparedStatement, 1, session.sessionId);
        sqlite3_bind_int(preparedStatement, 2, MPUploadStatusUploaded);
        sqlite3_bind_int64(preparedStatement, 3, [[MPPersistenceController_PRIVATE mpId] longLongValue]);
        
        while (sqlite3_step(preparedStatement) == SQLITE_ROW) {
            MPMessage *message = [[MPMessage alloc] initWithSessionId:@(session.sessionId)
                                                            messageId:int64Value(preparedStatement, 0)
                                                                 UUID:stringValue(preparedStatement, 1)
                                                          messageType:stringValue(preparedStatement, 2)
                                                          messageData:dataValue(preparedStatement, 3)
                                                            timestamp:doubleValue(preparedStatement, 4)
                                                         uploadStatus:(MPUploadStatus)intValue(preparedStatement, 5)
                                                               userId:@(int64Value(preparedStatement, 6))
                                                           dataPlanId:stringValue(preparedStatement, 7)
                                                      dataPlanVersion:@(intValue(preparedStatement, 8))];
            
            messagesVector.push_back(message);
        }
        
        sqlite3_clear_bindings(preparedStatement);
    }
    
    sqlite3_finalize(preparedStatement);
    
    if (!messagesVector.empty()) {
        messages = [NSArray arrayWithObjects:&messagesVector[0] count:messagesVector.size()];
    }
    
    return messages;
}

- (nullable NSArray<MPUpload *> *)fetchUploads {
    sqlite3_stmt *preparedStatement;
    string sqlStatement;
    
    sqlStatement = "SELECT _id, uuid, message_data, timestamp, session_id, upload_type, data_plan_id, data_plan_version, upload_settings FROM uploads ORDER BY timestamp, _id LIMIT 100";
    
    vector<MPUpload *> uploadsVector;
    
    if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
        while (sqlite3_step(preparedStatement) == SQLITE_ROW) {
            NSData *uploadSettingsData = dataValue(preparedStatement, 8);
            if (uploadSettingsData) {
                @try {
                    MPUploadSettings *uploadSettings = [NSKeyedUnarchiver unarchiveObjectWithData:uploadSettingsData];
                    MPUpload *upload = [[MPUpload alloc] initWithSessionId:@(int64Value(preparedStatement, 4))
                                                                  uploadId:int64Value(preparedStatement, 0)
                                                                      UUID:stringValue(preparedStatement, 1)
                                                                uploadData:dataValue(preparedStatement, 2)
                                                                 timestamp:doubleValue(preparedStatement, 3)
                                                                uploadType:(MPUploadType)int64Value(preparedStatement, 5)
                                                                dataPlanId:stringValue(preparedStatement, 6)
                                                           dataPlanVersion:intValue(preparedStatement, 7) ? @(intValue(preparedStatement, 7)) : nil
                                                            uploadSettings:uploadSettings];
                    uploadsVector.push_back(upload);
                } @catch(NSException *exception) {
                    MPILogError(@"Error while fetching upload: %@: %@", exception.name, exception.reason);
                }
            }
        }
        sqlite3_clear_bindings(preparedStatement);
    }
    
    sqlite3_finalize(preparedStatement);
    
    NSArray<MPUpload *> *uploads = nil;
    if (!uploadsVector.empty()) {
        uploads = [NSArray arrayWithObjects:&uploadsVector[0] count:uploadsVector.size()];
    }
    
    return uploads;
}

- (void)moveContentFromMpidZeroToMpid:(NSNumber *)mpid {
    [self moveUserDefaultsFromMpidZeroToMpid:mpid];
    [self moveDatabasesFromMpidZeroToMpid:mpid];
}

- (void)moveUserDefaultsFromMpidZeroToMpid:(NSNumber *)mpid {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary<NSString *, id> *dictionary = [userDefaults dictionaryRepresentation];
    [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([key rangeOfString:@"mParticle::0"].location == 0) {
            NSString *newKey = [key stringByReplacingOccurrencesOfString:@"mParticle::0" withString:[NSString stringWithFormat:@"mParticle::%@", mpid]];
            if (!dictionary[newKey]) {
                [userDefaults setObject:obj forKey:newKey];
            }
            
            [userDefaults removeObjectForKey:key];
        }
    }];
}

- (void)moveDatabasesFromMpidZeroToMpid:(NSNumber *)mpid {
    
    NSArray *mpidKeyedTables = @[
                                 @"sessions",
                                 @"previous_session",
                                 @"messages",
                                 @"breadcrumbs",
                                 @"cookies",
                                 @"consumer_info"
                                 ];
    
    [mpidKeyedTables enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        sqlite3_stmt *preparedStatement;
        NSString *sqlString = [NSString stringWithFormat:@"UPDATE %@ SET mpid = ? WHERE mpid = 0", obj];
        const string sqlStatement = string([sqlString UTF8String]);
        
        if (sqlite3_prepare_v2(self->mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            
            sqlite3_bind_int64(preparedStatement, 1, [mpid longLongValue]);
            
            if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                MPILogError(@"Error while updating zero-mpid table: %s", sqlite3_errmsg(self->mParticleDB));
            }
            
            sqlite3_clear_bindings(preparedStatement);
        }
        
        sqlite3_finalize(preparedStatement);
    }];
}

- (void)purgeMemory {
    sqlite3_db_release_memory(mParticleDB);
    sqlite3_release_memory(4096);
}

- (BOOL)openDatabase {
    if (databaseOpen) {
        return YES;
    }
    
    int statusCode;
    const char *databasePath = [self.databasePath UTF8String];
    statusCode = sqlite3_open_v2(databasePath, &mParticleDB, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FILEPROTECTION_NONE | SQLITE_OPEN_FULLMUTEX, NULL);
    
    if (statusCode != SQLITE_OK) {
        MPDatabaseState databaseState = [self verifyDatabaseState];
        if (databaseState == MPDatabaseStateCorrupted) {
            [self removeDatabase];
            
            statusCode = sqlite3_open_v2(databasePath, &mParticleDB, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FILEPROTECTION_NONE | SQLITE_OPEN_FULLMUTEX, NULL);
        }
    }
    
    databaseOpen = statusCode == SQLITE_OK;
    if (!databaseOpen) {
        MPILogError(@"Error opening database: %d - %s", statusCode, sqlite3_errmsg(mParticleDB));
        sqlite3_close(mParticleDB);
        mParticleDB = NULL;
    }
    
    return databaseOpen;
}

- (void)saveBreadcrumb:(MPMessage *)message {
    // Save breadcrumb
    sqlite3_stmt *preparedStatement;
    string sqlStatement = "INSERT INTO breadcrumbs (session_uuid, uuid, timestamp, breadcrumb_data, session_number, mpid) VALUES (?, ?, ?, ?, ?, ?)";
    
    if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
        string auxString = string(""); // not used
        sqlite3_bind_text(preparedStatement, 1, auxString.c_str(), (int)auxString.size(), SQLITE_TRANSIENT);
        
        auxString = string([message.uuid UTF8String]);
        sqlite3_bind_text(preparedStatement, 2, auxString.c_str(), (int)auxString.size(), SQLITE_STATIC);
        
        sqlite3_bind_double(preparedStatement, 3, message.timestamp);
        sqlite3_bind_blob(preparedStatement, 4, [message.messageData bytes], (int)[message.messageData length], SQLITE_STATIC);
        sqlite3_bind_int64(preparedStatement, 5, 0); //session_number Deprecated
        sqlite3_bind_int64(preparedStatement, 6, [[MPPersistenceController_PRIVATE mpId] longLongValue]);
        
        if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
            MPILogError(@"Error while storing breadcrumb: %s", sqlite3_errmsg(mParticleDB));
        } else {
            [MPListenerController.sharedInstance onEntityStored:MPDatabaseTableBreadcrumbs primaryKey:@(message.messageId) message:message.description];
        }
        
        sqlite3_clear_bindings(preparedStatement);
    } else {
        MPILogError(@"could not prepare statemnt: %s\n", sqlite3_errmsg(mParticleDB));
    }
    
    sqlite3_finalize(preparedStatement);
    
    // Prunes breadcrumbs
    sqlStatement = "DELETE FROM breadcrumbs WHERE mpid = ? AND _id NOT IN (SELECT _id FROM breadcrumbs WHERE mpid = ? ORDER BY _id DESC LIMIT ?)";
    
    if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
        sqlite3_bind_int64(preparedStatement, 1, [[MPPersistenceController_PRIVATE mpId] longLongValue]);
        sqlite3_bind_int64(preparedStatement, 2, [[MPPersistenceController_PRIVATE mpId] longLongValue]);
        sqlite3_bind_int(preparedStatement, 3, MaxBreadcrumbs);
        
        if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
            MPILogError(@"Error while pruning breadcrumbs: %s", sqlite3_errmsg(mParticleDB));
        }
        
        sqlite3_clear_bindings(preparedStatement);
    } else {
        MPILogError(@"could not prepare statemnt: %s\n", sqlite3_errmsg(mParticleDB));
    }
    
    sqlite3_finalize(preparedStatement);
}

- (void)saveConsumerInfo:(MPConsumerInfo *)consumerInfo {
    sqlite3_stmt *preparedStatement;
    
    vector<string> fields;
    vector<string> params;
    
    if (consumerInfo.uniqueIdentifier) {
        fields.push_back("unique_identifier");
        params.push_back("'" + string([consumerInfo.uniqueIdentifier UTF8String]) + "'");
    }
    
    string sqlStatement = "INSERT INTO consumer_info (mpid";
    for (auto field : fields) {
        sqlStatement += ", " + field;
    }
    
    sqlStatement += ") VALUES (?";
    
    for (auto param : params) {
        sqlStatement += ", " + param;
    }
    
    sqlStatement += ")";
    
    if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
        if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
            MPILogError(@"Error while storing consumer info: %s", sqlite3_errmsg(mParticleDB));
            sqlite3_clear_bindings(preparedStatement);
            sqlite3_finalize(preparedStatement);
            return;
        }
        
        consumerInfo.consumerInfoId = sqlite3_last_insert_rowid(mParticleDB);
        
        sqlite3_clear_bindings(preparedStatement);
    } else {
        MPILogError(@"could not prepare statemnt: %s\n", sqlite3_errmsg(mParticleDB));
    }
    
    sqlite3_finalize(preparedStatement);
    
    for (MPCookie *cookie in consumerInfo.cookies) {
        if (!cookie.expired) {
            [self saveCookie:cookie forConsumerInfo:consumerInfo];
        }
    }
}

- (void)saveForwardRecord:(MPForwardRecord *)forwardRecord {
    
    sqlite3_stmt *preparedStatement;
    const string sqlStatement = "INSERT INTO forwarding_records (forwarding_data, mpid) VALUES (?, ?)";
    
    if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
        NSData *data = [forwardRecord dataRepresentation];
        
        if (data) {
            sqlite3_bind_blob(preparedStatement, 1, [data bytes], (int)[data length], SQLITE_STATIC);
        } else {
            sqlite3_finalize(preparedStatement);
            return;
        }
        
        if (forwardRecord.mpid != nil) {
            sqlite3_bind_int64(preparedStatement, 2, forwardRecord.mpid.longLongValue);
        }
        else {
            sqlite3_finalize(preparedStatement);
            return;
        }
        
        if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
            MPILogError(@"Error while storing forward record: %s", sqlite3_errmsg(mParticleDB));
            sqlite3_clear_bindings(preparedStatement);
            sqlite3_finalize(preparedStatement);
            return;
        }
        
        forwardRecord.forwardRecordId = sqlite3_last_insert_rowid(mParticleDB);
        
        sqlite3_clear_bindings(preparedStatement);
    } else {
        MPILogError(@"could not prepare statemnt: %s\n", sqlite3_errmsg(mParticleDB));
    }
    
    sqlite3_finalize(preparedStatement);
}

- (void)saveIntegrationAttributes:(nonnull MPIntegrationAttributes *)integrationAttributes {
    [self deleteIntegrationAttributesForIntegrationId:integrationAttributes.integrationId];
    
    sqlite3_stmt *preparedStatement;
    const string sqlStatement = "INSERT INTO integration_attributes (kit_code, attributes_data) VALUES (?, ?)";
    
    if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
        NSError *error = nil;
        NSData *attributesData = nil;
        
        @try {
            attributesData = [NSJSONSerialization dataWithJSONObject:integrationAttributes.attributes options:0 error:&error];
        } @catch (NSException *exception) {
        }
        
        if (!attributesData && error != nil) {
            sqlite3_finalize(preparedStatement);
            return;
        }
        
        sqlite3_bind_int(preparedStatement, 1, [integrationAttributes.integrationId intValue]);
        sqlite3_bind_blob(preparedStatement, 2, [attributesData bytes], (int)[attributesData length], SQLITE_STATIC);
        
        if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
            MPILogError(@"Error while storing integration attributes: %s", sqlite3_errmsg(mParticleDB));
            sqlite3_clear_bindings(preparedStatement);
            sqlite3_finalize(preparedStatement);
            return;
        } else {
            [MPListenerController.sharedInstance onEntityStored:MPDatabaseTableAttributes primaryKey:integrationAttributes.integrationId message:integrationAttributes.description];
        }
        
        sqlite3_clear_bindings(preparedStatement);
    } else {
        MPILogError(@"could not prepare statemnt: %s\n", sqlite3_errmsg(mParticleDB));
    }
    
    sqlite3_finalize(preparedStatement);
}

- (void)saveMessage:(MPMessage *)message {
    if (!message.shouldUploadEvent) {
        MPILogDebug(@"Not saving message for event because shouldUploadEvent was set to NO, message id: %lld, type: %@", message.messageId, message.messageType);
        return;
    }
    
    NSInteger maxBytes = [MPPersistenceController_PRIVATE maxBytesPerEvent:message.messageType];
    if (message == nil || message.messageData.length > maxBytes) {
        MPILogError(@"Unable to save message that is nil or exceeds max message size!");
        return;
    }
    
    sqlite3_stmt *preparedStatement;
    const string sqlStatement = "INSERT INTO messages (message_type, session_id, uuid, timestamp, message_data, upload_status, data_plan_id, data_plan_version, mpid) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
    
    if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
        string auxString = string([message.messageType UTF8String]);
        sqlite3_bind_text(preparedStatement, 1, auxString.c_str(), (int)auxString.size(), SQLITE_TRANSIENT);
        
        if (message.sessionId != nil) {
            sqlite3_bind_int64(preparedStatement, 2, message.sessionId.longLongValue);
        } else {
            sqlite3_bind_null(preparedStatement, 2);
        }
        
        
        auxString = string([message.uuid UTF8String]);
        sqlite3_bind_text(preparedStatement, 3, auxString.c_str(), (int)auxString.size(), SQLITE_TRANSIENT);
        
        sqlite3_bind_double(preparedStatement, 4, message.timestamp);
        sqlite3_bind_blob(preparedStatement, 5, [message.messageData bytes], (int)[message.messageData length], SQLITE_STATIC);
        sqlite3_bind_int(preparedStatement, 6, (int)message.uploadStatus);
        
        if (message.dataPlanId != nil && ![message.dataPlanId isEqual:@"0"]) {
        string dataAuxString = string([message.dataPlanId UTF8String]);
            sqlite3_bind_text(preparedStatement, 7, dataAuxString.c_str(), (int)dataAuxString.size(), SQLITE_TRANSIENT);
            if (message.dataPlanVersion != nil && message.dataPlanVersion.intValue != 0) {
                sqlite3_bind_int64(preparedStatement, 8, message.dataPlanVersion.intValue);
            } else {
                sqlite3_bind_null(preparedStatement, 8);
            }
        } else {
            sqlite3_bind_null(preparedStatement, 7);
            sqlite3_bind_null(preparedStatement, 8);
        }
        
        sqlite3_bind_int64(preparedStatement, 9, [message.userId longLongValue]);
        
        if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
            MPILogError(@"Error while storing message: %s", sqlite3_errmsg(mParticleDB));
            sqlite3_clear_bindings(preparedStatement);
            sqlite3_finalize(preparedStatement);
            return;
        }
        
        message.messageId = sqlite3_last_insert_rowid(mParticleDB);
        
        [MPListenerController.sharedInstance onEntityStored:MPDatabaseTableMessages primaryKey:@(message.messageId) message:message.description];
        
        sqlite3_clear_bindings(preparedStatement);
    } else {
        MPILogError(@"could not prepare statemnt: %s\n", sqlite3_errmsg(mParticleDB));
    }
    
    sqlite3_finalize(preparedStatement);
}

- (void)saveSession:(MPSession *)session {
    if (session) {
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "INSERT INTO sessions (uuid, start_time, end_time, background_time, attributes_data, session_number, number_interruptions, event_count, suspend_time, length, mpid, session_user_ids, app_info, device_info) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            string auxString = string([session.uuid UTF8String]);
            sqlite3_bind_text(preparedStatement, 1, auxString.c_str(), (int)auxString.size(), SQLITE_STATIC);
            
            sqlite3_bind_double(preparedStatement, 2, session.startTime);
            sqlite3_bind_double(preparedStatement, 3, session.endTime);
            sqlite3_bind_double(preparedStatement, 4, session.backgroundTime);
            
            bindDictionaryAsBlob(preparedStatement, 5, session.attributesDictionary);
            
            sqlite3_bind_int64(preparedStatement, 6, 0); //session_number Deprecated
            sqlite3_bind_int(preparedStatement, 7, session.numberOfInterruptions);
            sqlite3_bind_int(preparedStatement, 8, session.eventCounter);
            sqlite3_bind_double(preparedStatement, 9, session.suspendTime);
            sqlite3_bind_double(preparedStatement, 10, session.length);
            sqlite3_bind_int64(preparedStatement, 11, [session.userId longLongValue]);
            sqlite3_bind_text(preparedStatement, 12, [session.sessionUserIds UTF8String], (int)session.sessionUserIds.length, SQLITE_TRANSIENT);
            
            bindDictionaryAsBlob(preparedStatement, 13, session.appInfo);
            bindDictionaryAsBlob(preparedStatement, 14, session.deviceInfo);
            
            if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                MPILogError(@"Error while storing session: %s", sqlite3_errmsg(mParticleDB));
                sqlite3_clear_bindings(preparedStatement);
                sqlite3_finalize(preparedStatement);
                return;
            }
            
            session.sessionId = sqlite3_last_insert_rowid(mParticleDB);
            
            [MPListenerController.sharedInstance onEntityStored:MPDatabaseTableSessions primaryKey:@(session.sessionId) message:session.description];

            sqlite3_clear_bindings(preparedStatement);
        } else {
            MPILogError(@"could not prepare statement: %s\n", sqlite3_errmsg(mParticleDB));
        }
        
        sqlite3_finalize(preparedStatement);
    }
}

- (void)saveUpload:(nonnull MPUpload *)upload {
    // Save upload
    if ([MParticle sharedInstance].stateMachine.optOut && !upload.containsOptOutMessage) {
        return;
    }
    
    sqlite3_stmt *preparedStatement;
    string sqlStatement = "INSERT INTO uploads (uuid, message_data, timestamp, session_id, upload_type, data_plan_id, data_plan_version, upload_settings) VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
    
    if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
        string auxString = string([upload.uuid UTF8String]);
        sqlite3_bind_text(preparedStatement, 1, auxString.c_str(), (int)auxString.size(), SQLITE_STATIC);
        
        sqlite3_bind_blob(preparedStatement, 2, [upload.uploadData bytes], (int)[upload.uploadData length], SQLITE_STATIC);
        sqlite3_bind_double(preparedStatement, 3, upload.timestamp);
        
        if (upload.sessionId != nil) {
            sqlite3_bind_int64(preparedStatement, 4, upload.sessionId.longLongValue);
        } else {
            sqlite3_bind_null(preparedStatement, 4);
        }
        
        sqlite3_bind_int64(preparedStatement, 5, upload.uploadType);
        
        if (upload.dataPlanId != nil && ![upload.dataPlanId isEqual:@"0"]) {
            string dataAuxString = string([upload.dataPlanId UTF8String]);
            sqlite3_bind_text(preparedStatement, 6, dataAuxString.c_str(), (int)dataAuxString.size(), SQLITE_TRANSIENT);
            if (upload.dataPlanVersion != nil &&  upload.dataPlanVersion.intValue != 0) {
                sqlite3_bind_int64(preparedStatement, 7, upload.dataPlanVersion.intValue);
            } else {
                sqlite3_bind_null(preparedStatement, 7);
            }
        } else {
            sqlite3_bind_null(preparedStatement, 6);
            sqlite3_bind_null(preparedStatement, 7);
        }
        
        @try {
            NSData *uploadSettingsData = [NSKeyedArchiver archivedDataWithRootObject:upload.uploadSettings];
            sqlite3_bind_blob(preparedStatement, 8, uploadSettingsData.bytes, (int)uploadSettingsData.length, SQLITE_TRANSIENT);
        } @catch(NSException *exception) {
            MPILogError(@"Error while storing upload: %@: %@", exception.name, exception.reason);
            sqlite3_clear_bindings(preparedStatement);
            sqlite3_finalize(preparedStatement);
            return;
        }
        
        if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
            MPILogError(@"Error while storing upload: %s", sqlite3_errmsg(mParticleDB));
            sqlite3_clear_bindings(preparedStatement);
            sqlite3_finalize(preparedStatement);
            return;
        }
        
        upload.uploadId = sqlite3_last_insert_rowid(mParticleDB);
        
        [MPListenerController.sharedInstance onEntityStored:MPDatabaseTableUploads primaryKey:@(upload.uploadId) message:upload.description];

        sqlite3_clear_bindings(preparedStatement);
    } else {
        MPILogError(@"could not prepare statement: %s\n", sqlite3_errmsg(mParticleDB));
    }
    
    sqlite3_finalize(preparedStatement);
}

- (void)updateConsumerInfo:(MPConsumerInfo *)consumerInfo {
    
    for (MPCookie *cookie in consumerInfo.cookies) {
        if (cookie.expired) {
            if (cookie.cookieId != 0) {
                [self deleteCookie:cookie];
            }
        } else {
            if (cookie.cookieId == 0) {
                [self saveCookie:cookie forConsumerInfo:consumerInfo];
            } else {
                [self updateCookie:cookie];
            }
        }
    }
}

- (void)updateSession:(MPSession *)session {
    if (session != nil) {
        sqlite3_stmt *preparedStatement;
        const string sqlStatement = "UPDATE sessions SET end_time = ?, attributes_data = ?, background_time = ?, number_interruptions = ?, event_count = ?, suspend_time = ?, length = ?, mpid = ?, session_user_ids = ? WHERE _id = ?";
        
        if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
            sqlite3_bind_double(preparedStatement, 1, session.endTime);
            
            NSData *attributesData = [NSJSONSerialization dataWithJSONObject:session.attributesDictionary options:0 error:nil];
            sqlite3_bind_blob(preparedStatement, 2, [attributesData bytes], (int)[attributesData length], SQLITE_STATIC);
            
            sqlite3_bind_double(preparedStatement, 3, session.backgroundTime);
            sqlite3_bind_int(preparedStatement, 4, session.numberOfInterruptions);
            sqlite3_bind_int(preparedStatement, 5, session.eventCounter);
            sqlite3_bind_double(preparedStatement, 6, session.suspendTime);
            sqlite3_bind_double(preparedStatement, 7, session.length);
            sqlite3_bind_int64(preparedStatement, 8, session.userId.longLongValue);
            sqlite3_bind_text(preparedStatement, 9, [session.sessionUserIds UTF8String], (int)session.sessionUserIds.length, SQLITE_TRANSIENT);
            sqlite3_bind_int64(preparedStatement, 10, session.sessionId);
            
            if (sqlite3_step(preparedStatement) != SQLITE_DONE) {
                MPILogError(@"Error while updating session: %s", sqlite3_errmsg(mParticleDB));
            }
            
            sqlite3_clear_bindings(preparedStatement);
        } else {
            MPILogError(@"could not prepare statement: %s\n", sqlite3_errmsg(mParticleDB));
        }
        
        sqlite3_finalize(preparedStatement);
    }
}

- (nonnull NSDictionary<NSString *, NSDictionary *> *)appAndDeviceInfoForSessionId:(nonnull NSNumber *)sessionId {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    sqlite3_stmt *preparedStatement;
    const string sqlStatement = "SELECT app_info, device_info FROM sessions WHERE _id = ?";
    
    if (sqlite3_prepare_v2(mParticleDB, sqlStatement.c_str(), (int)sqlStatement.size(), &preparedStatement, NULL) == SQLITE_OK) {
        sqlite3_bind_int64(preparedStatement, 1, sessionId.longLongValue);
        
        if (sqlite3_step(preparedStatement) == SQLITE_ROW) {
            dict[kMPApplicationInformationKey] = dictionaryRepresentation(preparedStatement, 0);
            dict[kMPDeviceInformationKey] = dictionaryRepresentation(preparedStatement, 1);
        }
        
        sqlite3_clear_bindings(preparedStatement);
    } else {
        MPILogError(@"could not prepare statement: %s\n", sqlite3_errmsg(mParticleDB));
    }
    
    sqlite3_finalize(preparedStatement);
    
    return dict;
}

@end

// Implementation of the C functions
#ifdef __cplusplus
extern "C" {
#endif

static inline NSData *dataValue(sqlite3_stmt *const preparedStatement, const int column) {
    __autoreleasing NSData *data = nil;
    const void *dataBytes = sqlite3_column_blob(preparedStatement, column);
    if (dataBytes == NULL) {
        return nil;
    }
    
    int dataLength = sqlite3_column_bytes(preparedStatement, column);
    
    data = [NSData dataWithBytes:dataBytes length:dataLength];
    return data;
}

static inline bool bindDictionaryAsBlob(sqlite3_stmt * _Nonnull const preparedStatement, const int column, NSDictionary * _Nullable dict) {
    if (!dict) {
        sqlite3_bind_null(preparedStatement, column);
        return true;
    }
    
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
    
    if (error) {
        MPILogError("Error serializing JSON: %@", error);
        return false;
    }
    
    sqlite3_bind_blob(preparedStatement, column, data.bytes, (int)data.length, SQLITE_TRANSIENT);
    return true;
}

static inline NSDictionary *dictionaryRepresentation(sqlite3_stmt *const preparedStatement, const int column) {
    __autoreleasing NSDictionary *dictionary = nil;
    const void *dataBytes = sqlite3_column_blob(preparedStatement, column);
    if (dataBytes == NULL) {
        return nil;
    }
    
    int dataLength = sqlite3_column_bytes(preparedStatement, column);
    
    NSError *error = nil;
    dictionary = [NSJSONSerialization JSONObjectWithData:[NSData dataWithBytes:dataBytes length:dataLength]
                                                 options:0
                                                   error:&error];
    
    if (error) {
        MPILogError(@"Error deserializing JSON: %@", error);
        return nil;
    }
    
    return dictionary;
}

static inline double doubleValue(sqlite3_stmt *const preparedStatement, const int column) {
    double doubleValue = sqlite3_column_double(preparedStatement, column);
    return doubleValue;
}

static inline int intValue(sqlite3_stmt *const preparedStatement, const int column) {
    int intValue = sqlite3_column_int(preparedStatement, column);
    return intValue;
}

static inline int64_t int64Value(sqlite3_stmt *const preparedStatement, const int column) {
    int64_t int64Value = sqlite3_column_int64(preparedStatement, column);
    return int64Value;
}

static inline NSString *stringValue(sqlite3_stmt *const preparedStatement, const int column) {
    const unsigned char *columnText = sqlite3_column_text(preparedStatement, column);
    if (columnText == NULL) {
        return nil;
    }
    
    __autoreleasing NSString *stringValue = [NSString stringWithUTF8String:(const char *)columnText];
    return stringValue;
}

#ifdef __cplusplus
}
#endif
