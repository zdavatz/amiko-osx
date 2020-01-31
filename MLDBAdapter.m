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
#import "MLUtilities.h"

enum {
  kMedId = 0, kTitle, kAuth, kAtcCode, kSubstances, kRegnrs, kAtcClass, kTherapy, kApplication, kIndications, kCustomerId, kPackInfo, kPackages, kAddInfo, kIdsStr, kSectionsStr, kContentStr, kStyleStr
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
static NSString *KEY_PACKAGES = @"packages";

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
    if (self == [MLDBAdapter class]) {
        if (SHORT_TABLE == nil) {
            SHORT_TABLE = [[NSString alloc] initWithFormat:@"%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@",
                           KEY_ROWID, KEY_TITLE, KEY_AUTH, KEY_ATCCODE, KEY_SUBSTANCES, KEY_REGNRS, KEY_ATCCLASS, KEY_THERAPY, KEY_APPLICATION, KEY_INDICATIONS, KEY_CUSTOMER_ID, KEY_PACK_INFO, KEY_PACKAGES];
        }
        if (FULL_TABLE == nil) {
            FULL_TABLE = [[NSString alloc] initWithFormat:@"%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@",
                          KEY_ROWID, KEY_TITLE, KEY_AUTH, KEY_ATCCODE, KEY_SUBSTANCES, KEY_REGNRS, KEY_ATCCLASS, KEY_THERAPY, KEY_APPLICATION, KEY_INDICATIONS, KEY_CUSTOMER_ID, KEY_PACK_INFO, KEY_PACKAGES, KEY_ADDINFO, KEY_IDS, KEY_SECTIONS, KEY_CONTENT, KEY_STYLE];
        }
    }
}

/** Instance functions
 */
#pragma mark Instance functions

- (BOOL) openDatabase:(NSString *)dbName
{
    // A. Check first users documents folder
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // Get documents directory
    NSString *documentsDir = [MLUtilities documentsDirectory];
    NSString *filePath = [[documentsDir stringByAppendingPathComponent:dbName] stringByAppendingPathExtension:@"db"];
    // Check if database exists
    if (filePath!=nil) {
        if ([fileManager fileExistsAtPath:filePath]) {
            NSLog(@"AIPS DB found in user's documents folder - %@", filePath);
            mySqliteDb = [[MLSQLiteDatabase alloc] initReadOnlyWithPath:filePath];
            return TRUE;
        }
    }
    
    // B. If no database is available, check if db is in app bundle
    filePath = [[NSBundle mainBundle] pathForResource:dbName ofType:@"db"];
    if (filePath!=nil ) {
        mySqliteDb = [[MLSQLiteDatabase alloc] initReadOnlyWithPath:filePath];
        NSLog(@"AIPS DB found in app bundle - %@", filePath);
        return TRUE;
    }
    
    return FALSE;
}

- (void) closeDatabase
{
    if (mySqliteDb)
        [mySqliteDb close];
}

- (NSInteger) getNumRecords
{
    NSInteger numRecords = [mySqliteDb numberRecordsForTable:DATABASE_TABLE];
    
    return numRecords;
}

- (NSInteger) getNumProducts
{
    NSString *query = [NSString stringWithFormat:@"select %@ from %@", KEY_PACK_INFO, DATABASE_TABLE];
    NSArray *results = [mySqliteDb performQuery:query];
    NSInteger numProducts = 0;
    for (NSArray *cursor in results)  {
        numProducts += [[[cursor firstObject] componentsSeparatedByString:@"\n"] count];
    }
    
    return numProducts;
}

- (NSArray *) getFullRecord:(long)rowId
{
    NSString *query = [NSString stringWithFormat:@"select %@ from %@ where %@=%ld", FULL_TABLE, DATABASE_TABLE, KEY_ROWID, rowId];
    
    return [mySqliteDb performQuery:query];
}

- (MLMedication *) getMediWithId:(long)rowId
{
    return [self cursorToFullMedInfo:[[self getFullRecord:rowId] firstObject]];
}

- (MLMedication *) getShortMediWithId:(long)rowId
{
    return [self cursorToShortMedInfo:[[self getFullRecord:rowId] firstObject]];
}

