/*
 
 Copyright (c) 2017 Max Lungarella <cybrmx@gmail.com>
 
 Created on 30/06/2017.
 
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

#import "MLContacts.h"
#import "MLPatient.h"

@implementation MLContacts
{
    NSMutableArray *groupOfContacts;
}

- (id) init
{
    if (self = [super init]) {
        return self;
    }
    return nil;
}

- (NSArray *) getAllContacts
{
    groupOfContacts = [NSMutableArray array];

    [self addAllContactsToArray:groupOfContacts];
    
    return groupOfContacts;
}

- (NSArray *) addAllContactsToArray:(NSMutableArray *)arrayOfContacts
{
    CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
    if (![CNContactStore class]) {
        return @[];
    }
    CNContactStore *addressBook = [[CNContactStore alloc] init];
    if (status != CNAuthorizationStatusAuthorized) {
        NSLog(@"This app was refused permissions to contacts.");
        return @[];
    }
    
    NSArray *keys = @[CNContactIdentifierKey,
                      CNContactFamilyNameKey,
                      CNContactGivenNameKey,
                      CNContactBirthdayKey,
                      CNContactPostalAddressesKey,
                      CNContactPhoneNumbersKey,
                      CNContactEmailAddressesKey];
    
    CNContactFetchRequest *request = [[CNContactFetchRequest alloc] initWithKeysToFetch:keys];
    
    NSError *error;
    [addressBook enumerateContactsWithFetchRequest:request
                                             error:&error
                                        usingBlock:^(CNContact * __nonnull contact, BOOL * __nonnull stop) {
                                            if (error) {
                                                NSLog(@"error fetching contacts %@", error);
                                            } else {
                                                MLPatient *patient = [[MLPatient alloc] init];
                                                patient.familyName = contact.familyName;
                                                patient.givenName = contact.givenName;
                                                // Postal address
                                                patient.postalAddress = @"";
                                                patient.zipCode = @"";
                                                patient.city = @"";
                                                patient.country = @"";
                                                if ([contact.postalAddresses count]>0) {
                                                    CNPostalAddress *pa = [contact.postalAddresses[0] value];
                                                    patient.postalAddress = pa.street;
                                                    patient.zipCode = pa.postalCode;
                                                    patient.city = pa.city;
                                                    patient.country = pa.country;
                                                }
                                                // Email address
                                                patient.emailAddress = @"";
                                                if ([contact.emailAddresses count]>0)
                                                    patient.emailAddress = [contact.emailAddresses[0] value];
                                                // Birthdate
                                                patient.birthDate = @"";
                                                if (contact.birthday.year>1900)
                                                    patient.birthDate = [NSString stringWithFormat:@"%ld-%ld-%ld", contact.birthday.day, contact.birthday.month, contact.birthday.year];
                                                // Phone number
                                                patient.phoneNumber = @"";
                                                if ([contact.phoneNumbers count]>0)
                                                    patient.phoneNumber = [[contact.phoneNumbers[0] value] stringValue];
                                                // Add only if patients names are meaningful
                                                if ([patient.familyName length]>0 && [patient.givenName length]>0) {
                                                    patient.databaseType = eAddressBook;
                                                    [arrayOfContacts addObject:patient];
                                                }
                                            }
                                        }];
    // Sort alphabetically
    if ([arrayOfContacts count]>0) {
        NSSortDescriptor *nameSort = [NSSortDescriptor sortDescriptorWithKey:@"familyName" ascending:YES];
        [arrayOfContacts sortUsingDescriptors:[NSArray arrayWithObject:nameSort]];
    }
    
    return arrayOfContacts;
}

@end
