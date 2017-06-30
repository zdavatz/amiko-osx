/*
 
 Copyright (c) 2017 Max Lungarella <cybrmx@gmail.com>
 
 Created on 21/06/2017.
 
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

#import "MLPatientDBAdapter.h"
#import "MLSQLiteDatabase.h"
#import "MLUtilities.h"
#import "MLContacts.h"

static NSString *KEY_ROWID = @"_id";
static NSString *KEY_UID = @"uid";
static NSString *KEY_FAMILYNAME = @"family_name";
static NSString *KEY_GIVENNAME = @"given_name";
static NSString *KEY_BIRTHDATE = @"birthdate";
static NSString *KEY_GENDER = @"gender";
static NSString *KEY_WEIGHT_KG = @"weight_kg";
static NSString *KEY_HEIGHT_CM = @"height_cm";
static NSString *KEY_ZIPCODE = @"zip";
static NSString *KEY_CITY = @"city";
static NSString *KEY_COUNTRY = @"country";
static NSString *KEY_ADDRESS = @"address";
static NSString *KEY_PHONE = @"phone";
static NSString *KEY_EMAIL = @"email";

static NSString *DATABASE_TABLE = @"patients";

/** Table columns for fast queries
 */
static NSString *FULL_TABLE = nil;
static NSString *DATABASE_COLUMNS = nil;

@implementation MLPatientDBAdapter
{
    MLSQLiteDatabase *myPatientDb;
}

/** Class function
 */
#pragma mark Class functions

+ (void) initialize
{
    if (self == [MLPatientDBAdapter class]) {
        if (FULL_TABLE == nil) {
            FULL_TABLE = [NSString stringWithFormat: @"%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@", KEY_ROWID, KEY_UID, KEY_FAMILYNAME, KEY_GIVENNAME, KEY_BIRTHDATE, KEY_GENDER, KEY_WEIGHT_KG, KEY_HEIGHT_CM, KEY_ZIPCODE, KEY_CITY, KEY_COUNTRY, KEY_ADDRESS, KEY_PHONE, KEY_EMAIL];
        }
        if (DATABASE_COLUMNS == nil) {
            DATABASE_COLUMNS = [NSString stringWithFormat: @"(%@ INTEGER, %@ TEXT, %@ TEXT, %@ TEXT, %@ TEXT, %@ TEXT, %@ INTEGER, %@ INTEGER, %@ TEXT, %@ TEXT, %@ TEXT, %@ TEXT, %@ TEXT, %@ TEXT)", KEY_ROWID, KEY_UID, KEY_FAMILYNAME, KEY_GIVENNAME, KEY_BIRTHDATE, KEY_GENDER, KEY_WEIGHT_KG, KEY_HEIGHT_CM, KEY_ZIPCODE, KEY_CITY, KEY_COUNTRY, KEY_ADDRESS, KEY_PHONE, KEY_EMAIL];
        }
    }
}

/** Instance functions
 */
#pragma mark Instance functions

- (BOOL) openDatabase:(NSString *)dbName
{
    
    // ********************
    MLContacts *contacts = [[MLContacts alloc] init];
    [contacts getAllContacts];
    
    // ********************
    
    if (myPatientDb == nil) {
        // Patient DB should be in the user's documents folder
        NSFileManager *fileManager = [NSFileManager defaultManager];
        // Get documents directory
        NSString *documentsDir = [MLUtilities documentsDirectory];
        NSString *filePath = [[documentsDir stringByAppendingPathComponent:dbName] stringByAppendingPathExtension:@"db"];
        // Check if database exists
        if (filePath!=nil) {
            // Load database if it exists already
            if ([fileManager fileExistsAtPath:filePath]) {
                NSLog(@"Patient DB found in user's documents folder %@", filePath);
                myPatientDb = [[MLSQLiteDatabase alloc] initReadWriteWithPath:filePath];
                return TRUE;
            } else {
                NSLog(@"Patient DB NOT found in user's documents folder %@", filePath);
                if ([[MLSQLiteDatabase alloc] createWithPath:filePath andTable:DATABASE_TABLE andColumns:DATABASE_COLUMNS]) {
                    myPatientDb = [[MLSQLiteDatabase alloc] initReadWriteWithPath:filePath];
                    return TRUE;
                }
            }
        }
    }
    return FALSE;
}

- (void) closeDatabase
{
    // The database is open as long as the app is open
    if (myPatientDb)
        [myPatientDb close];
}

- (BOOL) insertEntry:(MLPatient *)patient
{
    if (myPatientDb) {
        // Creates and returns a new UUID with RFC 4122 version 4 random bytes
        NSUUID *uuid = [NSUUID UUID];
        NSString *uuidStr = [uuid UUIDString];        
        NSString *columnStr = [NSString stringWithFormat:@"(%@)", FULL_TABLE];
        NSString *valueStr = [NSString stringWithFormat:@"(%ld, \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", %d, %d, \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\")", patient.rowId, uuidStr, patient.familyName, patient.givenName, patient.birthDate, patient.gender, patient.weightKg, patient.heightCm, patient.zipCode, patient.city, patient.country, patient.address, patient.phone, patient.email];
        [myPatientDb insertRowIntoTable:@"patients" forColumns:columnStr andValues:valueStr];
        return TRUE;
    }
    return FALSE;
}

- (BOOL) modifyEntry:(MLPatient *)patient
{
    if (myPatientDb) {
        return TRUE;
    }
    return FALSE;
}

- (BOOL) deleteEntry:(MLPatient *)patient
{
    if (myPatientDb) {
        return TRUE;
    }
    return FALSE;
}

- (NSInteger) getNumPatients
{
    NSInteger numRecords = [myPatientDb numberRecordsForTable:DATABASE_TABLE];
    
    return numRecords;
}

- (long) getLargestRowId
{
    NSString *query = [NSString stringWithFormat:@"select max(%@) from %@", KEY_ROWID, DATABASE_TABLE];
    NSArray *results = [myPatientDb performQuery:query];
    if ([results count]>0) {
        if (results[0]!=nil) {
            NSString *r = (NSString *)[results[0] objectAtIndex:0];
            if (![r isEqual:[NSNull null]])
                return [r longLongValue];
        }
    }
    return 0;
}

@end
