/*
 
 Copyright (c) 2017 Max Lungarella <cybrmx@gmail.com>
 
 Created on 18/08/2017.
 
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
#import "MLContacts.h"
#import "MLOperator.h"

@interface MLPrescriptionsAdapter : NSObject

@property (atomic) NSArray *cart;
@property (atomic) MLPatient *patient;
@property (atomic) MLOperator *doctor;
@property (atomic) NSString *placeDate;

- (NSArray *) listOfPrescriptionsForPatient:(MLPatient *)p;
- (NSArray *) listOfPrescriptionURLsForPatient:(MLPatient *)p;

- (void) deletePrescriptionWithName:(NSString *)name forPatient:(MLPatient *)p;
- (void) deleteAllPrescriptionsForPatient:(MLPatient *)p withBackup:(BOOL)backup;

- (NSURL *) savePrescriptionForPatient:(MLPatient *)p withUniqueHash:(NSString *)hash andOverwrite:(BOOL)overwrite;

- (NSString *) loadPrescriptionWithName:(NSString *)fileName forPatient:(MLPatient *)p;
- (NSString *) loadPrescriptionFromFile:(NSString *)filePath;

- (NSURL *) getPrescriptionUrl;
@end
