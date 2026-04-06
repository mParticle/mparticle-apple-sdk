#import "MPDatabaseMigrationController.h"
#import <sqlite3.h>
#import "MPSession.h"
#import "mParticle.h"
#import "MPBackendController.h"
#import "MPPersistenceController.h"
#import "MPIConstants.h"
#import "MPILogger.h"
#import "MPStateMachine.h"
#import "MPUpload.h"

@interface MParticle ()

@property (nonatomic, strong, readonly) MPPersistenceController_PRIVATE *persistenceController;
@property (nonatomic, strong, nonnull) MPBackendController_PRIVATE *backendController;
@property (nonatomic, strong, readonly) MPStateMachine_PRIVATE *stateMachine;

@end

@interface MPDatabaseMigrationController() {
    NSArray *migratedSessions;
}

@property (nonatomic, strong) NSArray<NSNumber *> *databaseVersions;

@end

@implementation MPDatabaseMigrationController

- (instancetype)initWithDatabaseVersions:(NSArray<NSNumber *> *)databaseVersions {
    self = [super init];
    if (self) {
        self.databaseVersions = [databaseVersions copy];
    }
    
    return self;
}

#pragma mark Private methods

- (void)deleteRecordsOlderThan:(NSTimeInterval)timestamp fromDatabase:(sqlite3 *)mParticleDB {
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

- (void)migrateSessionsFromDatabase:(sqlite3 *)oldDatabase toDatabase:(sqlite3 *)newDatabase {
    // v30 schema: uuid, start_time, end_time, attributes_data, session_number, background_time, number_interruptions, event_count, suspend_time, length, mpid, session_user_ids, app_info, device_info
    // v31 schema: same as v30
    const char *selectStatement = "SELECT uuid, start_time, end_time, attributes_data, session_number, background_time, number_interruptions, event_count, suspend_time, length, mpid, session_user_ids, app_info, device_info FROM sessions ORDER BY _id";
    const char *insertStatement = "INSERT INTO sessions (uuid, background_time, start_time, end_time, attributes_data, session_number, number_interruptions, event_count, suspend_time, length, mpid, session_user_ids, app_info, device_info) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
    
    sqlite3_stmt *selectStatementHandle, *insertStatementHandle;
    sqlite3_prepare_v2(oldDatabase, selectStatement, -1, &selectStatementHandle, NULL);
    sqlite3_prepare_v2(newDatabase, insertStatement, -1, &insertStatementHandle, NULL);
    
    while (sqlite3_step(selectStatementHandle) == SQLITE_ROW) {
        sqlite3_bind_text(insertStatementHandle, 1, (const char *)sqlite3_column_text(selectStatementHandle, 0), -1, SQLITE_TRANSIENT); // uuid
        sqlite3_bind_double(insertStatementHandle, 2, sqlite3_column_double(selectStatementHandle, 5)); // background_time
        sqlite3_bind_double(insertStatementHandle, 3, sqlite3_column_double(selectStatementHandle, 1)); // start_time
        sqlite3_bind_double(insertStatementHandle, 4, sqlite3_column_double(selectStatementHandle, 2)); // end_time
        sqlite3_bind_blob(insertStatementHandle, 5, sqlite3_column_blob(selectStatementHandle, 3), sqlite3_column_bytes(selectStatementHandle, 3), SQLITE_TRANSIENT); // attributes_data
        sqlite3_bind_int64(insertStatementHandle, 6, 0); // session_number (deprecated)
        sqlite3_bind_int(insertStatementHandle, 7, sqlite3_column_int(selectStatementHandle, 6)); // number_interruptions
        sqlite3_bind_int(insertStatementHandle, 8, sqlite3_column_int(selectStatementHandle, 7)); // event_count
        sqlite3_bind_double(insertStatementHandle, 9, sqlite3_column_double(selectStatementHandle, 8)); // suspend_time
        sqlite3_bind_double(insertStatementHandle, 10, sqlite3_column_double(selectStatementHandle, 9)); // length
        sqlite3_bind_int64(insertStatementHandle, 11, sqlite3_column_int64(selectStatementHandle, 10)); // mpid
        sqlite3_bind_text(insertStatementHandle, 12, (const char *)sqlite3_column_text(selectStatementHandle, 11), -1, SQLITE_TRANSIENT); // session_user_ids
        sqlite3_bind_blob(insertStatementHandle, 13, sqlite3_column_blob(selectStatementHandle, 12), sqlite3_column_bytes(selectStatementHandle, 12), SQLITE_TRANSIENT); // app_info
        sqlite3_bind_blob(insertStatementHandle, 14, sqlite3_column_blob(selectStatementHandle, 13), sqlite3_column_bytes(selectStatementHandle, 13), SQLITE_TRANSIENT); // device_info
        
        sqlite3_step(insertStatementHandle);
        sqlite3_reset(insertStatementHandle);
    }
    
    sqlite3_finalize(selectStatementHandle);
    sqlite3_finalize(insertStatementHandle);
}

- (void)migrateMessagesFromDatabase:(sqlite3 *)oldDatabase toDatabase:(sqlite3 *)newDatabase {
    // v30 schema: message_type, session_id, uuid, timestamp, message_data, upload_status, data_plan_id, data_plan_version, mpid
    // v31 schema: same as v30
    const char *selectStatement = "SELECT message_type, session_id, uuid, timestamp, message_data, upload_status, data_plan_id, data_plan_version, mpid FROM messages ORDER BY _id";
    const char *insertStatement = "INSERT INTO messages (message_type, session_id, uuid, timestamp, message_data, upload_status, data_plan_id, data_plan_version, mpid) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
    
    sqlite3_stmt *selectStatementHandle, *insertStatementHandle;
    sqlite3_prepare_v2(oldDatabase, selectStatement, -1, &selectStatementHandle, NULL);
    sqlite3_prepare_v2(newDatabase, insertStatement, -1, &insertStatementHandle, NULL);

    while (sqlite3_step(selectStatementHandle) == SQLITE_ROW) {
        sqlite3_bind_text(insertStatementHandle, 1, (const char *)sqlite3_column_text(selectStatementHandle, 0), -1, SQLITE_TRANSIENT); // message_type
        
        int64_t sessionId = sqlite3_column_int64(selectStatementHandle, 1);
        if (sessionId != 0) {
            sqlite3_bind_int64(insertStatementHandle, 2, sessionId);
        } else {
            sqlite3_bind_null(insertStatementHandle, 2);
        }
        
        sqlite3_bind_text(insertStatementHandle, 3, (const char *)sqlite3_column_text(selectStatementHandle, 2), -1, SQLITE_TRANSIENT); // uuid
        sqlite3_bind_double(insertStatementHandle, 4, sqlite3_column_double(selectStatementHandle, 3)); // timestamp
        
        NSString *messageString = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(selectStatementHandle, 4)];
        NSData *messageData = [messageString dataUsingEncoding:NSUTF8StringEncoding];
        sqlite3_bind_blob(insertStatementHandle, 5, [messageData bytes], (int)[messageData length], SQLITE_TRANSIENT); // message_data
        
        sqlite3_bind_int(insertStatementHandle, 6, sqlite3_column_int(selectStatementHandle, 5)); // upload_status
        
        const char *dataPlanId = (const char *)sqlite3_column_text(selectStatementHandle, 6);
        if (dataPlanId != nil && (dataPlanId[0] != '\0')) {
            sqlite3_bind_text(insertStatementHandle, 7, dataPlanId, -1, SQLITE_TRANSIENT);
        } else {
            sqlite3_bind_null(insertStatementHandle, 7);
        }
        
        int64_t dataPlanVersion = sqlite3_column_int64(selectStatementHandle, 7);
        if (dataPlanVersion != 0) {
            sqlite3_bind_int64(insertStatementHandle, 8, dataPlanVersion);
        } else {
            sqlite3_bind_null(insertStatementHandle, 8);
        }
        
        sqlite3_bind_int64(insertStatementHandle, 9, sqlite3_column_int64(selectStatementHandle, 8)); // mpid
        
        sqlite3_step(insertStatementHandle);
        sqlite3_reset(insertStatementHandle);
    }
    
    sqlite3_finalize(selectStatementHandle);
    sqlite3_finalize(insertStatementHandle);
}

