/*
 
 Copyright (c) 2013 Max Lungarella <cybrmx@gmail.com>
 
 Created on 24/08/2013.
 
 This file is part of AmiKo for OSX.
 
 AmiKo for OSX is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.
 
 ------------------------------------------------------------------------ */

#import "MLSQLiteDatabase.h"
#import "MLUtilities.h"

@implementation MLSQLiteDatabase
{
    // Instance variable declarations go here
    sqlite3 *database;
    dispatch_queue_t dbQueue;
}

/** Class functions
*/
#pragma mark class functions

+ (void) createEditableCopyOfDatabaseIfNeeded:(NSString *)dbName
{
    // Create NSFileManager object to check the status of the database and to copy it if required
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // Get documents directory
    NSString *documentsDir = [MLUtilities documentsDirectory];
    // Returns a new string made by appending to the receiver a given string
    NSString *writableDBPath = [documentsDir stringByAppendingPathComponent:dbName];
    // Check if the database has already been created at specified path
    BOOL success = [fileManager fileExistsAtPath:writableDBPath];
    // If the file exists, do nothing...
	if (success)
        return;

    NSError *error;
    // Get the path to the database in the application package
	NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:dbName];
    // Copy the database from the package to the users filesystem
	success = [fileManager copyItemAtPath:defaultDBPath toPath:writableDBPath error:&error];
	if (!success)
		NSLog(@"%s Failed to create writable database file with message '%@'.", __FUNCTION__, [error localizedDescription]);
}

/** Instance functions
*/
#pragma mark public methods

- (void) dealloc
{
}

- (id) initReadOnlyWithPath:(NSString *)path
{
    return [self initReadOnlyWithPath:path andQueue:nil];
}
- (id) initReadOnlyWithPath:(NSString *)path andQueue:(dispatch_queue_t)queue
{
    if (self = [super init]) {
        // Setup database object
        sqlite3 *dbConnection;
        // Open database from users filesystem
        NSFileManager *fileMgr = [[NSFileManager alloc] init];
        
        NSArray *content = [fileMgr contentsOfDirectoryAtPath:path error:nil];
        for (NSString *p in content) {
            NSLog(@"%@\n", p);
        }
        
        int rc;
        rc = sqlite3_open_v2([path UTF8String], &dbConnection, SQLITE_OPEN_READONLY, NULL);
        if (rc != SQLITE_OK) {
            NSLog(@"%s Unable to open database!", __FUNCTION__);
            return nil;
        }
        database = dbConnection;
        // Force using disk for temp storage to reduce memory footprint
        rc = sqlite3_exec(database, "PRAGMA temp_store=1", nil, nil, nil);
        if (rc != SQLITE_OK)
            NSLog(@"%s:%i, rc %d", __FUNCTION__, __LINE__, rc);
        
        dbQueue = queue;
    }

    return self;
}

- (id) initReadWriteWithPath:(NSString *)path
{
    if (self = [super init]) {
        // Setup database object
        sqlite3 *dbConnection;
        // Open database from user's filesystem
        NSFileManager *fileMgr = [[NSFileManager alloc] init];
        
        NSArray *content = [fileMgr contentsOfDirectoryAtPath:path error:nil];
        for (NSString *p in content) {
            NSLog(@"%@\n", p);
        }
        
        // Let's open it in read write mode
        if (sqlite3_open([path UTF8String], &dbConnection) != SQLITE_OK) {
            NSLog(@"%s Unable to open read/write database!", __FUNCTION__);
            return nil;
        }
        database = dbConnection;
        // Force using disk for temp storage to reduce memory footprint
        sqlite3_exec(database, "PRAGMA temp_store=1", nil, nil, nil);
        
        dbQueue = nil;
    }
    return self;
}

- (BOOL) createWithPath:(NSString *)path
               andTable:(NSString *)table
             andColumns:(NSString *)columns
{
    NSFileManager *fileMgr = [[NSFileManager alloc] init];
    
    if (![fileMgr fileExistsAtPath:path]) {
        // Setup database object
        sqlite3 *dbConnection;
        // Database does not exist yet. Let's open and create an empty table
        if (sqlite3_open([path UTF8String], &dbConnection) == SQLITE_OK) {
            NSString *queryStr = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ %@", table, columns];
            if (sqlite3_exec(dbConnection, [queryStr UTF8String], NULL, NULL, NULL) == SQLITE_OK) {
                NSLog(@"%@ table created successfully...", table);
                database = dbConnection;
            }
            else {
                NSLog(@"Failed to create table %@ for database with path %@", table, path);
                return FALSE;
            }
        }
        else {
            NSLog(@"Failed to create database with path %@", path);
            return FALSE;
        }
    }
    return TRUE;
}

