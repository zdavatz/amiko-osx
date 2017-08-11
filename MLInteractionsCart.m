/*
 
 Copyright (c) 2017 Max Lungarella <cybrmx@gmail.com>
 
 Created on 11/08/2017.
 
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

#import "MLInteractionsCart.h"

#import "MLMedication.h"

@implementation MLInteractionsCart

@synthesize cart;

- (id) init
{
    cart = [[NSMutableDictionary alloc] init];
    return [super init];
}

- (NSInteger) size
{
    return [cart count];
}

- (NSString *) interactionsAsHtmlForAdapter:(MLInteractionsAdapter *)adapter withTitles:(NSMutableArray *)titles andIds:(NSMutableArray *)ids
{
    NSMutableString *htmlStr = [[NSMutableString alloc] initWithString:@""];
    
    // Check if there are meds in the "Medikamentenkorb"
    if ([self size]>1) {
        // First sort them alphabetically
        NSArray *sortedNames = [[cart allKeys] sortedArrayUsingSelector: @selector(compare:)];
        // Big loop
        for (NSString *name1 in sortedNames) {
            for (NSString *name2 in sortedNames) {
                if (![name1 isEqualToString:name2]) {
                    // Extract meds by names from interaction basket
                    MLMedication *med1 = [cart valueForKey:name1];
                    MLMedication *med2 = [cart valueForKey:name2];
                    // Get ATC codes from interaction db
                    NSArray *m_code1 = [[med1 atccode] componentsSeparatedByString:@";"];
                    NSArray *m_code2 = [[med2 atccode] componentsSeparatedByString:@";"];
                    NSArray *atc1 = nil;
                    NSArray *atc2 = nil;
                    if ([m_code1 count]>1)
                        atc1 = [[m_code1 objectAtIndex:0] componentsSeparatedByString:@","];
                    if ([m_code2 count]>1)
                        atc2 = [[m_code2 objectAtIndex:0] componentsSeparatedByString:@","];
                    
                    NSString *atc_code1 = @"";
                    NSString *atc_code2 = @"";
                    if (atc1!=nil && [atc1 count]>0) {
                        for (atc_code1 in atc1) {
                            if (atc2!=nil && [atc2 count]>0) {
                                for (atc_code2 in atc2) {
                                    NSString *html = [adapter getInteractionHtmlBetween:atc_code1 and:atc_code2];
                                    if (html!=nil) {
                                        // Replace all occurrences of atc codes by med names apart from the FIRST one!
                                        NSRange range1 = [html rangeOfString:atc_code1 options:NSBackwardsSearch];
                                        html = [html stringByReplacingCharactersInRange:range1 withString:name1];
                                        NSRange range2 = [html rangeOfString:atc_code2 options:NSBackwardsSearch];
                                        html = [html stringByReplacingCharactersInRange:range2 withString:name2];
                                        // Concatenate strings
                                        [htmlStr appendString:html];
                                        // Add to title and anchor lists
                                        [titles addObject:[NSString stringWithFormat:@"%@ \u2192 %@", name1, name2]];
                                        [ids addObject:[NSString stringWithFormat:@"%@-%@", atc_code1, atc_code2]];
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    return htmlStr;
}

- (NSArray *) interactionsAsArrayForAdapter:(MLInteractionsAdapter *)adapter
{
    NSMutableArray *interactionsArray;
    
    if ([self size]>1) {
        // First sort them alphabetically
        NSArray *sortedNames = [[cart allKeys] sortedArrayUsingSelector: @selector(compare:)];
        // Big loop
        for (NSString *name1 in sortedNames) {
            for (NSString *name2 in sortedNames) {
                if (![name1 isEqualToString:name2]) {
                    // Extract meds by names from interaction basket
                    MLMedication *med1 = [cart valueForKey:name1];
                    MLMedication *med2 = [cart valueForKey:name2];
                    // Get ATC codes from interaction db
                    NSArray *m_code1 = [[med1 atccode] componentsSeparatedByString:@";"];
                    NSArray *m_code2 = [[med2 atccode] componentsSeparatedByString:@";"];
                    NSArray *atc1 = nil;
                    NSArray *atc2 = nil;
                    if ([m_code1 count]>1)
                        atc1 = [[m_code1 objectAtIndex:0] componentsSeparatedByString:@","];
                    if ([m_code2 count]>1)
                        atc2 = [[m_code2 objectAtIndex:0] componentsSeparatedByString:@","];
                    
                    NSString *atc_code1 = @"";
                    NSString *atc_code2 = @"";
                    if (atc1!=nil && [atc1 count]>0) {
                        for (atc_code1 in atc1) {
                            if (atc2!=nil && [atc2 count]>0) {
                                for (atc_code2 in atc2) {
                                    NSString *html = [adapter getInteractionHtmlBetween:atc_code1 and:atc_code2];
                                    if (html!=nil) {
                                        [interactionsArray addObject:[NSString stringWithFormat:@"%@ \u2192 %@", name1, name2]];
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    return interactionsArray;
}

@end
