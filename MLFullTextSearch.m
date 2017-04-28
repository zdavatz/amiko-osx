/*
 
 Copyright (c) 2017 Max Lungarella <cybrmx@gmail.com>
 
 Created on 28/04/2017.
 
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

#import "MLFullTextSearch.h"
#import "MLMedication.h"


@implementation MLFullTextSearch
{
    // Instance variable declarations go here
    NSArray *mListOfArticles;
    NSDictionary *mDict;
}

/** Properties
 */
#pragma mark properties

@synthesize listOfSectionIds;
@synthesize listOfSectionTitles;

/** Instance functions
 */
#pragma mark public methods

- (NSString *) tableWithArticles:(NSArray *)listOfArticles
              andRegChaptersDict:(NSDictionary *)dict
                       andFilter:(NSString *)filter
{
    int rows = 0;
    NSMutableDictionary *chaptersCountDict = [[NSMutableDictionary alloc] init];
    NSString *htmlStr = @"<ul>";

    // Assign list and dictionaries only if != nil
    if (listOfArticles!=nil) {
        mListOfArticles = listOfArticles;
        // Sort alphabetically (this is pretty neat!)
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
        mListOfArticles = [mListOfArticles sortedArrayUsingDescriptors:@[sort]];
    }
    if (dict!=nil)
        mDict = dict;
    
    // Loop through all articles
    for (MLMedication *m in mListOfArticles) {
        BOOL filtered = true;
        NSString *contentStyle;
        if (rows % 2 == 0) {
            contentStyle = [NSString stringWithFormat:@"<li style=\"background-color:whitesmoke;\" id=\"{firstLetter}\">"];
        } else {
            contentStyle = [NSString stringWithFormat:@"<li style=\"background-color:white;\" id=\"{firstLetter}\">"];
        }
        NSString *contentTitle = [NSString stringWithFormat:@"<a onclick=\"displayFachinfo('%@','{anchor}')\"><span style=\"font-size:0.8em\"><b>%@</b></span></a> <span style=\"font-size:0.7em\"> | %@</span><br>", m.regnrs, m.title, m.auth];

        NSString *contentChapters = @"";
        NSArray *regnrs = [m.regnrs componentsSeparatedByString:@","];
        NSDictionary *indexToTitlesDict = [m indexToTitlesDict];    // id -> chapter title
        // List of chapters
        if ([regnrs count]>0) {
            NSString *r = [regnrs objectAtIndex:0];
            if ([mDict objectForKey:r]) {
                NSSet *chapters = mDict[r];
                for (NSString *c in chapters) {
                    if ([indexToTitlesDict objectForKey:c]) {
                        NSString *cStr = indexToTitlesDict[c];
                        if ([filter length]==0 || [filter isEqualToString:cStr]) {
                            contentChapters = [contentChapters stringByAppendingFormat:@"<span style=\"font-size:0.75em; color:#0088BB\"> <a onclick=\"displayFachinfo('{regnr}','{anchor}')\">%@</a></span><br>", cStr];
                            int count = 0;
                            if ([chaptersCountDict objectForKey:cStr])
                                count = [chaptersCountDict[cStr] intValue];
                            chaptersCountDict[cStr] = [NSNumber numberWithInt:count+1];
                            filtered = false;
                        }
                    }
                }
            }
        }
        if (!filtered) {
            htmlStr = [htmlStr stringByAppendingFormat:@"%@%@%@</li>", contentStyle, contentTitle, contentChapters];
            rows++;
        }
    }
    
    htmlStr = [htmlStr stringByAppendingFormat:@"</ul>"];
    
    NSMutableArray *listOfIds = [[NSMutableArray alloc] init];
    NSMutableArray *listOfTitles = [[NSMutableArray alloc] init];
    for (NSString *cStr in chaptersCountDict) {
        [listOfIds addObject:cStr];
        [listOfTitles addObject:[NSString stringWithFormat:@"%@ (%@)", cStr, chaptersCountDict[cStr]]];
    }
    // Update section ids (anchors)
    listOfSectionIds = [NSArray arrayWithArray:listOfIds];
    // Update section titles
    listOfSectionTitles = [NSArray arrayWithArray:listOfTitles];
    
    return htmlStr;
}

@end
