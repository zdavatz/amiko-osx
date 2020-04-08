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

#import "LegacyPatientDBAdapter.h"

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

@implementation LegacyPatientDBAdapter
{
    MLSQLiteDatabase *myPatientDb;
}

/** Class function
 */
#pragma mark Class functions

+ (LegacyPatientDBAdapter *)sharedInstance
{
    NSLog(@"%s", __FUNCTION__);
    __strong static id sharedObject = nil;
    
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        sharedObject = [[self alloc] init];
        
        if (![sharedObject openDatabase]) {
            NSLog(@"Could not open patient DB!");
            sharedObject = nil;
        }
        
    });
    return sharedObject;
}

+ (void) initialize
{
    if (self == [LegacyPatientDBAdapter class]) {
        if (ALL_COLUMNS == nil) {
            ALL_COLUMNS = [NSString stringWithFormat: @"%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@", KEY_ROWID, KEY_TIMESTAMP, KEY_UID, KEY_FAMILYNAME, KEY_GIVENNAME, KEY_BIRTHDATE, KEY_GENDER, KEY_WEIGHT_KG, KEY_HEIGHT_CM, KEY_ZIPCODE, KEY_CITY, KEY_COUNTRY, KEY_ADDRESS, KEY_PHONE, KEY_EMAIL];
        }
    }
}

/** Instance functions
 */
#pragma mark Instance functions

- (BOOL) openDatabase
{
    if (myPatientDb == nil) {
        // Patient DB should be in the user's documents folder
        NSFileManager *fileManager = [NSFileManager defaultManager];
        // Get documents directory
        NSString *filePath = [self dbPath];
        // Check if database exists
        if (filePath!=nil) {
            // Load database if it exists already
            if ([fileManager fileExistsAtPath:filePath]) {
                NSLog(@"Patient DB found in user's documents folder %@", filePath);
                myPatientDb = [[MLSQLiteDatabase alloc] initReadWriteWithPath:filePath];
                return TRUE;
            }
        }
    }
    return FALSE;
}

- (NSString *)dbPath {
    NSString *documentsDir = [MLUtilities documentsDirectory];
    return [documentsDir stringByAppendingPathComponent:@"patient_db.db"];
}

- (void) closeDatabase
{
    // The database is open as long as the app is open
    if (myPatientDb)
        [myPatientDb close];
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

- (MLPatient *) cursorToPatient:(NSArray *)cursor
{
    MLPatient *patient = [[MLPatient alloc] init];

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
