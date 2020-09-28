//
//  MLPatientSync.m
//  AmiKo
//
//  Created by b123400 on 2020/09/19.
//  Copyright © 2020 Ywesee GmbH. All rights reserved.
//

#import "MLPatientSync.h"

@interface MLPersistenceManager ()

- (NSURL *)documentDirectory;
- (NSString *)addPatient:(MLPatient *)patient updateICloud:(BOOL)updateICloud;
- (NSString *)upsertPatient:(MLPatient *)patient withTimestamp:(NSDate*)date updateICloud:(BOOL)updateICloud;
- (BOOL)deletePatient:(MLPatient *)patient updateICloud:(BOOL)updateICloud;

@end

@interface MLPatientSync ()
@property (nonatomic, strong) NSMetadataQuery *query;
@property (nonatomic, weak) MLPersistenceManager *persistenceManager;
@end

@implementation MLPatientSync

- (instancetype)initWithPersistenceManager:(MLPersistenceManager*)manager {
    if (self = [super init]) {
        self.persistenceManager = manager;

        self.query = [[NSMetadataQuery alloc] init];
        self.query.predicate = [NSPredicate predicateWithValue:YES];
        self.query.searchScopes = @[NSMetadataQueryUbiquitousDocumentsScope];
        self.query.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"lastPathComponent" ascending:YES]];
        [self.query startQuery];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(ubiquitousStoreDidUpdate:) name:NSMetadataQueryDidUpdateNotification object:self.query];
        [self initialICloudDownload];
        [self initialImport];
        [self initialMigrationToICloudFiles:nil];
    }
    return self;
}

- (void)initialICloudDownload {
    // Trigger download when the app starts
    if (self.persistenceManager.currentSource != MLPersistenceSourceICloud) {
        return;
    }
    NSFileManager *manager = [NSFileManager defaultManager];
    NSError *error = nil;
    
    NSURL *patientURL = [self patientsFolder];
    if (![manager fileExistsAtPath:patientURL.path]) {
        return;
    }
    NSArray<NSURL*> *urls = [manager contentsOfDirectoryAtURL:patientURL
                                   includingPropertiesForKeys:nil
                                                      options:0
                                                        error:&error];
    for (NSURL *url in urls) {
        [manager startDownloadingUbiquitousItemAtURL:url error:&error];
    }
}

// Patient files maybe updated when the app is not running, we scan the folder and update the "downloaded" files.
// Files that are now downloaded are handled by `initialICloudDownload`.
- (void)initialImport {
    if (self.persistenceManager.currentSource != MLPersistenceSourceICloud) {
        return;
    }
    NSFileManager *manager = [NSFileManager defaultManager];
    NSError *error = nil;
    
    NSURL *patientURL = [self patientsFolder];
    if (![manager fileExistsAtPath:patientURL.path]) {
        return;
    }
    NSArray<NSURL*> *urls = [manager contentsOfDirectoryAtURL:patientURL
                                   includingPropertiesForKeys:nil
                                                      options:0
                                                        error:&error];
    for (NSURL *url in urls) {
        if ([manager isUbiquitousItemAtURL:url]) {
            NSString *downloadStatus = nil;
            NSError *error = nil;
            if ([url getResourceValue:&downloadStatus forKey:NSURLUbiquitousItemDownloadingStatusKey error:&error] &&
                error == nil &&
                ![downloadStatus isEqualToString:NSURLUbiquitousItemDownloadingStatusCurrent]) {
                continue;
            }
        }
        
        NSDictionary *attributes = [manager attributesOfItemAtPath:url.path
                                                             error:&error];
        NSDate *lastUpdated = [attributes fileModificationDate];
        NSString *uniqueId = [url lastPathComponent];
        MLPatient *patient = [self.persistenceManager getPatientWithUniqueID:uniqueId];
        if ([patient.timestamp compare:lastUpdated] == NSOrderedAscending) {
            // File is newer than the patient in db
            [self importPatientFromICloudFile:url toCoreData:nil];
        }
    }
}

