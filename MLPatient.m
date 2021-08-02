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
@synthesize healthCardExpiry;
@synthesize insuranceGLN;

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
    healthCardExpiry = [self getString:KEY_AMK_PAT_HEALTH_CARD_EXPIRY orNilFromDict:dict];
    insuranceGLN =  [self getString:KEY_AMK_PAT_INSURANCE_GLN orNilFromDict:dict];
    
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
    [patientDict setObject:self.healthCardExpiry ?: @"" forKey:KEY_AMK_PAT_HEALTH_CARD_EXPIRY];
    [patientDict setObject:self.insuranceGLN  ?: @"" forKey:KEY_AMK_PAT_INSURANCE_GLN];
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

- (NSDictionary *)findParticipantsKvg {
    NSLog(@"Patient findParticipantsKvg '%@'", self.bagNumber);
    NSString *jsonPath = [[NSBundle mainBundle] pathForResource:@"participants-kvg" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:jsonPath
                                          options:0
                                            error:nil];
    NSArray *dicts = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    NSMutableString *myBagNumberStr = [NSMutableString string];
    for (NSUInteger i = 0; i < self.bagNumber.length; i++) {
        unichar character = [self.bagNumber characterAtIndex:i];
        if (character >= '0' && character <= '9') {
            [myBagNumberStr appendString:[NSString stringWithCharacters:&character length:1]];
        }
    }
    
    for (NSDictionary *dict in dicts) {
        NSNumber *bagNumber = dict[@"bagNumber"];
        if ([bagNumber isKindOfClass:[NSNumber class]]) {
            if (myBagNumberStr.integerValue == bagNumber.integerValue) {
                return dict;
            }
        }
    }
    return nil;
}

- (NSString *)findParticipantGLN {
    return [self.insuranceGLN length] ? self.insuranceGLN : [self findParticipantsKvg][@"glnParticipant"];
}

- (NSString *)findCantonShortCode {
    NSString *csvPath = [[NSBundle mainBundle] pathForResource:@"Postleitzahlen-Schweiz" ofType:@"csv"];
    NSData *data = [NSData dataWithContentsOfFile:csvPath
                                          options:0
                                            error:nil];
    NSString *csvString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSArray<NSString *> *rows = [csvString componentsSeparatedByString:@"\n"];
    for (NSInteger rowIndex = 1; rowIndex < [rows count]; rowIndex++) {
        NSArray *cols = [rows[rowIndex] componentsSeparatedByString:@";"];
        if ([cols count] < 6) continue;
        NSString *zipCode = cols[0];
        NSString *cityName = cols[1];
        NSString *canton1 = cols[2];
        NSString *canton2 = cols[3];
        NSString *canton3 = cols[4];
        NSString *shortCode = cols[5];
        if ([self.zipCode integerValue] == [zipCode integerValue]
            || [self.city.lowercaseString isEqualToString:cityName.lowercaseString]
            || [self.city.lowercaseString isEqualToString:canton1.lowercaseString]
            || [self.city.lowercaseString isEqualToString:canton2.lowercaseString]
            || [self.city.lowercaseString isEqualToString:canton3.lowercaseString]
            ) {
            return shortCode;
        }
    }
    return nil;
}

@end
