/*
 
 Copyright (c) 2017 Max Lungarella <cybrmx@gmail.com>
 
 Created on 27/10/2017.
 
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

#define LEGACY_DEFAULTS_DOC_TITLE      @"title"
#define LEGACY_DEFAULTS_DOC_NAME       @"givenname"
#define LEGACY_DEFAULTS_DOC_SURNAME    @"familyname"
#define LEGACY_DEFAULTS_DOC_ADDRESS    @"postaladdress"
#define LEGACY_DEFAULTS_DOC_CITY       @"city"
#define LEGACY_DEFAULTS_DOC_ZIP        @"zipcode"
#define LEGACY_DEFAULTS_DOC_PHONE      @"phonenumber"
#define LEGACY_DEFAULTS_DOC_EMAIL      @"emailaddress"
#define LEGACY_DEFAULTS_DOC_COUNTRY    @"country"

#define KEY_AMK_DOC_TITLE       @"title"
#define KEY_AMK_DOC_NAME        @"given_name"
#define KEY_AMK_DOC_SURNAME     @"family_name"
#define KEY_AMK_DOC_ADDRESS     @"postal_address"
#define KEY_AMK_DOC_CITY        @"city"
#define KEY_AMK_DOC_COUNTRY     @"country"
#define KEY_AMK_DOC_ZIP         @"zip_code"
#define KEY_AMK_DOC_PHONE       @"phone_number"
#define KEY_AMK_DOC_EMAIL       @"email_address"

#define KEY_AMK_DOC_SIGNATURE   @"signature"
#define DOC_SIGNATURE_FILENAME  @"op_signature.png"

@interface MLOperator : NSObject

@property (atomic, copy) NSString *title;
@property (atomic, copy) NSString *familyName;
@property (atomic, copy) NSString *givenName;
@property (atomic, copy) NSString *postalAddress;
@property (atomic, copy) NSString *zipCode;
@property (atomic, copy) NSString *city;
@property (atomic, copy) NSString *country;
@property (atomic, copy) NSString *phoneNumber;
@property (atomic, copy) NSString *emailAddress;

- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSString *) retrieveOperatorAsString;
- (void)importFromDict:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

@end
