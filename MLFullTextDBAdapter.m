/*
 
 Copyright (c) 2017 Max Lungarella <cybrmx@gmail.com>
 
 Created on 20/04/2017.
 
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

#import "MLFullTextDBAdapter.h"
#import "MLFullTextEntry.h"
#import "MLSQLiteDatabase.h"
#import "MLUtilities.h"

enum {
    kRowId = 0, kKeyword, kRegnrs
};

static NSString *KEY_ROWID = @"id";
static NSString *KEY_KEYWORD = @"keyword";
static NSString *KEY_REGNR = @"regnr";

static NSString *DATABASE_TABLE = @"frequency";

@implementation MLFullTextDBAdapter
{
    // Instance variable declarations go here
    MLSQLiteDatabase *myFullTextDb;
}

/** Instance functions
 */
#pragma mark public methods

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
            NSLog(@"Fulltext DB found documents folder - %@", filePath);
            myFullTextDb = [[MLSQLiteDatabase alloc] initReadOnlyWithPath:filePath];
            return true;
        }
    }
    
    // B. If no database is available, check if db is in app bundle
    filePath = [[NSBundle mainBundle] pathForResource:dbName ofType:@"db"];
    if (filePath!=nil ) {
        myFullTextDb = [[MLSQLiteDatabase alloc] initReadOnlyWithPath:filePath];
        NSLog(@"Fulltext DB found in app bundle - %@", filePath);
        return true;
    }
    
    return false;
}

- (void) closeDatabase
{
    if (myFullTextDb)
        [myFullTextDb close];
}

- (NSInteger) getNumRecords
{
    return [myFullTextDb numberRecordsForTable:DATABASE_TABLE];
}

/** Get full text from hash
 */
- (MLFullTextEntry *) searchHash:(NSString *)hash
{
    NSString *query = [NSString stringWithFormat:@"select * from %@ where %@ like '%@'", DATABASE_TABLE, KEY_ROWID, hash];
    NSArray *results = [myFullTextDb performQuery:query];
    
    return [self cursorToFullTextEntry:[results firstObject]];
}

/** Search fulltext containing keyword
 */
- (NSArray *) searchKeyword:(NSString *)keyword
{
    NSString *query = [NSString stringWithFormat:@"select * from %@ where %@ like '%@%%'", DATABASE_TABLE, KEY_KEYWORD, keyword];
    NSArray *results = [myFullTextDb performQuery:query];
    
    return [self extractFullTextEntryFrom:results];
}

- (MLFullTextEntry *) cursorToFullTextEntry:(NSArray *)cursor
{
    MLFullTextEntry *entry = [[MLFullTextEntry alloc] init];
    
    [entry setHash:(NSString *)[cursor objectAtIndex:kRowId]];
    [entry setKeyword:(NSString *)[cursor objectAtIndex:kKeyword]];
    NSString *regnrsAndChapters = (NSString *)[cursor objectAtIndex:kRegnrs];
    if (regnrsAndChapters!=nil) {
        NSMutableDictionary *dict = [self regChapterDict:regnrsAndChapters];
        [entry setRegChaptersDict:dict];
    }
    [entry setRegnrs:regnrsAndChapters];
    
    return entry;
}

- (NSArray *) extractFullTextEntryFrom:(NSArray *)results
{
    NSMutableArray *entryList = [NSMutableArray array];
    
    for (NSArray *cursor in results) {
        
        assert(cursor!=nil);
        
        MLFullTextEntry *entry = [[MLFullTextEntry alloc] init];
        [entry setHash:(NSString *)[cursor objectAtIndex:kRowId]];
        [entry setKeyword:(NSString *)[cursor objectAtIndex:kKeyword]];
        NSString *regnrsAndChapters = (NSString *)[cursor objectAtIndex:kRegnrs];
        if (regnrsAndChapters!=nil) {
            NSMutableDictionary *dict = [self regChapterDict:regnrsAndChapters];
            [entry setRegChaptersDict:dict];
        }
        [entry setRegnrs:regnrsAndChapters];
        
        [entryList addObject:entry];
    }
    
    return entryList;
}

- (NSMutableDictionary *) regChapterDict:(NSString *)regChapterStr
{
    NSMutableString *regnr = [[NSMutableString alloc] init];
    NSMutableString *chapters = [[NSMutableString alloc] init];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];   // regnr -> set of chapters
    // Format: 65000(13)|65001(14)|...
    NSArray *rac = [regChapterStr componentsSeparatedByString:@"|"];
    NSMutableSet *set = [NSMutableSet setWithArray:rac];
    // Loop through all regnr-chapter pairs
    for (NSString *r in set) {
        // Extract chapters located between parentheses
        NSArray *str1 = [r componentsSeparatedByString:@"("];
        if (str1!=nil) {
            regnr = [str1 objectAtIndex:0];
            if ([str1 count]>1) {
                NSArray *str2 = [[str1 objectAtIndex:1] componentsSeparatedByString:@")"];
                chapters = [str2 objectAtIndex:0];
            }
            NSMutableSet *chaptersSet = [[NSMutableSet alloc] init];
            if ([dict objectForKey:regnr]!=nil) {
                chaptersSet = [dict objectForKey:regnr];
            }
            // Split chapters listed as comma-separated string
            NSArray *c = [chapters componentsSeparatedByString:@","];
            for (NSString *chapter in c) {
                [chaptersSet addObject:chapter];
            }
            // Update dictionary
            dict[regnr] = chaptersSet;
        } else {
            // No chapters for this regnr -> do nothing
        }
    }
    return dict;
}

@end
