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
#import "MLUtilities.h"

@implementation MLPatient

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
@synthesize bagNumber;
@synthesize healthCardNumber;

- (void)importFromDict:(NSDictionary *)dict
{
    uniqueId =      [self getString:KEY_AMK_PAT_ID orNilFromDict:dict];
    familyName =    [self getString:KEY_AMK_PAT_SURNAME orNilFromDict:dict];
    givenName =     [self getString:KEY_AMK_PAT_NAME orNilFromDict:dict];
    birthDate =     [self getString:KEY_AMK_PAT_BIRTHDATE orNilFromDict:dict];
    weightKg =      [[self getString:KEY_AMK_PAT_WEIGHT orNilFromDict:dict] intValue];
    heightCm =      [[self getString:KEY_AMK_PAT_HEIGHT orNilFromDict:dict] intValue];
    gender =        [self getString:KEY_AMK_PAT_GENDER orNilFromDict:dict];
    postalAddress = [self getString:KEY_AMK_PAT_ADDRESS orNilFromDict:dict];
    zipCode =       [self getString:KEY_AMK_PAT_ZIP orNilFromDict:dict];
    city =          [self getString:KEY_AMK_PAT_CITY orNilFromDict:dict];
    country =       [self getString:KEY_AMK_PAT_COUNTRY orNilFromDict:dict];
    phoneNumber =   [self getString:KEY_AMK_PAT_PHONE orNilFromDict:dict];
    emailAddress =  [self getString:KEY_AMK_PAT_EMAIL orNilFromDict:dict];
    bagNumber =     [self getString:KEY_AMK_PAT_BAG_NUMBER orNilFromDict:dict];
    healthCardNumber = [self getString:KEY_AMK_PAT_HEALTH_CARD_NUMBER orNilFromDict:dict];
    
    NSString *newUniqueID = [self generateUniqueID];
    
    if (!uniqueId.length) { // The ID was not defined from the dictionary
        uniqueId = newUniqueID; // assign it here
    }
    else if (![uniqueId isEqualToString:newUniqueID]) {
        NSLog(@"WARNING: imported ID:%@, expected ID %@", uniqueId, newUniqueID);
    }
}

- (NSDictionary <NSString *, NSString *> *)dictionaryRepresentation {
    NSMutableDictionary *patientDict = [[NSMutableDictionary alloc] init];
    [patientDict setObject:self.uniqueId             forKey:KEY_AMK_PAT_ID];
    [patientDict setObject:self.familyName           forKey:KEY_AMK_PAT_SURNAME];
    [patientDict setObject:self.givenName            forKey:KEY_AMK_PAT_NAME];
    [patientDict setObject:self.birthDate            forKey:KEY_AMK_PAT_BIRTHDATE];
    [patientDict setObject:self.gender        ?: @"" forKey:KEY_AMK_PAT_GENDER];
    [patientDict setObject:[NSString stringWithFormat:@"%d", self.weightKg] forKey:KEY_AMK_PAT_WEIGHT];
    [patientDict setObject:[NSString stringWithFormat:@"%d", self.heightCm] forKey:KEY_AMK_PAT_HEIGHT];
    [patientDict setObject:self.postalAddress ?: @"" forKey:KEY_AMK_PAT_ADDRESS];
    [patientDict setObject:self.zipCode       ?: @"" forKey:KEY_AMK_PAT_ZIP];
    [patientDict setObject:self.city          ?: @"" forKey:KEY_AMK_PAT_CITY];
    [patientDict setObject:self.country       ?: @"" forKey:KEY_AMK_PAT_COUNTRY];
    [patientDict setObject:self.phoneNumber   ?: @"" forKey:KEY_AMK_PAT_PHONE];
    [patientDict setObject:self.emailAddress  ?: @"" forKey:KEY_AMK_PAT_EMAIL];
    [patientDict setObject:self.bagNumber     ?: @"" forKey:KEY_AMK_PAT_BAG_NUMBER];
    [patientDict setObject:self.healthCardNumber ?: @"" forKey:KEY_AMK_PAT_HEALTH_CARD_NUMBER];
    return patientDict;
}

- (NSString *) generateUniqueID
{
    NSString *birthDateString = birthDate;
    
    // Transform birthday string from 05.05.2000 to 5.5.2000
    NSArray<NSString*> *parts = [birthDate componentsSeparatedByString:@"."];
    if ([parts count] == 3) {
        NSString *dayString = parts[0];
        NSString *monthString = parts[1];
        NSString *yearString = parts[2];
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        NSNumber *dayNum = [formatter numberFromString:dayString];
        NSNumber *monthNum = [formatter numberFromString:monthString];
        NSNumber *yearNum = [formatter numberFromString:yearString];
        birthDateString = [NSString stringWithFormat:@"%d.%d.%d", dayNum.intValue, monthNum.intValue, yearNum.intValue];
    }

    // The UUID should be unique and should be based on familyname, givenname, and birthday
    NSString *str = [NSString stringWithFormat:@"%@.%@.%@", [familyName lowercaseString] , [givenName lowercaseString], birthDateString];
    NSString *hashed = [MLUtilities sha256:str];
    return hashed;
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

- (NSString*)getString:(NSString *)key orNilFromDict:(NSDictionary *)dict {
    id obj = [dict objectForKey:key];
    if ([obj isKindOfClass:[NSString class]]) {
        return obj;
    }
    return nil;
}

@end