- (NSInteger) numberRecordsForTable:(NSString *)table
{
    NSInteger numTableRecords = -1;
    sqlite3_stmt *sqlClause = nil;
    
    NSString *sqlStatement = [NSString stringWithFormat: @"SELECT COUNT(*) FROM %@", table];
    const char *sql = [sqlStatement UTF8String];
    if (sqlite3_prepare_v2(database, sql, -1, &sqlClause, NULL) == SQLITE_OK) {
        while(sqlite3_step(sqlClause) == SQLITE_ROW) {
            numTableRecords = sqlite3_column_int(sqlClause, 0);
        }
    }
    else {
        NSLog(@"%s Could not prepare statement: %s", __FUNCTION__, sqlite3_errmsg(database));
    }
    return numTableRecords;
}

- (NSArray *) performQuery:(NSString *)query
{
    if (dbQueue != nil && [NSThread isMainThread]) {
        __block NSArray *result = nil;
        dispatch_sync(dbQueue, ^{
            result = [self performQueryInQueue:query];
        });
        return result;
    }
    return [self performQueryInQueue:query];
}
- (NSArray *) performQueryInQueue:(NSString *)query
{
    sqlite3_stmt *compiledStatement = nil;
    // Convert NSString to a C String
    const char *sql = [query UTF8String];
    
    int error_code = SQLITE_OK;
    // Open database from users filesystem
    if ( (error_code=sqlite3_prepare_v2(database, sql, -1, &compiledStatement, nil)) != SQLITE_OK) {
        NSLog(@"%s Error with code %d when preparing query!", __FUNCTION__, error_code);
    } else {
        NSMutableArray *result = [NSMutableArray array];
        @autoreleasepool {
            // Loop through results and add them to feeds array
            while (sqlite3_step(compiledStatement) == SQLITE_ROW) {
                NSMutableArray *row = [NSMutableArray array];     
                for (int i=0; i<sqlite3_column_count(compiledStatement); i++) {
                    int colType = sqlite3_column_type(compiledStatement, i);
                    id value;
                    if (colType == SQLITE_TEXT) {
                        const char *col = (const char *)sqlite3_column_text(compiledStatement, i);
                        value = [[NSString alloc] initWithUTF8String:col];
                    } else if (colType == SQLITE_INTEGER) {
                        int col = sqlite3_column_int(compiledStatement, i);
                        value = [NSNumber numberWithInt:col];
                    } else if (colType == SQLITE_FLOAT) {
                        double col = sqlite3_column_double(compiledStatement, i);
                        value = [NSNumber numberWithDouble:col];
                    } else if (colType == SQLITE_NULL) {
                        value = [NSNull null];
                    } else {
                        NSLog(@"%s Unknown data type.", __FUNCTION__);
                    }
                    // Add value to row
                    [row addObject:value];
                    value = nil;
                }
                // Add row to array
                [result addObject:row];
            }
            // Reset statement (not necessary)
            sqlite3_reset(compiledStatement);
            // Release compiled statement from memory
            sqlite3_finalize(compiledStatement);
        }
        return result;
    }
    return nil;
}

- (BOOL) insertRowIntoTable:(NSString *)table forColumns:(NSString *)columns andValues:(NSString *)values
{
    char *errMsg;
    NSString *query = [NSString stringWithFormat:@"insert into %@ %@ values %@", table, columns, values];
    if (sqlite3_exec(database, [query UTF8String], NULL, NULL, &errMsg) != SQLITE_OK) {
        NSLog(@"Failed to insert record into table %@ with query %@: %s", table, query, errMsg);
        return FALSE;
    }
    return TRUE;
}

- (BOOL) updateRowIntoTable:(NSString *)table forExpressions:(NSString *)expressions andConditions:(NSString *)conditions
{
    char *errMsg;
    NSString *query = [NSString stringWithFormat:@"update %@ set %@ where %@", table, expressions, conditions];
    if (sqlite3_exec(database, [query UTF8String], NULL, NULL, &errMsg) != SQLITE_OK) {
        NSLog(@"Failed to replace record into table %@ with query %@: %s", table, query, errMsg);
        return FALSE;
    }
    return TRUE;
}

- (BOOL) deleteRowFromTable:(NSString *)table withRowId:(long)rowId
{
    char *errMsg;
    NSString *query = [NSString stringWithFormat:@"delete from %@ where rowId=%ld", table, rowId];
    if (sqlite3_exec(database, [query UTF8String], NULL, NULL, &errMsg) != SQLITE_OK) {
        NSLog(@"Failed to delete record from db: %s", errMsg);
        return FALSE;
    }
    return TRUE;
}

- (BOOL) deleteRowFromTable:(NSString *)table withUId:(NSString *)uId
{
    char *errMsg;
    NSString *query = [NSString stringWithFormat:@"delete from %@ where uid='%@'", table, uId];
    if (sqlite3_exec(database, [query UTF8String], NULL, NULL, &errMsg) != SQLITE_OK) {
        NSLog(@"Failed to delete record from db: %s", errMsg);
        return FALSE;
    }
    return TRUE;
}

- (void) close
{
    sqlite3_close(database);
}

@end