- (MLMedication *) getMediWithRegnr:(NSString *)regnr
{
    NSString *query = [NSString stringWithFormat:@"select %@ from %@ where %@ like '%%, %@%%' or %@ like '%@%%'", FULL_TABLE, DATABASE_TABLE, KEY_REGNRS, regnr, KEY_REGNRS, regnr];
    NSArray *cursor = [[mySqliteDb performQuery:query] firstObject];
    
    return [self cursorToFullMedInfo:cursor];
}

- (NSArray *) searchWithQuery:(NSString *)query;
{
    return [mySqliteDb performQuery:query];
}

/** Search Präparat
 */
- (NSArray *) searchTitle:(NSString *)title
{
    NSString *replaced = [[[[[[title lowercaseString]
                          stringByReplacingOccurrencesOfString:@"a" withString:@"[aáàäâã]"]
                         stringByReplacingOccurrencesOfString:@"e" withString:@"[eéèëê]"]
                        stringByReplacingOccurrencesOfString:@"i" withString:@"[iíìî]"]
                       stringByReplacingOccurrencesOfString:@"o" withString:@"[oóòöôõ]"]
                      stringByReplacingOccurrencesOfString:@"u" withString:@"[uúùüû]"];

    NSString *query = [NSString stringWithFormat:@"select %@ from %@ where lower(%@) GLOB '*%@*'",
                       SHORT_TABLE, DATABASE_TABLE, KEY_TITLE, replaced];

    NSArray *results = [mySqliteDb performQuery:query];
    
    return [self extractShortMedInfoFrom:results];
}

/** Search Inhaber
 */
