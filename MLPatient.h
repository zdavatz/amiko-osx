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

#import <Foundation/Foundation.h>

enum database_t {
    eLocal=0, eAddressBook=1
};

@interface MLPatient : NSObject

@property (atomic, assign) long rowId;
@property (atomic, copy) NSString *uniqueId;
@property (atomic, copy) NSString *familyName;
@property (atomic, copy) NSString *givenName;
@property (atomic, copy) NSString *birthDate;
@property (atomic, copy) NSString *gender;
@property (atomic, assign) int weightKg;
@property (atomic, assign) int heightCm;
@property (atomic, copy) NSString *zipCode;
@property (atomic, copy) NSString *city;
@property (atomic, copy) NSString *country;
@property (atomic, copy) NSString *postalAddress;
@property (atomic, copy) NSString *phoneNumber;
@property (atomic, copy) NSString *emailAddress;
@property (atomic, assign) enum database_t databaseType;

- (NSString *) generateUniqueID;
- (NSString *) asString;

@end
