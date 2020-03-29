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

#import "MLPersistenceManager.h"
#import "MLUtilities.h"
#import "MLPrescriptionItem.h"

@implementation MLPrescriptionsAdapter
{
    NSString *currentFileName;
}

@synthesize cart;
@synthesize patient;
@synthesize doctor;
@synthesize placeDate;

// Returns an array of filenames (NSString),
// just the basename with the extension ".amk" stripped off
- (NSArray *) listOfPrescriptionsForPatient:(MLPatient *)p
{
    if (!p) {
#ifdef DEBUG
        NSLog(@"%s MLPatient not defined", __FUNCTION__);
#endif
        return nil;
    }

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
        
        // Sort
        NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:nil ascending:NO];
        NSArray *sortedArray = [[NSArray arrayWithArray:amkFiles] sortedArrayUsingDescriptors:@[sd]];
        amkFiles = [sortedArray mutableCopy];
    }

    return amkFiles;
}

// Returns an array of filenames (NSString), the full path
- (NSArray *) listOfPrescriptionURLsForPatient:(MLPatient *)p
{
    if (!p) {
#ifdef DEBUG
        NSLog(@"%s MLPatient not defined", __FUNCTION__);
#endif
        return nil;
    }

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

        // Sort
        NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:nil ascending:NO];
        NSArray *sortedArray = [[NSArray arrayWithArray:amkURLs] sortedArrayUsingDescriptors:@[sd]];
        amkURLs = [sortedArray mutableCopy];
    }
    
    return amkURLs;
}

- (void) deletePrescriptionWithName:(NSString *)name forPatient:(MLPatient *)p
{
    if (p!=nil) {
        // Assign patient
        patient = p;
        
        NSString *documentsDir = [MLUtilities documentsDirectory];
        // Check if patient has already a directory, if not create one
        NSString *patientDir = [documentsDir stringByAppendingString:[NSString stringWithFormat:@"/%@", patient.uniqueId]];
        
        // Delete file
        NSError *error = nil;
        NSString *path = [NSString stringWithFormat:@"%@/%@.amk", patientDir, name];
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        if (!success) {
            NSLog(@"Error: %@", [error userInfo]);
        }
    }
}

- (void) deleteAllPrescriptionsForPatient:(MLPatient *)p withBackup:(BOOL)backup
{
    if (p!=nil) {
        // Assign patient
        patient = p;
        
        NSString *documentsDir = [MLUtilities documentsDirectory];
        NSString *patientDir = [documentsDir stringByAppendingString:[NSString stringWithFormat:@"/%@", patient.uniqueId]];
        
        if (backup==YES) {
            NSString *backupDir = [NSString stringWithFormat:@".%@", patientDir];
            [[NSFileManager defaultManager] moveItemAtPath:patientDir toPath:backupDir error:nil];
        } else {
            [[NSFileManager defaultManager] removeItemAtPath:patientDir error:nil];
        }
    }
}

- (NSURL *) getPrescriptionUrl
{
    return [[NSURL alloc] initWithString:currentFileName];
}

