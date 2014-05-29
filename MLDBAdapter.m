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

#import "MLDBAdapter.h"
#import "MLSQLiteDatabase.h"
#import "MLCustomURLConnection.h"

enum {
  kMedId = 0, kTitle, kAuth, kAtcCode, kSubstances, kRegnrs, kAtcClass, kTherapy, kApplication, kIndications, kCustomerId, kPackInfo, kAddInfo, kIdsStr, kSectionsStr, kContentStr, kStyleStr
};

static NSString *KEY_ROWID = @"_id";
static NSString *KEY_TITLE = @"title";
static NSString *KEY_AUTH = @"auth";
static NSString *KEY_ATCCODE = @"atc";
static NSString *KEY_SUBSTANCES = @"substances";
static NSString *KEY_REGNRS = @"regnrs";
static NSString *KEY_ATCCLASS = @"atc_class";
static NSString *KEY_THERAPY = @"tindex_str";
static NSString *KEY_APPLICATION = @"application_str";
static NSString *KEY_INDICATIONS = @"indications_str";
static NSString *KEY_CUSTOMER_ID = @"customer_id";
static NSString *KEY_PACK_INFO = @"pack_info_str";
static NSString *KEY_ADDINFO = @"add_info_str";
static NSString *KEY_IDS = @"ids_str";
static NSString *KEY_SECTIONS = @"titles_str";
static NSString *KEY_CONTENT = @"content";
static NSString *KEY_STYLE = @"style_str";

static NSString *DATABASE_TABLE = @"amikodb";

/** Table columns used for fast queries
 */
static NSString *SHORT_TABLE = nil;
static NSString *FULL_TABLE = nil;

@implementation MLDBAdapter
{
    MLSQLiteDatabase *mySqliteDb;
    NSMutableDictionary *myDrugInteractionMap;
}

/** Class functions
 */
#pragma mark Class functions

+ (void) initialize
{
    if (self == [MLDBAdapter class]) {
        if (SHORT_TABLE == nil) {
            SHORT_TABLE = [[NSString alloc] initWithFormat:@"%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@",
                           KEY_ROWID, KEY_TITLE, KEY_AUTH, KEY_ATCCODE, KEY_SUBSTANCES, KEY_REGNRS, KEY_ATCCLASS, KEY_THERAPY, KEY_APPLICATION, KEY_INDICATIONS, KEY_CUSTOMER_ID, KEY_PACK_INFO];
        }
        if (FULL_TABLE == nil) {
            FULL_TABLE = [[NSString alloc] initWithFormat:@"%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@",
                          KEY_ROWID, KEY_TITLE, KEY_AUTH, KEY_ATCCODE, KEY_SUBSTANCES, KEY_REGNRS, KEY_ATCCLASS, KEY_THERAPY, KEY_APPLICATION, KEY_INDICATIONS, KEY_CUSTOMER_ID, KEY_PACK_INFO, KEY_ADDINFO, KEY_IDS, KEY_SECTIONS, KEY_CONTENT, KEY_STYLE];
        }
    }
}

/** Instance functions
 */
#pragma mark Instance functions

