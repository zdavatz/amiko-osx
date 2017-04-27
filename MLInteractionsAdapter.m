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

#import "MLInteractionsAdapter.h"
#import "MLUtilities.h"

@implementation MLInteractionsAdapter
{
    NSMutableDictionary *myDrugInteractionMap;
}

/** Instance functions
 */
#pragma mark Instance functions

- (BOOL) openInteractionsCsvFile:(NSString *)name
{
    NSString *documentsDir = [MLUtilities documentsDirectory];;
    
    // ** A. Check first users documents folder
    NSString *filePath = [[documentsDir stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"csv"];
    // Check if database exists
    if (filePath!=nil) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:filePath]) {
            NSLog(@"Drug interactions csv found in documents folder - %@", filePath);
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

- (void) closeInteractionsCsvFile
{
    if ([myDrugInteractionMap count]>0) {
        [myDrugInteractionMap removeAllObjects];
    }
}

- (NSInteger) getNumInteractions
{
    if (myDrugInteractionMap!=nil)
        return [myDrugInteractionMap count];
    
    return 0;
}

- (NSString *) getInteractionHtmlBetween:(NSString *)atc1 and:(NSString *)atc2
{
    if ([myDrugInteractionMap count]>0) {
        NSString *key = [NSString stringWithFormat:@"%@-%@", atc1, atc2];
        return [myDrugInteractionMap valueForKey:key];
    }
    return @"";
}

- (BOOL) readDrugInteractionMap:(NSString *)filePath
{
    // Read drug interactions csv line after line
    NSString *content = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    NSArray *rows = [content componentsSeparatedByString:@"\n"];
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

@end
