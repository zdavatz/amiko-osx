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

#import "MLDataStore.h"

@implementation MLDataStore

@synthesize favMedsSet;

#pragma mark Class methods

+ (MLDataStore *) initWithFavMedsSet: (NSMutableSet *)favMedsSet
{
    MLDataStore *favMeds = [[MLDataStore alloc] init];
    
    favMeds.favMedsSet = [NSSet setWithSet:favMedsSet];
    
    return favMeds;
}

#pragma mark Delegate methods

/** Returns a coder used as a dictionary
 */
- (void) encodeWithCoder: (NSCoder *)encoder
{
    // In a dictionary -> setValue:forKey:
    [encoder encodeObject:favMedsSet forKey:@"kFavMedsSet"];
}

/** Called when you try to unarchive class using NSKeyedUnarchiver
 */
- (id) initWithCoder: (NSCoder *)decoder
{
    self = [super init];
    if (self != nil) {
        // In a dictionary -> objectForKey:
        favMedsSet = [decoder decodeObjectForKey:@"kFavMedsSet"];
    }
    return self;
}

@end
