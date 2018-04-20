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