// The migration that copies files from coredata to iCloud files
- (void)initialMigrationToICloudFiles: (void (^ _Nullable)(bool success))callback {
    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:[[self patientsFolder] path]]) {
        [manager createDirectoryAtURL:[self patientsFolder]
          withIntermediateDirectories:YES
                           attributes:nil error:nil];
        [self generatePatientFilesForICloud:callback];
    }
}

// We used to use CloudKit to sync coredata, it wasn't very nice: https://github.com/zdavatz/amiko-osx/issues/109
// So we will be generating files for each patient entry and sync via iCloud document
- (NSURL *)patientsFolder {
    return [[self.persistenceManager documentDirectory] URLByAppendingPathComponent:@"patients"];
}
- (NSURL *)urlForPatientRepresentation: (MLPatient *)p {
    return [[self patientsFolder] URLByAppendingPathComponent:p.uniqueId];
}

- (void)importPatientsFromICloudToCoreData: (void (^ _Nullable)(bool success))callback {
    if (self.persistenceManager.currentSource != MLPersistenceSourceICloud) {
        if (callback != nil) {
            callback(NO);
        }
        return;
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
        NSError *error = nil;
        NSArray <NSURL *> *urls = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[self patientsFolder]
                                                                includingPropertiesForKeys:nil // add resource keys if needed
                                                                                   options:0
                                                                                    error:&error];
        for (NSURL *url in urls) {
            
            if ([fileManager isUbiquitousItemAtURL:url]) {
                NSString *downloadStatus = nil;
                NSError *error = nil;
                if ([url getResourceValue:&downloadStatus forKey:NSURLUbiquitousItemDownloadingStatusKey error:&error] &&
                    error == nil &&
                    ![downloadStatus isEqualToString:NSURLUbiquitousItemDownloadingStatusCurrent]) {
                    [fileManager startDownloadingUbiquitousItemAtURL:url error:&error];
                    continue;
                }
            }
            
            NSError *error = nil;
            NSData *jsonData = [NSData dataWithContentsOfURL:url options:0 error:&error];
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
            MLPatient *p = [MLPatient new];
            [p importFromDict:dict];
            
            NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:url.path
                                                                                        error:&error];
            NSDate *lastUpdated = [attributes fileModificationDate];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.persistenceManager upsertPatient:p withTimestamp:lastUpdated updateICloud:NO];
            });
        }
        if (callback != nil) {
            callback(YES);
        }
    });
}

- (void)importPatientFromICloudFile:(NSURL*)url toCoreData:(void (^ _Nullable)(bool success))callback {
    if (self.persistenceManager.currentSource != MLPersistenceSourceICloud) {
        if (callback != nil) {
            callback(NO);
        }
        return;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager isUbiquitousItemAtURL:url]) {
        NSString *downloadStatus = nil;
        NSError *error = nil;
        if ([url getResourceValue:&downloadStatus forKey:NSURLUbiquitousItemDownloadingStatusKey error:&error] &&
            error == nil &&
            ![downloadStatus isEqualToString:NSURLUbiquitousItemDownloadingStatusCurrent]) {
            [fileManager startDownloadingUbiquitousItemAtURL:url error:&error];
            return;
        }
    }
    
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
        NSError *error = nil;
        NSData *jsonData = [NSData dataWithContentsOfURL:url options:0 error:&error];
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
        MLPatient *p = [MLPatient new];
        [p importFromDict:dict];
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:url.path
                                                                                    error:&error];
        NSDate *lastUpdated = [attributes fileModificationDate];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.persistenceManager upsertPatient:p withTimestamp:lastUpdated updateICloud:NO];
        });
        if (callback != nil) {
            callback(YES);
        }
    });
}

