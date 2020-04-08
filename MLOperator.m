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

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    if (self = [super init]) {
        [self importFromDict:dict];
    }
    return self;
}

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

- (void)importFromDict:(NSDictionary *)dict
{
    title =         [dict objectForKey:KEY_AMK_DOC_TITLE];
    familyName =    [dict objectForKey:KEY_AMK_DOC_SURNAME];
    givenName =     [dict objectForKey:KEY_AMK_DOC_NAME];
    postalAddress = [dict objectForKey:KEY_AMK_DOC_ADDRESS];
    zipCode =       [dict objectForKey:KEY_AMK_DOC_ZIP];
    city =          [dict objectForKey:KEY_AMK_DOC_CITY];
    country =       [dict objectForKey:KEY_AMK_DOC_COUNTRY] ?: @"";
    phoneNumber =   [dict objectForKey:KEY_AMK_DOC_PHONE];
    emailAddress =  [dict objectForKey:KEY_AMK_DOC_EMAIL];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ title:%@, givenName:%@, familyName:%@",
            NSStringFromClass([self class]), title, givenName, familyName];
}

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *doctorDict = [NSMutableDictionary new];
    doctorDict[KEY_AMK_DOC_TITLE] = self.title;
    doctorDict[KEY_AMK_DOC_NAME] = self.givenName;
    doctorDict[KEY_AMK_DOC_SURNAME] = self.familyName;
    doctorDict[KEY_AMK_DOC_ADDRESS] = self.postalAddress;
    doctorDict[KEY_AMK_DOC_CITY] = self.city;
    doctorDict[KEY_AMK_DOC_COUNTRY] = self.country;
    doctorDict[KEY_AMK_DOC_ZIP] = self.zipCode;
    doctorDict[KEY_AMK_DOC_PHONE] = self.phoneNumber;
    doctorDict[KEY_AMK_DOC_EMAIL] = self.emailAddress;
    return doctorDict;
}

@end
