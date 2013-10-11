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

enum {
  kMedId = 0, kTitle, kAuth, kAtcCode, kSubstances, kRegnrs, kAtcClass, kTherapy, kApplication, kCustomerId, kPackInfo, kAddInfo, kIdsStr, kSectionsStr, kContentStr, kStyleStr
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
}

/** Class functions
 */
#pragma mark Class functions

+ (void) initialize
{
    if (self == [MLDBAdapter class])
    {
        if (SHORT_TABLE == nil) {
            SHORT_TABLE = [[NSString alloc] initWithFormat:@"%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@",
                           KEY_ROWID, KEY_TITLE, KEY_AUTH, KEY_ATCCODE, KEY_SUBSTANCES, KEY_REGNRS, KEY_ATCCLASS, KEY_THERAPY, KEY_APPLICATION, KEY_CUSTOMER_ID, KEY_PACK_INFO];
        }
        if (FULL_TABLE == nil) {
            FULL_TABLE = [[NSString alloc] initWithFormat:@"%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@",
                          KEY_ROWID, KEY_TITLE, KEY_AUTH, KEY_ATCCODE, KEY_SUBSTANCES, KEY_REGNRS, KEY_ATCCLASS, KEY_THERAPY, KEY_APPLICATION, KEY_CUSTOMER_ID, KEY_PACK_INFO, KEY_ADDINFO, KEY_IDS, KEY_SECTIONS, KEY_CONTENT, KEY_STYLE];
        }
    }
}

/** Instance functions
 */
#pragma mark Instance functions

- (int) openDatabase: (NSString *)name
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:name ofType:@"db"];
    
    if (filePath!=nil )
        mySqliteDb = [[MLSQLiteDatabase alloc] initWithPath:filePath];
    else
        return 0;
    return 1;
}

- (void) closeDatabase
{
    [mySqliteDb close];
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

- (NSArray *) searchWithQuery: (NSString *)query;
{
    return [mySqliteDb performQuery:query];
}

/** Search Präparat
 */
- (NSArray *) searchTitle: (NSString *)title
{
    NSString *query = [NSString stringWithFormat:@"select %@ from %@ where %@ like '%@%%'",
                       SHORT_TABLE, DATABASE_TABLE, KEY_TITLE, title];
    NSArray *results = [mySqliteDb performQuery:query];
    
    return [self extractShortMedInfoFrom:results];
}

/** Search Inhaber
 */
- (NSArray *) searchAuthor: (NSString *)author
{
    NSString *query = [NSString stringWithFormat:@"select %@ from %@ where %@ like '%@%%'",
                       SHORT_TABLE, DATABASE_TABLE, KEY_AUTH, author];
    NSArray *results = [mySqliteDb performQuery:query];
    
    return [self extractShortMedInfoFrom:results];
}

/** Search ATC Code
 */
- (NSArray *) searchATCCode: (NSString *)atccode
{
    NSString *query = [NSString stringWithFormat:@"select %@ from %@ where %@ like '%%;%@%%' or %@ like '%@%%' or %@ like '%% %@%%' or %@ like '%@%%' or %@ like '%%;%@%%'",
                       SHORT_TABLE, DATABASE_TABLE, KEY_ATCCODE, atccode, KEY_ATCCODE, atccode, KEY_ATCCODE, atccode, KEY_ATCCLASS, atccode, KEY_ATCCLASS, atccode];
    NSArray *results = [mySqliteDb performQuery:query];
    
    return [self extractShortMedInfoFrom:results];
}

/** Search Reg. Nr.
 */
- (NSArray *) searchIngredients: (NSString *)ingredients
{
    NSString *query = [NSString stringWithFormat:@"select %@ from %@ where %@ like '%%, %@%%' or %@ like '%@%%' or %@ like '%%-%@%%'",
                       SHORT_TABLE, DATABASE_TABLE, KEY_SUBSTANCES, ingredients, KEY_SUBSTANCES, ingredients, KEY_SUBSTANCES, ingredients];
    NSArray *results = [mySqliteDb performQuery:query];
    
    return [self extractShortMedInfoFrom:results];
}

/** Search Wirkstoff
 */
- (NSArray *) searchRegNr: (NSString *)regnr
{
    NSString *query = [NSString stringWithFormat:@"select %@ from %@ where %@ like '%%, %@%%' or %@ like '%@%%'",
                       SHORT_TABLE, DATABASE_TABLE, KEY_REGNRS, regnr, KEY_REGNRS, regnr];
    NSArray *results = [mySqliteDb performQuery:query];
    
    return [self extractShortMedInfoFrom:results];
}

/** Search Therapie
 */
- (NSArray *) searchTherapy: (NSString *)therapy
{
    NSString *query = [NSString stringWithFormat:@"select %@ from %@ where %@ like '%%, %@%%' or %@ like '%@%%' or %@ like '%% %@%%'",
                       SHORT_TABLE, DATABASE_TABLE, KEY_THERAPY, therapy, KEY_THERAPY, therapy, KEY_THERAPY, therapy];
    NSArray *results = [mySqliteDb performQuery:query];

    return [self extractShortMedInfoFrom:results];
}

/** Search Application
 */
- (NSArray *) searchApplication: (NSString *)application
{
    NSString *query = [NSString stringWithFormat:@"select %@ from %@ where %@ like '%%, %@%%' or %@ like '%@%%' or %@ like '%% %@%%' or %@ like '%%;%@%%'",
                       SHORT_TABLE, DATABASE_TABLE, KEY_APPLICATION, application, KEY_APPLICATION, application, KEY_APPLICATION, application, KEY_APPLICATION, application];
    NSArray *results = [mySqliteDb performQuery:query];

    return [self extractShortMedInfoFrom:results];
}

- (MLMedication *) cursorToShortMedInfo: (NSArray *)cursor
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
    [medi setCustomerId:[(NSString *)[cursor objectAtIndex:kCustomerId] intValue]];
    [medi setPackInfo:(NSString *)[cursor objectAtIndex:kPackInfo]];
    
    return medi;
}

- (MLMedication *) cursorToFullMedInfo: (NSArray *)cursor
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
    [medi setCustomerId:[(NSString *)[cursor objectAtIndex:kCustomerId] intValue]];
    [medi setPackInfo:(NSString *)[cursor objectAtIndex:kPackInfo]];
    [medi setAddInfo:(NSString *)[cursor objectAtIndex:kAddInfo]];
    [medi setSectionIds:(NSString *)[cursor objectAtIndex:kIdsStr]];
    [medi setSectionTitles:(NSString *)[cursor objectAtIndex:kSectionsStr]];
    [medi setContentStr:(NSString *)[cursor objectAtIndex:kContentStr]];
    [medi setStyleStr:(NSString *)[cursor objectAtIndex:kStyleStr]];
    
    return medi;
}

- (NSArray *) extractShortMedInfoFrom: (NSArray *)results
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
        [medi setCustomerId:[(NSString *)[cursor objectAtIndex:kCustomerId] intValue]];
        [medi setPackInfo:(NSString *)[cursor objectAtIndex:kPackInfo]];
        
        [medList addObject:medi];
    }
    
    return medList;
}

- (NSArray *) extractFullMedInfoFrom: (NSArray *)results;
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
