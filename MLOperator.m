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

#import "MLOperator.h"

@implementation MLOperator

@synthesize title;
@synthesize familyName;
@synthesize givenName;
@synthesize postalAddress;
@synthesize zipCode;
@synthesize city;
@synthesize country;
@synthesize phoneNumber;
@synthesize emailAddress;

- (NSString *) retrieveOperatorAsString
{
    if (title==nil)
        title = @"";
    if (postalAddress==nil)
        postalAddress = @"";
    if (zipCode==nil)
        zipCode = @"";
    if (city==nil)
        city = @"";
    if (phoneNumber==nil)
        phoneNumber = @"";
    if (emailAddress==nil)
        emailAddress = @"";
    if (givenName==nil)
        givenName = @"";
    
    if (familyName!=nil) {
        return [NSString stringWithFormat:@"%@ %@ %@\r\n%@\r\n%@ %@\r\n%@\r\n%@",
                title, givenName, familyName, postalAddress, zipCode, city, phoneNumber, emailAddress];
    } else {
        return @"...";
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ title:%@, givenName:%@, familyName:%@",
            NSStringFromClass([self class]), title, givenName, familyName];
}

@end