- (void)migrateUploadsFromDatabase:(sqlite3 *)oldDatabase toDatabase:(sqlite3 *)newDatabase {
    // v30 schema: uuid, message_data, timestamp, session_id, upload_type, data_plan_id, data_plan_version
    // v31 schema: adds upload_settings
    const char *selectStatement = "SELECT uuid, message_data, timestamp, session_id, upload_type, data_plan_id, data_plan_version FROM uploads ORDER BY _id";
    const char *insertStatement = "INSERT INTO uploads (uuid, message_data, timestamp, session_id, upload_type, data_plan_id, data_plan_version, upload_settings) VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
    
    sqlite3_stmt *selectStatementHandle, *insertStatementHandle;
    sqlite3_prepare_v2(oldDatabase, selectStatement, -1, &selectStatementHandle, NULL);
    sqlite3_prepare_v2(newDatabase, insertStatement, -1, &insertStatementHandle, NULL);
    
    // Create current upload settings to use for migrated uploads
    MPUploadSettings *uploadSettings = [MPUploadSettings currentUploadSettingsWithStateMachine:[MParticle sharedInstance].stateMachine networkOptions:[MParticle sharedInstance].networkOptions];
    
    while (sqlite3_step(selectStatementHandle) == SQLITE_ROW) {
        sqlite3_bind_text(insertStatementHandle, 1, (const char *)sqlite3_column_text(selectStatementHandle, 0), -1, SQLITE_TRANSIENT); // uuid
        
        NSString *messageString = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(selectStatementHandle, 1)];
        NSData *messageData = [messageString dataUsingEncoding:NSUTF8StringEncoding];
        sqlite3_bind_blob(insertStatementHandle, 2, [messageData bytes], (int)[messageData length], SQLITE_TRANSIENT); // message_data
        
        sqlite3_bind_double(insertStatementHandle, 3, sqlite3_column_double(selectStatementHandle, 2)); // timestamp
        
        int64_t sessionId = sqlite3_column_int64(selectStatementHandle, 3);
        if (sessionId != 0) {
            sqlite3_bind_int64(insertStatementHandle, 4, sessionId);
        } else {
            sqlite3_bind_null(insertStatementHandle, 4);
        }
        
        sqlite3_bind_int64(insertStatementHandle, 5, sqlite3_column_int64(selectStatementHandle, 4)); // upload_type
        
        const char *dataPlanId = (const char *)sqlite3_column_text(selectStatementHandle, 5);
        if (dataPlanId != nil && (dataPlanId[0] != '\0')) {
            sqlite3_bind_text(insertStatementHandle, 6, dataPlanId, -1, SQLITE_TRANSIENT);
        } else {
            sqlite3_bind_null(insertStatementHandle, 6);
        }
        
        int64_t dataPlanVersion = sqlite3_column_int64(selectStatementHandle, 6);
        if (dataPlanVersion != 0) {
            sqlite3_bind_int64(insertStatementHandle, 7, dataPlanVersion);
        } else {
            sqlite3_bind_null(insertStatementHandle, 7);
        }
        
        // Add upload_settings (new in v31)
        NSError *error;
        NSData *uploadSettingsData = [NSKeyedArchiver archivedDataWithRootObject:uploadSettings requiringSecureCoding:YES error:&error];
        if (error != nil) {
            MPILogError(@"Error while migrating upload record: %ld: %@", error.code, error.localizedDescription);
            sqlite3_reset(insertStatementHandle);
            continue;
        }
        sqlite3_bind_blob(insertStatementHandle, 8, uploadSettingsData.bytes, (int)uploadSettingsData.length, SQLITE_TRANSIENT);
        
        sqlite3_step(insertStatementHandle);
        sqlite3_reset(insertStatementHandle);
    }
    
    sqlite3_finalize(selectStatementHandle);
    sqlite3_finalize(insertStatementHandle);
}