// It will in any case create a new file
// if the overwrite flag is set, delete the original file
- (NSURL *) savePrescriptionForPatient:(MLPatient *)p
                        withUniqueHash:(NSString *)hash
                          andOverwrite:(BOOL)overwrite
{
    if (!p) {
        NSLog(@"%s %d, patient not defined", __FUNCTION__, __LINE__);
        return nil;
    }

    if (overwrite && !currentFileName) {
        NSLog(@"%s %d, cannot overwrite an empty filename", __FUNCTION__, __LINE__);
        return nil;
    }

    if ([cart count] < 1) {
        NSLog(@"%s %d, cart is empty", __FUNCTION__, __LINE__);
        return nil;
    }

    // Assign patient
    patient = p;
    
    NSString *documentsDir = [MLUtilities documentsDirectory];
    // Check if patient has already a directory, if not create one
    NSString *patientDir = [documentsDir stringByAppendingString:[NSString stringWithFormat:@"/%@", patient.uniqueId]];
    
    if (overwrite) {
        // Delete old file
        NSError *error = nil;
        NSString *path = currentFileName; // full path. Okay when coming from "Send" button
        //NSLog(@"%s %d, will delete:<%@>", __FUNCTION__, __LINE__, path);
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        if (!success) {
            NSLog(@"Error: %@", [error userInfo]);
        }
    }
    
    // Define a new filename
    NSString *currentTime = [[MLUtilities currentTime] stringByReplacingOccurrencesOfString:@":" withString:@""];
    currentTime = [currentTime stringByReplacingOccurrencesOfString:@"." withString:@""];
    NSString *fileName = [NSString stringWithFormat:@"RZ_%@.amk", currentTime];
    
    [[NSFileManager defaultManager] createDirectoryAtPath:patientDir withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *path = [NSString stringWithFormat:@"%@/%@", patientDir, fileName];

    currentFileName = path;  // full path
    NSLog(@"%s new currentFileName:%@", __FUNCTION__, currentFileName);

    NSMutableDictionary *prescriptionDict = [[NSMutableDictionary alloc] init];
    
    NSMutableDictionary *patientDict = [[NSMutableDictionary alloc] init];
    [patientDict setObject:patient.uniqueId      forKey:KEY_AMK_PAT_ID];
    [patientDict setObject:patient.familyName    forKey:KEY_AMK_PAT_SURNAME];
    [patientDict setObject:patient.givenName     forKey:KEY_AMK_PAT_NAME];
    [patientDict setObject:patient.birthDate     forKey:KEY_AMK_PAT_BIRTHDATE];
    [patientDict setObject:patient.gender        forKey:KEY_AMK_PAT_GENDER];
    [patientDict setObject:[NSString stringWithFormat:@"%d", patient.weightKg] forKey:KEY_AMK_PAT_WEIGHT];
    [patientDict setObject:[NSString stringWithFormat:@"%d", patient.heightCm] forKey:KEY_AMK_PAT_HEIGHT];
    [patientDict setObject:patient.postalAddress forKey:KEY_AMK_PAT_ADDRESS];
    [patientDict setObject:patient.zipCode       forKey:KEY_AMK_PAT_ZIP];
    [patientDict setObject:patient.city          forKey:KEY_AMK_PAT_CITY];
    [patientDict setObject:patient.country       forKey:KEY_AMK_PAT_COUNTRY];
    [patientDict setObject:patient.phoneNumber   forKey:KEY_AMK_PAT_PHONE];
    [patientDict setObject:patient.emailAddress  forKey:KEY_AMK_PAT_EMAIL];
    
    MLOperator *doctor = [[MLPersistenceManager shared] doctor];
    NSMutableDictionary *operatorDict = [[doctor dictionaryRepresentation] mutableCopy];
    placeDate = [NSString stringWithFormat:@"%@, %@",
                 doctor.city,
                 [MLUtilities prettyTime]];
    
    NSString *encodedImgStr = @"";
    NSImage *doctorImage = [[MLPersistenceManager shared] doctorSignature];
    if (doctorImage!=nil) {
        NSData *imgData = [doctorImage TIFFRepresentation];
        NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imgData];
        NSData *data = [imageRep representationUsingType:NSPNGFileType properties:@{}];
        encodedImgStr = [data base64Encoding];
    }
    [operatorDict setObject:encodedImgStr forKey:KEY_AMK_DOC_SIGNATURE];
    
    NSMutableArray *prescription = [[NSMutableArray alloc] init];
    for (MLPrescriptionItem *item in cart) {
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setObject:item.title forKey:@"product_name"];
        [dict setObject:item.fullPackageInfo forKey:@"package"];
        if (item.eanCode!=nil)
            [dict setObject:item.eanCode forKey:@"eancode"];
        [dict setObject:item.comment forKey:@"comment"];
        [dict setObject:item.med.title forKey:@"title"];
        [dict setObject:item.med.auth forKey:@"owner"];
        [dict setObject:item.med.regnrs forKey:@"regnrs"];
        [dict setObject:item.med.atccode forKey:@"atccode"];
        [prescription addObject:dict];
    }
        
    [prescriptionDict setObject:hash forKey:@"prescription_hash"];
    [prescriptionDict setObject:placeDate forKey:@"place_date"];
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

- (NSString *) loadPrescriptionFromFile:(NSString *)filePath
{
    NSError *error = nil;
    NSString *base64Str = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    NSString *jsonStr = [MLUtilities decodeBase64ToString:base64Str];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:[jsonStr dataUsingEncoding:NSUTF8StringEncoding]
                                                             options: NSJSONReadingMutableContainers
                                                               error:&error];
    currentFileName = filePath;
    //NSLog(@"%s currentFileName:%@", __FUNCTION__, currentFileName);
    
    // Prescription
    NSMutableArray *prescription = [[NSMutableArray alloc] init];
    for (NSDictionary *p in [jsonDict objectForKey:@"medications"]) {
        MLMedication *med = [[MLMedication alloc] init];
        [med importFromDict:p];
        
        MLPrescriptionItem *item = [[MLPrescriptionItem alloc] init];
        [item importFromDict:p];
        item.med = med;
        
        [prescription addObject:item];
    }
    cart = [prescription copy];
    
    NSDictionary *patientDict = [jsonDict objectForKey:@"patient"];
    patient = [[MLPatient alloc] init];
    [patient importFromDict:patientDict];
    
    NSDictionary *operatorDict = [jsonDict objectForKey:@"operator"];
    doctor = [[MLOperator alloc] init];
    [doctor importFromDict:operatorDict];
    
    placeDate = [jsonDict objectForKey:@"place_date"];
    if (placeDate == nil)
        placeDate = [jsonDict objectForKey:@"date"];

    NSString *hash = [jsonDict objectForKey:@"prescription_hash"];
    return hash;
}

- (NSString *) loadPrescriptionWithName:(NSString *)fileName forPatient:(MLPatient *)p
{
    NSString *prescription_hash = @"";
    NSString *documentsDir = [MLUtilities documentsDirectory];
    // Check if patient has already a directory, if not create one
    NSString *filePath = [documentsDir stringByAppendingString:[NSString stringWithFormat:@"/%@/%@.amk", p.uniqueId, fileName]];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]) {
        prescription_hash = [self loadPrescriptionFromFile:filePath];
        currentFileName = [NSString stringWithFormat:@"%@.amk", fileName];
    }
    
    return prescription_hash;
}

@end
