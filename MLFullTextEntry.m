/*
 
 Copyright (c) 2017 Max Lungarella <cybrmx@gmail.com>
 
 Created on 27/04/2017.
 
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

#import "MLFullTextEntry.h"

@implementation MLFullTextEntry
{
    // Instance variable declarations go here
    NSDictionary *regChaptersDict;
}

/** Properties
 */
#pragma mark properties

@synthesize hash;
@synthesize keyword;
@synthesize regnrs;

/** Instance functions
 */
#pragma mark public methods

- (void) setRegChaptersDict:(NSMutableDictionary *)dict
{
    regChaptersDict = [NSDictionary dictionaryWithDictionary:dict];
}

- (NSDictionary *) getRegChaptersDict
{
    return regChaptersDict;
}

- (NSString *) getRegnrs
{
    NSMutableString *regStr = [[NSMutableString alloc] initWithString:@""];
    for (id key in regChaptersDict) {
        NSString *value = [regChaptersDict objectForKey:key];
        [regStr appendString:[NSString stringWithFormat:@"%@,", key]];

        NSLog(@"key=%@ value=%@", key, value);
    }
    
    return regStr;
}

- (NSSet *) getChaptersForKey:(NSString *)regnr
{
    return [regChaptersDict objectForKey:regnr];
}

- (NSArray *) getRegnrsAsArray
{
    return [regChaptersDict allKeys];
}

- (unsigned long) numHits
{
    return[regChaptersDict count];
}

@end