- (void)migrateForwardingRecordsFromDatabase:(sqlite3 *)oldDatabase toDatabase:(sqlite3 *)newDatabase {
    // v30 and v31 schema are identical
    const char *selectStatement = "SELECT _id, forwarding_data, mpid FROM forwarding_records";
    const char *insertStatement = "INSERT INTO forwarding_records (_id, forwarding_data, mpid) VALUES (?, ?, ?)";
    
    sqlite3_stmt *selectStatementHandle, *insertStatementHandle;
    sqlite3_prepare_v2(oldDatabase, selectStatement, -1, &selectStatementHandle, NULL);
    sqlite3_prepare_v2(newDatabase, insertStatement, -1, &insertStatementHandle, NULL);
    
    while (sqlite3_step(selectStatementHandle) == SQLITE_ROW) {
        sqlite3_bind_int(insertStatementHandle, 1, sqlite3_column_int(selectStatementHandle, 0));
        sqlite3_bind_blob(insertStatementHandle, 2, sqlite3_column_blob(selectStatementHandle, 1), sqlite3_column_bytes(selectStatementHandle, 1), SQLITE_TRANSIENT);
        sqlite3_bind_int64(insertStatementHandle, 3, sqlite3_column_int64(selectStatementHandle, 2));
        sqlite3_step(insertStatementHandle);
        sqlite3_reset(insertStatementHandle);
    }
    
    sqlite3_finalize(selectStatementHandle);
    sqlite3_finalize(insertStatementHandle);
}

