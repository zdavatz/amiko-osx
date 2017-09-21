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

#import "MLPrescriptionsAdapter.h"

#import "MLUtilities.h"
#import "MLPrescriptionItem.h"

@implementation MLPrescriptionsAdapter
{
    NSString *currentFileName;
}

@synthesize cart;
@synthesize patient;

- (NSArray *) listOfPrescriptionsForPatient:(MLPatient *)p
{
    NSMutableArray *amkFiles = [[NSMutableArray alloc] init];

    NSString *documentsDir = [MLUtilities documentsDirectory];
    // Check if patient has already a directory, if not create one
    NSString *patientDir = [documentsDir stringByAppendingString:[NSString stringWithFormat:@"/%@", p.uniqueId]];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = false;
    [fileManager fileExistsAtPath:patientDir isDirectory:&isDir];
    if (isDir) {
        // List content of directory
        NSArray* dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:patientDir error:NULL];
        [dirs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString *filename = (NSString *)obj;
            NSString *extension = [[filename pathExtension] lowercaseString];
            if ([extension isEqualToString:@"amk"]) {
                filename = [filename stringByReplacingOccurrencesOfString:@".amk" withString:@""];
                [amkFiles addObject:filename];
            }
        }];
    }
    
    return amkFiles;
}

- (NSArray *) listOfPrescriptionURLsForPatient:(MLPatient *)p
{
    NSMutableArray *amkURLs = [[NSMutableArray alloc] init];
    
    NSString *documentsDir = [MLUtilities documentsDirectory];
    // Check if patient has already a directory, if not create one
    NSString *patientDir = [documentsDir stringByAppendingString:[NSString stringWithFormat:@"/%@", p.uniqueId]];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = false;
    [fileManager fileExistsAtPath:patientDir isDirectory:&isDir];
    if (isDir) {
        // List content of directory
        NSArray* dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:patientDir error:NULL];
        [dirs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString *filename = (NSString *)obj;
            NSString *extension = [[filename pathExtension] lowercaseString];
            if ([extension isEqualToString:@"amk"]) {
                [amkURLs addObject:[NSString stringWithFormat:@"%@/%@", patientDir, filename]];
            }
        }];
    }
    
    return amkURLs;
}

