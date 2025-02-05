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

#define KEY_AMK_PAT_ID          @"patient_id"
#define KEY_AMK_PAT_NAME        @"given_name"
#define KEY_AMK_PAT_SURNAME     @"family_name"
#define KEY_AMK_PAT_BIRTHDATE   @"birth_date"
#define KEY_AMK_PAT_WEIGHT      @"weight_kg"
#define KEY_AMK_PAT_HEIGHT      @"height_cm"
#define KEY_AMK_PAT_GENDER      @"gender"
#define KEY_AMK_PAT_ADDRESS     @"postal_address"
#define KEY_AMK_PAT_ZIP         @"zip_code"
#define KEY_AMK_PAT_CITY        @"city"
#define KEY_AMK_PAT_COUNTRY     @"country"
#define KEY_AMK_PAT_PHONE       @"phone_number"
#define KEY_AMK_PAT_EMAIL       @"email_address"
#define KEY_AMK_PAT_BAG_NUMBER  @"bag_number"
#define KEY_AMK_PAT_HEALTH_CARD_NUMBER @"health_card_number"
#define KEY_AMK_PAT_HEALTH_CARD_EXPIRY @"health_card_expiry"
#define KEY_AMK_PAT_INSURANCE_GLN @"insurance_gln"

enum database_t {
    eLocal=0, eAddressBook=1
};

@interface MLPatient : NSObject

@property (atomic, copy, nullable) NSString *uniqueId;
@property (atomic, copy, nullable) NSString *familyName;
@property (atomic, copy, nullable) NSString *givenName;
@property (atomic, copy, nullable) NSString *birthDate;
@property (atomic, copy, nullable) NSString *gender;
@property (atomic, assign) int weightKg;
@property (atomic, assign) int heightCm;
@property (atomic, copy, nullable) NSString *zipCode;
@property (atomic, copy, nullable) NSString *city;
@property (atomic, copy, nullable) NSString *country;
@property (atomic, copy, nullable) NSString *postalAddress;
@property (atomic, copy, nullable) NSString *phoneNumber;
@property (atomic, copy, nullable) NSString *emailAddress;
@property (atomic, copy, nullable) NSString *bagNumber;
@property (atomic, copy, nullable) NSString *healthCardNumber;
@property (atomic, copy, nullable) NSString *healthCardExpiry;
@property (atomic, copy, nullable) NSString *insuranceGLN;
@property (atomic, assign) enum database_t databaseType;

// Only available when patient is read from database
@property (nonatomic, strong, nullable) NSDate *timestamp;

- (void)importFromDict:(NSDictionary * _Nonnull)dict;
- (NSDictionary <NSString *, NSString *> * _Nonnull)dictionaryRepresentation;
- (NSString * _Nonnull)generateUniqueID;
- (NSString * _Nonnull)asString;
- (NSDictionary * _Nullable)findParticipantsKvg;
- (NSString * _Nullable)findParticipantGLN;
- (NSString * _Nullable)findCantonShortCode;

@end