- (void)migrateConsumerInfoFromDatabase:(sqlite3 *)oldDatabase toDatabase:(sqlite3 *)newDatabase {
    // Consumer Info - v30 and v31 schema are identical
    const char *selectStatement = "SELECT _id, mpid, unique_identifier FROM consumer_info";
    const char *insertStatement = "INSERT INTO consumer_info (_id, mpid, unique_identifier) VALUES (?, ?, ?)";
    
    sqlite3_stmt *selectStatementHandle = NULL;
    sqlite3_stmt *insertStatementHandle = NULL;
    
    sqlite3_prepare_v2(oldDatabase, selectStatement, -1, &selectStatementHandle, NULL);
    sqlite3_prepare_v2(newDatabase, insertStatement, -1, &insertStatementHandle, NULL);
    
    while (sqlite3_step(selectStatementHandle) == SQLITE_ROW) {
        sqlite3_bind_int(insertStatementHandle, 1, sqlite3_column_int(selectStatementHandle, 0));
        sqlite3_bind_int64(insertStatementHandle, 2, sqlite3_column_int64(selectStatementHandle, 1));
        sqlite3_bind_text(insertStatementHandle, 3, (const char *)sqlite3_column_text(selectStatementHandle, 2), -1, SQLITE_TRANSIENT);
        sqlite3_step(insertStatementHandle);
        sqlite3_reset(insertStatementHandle);
    }
    
    sqlite3_finalize(selectStatementHandle);
    sqlite3_finalize(insertStatementHandle);
    
    // Cookies - v30 and v31 schema are identical
    selectStatement = "SELECT _id, consumer_info_id, content, domain, expiration, name, mpid FROM cookies";
    insertStatement = "INSERT INTO cookies (_id, consumer_info_id, content, domain, expiration, name, mpid) VALUES (?, ?, ?, ?, ?, ?, ?)";
    
    sqlite3_prepare_v2(oldDatabase, selectStatement, -1, &selectStatementHandle, NULL);
    sqlite3_prepare_v2(newDatabase, insertStatement, -1, &insertStatementHandle, NULL);
    
    while (sqlite3_step(selectStatementHandle) == SQLITE_ROW) {
        sqlite3_bind_int(insertStatementHandle, 1, sqlite3_column_int(selectStatementHandle, 0));
        sqlite3_bind_int(insertStatementHandle, 2, sqlite3_column_int(selectStatementHandle, 1));
        sqlite3_bind_text(insertStatementHandle, 3, (const char *)sqlite3_column_text(selectStatementHandle, 2), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatementHandle, 4, (const char *)sqlite3_column_text(selectStatementHandle, 3), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatementHandle, 5, (const char *)sqlite3_column_text(selectStatementHandle, 4), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatementHandle, 6, (const char *)sqlite3_column_text(selectStatementHandle, 5), -1, SQLITE_TRANSIENT);
        sqlite3_bind_int64(insertStatementHandle, 7, sqlite3_column_int64(selectStatementHandle, 6));
        sqlite3_step(insertStatementHandle);
        sqlite3_reset(insertStatementHandle);
    }
    
    sqlite3_finalize(selectStatementHandle);
    sqlite3_finalize(insertStatementHandle);
}