- (NSArray *) searchAuthor:(NSString *)author
{
    NSString *query = [NSString stringWithFormat:@"select %@ from %@ where %@ like '%@%%'", SHORT_TABLE, DATABASE_TABLE, KEY_AUTH, author];
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

/** Search Wirkstoff
 */
- (NSArray *) searchIngredients:(NSString *)ingredients
{
    NSString *query = [NSString stringWithFormat:@"select %@ from %@ where %@ like '%%, %@%%' or %@ like '%@%%' or %@ like '%%-%@%%'",
                       SHORT_TABLE, DATABASE_TABLE, KEY_SUBSTANCES, ingredients, KEY_SUBSTANCES, ingredients, KEY_SUBSTANCES, ingredients];
    NSArray *results = [mySqliteDb performQuery:query];
    
    return [self extractShortMedInfoFrom:results];
}

/** Search Reg. Nr.
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
    NSString *query = [NSString stringWithFormat:@"select %@ from %@ where %@ like '%%, %@%%' or %@ like '%@%%' or %@ like '%% %@%%'", SHORT_TABLE, DATABASE_TABLE, KEY_THERAPY, therapy, KEY_THERAPY, therapy, KEY_THERAPY, therapy];
    NSArray *results = [mySqliteDb performQuery:query];

    return [self extractShortMedInfoFrom:results];
}

/** Search Application
 */
- (NSArray *) searchApplication:(NSString *)application
{
    NSString *query = [NSString stringWithFormat:@"select %@ from %@ where %@ like '%%, %@%%' or %@ like '%@%%' or %@ like '%% %@%%' or %@ like '%%;%@%%' or %@ like '%@%%' or %@ like '%%;%@%%'", SHORT_TABLE, DATABASE_TABLE, KEY_APPLICATION, application, KEY_APPLICATION, application, KEY_APPLICATION, application, KEY_APPLICATION, application, KEY_INDICATIONS, application, KEY_INDICATIONS, application];
    NSArray *results = [mySqliteDb performQuery:query];

    return [self extractShortMedInfoFrom:results];
}

/** Search Reg. Nrs. given a list of reg. nr.
 */
- (NSArray *) searchRegnrsFromList:(NSArray *)listOfRegnrs
{
    const unsigned int N = 40;
    NSMutableArray *listOfMedis = [[NSMutableArray alloc] init];
    
    NSUInteger C = [listOfRegnrs count];    // E.g. 100
    NSUInteger capacityA = (C / N) * N;     // E.g. 100/40 * 40 = 80
    NSUInteger capacityB = C - capacityA;   // 100 - 80 = 20
    NSMutableArray *listA = [NSMutableArray arrayWithCapacity:capacityA];
    NSMutableArray *listB = [NSMutableArray arrayWithCapacity:capacityB];
    
    [listOfRegnrs enumerateObjectsUsingBlock:^(id object, NSUInteger index, BOOL *stop) {
        NSMutableArray *output = (index < capacityA) ? listA : listB;
        [output addObject:object];
    }];
    
    NSString *subQuery = @"";
    int count = 0;
    // Loop through first (long) list
    for (NSString *reg in listA) {
        subQuery = [subQuery stringByAppendingString:[NSString stringWithFormat:@"%@ like '%%, %@%%' or %@ like '%@%%'", KEY_REGNRS, reg, KEY_REGNRS, reg]];
        count++;
        if (count % N == 0) {
            NSString *query = [NSString stringWithFormat:@"select %@ from %@ where %@", FULL_TABLE, DATABASE_TABLE, subQuery];
            NSArray *results = [mySqliteDb performQuery:query];
            for (NSArray *cursor in results) {
                MLMedication *m = [self cursorToVeryShortMedInfo:cursor];
                [listOfMedis addObject:m];
            }
            subQuery = @"";
        } else {
            subQuery = [subQuery stringByAppendingString:@" or "];
        }
    }
    // Loop through second (short) list
    for (NSString *reg in listB) {
        subQuery = [subQuery stringByAppendingString:[NSString stringWithFormat:@"%@ like '%%, %@%%' or %@ like '%@%%' or ", KEY_REGNRS, reg, KEY_REGNRS, reg]];
    }
    if ([subQuery length] > 4) {
        subQuery = [subQuery substringWithRange:NSMakeRange(0, [subQuery length]-4)];   // Remove last 'or'
        NSString *query = [NSString stringWithFormat:@"select %@ from %@ where %@", FULL_TABLE, DATABASE_TABLE, subQuery];
        NSArray *results = [mySqliteDb performQuery:query];
        for (NSArray *cursor in results) {
            MLMedication *m = [self cursorToVeryShortMedInfo:cursor];
            [listOfMedis addObject:m];
        }
    }
    
    return listOfMedis;
}

- (MLMedication *) cursorToVeryShortMedInfo:(NSArray *)cursor
{
    MLMedication *medi = [[MLMedication alloc] init];
    
    [medi setMedId:[(NSString *)[cursor objectAtIndex:kMedId] longLongValue]];
    [medi setTitle:(NSString *)[cursor objectAtIndex:kTitle]];
    [medi setAuth:(NSString *)[cursor objectAtIndex:kAuth]];
    [medi setRegnrs:(NSString *)[cursor objectAtIndex:kRegnrs]];
    [medi setSectionIds:(NSString *)[cursor objectAtIndex:kIdsStr]];
    [medi setSectionTitles:(NSString *)[cursor objectAtIndex:kSectionsStr]];
    
    return medi;
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
    [medi setPackages:(NSString *)[cursor objectAtIndex:kPackages]];
    
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

- (NSArray *) extractVeryShortMedInfoFrom:(NSArray *)results
{
    NSMutableArray *medList = [NSMutableArray array];
    
    for (NSArray *cursor in results)  {
        MLMedication *medi = [self cursorToVeryShortMedInfo:cursor];
        [medList addObject:medi];
    }
    
    return medList;
}

- (NSArray *) extractShortMedInfoFrom:(NSArray *)results
{
    NSMutableArray *medList = [NSMutableArray array];

    for (NSArray *cursor in results)  {
        MLMedication *medi = [self cursorToShortMedInfo:cursor];
        [medList addObject:medi];
    }
    
    return medList;
}

- (NSArray *) extractFullMedInfoFrom:(NSArray *)results;
{
    NSMutableArray *medList = [NSMutableArray array];
    
    for (NSArray *cursor in results) {
        MLMedication *medi = [self cursorToFullMedInfo:cursor];
        [medList addObject:medi];
    }
    
    return medList;
}

@end