- (BOOL) openInteractionsCsvFile:(NSString *)name
{    
    // ** A. Check first users documents folder
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // Get documents directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [paths lastObject];
    NSString *filePath = [[documentsDir stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"csv"];
    // Check if database exists
    if (filePath!=nil) {
        if ([fileManager fileExistsAtPath:filePath]) {
            NSLog(@"Drug interactions csv found documents folder - %@", filePath);
            return [self readDrugInteractionMap:filePath];
        }
    }
    
    // ** B. If no database is available, check if db is in app bundle
    filePath = [[NSBundle mainBundle] pathForResource:name ofType:@"csv"];
    if (filePath!=nil ) {
        NSLog(@"Drug interactions csv found in app bundle - %@", filePath);
        // Read drug interactions csv line after line
        return [self readDrugInteractionMap:filePath];
    }
    
    return FALSE;
}

- (BOOL) readDrugInteractionMap:(NSString *)filePath
{
    // Read drug interactions csv line after line
    NSString *content = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    NSArray *rows = [content componentsSeparatedByString:@"\n"];
    NSLog(@"Number of records in interaction file = %lu", (unsigned long)[rows count]);
    myDrugInteractionMap = [[NSMutableDictionary alloc] init];
    /*
     token[0]: ATC-Code1
     token[1]: ATC-Code2
     token[2]: Html
    */
    for (NSString *s in rows) {
        if (![s isEqualToString:@""]) {
            NSArray *token = [s componentsSeparatedByString:@"||"];
            NSString *key = [NSString stringWithFormat:@"%@-%@", token[0], token[1]];
            [myDrugInteractionMap setObject:token[2] forKey:key];
        }
    }
    return TRUE;

}

- (NSString *) getInteractionHtmlBetween:(NSString *)atc1 and:(NSString *)atc2
{
    if ([myDrugInteractionMap count]>0) {
        NSString *key = [NSString stringWithFormat:@"%@-%@", atc1, atc2];
        return [myDrugInteractionMap valueForKey:key];
    }
    return @"";
}

- (BOOL) openDatabase: (NSString *)dbName
{
    // A. Check first users documents folder
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // Get documents directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [paths lastObject];
    NSString *filePath = [[documentsDir stringByAppendingPathComponent:dbName] stringByAppendingPathExtension:@"db"];
    // Check if database exists
    if (filePath!=nil) {
        if ([fileManager fileExistsAtPath:filePath]) {
            NSLog(@"Database found documents folder - %@", filePath);            
            mySqliteDb = [[MLSQLiteDatabase alloc] initWithPath:filePath];
            return TRUE;
        }
    }
    
    // B. If no database is available, check if db is in app bundle
    filePath = [[NSBundle mainBundle] pathForResource:dbName ofType:@"db"];
    if (filePath!=nil ) {
        mySqliteDb = [[MLSQLiteDatabase alloc] initWithPath:filePath];
        NSLog(@"Database found in app bundle - %@", filePath);
        return TRUE;
    }
    
    return FALSE;
}

- (void) closeDatabase
{
    if (mySqliteDb)
        [mySqliteDb close];
}

- (void) updateDatabase:(NSString *)language for:(NSString *)owner
{
    MLCustomURLConnection *reportConn = [[MLCustomURLConnection alloc] init];
    MLCustomURLConnection *dbConn = [[MLCustomURLConnection alloc] init];
 
    if ([language isEqualToString:@"de"]) {
        [reportConn downloadFileWithName:@"amiko_report_de.html" andModal:NO];
        if ([owner isEqualToString:@"ywesee"])
            [dbConn downloadFileWithName:@"amiko_db_full_idx_de.zip" andModal:YES];
        else if ([owner isEqualToString:@"zurrose"])
            [dbConn downloadFileWithName:@"amiko_db_full_idx_zr_de.zip" andModal:YES];
    } else if ([language isEqualToString:@"fr"]) {
        [reportConn downloadFileWithName:@"amiko_report_fr.html" andModal:NO];
        if ([owner isEqualToString:@"ywesee"])
            [dbConn downloadFileWithName:@"amiko_db_full_idx_fr.zip" andModal:YES];
        else if ([owner isEqualToString:@"zurrose"])
            [dbConn downloadFileWithName:@"amiko_db_full_idx_zr_fr.zip" andModal:YES];
    }
    
}

- (NSInteger) getNumRecords
{
    NSInteger numRecords = [mySqliteDb numberRecordsForTable:DATABASE_TABLE];
    
    return numRecords;
}

- (NSArray *) getRecord: (long)rowId
{
    NSString *query = [NSString stringWithFormat:@"select %@ from %@ where %@=%ld",
                       FULL_TABLE, DATABASE_TABLE, KEY_ROWID, rowId];
    //NSArray *results = [mySqliteDb performQuery:query];
    
    return [mySqliteDb performQuery:query];
}

- (MLMedication *) searchId: (long)rowId
{
    // getRecord returns an NSArray* hence the objectAtIndex!!   
    return [self cursorToFullMedInfo:[[self getRecord:rowId] objectAtIndex:0]];
}

- (NSArray *) searchWithQuery:(NSString *)query;
{
    return [mySqliteDb performQuery:query];
}

/** Search Präparat
 */
- (NSArray *) searchTitle:(NSString *)title
{
    NSString *query = [NSString stringWithFormat:@"select %@ from %@ where %@ like '%@%%'",
                       SHORT_TABLE, DATABASE_TABLE, KEY_TITLE, title];
    NSArray *results = [mySqliteDb performQuery:query];
    
    return [self extractShortMedInfoFrom:results];
}

/** Search Inhaber
 */
- (NSArray *) searchAuthor:(NSString *)author
{
    NSString *query = [NSString stringWithFormat:@"select %@ from %@ where %@ like '%@%%'",
                       SHORT_TABLE, DATABASE_TABLE, KEY_AUTH, author];
    NSArray *results = [mySqliteDb performQuery:query];
    
    return [self extractShortMedInfoFrom:results];
}

/** Search ATC Code
 */
- (NSArray *) searchATCCode:(NSString *)atccode
{
    NSString *query = [NSString stringWithFormat:@"select %@ from %@ where %@ like '%%;%@%%' or %@ like '%@%%' or %@ like '%% %@%%' or %@ like '%%%@%%' or %@ like '%%;%%%@%%'",
                       SHORT_TABLE, DATABASE_TABLE, KEY_ATCCODE, atccode, KEY_ATCCODE, atccode, KEY_ATCCODE, atccode, KEY_ATCCLASS, atccode, KEY_ATCCLASS, atccode];
    NSArray *results = [mySqliteDb performQuery:query];
    
    return [self extractShortMedInfoFrom:results];
}

/** Search Reg. Nr.
 */
- (NSArray *) searchIngredients:(NSString *)ingredients
{
    NSString *query = [NSString stringWithFormat:@"select %@ from %@ where %@ like '%%, %@%%' or %@ like '%@%%' or %@ like '%%-%@%%'",
                       SHORT_TABLE, DATABASE_TABLE, KEY_SUBSTANCES, ingredients, KEY_SUBSTANCES, ingredients, KEY_SUBSTANCES, ingredients];
    NSArray *results = [mySqliteDb performQuery:query];
    
    return [self extractShortMedInfoFrom:results];
}

/** Search Wirkstoff
 */
- (NSArray *) searchRegNr:(NSString *)regnr
{
    NSString *query = [NSString stringWithFormat:@"select %@ from %@ where %@ like '%%, %@%%' or %@ like '%@%%'",
                       SHORT_TABLE, DATABASE_TABLE, KEY_REGNRS, regnr, KEY_REGNRS, regnr];
    NSArray *results = [mySqliteDb performQuery:query];
    
    return [self extractShortMedInfoFrom:results];
}

/** Search Therapie
 */
- (NSArray *) searchTherapy:(NSString *)therapy
{
    NSString *query = [NSString stringWithFormat:@"select %@ from %@ where %@ like '%%, %@%%' or %@ like '%@%%' or %@ like '%% %@%%'",
                       SHORT_TABLE, DATABASE_TABLE, KEY_THERAPY, therapy, KEY_THERAPY, therapy, KEY_THERAPY, therapy];
    NSArray *results = [mySqliteDb performQuery:query];

    return [self extractShortMedInfoFrom:results];
}

/** Search Application
 */
- (NSArray *) searchApplication:(NSString *)application
{
    NSString *query = [NSString stringWithFormat:@"select %@ from %@ where %@ like '%%, %@%%' or %@ like '%@%%' or %@ like '%% %@%%' or %@ like '%%;%@%%' or %@ like '%@%%' or %@ like '%%;%@%%'",
                       SHORT_TABLE, DATABASE_TABLE, KEY_APPLICATION, application, KEY_APPLICATION, application, KEY_APPLICATION, application, KEY_APPLICATION, application, KEY_INDICATIONS, application, KEY_INDICATIONS, application];
    NSArray *results = [mySqliteDb performQuery:query];

    return [self extractShortMedInfoFrom:results];
}

- (MLMedication *) cursorToShortMedInfo:(NSArray *)cursor
{
    MLMedication *medi = [[MLMedication alloc] init];
        
    [medi setMedId:[(NSString *)[cursor objectAtIndex:kMedId] longLongValue]];
    [medi setTitle:(NSString *)[cursor objectAtIndex:kTitle]];
    [medi setAuth:(NSString *)[cursor objectAtIndex:kAuth]];
    [medi setAtccode:(NSString *)[cursor objectAtIndex:kAtcCode]];
    [medi setSubstances:(NSString *)[cursor objectAtIndex:kSubstances]];
    [medi setRegnrs:(NSString *)[cursor objectAtIndex:kRegnrs]];
    [medi setAtcClass:(NSString *)[cursor objectAtIndex:kAtcClass]];
    [medi setTherapy:(NSString *)[cursor objectAtIndex:kTherapy]];
    [medi setApplication:(NSString *)[cursor objectAtIndex:kApplication]];
    [medi setIndications:(NSString *)[cursor objectAtIndex:kIndications]];
    [medi setCustomerId:[(NSString *)[cursor objectAtIndex:kCustomerId] intValue]];
    [medi setPackInfo:(NSString *)[cursor objectAtIndex:kPackInfo]];
    
    return medi;
}

- (MLMedication *) cursorToFullMedInfo:(NSArray *)cursor
{
    MLMedication *medi = [[MLMedication alloc] init];
    
    [medi setMedId:[(NSString *)[cursor objectAtIndex:kMedId] longLongValue]];
    [medi setTitle:(NSString *)[cursor objectAtIndex:kTitle]];
    [medi setAuth:(NSString *)[cursor objectAtIndex:kAuth]];
    [medi setAtccode:(NSString *)[cursor objectAtIndex:kAtcCode]];
    [medi setSubstances:(NSString *)[cursor objectAtIndex:kSubstances]];
    [medi setRegnrs:(NSString *)[cursor objectAtIndex:kRegnrs]];
    [medi setAtcClass:(NSString *)[cursor objectAtIndex:kAtcClass]];
    [medi setTherapy:(NSString *)[cursor objectAtIndex:kTherapy]];
    [medi setApplication:(NSString *)[cursor objectAtIndex:kApplication]];
    [medi setIndications:(NSString *)[cursor objectAtIndex:kIndications]];
    [medi setCustomerId:[(NSString *)[cursor objectAtIndex:kCustomerId] intValue]];
    [medi setPackInfo:(NSString *)[cursor objectAtIndex:kPackInfo]];
    [medi setAddInfo:(NSString *)[cursor objectAtIndex:kAddInfo]];
    [medi setSectionIds:(NSString *)[cursor objectAtIndex:kIdsStr]];
    [medi setSectionTitles:(NSString *)[cursor objectAtIndex:kSectionsStr]];
    [medi setContentStr:(NSString *)[cursor objectAtIndex:kContentStr]];
    [medi setStyleStr:(NSString *)[cursor objectAtIndex:kStyleStr]];
    
    return medi;
}

- (NSArray *) extractShortMedInfoFrom:(NSArray *)results
{
    NSMutableArray *medList = [NSMutableArray array];

    for (NSArray *cursor in results) {
        MLMedication *medi = [[MLMedication alloc] init];
        
        [medi setMedId:[(NSString *)[cursor objectAtIndex:kMedId] longLongValue]];
        [medi setTitle:(NSString *)[cursor objectAtIndex:kTitle]];
        [medi setAuth:(NSString *)[cursor objectAtIndex:kAuth]];
        [medi setAtccode:(NSString *)[cursor objectAtIndex:kAtcCode]];
        [medi setSubstances:(NSString *)[cursor objectAtIndex:kSubstances]];
        [medi setRegnrs:(NSString *)[cursor objectAtIndex:kRegnrs]];
        [medi setAtcClass:(NSString *)[cursor objectAtIndex:kAtcClass]];
        [medi setTherapy:(NSString *)[cursor objectAtIndex:kTherapy]];
        [medi setApplication:(NSString *)[cursor objectAtIndex:kApplication]];
        [medi setIndications:(NSString *)[cursor objectAtIndex:kIndications]];
        [medi setCustomerId:[(NSString *)[cursor objectAtIndex:kCustomerId] intValue]];
        [medi setPackInfo:(NSString *)[cursor objectAtIndex:kPackInfo]];
        
        [medList addObject:medi];
    }
    
    return medList;
}

- (NSArray *) extractFullMedInfoFrom:(NSArray *)results;
{
    NSMutableArray *medList = [NSMutableArray array];
    
    for (NSArray *cursor in results) {
        MLMedication *medi = [[MLMedication alloc] init];
        
        [medi setMedId:[(NSString *)[cursor objectAtIndex:kMedId] longLongValue]];
        [medi setTitle:(NSString *)[cursor objectAtIndex:kTitle]];
        [medi setAuth:(NSString *)[cursor objectAtIndex:kAuth]];
        [medi setAtccode:(NSString *)[cursor objectAtIndex:kAtcCode]];
        [medi setSubstances:(NSString *)[cursor objectAtIndex:kSubstances]];
        [medi setRegnrs:(NSString *)[cursor objectAtIndex:kRegnrs]];
        [medi setAtcClass:(NSString *)[cursor objectAtIndex:kAtcClass]];
        [medi setTherapy:(NSString *)[cursor objectAtIndex:kTherapy]];
        [medi setApplication:(NSString *)[cursor objectAtIndex:kApplication]];
        [medi setIndications:(NSString *)[cursor objectAtIndex:kIndications]];
        [medi setCustomerId:[(NSString *)[cursor objectAtIndex:kCustomerId] intValue]];
        [medi setPackInfo:(NSString *)[cursor objectAtIndex:kPackInfo]];
        [medi setAddInfo:(NSString *)[cursor objectAtIndex:kAddInfo]];
        [medi setSectionIds:(NSString *)[cursor objectAtIndex:kIdsStr]];
        [medi setSectionTitles:(NSString *)[cursor objectAtIndex:kSectionsStr]];
        [medi setContentStr:(NSString *)[cursor objectAtIndex:kContentStr]];
        [medi setStyleStr:(NSString *)[cursor objectAtIndex:kStyleStr]];
        
        [medList addObject:medi];
    }
    
    return medList;
}

@end
