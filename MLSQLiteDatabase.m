/*
 
 Copyright (c) 2013 Max Lungarella <cybrmx@gmail.com>
 
 Created on 24/08/2013.
 
 This file is part of AMiKoOSX.
 
 AmiKoOSX is free software: you can redistribute it and/or modify
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

@implementation MLSQLiteDatabase
{
    // Instance variable declarations go here
    sqlite3 *database;
}

/** Class functions
*/
#pragma mark Class functions

+ (void) createEditableCopyOfDatabaseIfNeeded: (NSString *)dbName
{
    // Create NSFileManager object to check the status of the database and to copy it if required
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // Get documents directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [paths objectAtIndex:0];
    // Returns a new string made by appending to the receiver a given string
    NSString *dbPath = [documentsDir stringByAppendingPathComponent:dbName];
    // Check if the database has already been created at specified path
    BOOL success = [fileManager fileExistsAtPath:dbPath];

	if (success) {
	    NSError *error;
        // Get the path to the database in the application package
		NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:dbName];
        // Copy the database from the package to the users filesystem
		success = [fileManager copyItemAtPath:defaultDBPath toPath:dbPath error:&error];
		
		if (!success)
			NSLog(@"%s Failed to create writable database file with message '%@'.", __FUNCTION__, [error localizedDescription]);
	}
}

/** Instance functions
*/
#pragma mark Instance functions

- (void) dealloc
{
    //
}

- (id) initWithPath: (NSString *)path
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
        
        if (sqlite3_open([path UTF8String], &dbConnection) != SQLITE_OK) {
            NSLog(@"%s Unable to open database!", __FUNCTION__);
            return nil;
        }
        database = dbConnection;
        // Force using disk for temp storage to reduce memory footprint
        sqlite3_exec(database, "PRAGMA temp_store=1", nil, nil, nil);
    }
    return self;
}

- (NSInteger) numberRecordsForTable: (NSString *)table
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

- (NSArray *) performQuery: (NSString *)query
{
    sqlite3_stmt *compiledStatement = nil;
    // Convert NSString to a C String
    const char *sql = [query UTF8String];
    
    // Open database from users filesystem
    if (sqlite3_prepare_v2(database, sql, -1, &compiledStatement, nil) != SQLITE_OK) {
        NSLog(@"%s Error when preparing query!", __FUNCTION__);
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

- (void) close
{
    sqlite3_close(database);
}

@end
