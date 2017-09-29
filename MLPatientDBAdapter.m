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
static NSString *KEY_TIMESTAMP = @"time_stamp";
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
static NSString *ALL_COLUMNS = nil;
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
        if (ALL_COLUMNS == nil) {
            ALL_COLUMNS = [NSString stringWithFormat: @"%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@", KEY_ROWID, KEY_TIMESTAMP, KEY_UID, KEY_FAMILYNAME, KEY_GIVENNAME, KEY_BIRTHDATE, KEY_GENDER, KEY_WEIGHT_KG, KEY_HEIGHT_CM, KEY_ZIPCODE, KEY_CITY, KEY_COUNTRY, KEY_ADDRESS, KEY_PHONE, KEY_EMAIL];
        }
        if (DATABASE_COLUMNS == nil) {
            DATABASE_COLUMNS = [NSString stringWithFormat: @"(%@ INTEGER, %@ TEXT, %@ TEXT, %@ TEXT, %@ TEXT, %@ TEXT, %@ TEXT, %@ INTEGER, %@ INTEGER, %@ TEXT, %@ TEXT, %@ TEXT, %@ TEXT, %@ TEXT, %@ TEXT)", KEY_ROWID, KEY_TIMESTAMP, KEY_UID, KEY_FAMILYNAME, KEY_GIVENNAME, KEY_BIRTHDATE, KEY_GENDER, KEY_WEIGHT_KG, KEY_HEIGHT_CM, KEY_ZIPCODE, KEY_CITY, KEY_COUNTRY, KEY_ADDRESS, KEY_PHONE, KEY_EMAIL];
        }
    }
}

/** Instance functions
 */
#pragma mark Instance functions

