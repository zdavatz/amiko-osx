/*
 
 Copyright (c) 2017 Max Lungarella <cybrmx@gmail.com>
 
 Created on 28/06/2017.
 
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

#import "MLPatient.h"

@implementation MLPatient

@synthesize rowId;
@synthesize uniqueId;
@synthesize familyName;
@synthesize givenName;
@synthesize birthDate;
@synthesize gender;
@synthesize weightKg;
@synthesize heightCm;
@synthesize zipCode;
@synthesize city;
@synthesize country;
@synthesize postalAddress;
@synthesize phoneNumber;
@synthesize emailAddress;
@synthesize databaseType;

- (void)importFromDict:(NSDictionary *)dict
{
    uniqueId =      [dict objectForKey: KEY_AMK_PAT_ID];
    familyName =    [dict objectForKey: KEY_AMK_PAT_SURNAME];
    givenName =     [dict objectForKey: KEY_AMK_PAT_NAME];
    birthDate =     [dict objectForKey: KEY_AMK_PAT_BIRTHDATE];
    weightKg =      [[dict objectForKey:KEY_AMK_PAT_WEIGHT] intValue];
    heightCm =      [[dict objectForKey:KEY_AMK_PAT_HEIGHT] intValue];
    gender =        [dict objectForKey: KEY_AMK_PAT_GENDER];
    postalAddress = [dict objectForKey: KEY_AMK_PAT_ADDRESS];
    zipCode =       [dict objectForKey: KEY_AMK_PAT_ZIP];
    city =          [dict objectForKey: KEY_AMK_PAT_CITY];
    country =       [dict objectForKey: KEY_AMK_PAT_COUNTRY];
    phoneNumber =   [dict objectForKey: KEY_AMK_PAT_PHONE];
    emailAddress =  [dict objectForKey: KEY_AMK_PAT_EMAIL];
    
    NSString *newUniqueID = [self generateUniqueID];
    
    if (!uniqueId.length) { // The ID was not defined from the dictionary
        uniqueId = newUniqueID; // assign it here
    }
    else if (![uniqueId isEqualToString:newUniqueID]) {
        NSLog(@"WARNING: imported ID:%@, expected ID %@", uniqueId, newUniqueID);
    }
}

- (NSString *) generateUniqueID
{
    // The UUID should be unique and should be based on familyname, givenname, and birthday
    NSUInteger uniqueHash = [[NSString stringWithFormat:@"%@.%@.%@", familyName , givenName, birthDate] hash];
    return [NSString stringWithFormat:@"%lu", uniqueHash];    // e.g. 3466684318797166812
}

- (NSString *) asString
{
    return [NSString stringWithFormat:@"%@ %@\r\n%@\r\nCH-%@ %@\r\n%@\r\n%@", givenName, familyName, postalAddress, zipCode, city, phoneNumber, emailAddress];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ givenName:%@, familyName:%@, birthDate:%@, uniqueId:%@",
            NSStringFromClass([self class]), givenName, familyName, birthDate, uniqueId];
}

@end