- (void)migrateIntegrationAttributesFromDatabase:(sqlite3 *)oldDatabase toDatabase:(sqlite3 *)newDatabase {
    // v30 and v31 schema are identical
    const char *selectStatement = "SELECT _id, kit_code, attributes_data FROM integration_attributes";
    const char *insertStatement = "INSERT INTO integration_attributes (_id, kit_code, attributes_data) VALUES (?, ?, ?)";
    
    sqlite3_stmt *selectStatementHandle, *insertStatementHandle;
    sqlite3_prepare_v2(oldDatabase, selectStatement, -1, &selectStatementHandle, NULL);
    sqlite3_prepare_v2(newDatabase, insertStatement, -1, &insertStatementHandle, NULL);
    
    while (sqlite3_step(selectStatementHandle) == SQLITE_ROW) {
        sqlite3_bind_int(insertStatementHandle, 1, sqlite3_column_int(selectStatementHandle, 0));
        sqlite3_bind_int(insertStatementHandle, 2, sqlite3_column_int(selectStatementHandle, 1));
        sqlite3_bind_blob(insertStatementHandle, 3, sqlite3_column_blob(selectStatementHandle, 2), sqlite3_column_bytes(selectStatementHandle, 2), SQLITE_TRANSIENT);
        sqlite3_step(insertStatementHandle);
        sqlite3_reset(insertStatementHandle);
    }
    
    sqlite3_finalize(selectStatementHandle);
    sqlite3_finalize(insertStatementHandle);
}

#pragma mark Public methods

- (void)migrateDatabaseFromVersion:(NSNumber *)oldVersion {
    [self migrateDatabaseFromVersion:oldVersion deleteDbFile:YES];
}

- (void)migrateDatabaseFromVersion:(NSNumber *)oldVersion deleteDbFile:(BOOL)deleteDbFile {
    NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSNumber *currentDatabaseVersion = [self.databaseVersions lastObject];
    NSString *databaseName = [NSString stringWithFormat:@"mParticle%@.db", currentDatabaseVersion];
    NSString *databasePath = [documentsDirectory stringByAppendingPathComponent:databaseName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    sqlite3 *oldmParticleDB;
    sqlite3 *mParticleDB;
    NSString *dbPath;
    
    if (sqlite3_open_v2([databasePath UTF8String], &mParticleDB, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FILEPROTECTION_NONE | SQLITE_OPEN_FULLMUTEX, NULL) != SQLITE_OK) {
        return;
    }
    
    databaseName = [NSString stringWithFormat:@"mParticle%@.db", oldVersion];
    dbPath = [documentsDirectory stringByAppendingPathComponent:databaseName];
    
    if (![fileManager fileExistsAtPath:dbPath] || (sqlite3_open_v2([dbPath UTF8String], &oldmParticleDB, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FILEPROTECTION_NONE | SQLITE_OPEN_FULLMUTEX, NULL) != SQLITE_OK)) {
        sqlite3_close(mParticleDB);
        return;
    }
    
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    [self deleteRecordsOlderThan:(currentTime - SEVEN_DAYS) fromDatabase:oldmParticleDB];
    [self migrateConsumerInfoFromDatabase:oldmParticleDB toDatabase:mParticleDB];
    [self migrateSessionsFromDatabase:oldmParticleDB toDatabase:mParticleDB];
    [self migrateMessagesFromDatabase:oldmParticleDB toDatabase:mParticleDB];
    [self migrateUploadsFromDatabase:oldmParticleDB toDatabase:mParticleDB];
    [self migrateForwardingRecordsFromDatabase:oldmParticleDB toDatabase:mParticleDB];
    [self migrateIntegrationAttributesFromDatabase:oldmParticleDB toDatabase:mParticleDB];

    sqlite3_close(oldmParticleDB);
    if (deleteDbFile) {
        [fileManager removeItemAtPath:dbPath error:nil];
    }
    sqlite3_close(mParticleDB);
}

- (NSNumber *)needsMigration {
    NSMutableArray *oldDatabaseVersions = [self.databaseVersions mutableCopy];
    [oldDatabaseVersions removeLastObject];
    
    if (oldDatabaseVersions.count == 0) {
        return nil;
    }
    
    NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // Only check for v30 database (the only version we migrate from)
    NSNumber *databaseVersion = oldDatabaseVersions[0];
    NSString *databaseName = [NSString stringWithFormat:@"mParticle%@.db", databaseVersion];
    NSString *dbPath = [documentsDirectory stringByAppendingPathComponent:databaseName];
    
    if ([fileManager fileExistsAtPath:dbPath]) {
        return databaseVersion;
    }
    
    return nil;
}

@end