- (void)generatePatientFilesForICloud: (void (^ _Nullable)(bool success))callback {
    if (self.persistenceManager.currentSource != MLPersistenceSourceICloud) {
        if (callback != nil) {
            callback(NO);
        }
        return;
    }
    NSArray<MLPatient*> *patients = [self.persistenceManager getAllPatients];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
        for (MLPatient *patient in patients) {
            NSError *error = nil;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[patient dictionaryRepresentation]
                                                               options:0
                                                                 error:&error];
            NSURL *url = [self urlForPatientRepresentation:patient];
            [jsonData writeToURL:url atomically:YES];
            if (patient.timestamp != nil) {
                [[NSFileManager defaultManager] setAttributes:@{
                    NSFileModificationDate: patient.timestamp
                }
                                                 ofItemAtPath:url.path
                                                        error:&error];
            }
        }
        if (callback != nil) {
            callback(YES);
        }
    });
}

- (void)generatePatientFile: (MLPatient*)patient forICloud: (void (^ _Nullable)(bool success))callback {
    if (self.persistenceManager.currentSource != MLPersistenceSourceICloud) {
        if (callback != nil) {
            callback(NO);
        }
        return;
    }
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
        NSError *error = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[patient dictionaryRepresentation]
                                                           options:0
                                                             error:&error];
        NSURL *url = [self urlForPatientRepresentation:patient];
        [jsonData writeToURL:url options:NSDataWritingAtomic error:&error];
        if (patient.timestamp != nil) {
            [[NSFileManager defaultManager] setAttributes:@{
                NSFileModificationDate: patient.timestamp
            }
                                             ofItemAtPath:url.path
                                                    error:&error];
        }
        if (callback != nil) {
            callback(error == nil);
        }
    });
}

- (void)deletePatientFileForICloud: (MLPatient*)patient {
    if (self.persistenceManager.currentSource != MLPersistenceSourceICloud) {
        return;
    }
    NSURL *url = [self urlForPatientRepresentation:patient];
    [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
}

- (void)ubiquitousStoreDidUpdate:(NSNotification *)notification {
    NSString *patientPath = [[[self patientsFolder] standardizedURL] path];
    NSArray<NSMetadataItem*> *addedItems = notification.userInfo[NSMetadataQueryUpdateAddedItemsKey];
    NSArray<NSMetadataItem*> *changedItems = notification.userInfo[NSMetadataQueryUpdateChangedItemsKey];
    
    NSArray<NSMetadataItem*> *updatedItems = [addedItems arrayByAddingObjectsFromArray:changedItems];
    for (NSMetadataItem *item in updatedItems) {
        NSURL *url = [item valueForAttribute:NSMetadataItemURLKey];
        if (![[[url standardizedURL] path] hasPrefix:patientPath]) {
            continue;
        }
        NSNumber *isDirectory;
        BOOL success = [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
        if (success && [isDirectory boolValue]) {
            continue;
        }
        
        [self importPatientFromICloudFile:url toCoreData:^(bool success) {
            if (!success) {
                NSLog(@"Cannot update patient from iCloud");
            }
        }];
    }
    
    NSArray<NSMetadataItem*> *deletedItems = notification.userInfo[NSMetadataQueryUpdateRemovedItemsKey];
    for (NSMetadataItem *item in deletedItems) {
        NSURL *url = [item valueForAttribute:NSMetadataItemURLKey];
        if (![[[url standardizedURL] path] hasPrefix:patientPath]) {
            continue;
        }
        NSNumber *isDirectory;
        BOOL success = [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
        if (success && [isDirectory boolValue]) {
            continue;
        }
        NSString *patientUniqueId = [[url pathComponents] lastObject];
        dispatch_async(dispatch_get_main_queue(), ^{
            MLPatient *p = [self.persistenceManager getPatientWithUniqueID:patientUniqueId];
            [self.persistenceManager deletePatient:p updateICloud:NO];
        });
    }
}

@end