- (NSURL *) savePrescriptionForPatient:(MLPatient *)p withUniqueHash:(NSString *)hash andOverwrite:(BOOL)overwrite
{
    if (p!=nil) {
        // Assign patient
        patient = p;
        
        NSString *documentsDir = [MLUtilities documentsDirectory];
        // Check if patient has already a directory, if not create one
        NSString *patientDir = [documentsDir stringByAppendingString:[NSString stringWithFormat:@"/%@", patient.uniqueId]];
        
        if (overwrite) {
            // Delete old file
            NSError *error = nil;
            NSString *path = [NSString stringWithFormat:@"%@/%@", patientDir, currentFileName];
            BOOL success = [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
            if (!success) {
                NSLog(@"Error: %@", [error userInfo]);
            }
        }
        
        NSString *currentTime = [[MLUtilities currentTime] stringByReplacingOccurrencesOfString:@":" withString:@""];
        currentTime = [currentTime stringByReplacingOccurrencesOfString:@"." withString:@""];
        NSString *fileName = [NSString stringWithFormat:@"RZ_%@.amk", currentTime];

        // Assign filename
        currentFileName = fileName;

        [[NSFileManager defaultManager] createDirectoryAtPath:patientDir withIntermediateDirectories:YES attributes:nil error:nil];
        NSString *path = [NSString stringWithFormat:@"%@/%@", patientDir, fileName];
        
        NSMutableDictionary *prescriptionDict = [[NSMutableDictionary alloc] init];
        
        NSMutableDictionary *patientDict = [[NSMutableDictionary alloc] init];
        [patientDict setObject:patient.uniqueId forKey:@"patient_id"];
        [patientDict setObject:patient.familyName forKey:@"family_name"];
        [patientDict setObject:patient.givenName forKey:@"given_name"];
        [patientDict setObject:patient.birthDate forKey:@"birth_date"];
        [patientDict setObject:patient.gender forKey:@"gender"];
        [patientDict setObject:[NSString stringWithFormat:@"%d", patient.weightKg] forKey:@"weight_kg"];
        [patientDict setObject:[NSString stringWithFormat:@"%d", patient.heightCm] forKey:@"height_cm"];
        [patientDict setObject:patient.postalAddress forKey:@"postal_address"];
        [patientDict setObject:patient.zipCode forKey:@"zip_code"];
        [patientDict setObject:patient.city forKey:@"city"];
        [patientDict setObject:patient.country forKey:@"country"];
        [patientDict setObject:patient.phoneNumber forKey:@"phone_number"];
        [patientDict setObject:patient.emailAddress forKey:@"email_address"];
        
        NSMutableDictionary *operatorDict = [[NSMutableDictionary alloc] init];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [operatorDict setObject:[defaults stringForKey:@"title"] forKey:@"title"];
        [operatorDict setObject:[defaults stringForKey:@"familyname"] forKey:@"family_name"];
        [operatorDict setObject:[defaults stringForKey:@"givenname"] forKey:@"given_name"];
        [operatorDict setObject:[defaults stringForKey:@"postaladdress"] forKey:@"postal_address"];
        [operatorDict setObject:[defaults stringForKey:@"zipcode"] forKey:@"zip_code"];
        [operatorDict setObject:[defaults stringForKey:@"city"] forKey:@"city"];
        [operatorDict setObject:[defaults stringForKey:@"phonenumber"] forKey:@"phone_number"];
        [operatorDict setObject:[defaults stringForKey:@"emailaddress"] forKey:@"email_address"];
        
        NSString *encodedImgStr = @"";
        NSString *filePath = [[MLUtilities documentsDirectory] stringByAppendingPathComponent:@"op_signature.png"];
        if (filePath!=nil) {
            NSImage *img = [[NSImage alloc] initWithContentsOfFile:filePath];
            NSData *imgData = [img TIFFRepresentation];
            NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imgData];
            NSData *data = [imageRep representationUsingType:NSPNGFileType properties:@{}];
            encodedImgStr = [data base64Encoding];
        }
        [operatorDict setObject:encodedImgStr forKey:@"signature"];
        
        NSMutableArray *prescription = [[NSMutableArray alloc] init];
        for (MLPrescriptionItem *item in cart) {
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
            [dict setObject:item.title forKey:@"product_name"];
            [dict setObject:item.fullPackageInfo forKey:@"package"];
            [dict setObject:item.med.auth forKey:@"owner"];
            [dict setObject:item.med.regnrs forKey:@"regnrs"];
            [dict setObject:item.comment forKey:@"comment"];
            [prescription addObject:dict];
        }
                
        [prescriptionDict setObject:hash forKey:@"prescription_hash"];
        [prescriptionDict setObject:currentTime forKey:@"date"];
        [prescriptionDict setObject:patientDict forKey:@"patient"];
        [prescriptionDict setObject:operatorDict forKey:@"operator"];
        [prescriptionDict setObject:prescription forKey:@"medications"];
        
        // Map cart array to json
        NSError *error = nil;
        NSData *jsonObject = [NSJSONSerialization dataWithJSONObject:prescriptionDict
                                                             options:NSJSONWritingPrettyPrinted
                                                               error:&error];
        // BOOL success = [jsonObject writeToFile:path options:NSUTF8StringEncoding error:&error];
        
        NSString *jsonStr = [[NSString alloc] initWithData:jsonObject encoding:NSUTF8StringEncoding];
        NSString *base64Str = [MLUtilities encodeStringToBase64:jsonStr];
        
        BOOL success = [base64Str writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
        if (!success) {
            NSLog(@"Error: %@", [error userInfo]);
        }

        return [[NSURL alloc] initWithString:path];
    }
    return nil;
}

- (void) loadPrescriptionFromFile:(NSString *)filePath
{
    NSError *error = nil;
    NSString *base64Str = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    NSString *jsonStr = [MLUtilities decodeBase64ToString:base64Str];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:[jsonStr dataUsingEncoding:NSUTF8StringEncoding]
                                                             options: NSJSONReadingMutableContainers
                                                               error:&error];
    
    NSMutableArray *prescription = [[NSMutableArray alloc] init];
    for (NSDictionary *p in [jsonDict objectForKey:@"medications"]) {
        MLPrescriptionItem *item = [[MLPrescriptionItem alloc] init];
        item.title = [p objectForKey:@"product_name"];
        item.fullPackageInfo = [p objectForKey:@"package"];
        item.comment = [p objectForKey:@"comment"];
        MLMedication *med = [[MLMedication alloc] init];
        med.auth = [p objectForKey:@"owner"];
        med.regnrs = [p objectForKey:@"regnrs"];
        item.med = med;
        [prescription addObject:item];
    }
    cart = [prescription copy];
}

- (void) loadPrescriptionWithName:(NSString *)fileName forPatient:(MLPatient *)p
{
    NSString *documentsDir = [MLUtilities documentsDirectory];
    // Check if patient has already a directory, if not create one
    NSString *filePath = [documentsDir stringByAppendingString:[NSString stringWithFormat:@"/%@/%@.amk", p.uniqueId, fileName]];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]) {
        [self loadPrescriptionFromFile:filePath];
        currentFileName = [NSString stringWithFormat:@"%@.amk", fileName];
    }
}

@end