- (BOOL) openDatabase:(NSString *)dbName
{   
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

- (NSString *) addEntry:(MLPatient *)patient
{
    if (myPatientDb) {
        // Patient entry does not exist (yet)
        NSString *uuidStr = [patient generateUniqueID];    // e.g. 3466684318797166812
        NSString *timeStr = [MLUtilities currentTime];
        NSString *columnStr = [NSString stringWithFormat:@"(%@)", ALL_COLUMNS];
        NSString *valueStr = [NSString stringWithFormat:@"(%ld, \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", %d, %d, \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\")", patient.rowId, timeStr, uuidStr, patient.familyName, patient.givenName, patient.birthDate, patient.gender, patient.weightKg, patient.heightCm, patient.zipCode, patient.city, patient.country, patient.postalAddress, patient.phoneNumber, patient.emailAddress];
        // Insert new entry into DB
        [myPatientDb insertRowIntoTable:@"patients" forColumns:columnStr andValues:valueStr];
        return uuidStr;
    }
    return nil;
}

- (NSString *) insertEntry:(MLPatient *)patient
{
    if (myPatientDb) {
        // If UUID exist re-use it!
        if (patient.uniqueId!=nil && [patient.uniqueId length]>0) {
            NSString *expressions = [NSString stringWithFormat:@"%@=%d, %@=%d, %@=\"%@\", %@=\"%@\", %@=\"%@\", %@=\"%@\", %@=\"%@\", %@=\"%@\", %@=\"%@\"", KEY_WEIGHT_KG, patient.weightKg, KEY_HEIGHT_CM, patient.heightCm, KEY_ZIPCODE, patient.zipCode, KEY_CITY, patient.city, KEY_COUNTRY, patient.country, KEY_ADDRESS, patient.postalAddress, KEY_PHONE, patient.phoneNumber, KEY_EMAIL, patient.emailAddress, KEY_GENDER, patient.gender];
            NSString *conditions = [NSString stringWithFormat:@"%@=\"%@\"", KEY_UID, patient.uniqueId];
            // Update existing entry
            [myPatientDb updateRowIntoTable:@"patients" forExpressions:expressions andConditions:conditions];
            return patient.uniqueId;
        } else {
            return [self addEntry:patient];
        }
    }
    return nil;
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
        [myPatientDb deleteRowFromTable:@"patients" withRowId:patient.rowId];
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

- (NSArray *) getAllPatients
{
    NSMutableArray *listOfPatients = [NSMutableArray array];
    
    NSString *query = [NSString stringWithFormat:@"select %@ from %@", ALL_COLUMNS, DATABASE_TABLE];
    NSArray *results = [myPatientDb performQuery:query];
    if ([results count]>0) {
        for (NSArray *cursor in results) {
            [listOfPatients addObject:[self cursorToPatient:cursor]];
        }
        // Sort alphabetically
        NSSortDescriptor *nameSort = [NSSortDescriptor sortDescriptorWithKey:@"familyName" ascending:YES];
        [listOfPatients sortUsingDescriptors:[NSArray arrayWithObject:nameSort]];
    }
    
    return listOfPatients;
}
- (NSArray *) getPatientsWithKey:(NSString *)key
{
    NSMutableArray *listOfPatients = [NSMutableArray array];

    NSArray *searchKeys = [key componentsSeparatedByString:@" "];
    if ([searchKeys count]>0) {
        /*
         NSString *query = [NSString stringWithFormat:@"select %@ from %@ where %@ like '%@%%' or %@ like '%@%%' or %@ like '%@%%' or %@ like '%@%%'", ALL_COLUMNS, DATABASE_TABLE, KEY_FAMILYNAME, key, KEY_GIVENNAME, key, KEY_CITY, key, KEY_ZIPCODE, key];
         */
        NSMutableString *wq = [[NSMutableString alloc] init];
        for (NSString *k in searchKeys) {
            if ([k length]>0) {
                NSString *q = [NSString stringWithFormat:@"(%@ like '%@%%' or %@ like '%@%%' or %@ like '%@%%' or %@ like '%@%%') and ", KEY_FAMILYNAME, k, KEY_GIVENNAME, k, KEY_CITY, k, KEY_ZIPCODE, k];
                [wq appendString:q];
            }
        }
        if ([wq length]>5) {
            NSString *whereQuery = [wq substringToIndex:[wq length]-5];
            NSString *query = [NSString stringWithFormat:@"select %@ from %@ where %@", ALL_COLUMNS, DATABASE_TABLE, whereQuery];
            NSArray *results = [myPatientDb performQuery:query];
            if ([results count]>0) {
                for (NSArray *cursor in results) {
                    [listOfPatients addObject:[self cursorToPatient:cursor]];
                }
            }
        }
    }
    
    return listOfPatients;
}

- (MLPatient *) getPatientWithUniqueID:(NSString *)uniqueID
{
    if (uniqueID!=nil) {
        NSString *query = [NSString stringWithFormat:@"select %@ from %@ where %@ like '%@'", ALL_COLUMNS, DATABASE_TABLE, KEY_UID, uniqueID];
        NSArray *results = [myPatientDb performQuery:query];
        if ([results count]>0) {
            for (NSArray *cursor in results) {
                return [self cursorToPatient:cursor];
            }
        }
    }
    return nil;
}

- (MLPatient *) cursorToPatient:(NSArray *)cursor
{
    MLPatient *patient = [[MLPatient alloc] init];
    
    patient.rowId = [[cursor objectAtIndex:0] longLongValue];
    patient.uniqueId = (NSString *)[cursor objectAtIndex:2];
    patient.familyName = (NSString *)[cursor objectAtIndex:3];
    patient.givenName = (NSString *)[cursor objectAtIndex:4];
    patient.birthDate = (NSString *)[cursor objectAtIndex:5];
    patient.gender = (NSString *)[cursor objectAtIndex:6];
    patient.weightKg = [[cursor objectAtIndex:7] intValue];
    patient.heightCm = [[cursor objectAtIndex:8] intValue];
    patient.zipCode = (NSString *)[cursor objectAtIndex:9];
    patient.city = (NSString *)[cursor objectAtIndex:10];
    patient.country = (NSString *)[cursor objectAtIndex:11];
    patient.postalAddress = (NSString *)[cursor objectAtIndex:12];
    patient.phoneNumber = (NSString *)[cursor objectAtIndex:13];
    patient.emailAddress = (NSString *)[cursor objectAtIndex:14];
    patient.databaseType = eLocal;
    
    return patient;
}

@end
