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
    NSURL *currentFileURL;
}

@synthesize cart;
@synthesize patient;
@synthesize doctor;
@synthesize placeDate;

// Returns an array of filenames (NSString),
// just the basename with the extension ".amk" stripped off
- (NSArray<NSString *> *) listOfPrescriptionsForPatient:(MLPatient *)p
{
    if (!p) {
#ifdef DEBUG
        NSLog(@"%s MLPatient not defined", __FUNCTION__);
#endif
        return nil;
    }

    NSMutableArray<NSString *> *amkFiles = [[NSMutableArray alloc] init];
    // Check if patient has already a directory, if not create one
    NSURL *patientDir = [[MLPersistenceManager shared] amkDirectoryForPatient:p.uniqueId];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    if ([fileManager fileExistsAtPath:patientDir.path isDirectory:&isDir] && isDir) {
        // List content of directory
        NSArray<NSURL *> *files = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:patientDir
                                                                includingPropertiesForKeys:nil
                                                                                   options:0
                                                                                     error:nil];
        for (NSURL *file in files) {
            if ([fileManager isUbiquitousItemAtURL:file]) {
                NSString *downloadStatus = nil;
                NSError *error = nil;
                if ([file getResourceValue:&downloadStatus forKey:NSURLUbiquitousItemDownloadingStatusKey error:&error] &&
                    error == nil &&
                    ![downloadStatus isEqualToString:NSURLUbiquitousItemDownloadingStatusCurrent]) {
                    [fileManager startDownloadingUbiquitousItemAtURL:file error:&error];
                    continue;
                }
            }
            NSString *extension = [[file pathExtension] lowercaseString];
            if ([extension isEqualToString:@"amk"]) {
                [amkFiles addObject:[file path]];
            }
        }
        // Sort
        [amkFiles sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    }

    return amkFiles;
}

- (void) deletePrescriptionWithName:(NSString *)name forPatient:(MLPatient *)p
{
    if (p!=nil) {
        // Assign patient
        patient = p;

        NSURL *patientDir = [[MLPersistenceManager shared] amkDirectoryForPatient:patient.uniqueId];
        
        // Delete file
        NSURL *fileURL = [[patientDir URLByAppendingPathComponent:name] URLByAppendingPathExtension:@"amk"];
        [[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
    }
}

- (NSURL *) getPrescriptionUrl
{
    return currentFileURL;
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

    if (overwrite && !currentFileURL) {
        NSLog(@"%s %d, cannot overwrite an empty filename", __FUNCTION__, __LINE__);
        return nil;
    }

    if ([cart count] < 1) {
        NSLog(@"%s %d, cart is empty", __FUNCTION__, __LINE__);
        return nil;
    }

    // Assign patient
    patient = p;

    NSURL *patientDir = [[MLPersistenceManager shared] amkDirectoryForPatient:patient.uniqueId];
    
    if (overwrite) {
        // Delete old file
        NSError *error = nil;
        if (![[NSFileManager defaultManager] removeItemAtURL:currentFileURL error:&error]) {
            NSLog(@"Error: %@", [error userInfo]);
        }
    }
    
    // Define a new filename
    NSString *currentTime = [[MLUtilities currentTime] stringByReplacingOccurrencesOfString:@":" withString:@""];
    currentTime = [currentTime stringByReplacingOccurrencesOfString:@"." withString:@""];
    NSString *fileName = [NSString stringWithFormat:@"RZ_%@.amk", currentTime];
    
    NSURL *file = [patientDir URLByAppendingPathComponent:fileName];

    currentFileURL = file;  // full path
    NSLog(@"%s new currentFileName:%@", __FUNCTION__, currentFileURL);

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

    NSString *jsonStr = [[NSString alloc] initWithData:jsonObject encoding:NSUTF8StringEncoding];
    NSString *base64Str = [MLUtilities encodeStringToBase64:jsonStr];

    if (![base64Str writeToURL:file atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
        NSLog(@"Error: %@", [error userInfo]);
    }

    return file;
}

- (NSString *) loadPrescriptionFromURL:(NSURL *)fileURL
{
    NSError *error = nil;
    NSString *base64Str = [NSString stringWithContentsOfURL:fileURL
                                                   encoding:NSUTF8StringEncoding
                                                      error:&error];
    NSString *jsonStr = [MLUtilities decodeBase64ToString:base64Str];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:[jsonStr dataUsingEncoding:NSUTF8StringEncoding]
                                                             options: NSJSONReadingMutableContainers
                                                               error:&error];
    currentFileURL = fileURL;
    
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

@end
