//
//  MLPersistenceManager.m
//  AmiKoDesitin
//
//  Created by b123400 on 2020/03/14.
//  Copyright © 2020 Ywesee GmbH. All rights reserved.
//

#import "MLPersistenceManager.h"
#import "MLUtilities.h"
#import "PatientModel+CoreDataClass.h"
#import "LegacyPatientDBAdapter.h"
#import "MLiCloudToLocalMigration.h"
#import "MLPatientSync.h"

#define KEY_PERSISTENCE_SOURCE @"KEY_PERSISTENCE_SOURCE"
#define KEY_MEDIDATA_INVOICE_XML_DIRECTORY @"KEY_MEDIDATA_INVOICE_XML_DIRECTORY"
#define KEY_MEDIDATA_INVOICE_RESPONSE_XML_DIRECTORY @"KEY_MEDIDATA_INVOICE_RESPONSE_XML_DIRECTORY"

@interface MLPersistenceManager () <MLiCloudToLocalMigrationDelegate>

@property (nonatomic, strong) MLiCloudToLocalMigration *iCloudToLocalMigration;
@property (nonatomic, strong) MLPatientSync *patientSync;

- (void)migrateToICloud;
- (void)migrateToLocal:(BOOL)deleteFilesOnICloud;

@property NSPersistentContainer *coreDataContainer;

@end

@implementation MLPersistenceManager

+ (instancetype)shared {
    __strong static id sharedObject = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedObject = [[MLPersistenceManager alloc] init];
    });
    
    return sharedObject;
}

- (instancetype)init {
    if (self = [super init]) {
        self.coreDataContainer = [[NSPersistentContainer alloc] initWithName:@"Model"];
        
        NSPersistentStoreDescription *description = [[self.coreDataContainer persistentStoreDescriptions] firstObject];
        if (@available(macOS 10.13, *)) {
            [description setOption:@1 forKey:NSPersistentHistoryTrackingKey];
        } else {
            // Fallback on earlier versions
        }

        [self.coreDataContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription * _Nonnull desc, NSError * _Nullable error) {
            if (error != nil) {
                NSLog(@"Coredata error %@", error);
                return;
            }
            [self.coreDataContainer viewContext].automaticallyMergesChangesFromParent = YES;
            [self migratePatientSqliteToCoreData];
        }];
        
        [self doctor]; // Migrate to file based doctor storage
        [self migrateFromOldFavourites];
        [self migrateToAMKDirectory];
        [self initialICloudDownload];
        self.patientSync = [[MLPatientSync alloc] initWithPersistenceManager:self];
    }
    return self;
}

+ (BOOL)supportICloud {
    if (@available(macOS 10.15, *)) {
        return [[NSFileManager defaultManager] ubiquityIdentityToken] != nil;
    } else {
        return NO;
    }
}

- (void)setCurrentSourceToLocalWithDeleteICloud:(BOOL)deleteFilesOnICloud {
    if (self.currentSource == MLPersistenceSourceLocal) return;
    [self migrateToLocal:deleteFilesOnICloud];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:MLPersistenceSourceLocal forKey:KEY_PERSISTENCE_SOURCE];
    [defaults synchronize];
}
- (void)setCurrentSourceToICloud {
    if (self.currentSource == MLPersistenceSourceICloud || ![MLPersistenceManager supportICloud]) {
        return;
    }
    [self migrateToICloud];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:MLPersistenceSourceICloud forKey:KEY_PERSISTENCE_SOURCE];
    [defaults synchronize];
}

- (MLPersistenceSource)currentSource {
    MLPersistenceSource source = [[NSUserDefaults standardUserDefaults] integerForKey:KEY_PERSISTENCE_SOURCE];
    if (source == MLPersistenceSourceICloud && [MLPersistenceManager supportICloud]) {
        return MLPersistenceSourceICloud;
    }
    return MLPersistenceSourceLocal;
}

- (NSURL *)iCloudDocumentDirectory {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSURL *rootDir = [manager URLForUbiquityContainerIdentifier:[MLUtilities iCloudContainerIdentifier]];
    NSURL *docUrl = [rootDir URLByAppendingPathComponent:@"Documents"];
    if (![manager fileExistsAtPath:[docUrl path]]) {
        [manager createDirectoryAtURL:docUrl
          withIntermediateDirectories:YES
                           attributes:nil
                                error:nil];
    }
    return docUrl;
}

- (NSURL *)documentDirectory {
    if (self.currentSource == MLPersistenceSourceICloud) {
        return [self iCloudDocumentDirectory];
    }
    return [NSURL fileURLWithPath:[MLUtilities documentsDirectory]];
}

- (NSManagedObjectContext *)managedViewContext {
    return self.coreDataContainer.viewContext;
}

- (void)initialICloudDownload {
    // Trigger download when the app starts
    if (self.currentSource != MLPersistenceSourceICloud) {
        return;
    }
    NSFileManager *manager = [NSFileManager defaultManager];
    NSError *error = nil;

    NSURL *remoteDoctorURL = [self doctorDictionaryURL];
    [manager startDownloadingUbiquitousItemAtURL:remoteDoctorURL error:&error];
    if (error != nil) {
        NSLog(@"Cannot start downloading doctor %@", error);
    }
    
    NSURL *signatureURL = [[self documentDirectory] URLByAppendingPathComponent:DOC_SIGNATURE_FILENAME];
    [manager startDownloadingUbiquitousItemAtURL:signatureURL error:&error];
    if (error != nil) {
        NSLog(@"Cannot start downloading doctor signature %@", error);
    }
    
    NSURL *favouriteURL = [[self documentDirectory] URLByAppendingPathComponent:@"favourites"];
    [manager startDownloadingUbiquitousItemAtURL:favouriteURL error:&error];
    if (error != nil) {
        NSLog(@"Cannot start downloading favourite %@", error);
    }
}

- (BOOL)hadSetupMedidataInvoiceXMLDirectory {
    NSData *bookmark = [[NSUserDefaults standardUserDefaults] objectForKey:KEY_MEDIDATA_INVOICE_XML_DIRECTORY];
    return bookmark != nil;
}

- (NSURL *)medidataInvoiceXMLDirectory {
    NSData *bookmark = [[NSUserDefaults standardUserDefaults] objectForKey:KEY_MEDIDATA_INVOICE_XML_DIRECTORY];
    if (!bookmark) {
        return nil;
    }
    NSError *error = nil;
    BOOL isStale = NO;
    NSURL *url = [NSURL URLByResolvingBookmarkData:bookmark
                                           options:NSURLBookmarkResolutionWithSecurityScope
                                     relativeToURL:nil
                               bookmarkDataIsStale:&isStale
                                             error:&error];
    if (error) {
        NSLog(@"%@", [error description]);
        return nil;
    }
    if (isStale) {
        [self setMedidataInvoiceXMLDirectory:url];
    }
    return url;
}

- (void)setMedidataInvoiceXMLDirectory:(NSURL *)url {
    NSError *error = nil;
    NSData *data = [url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                 includingResourceValuesForKeys:nil
                                  relativeToURL:nil error:&error];
    if (error) {
        NSLog(@"%@", [error description]);
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:data forKey:KEY_MEDIDATA_INVOICE_XML_DIRECTORY];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)hadSetupMedidataInvoiceResponseXMLDirectory {
    return [[NSUserDefaults standardUserDefaults] objectForKey:KEY_MEDIDATA_INVOICE_RESPONSE_XML_DIRECTORY] != nil;
}

- (NSURL *)medidataInvoiceResponseXMLDirectory {
    NSData *bookmark = [[NSUserDefaults standardUserDefaults] objectForKey:KEY_MEDIDATA_INVOICE_RESPONSE_XML_DIRECTORY];
    if (!bookmark) {
        return nil;
    }
    NSError *error = nil;
    BOOL isStale = NO;
    NSURL *url = [NSURL URLByResolvingBookmarkData:bookmark
                                           options:NSURLBookmarkResolutionWithSecurityScope
                                     relativeToURL:nil
                               bookmarkDataIsStale:&isStale
                                             error:&error];
    if (error) {
        NSLog(@"%@", [error description]);
        return nil;
    }
    if (isStale) {
        [self setMedidataInvoiceResponseXMLDirectory:url];
    }
    return url;
}

- (void)setMedidataInvoiceResponseXMLDirectory:(NSURL *)url {
    NSError *error = nil;
    NSData *bookmark = [url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                     includingResourceValuesForKeys:nil
                                      relativeToURL:nil
                                              error:&error];
    if (error) {
        NSLog(@"%@", [error description]);
        return;
    }
    [[NSUserDefaults standardUserDefaults] setObject:bookmark forKey:KEY_MEDIDATA_INVOICE_RESPONSE_XML_DIRECTORY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

# pragma mark - Migration Local -> iCloud

- (void)migrateToICloud {
    if (self.currentSource == MLPersistenceSourceICloud) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSFileManager *manager = [NSFileManager defaultManager];
        NSURL *localDocument = [NSURL fileURLWithPath:[MLUtilities documentsDirectory]];
        NSURL *remoteDocument = [self iCloudDocumentDirectory];

        NSURL *remoteDoctorURL = [remoteDocument URLByAppendingPathComponent:@"doctor.plist"];
        [MLUtilities moveFile:[localDocument URLByAppendingPathComponent:@"doctor.plist"]
                        toURL:remoteDoctorURL
          overwriteIfExisting:NO];
        [manager startDownloadingUbiquitousItemAtURL:remoteDoctorURL error:nil];
        
        NSURL *signatureURL = [remoteDocument URLByAppendingPathComponent:DOC_SIGNATURE_FILENAME];
        [MLUtilities moveFile:[localDocument URLByAppendingPathComponent:DOC_SIGNATURE_FILENAME]
                      toURL:signatureURL
        overwriteIfExisting:YES];
        [manager startDownloadingUbiquitousItemAtURL:signatureURL error:nil];

        NSURL *favouriteURL = [remoteDocument URLByAppendingPathComponent:@"favourites"];
        [MLUtilities moveFile:[localDocument URLByAppendingPathComponent:@"favourites"]
                        toURL:favouriteURL
          overwriteIfExisting:YES];
        [manager startDownloadingUbiquitousItemAtURL:favouriteURL error:nil];

        NSURL *amkDirectoryURL = [remoteDocument URLByAppendingPathComponent:@"amk" isDirectory:YES];
        [MLUtilities mergeFolderRecursively:[localDocument URLByAppendingPathComponent:@"amk" isDirectory:YES]
                                         to:amkDirectoryURL
                             deleteOriginal:YES];
        [self.patientSync generatePatientFilesForICloud:nil];
    });
}

# pragma mark - Migrate to local

- (void)migrateToLocal:(BOOL)deleteFilesOnICloud {
    if (self.currentSource == MLPersistenceSourceLocal) {
        return;
    }

    MLiCloudToLocalMigration *migration = [[MLiCloudToLocalMigration alloc] init];
    migration.delegate = self;
    migration.deleteFilesOnICloud = deleteFilesOnICloud;
    [migration start];
    self.iCloudToLocalMigration = migration;
}

- (void)didFinishedICloudToLocalMigration:(id)sender {
    self.iCloudToLocalMigration = nil;
    NSLog(@"Migration is done");
}

# pragma mark - Doctor

- (NSURL *)doctorDictionaryURL {
    return [[self documentDirectory] URLByAppendingPathComponent:@"doctor.plist"];
}

- (void)setDoctor:(MLOperator *)operator {
    [[operator dictionaryRepresentation] writeToURL:self.doctorDictionaryURL atomically:YES];
}

- (MLOperator *)doctor {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    // Migrate to file based doctor.plist
    if ([defaults stringForKey:LEGACY_DEFAULTS_DOC_SURNAME]) {
        MLOperator *operator = [[MLOperator alloc] init];
        operator.title = [defaults stringForKey:LEGACY_DEFAULTS_DOC_TITLE];
        operator.familyName = [defaults stringForKey:LEGACY_DEFAULTS_DOC_SURNAME];
        operator.givenName = [defaults stringForKey:LEGACY_DEFAULTS_DOC_NAME];
        operator.postalAddress = [defaults stringForKey:LEGACY_DEFAULTS_DOC_ADDRESS];
        operator.zipCode = [defaults stringForKey:LEGACY_DEFAULTS_DOC_ZIP];
        operator.city = [defaults stringForKey:LEGACY_DEFAULTS_DOC_CITY];
        operator.country = [defaults stringForKey:LEGACY_DEFAULTS_DOC_COUNTRY];
        operator.phoneNumber = [defaults stringForKey:LEGACY_DEFAULTS_DOC_PHONE];
        operator.emailAddress = [defaults stringForKey:LEGACY_DEFAULTS_DOC_EMAIL];
        [self setDoctor:operator];
        [defaults removeObjectForKey:LEGACY_DEFAULTS_DOC_TITLE];
        [defaults removeObjectForKey:LEGACY_DEFAULTS_DOC_SURNAME];
        [defaults removeObjectForKey:LEGACY_DEFAULTS_DOC_NAME];
        [defaults removeObjectForKey:LEGACY_DEFAULTS_DOC_ADDRESS];
        [defaults removeObjectForKey:LEGACY_DEFAULTS_DOC_ZIP];
        [defaults removeObjectForKey:LEGACY_DEFAULTS_DOC_CITY];
        [defaults removeObjectForKey:LEGACY_DEFAULTS_DOC_COUNTRY];
        [defaults removeObjectForKey:LEGACY_DEFAULTS_DOC_PHONE];
        [defaults removeObjectForKey:LEGACY_DEFAULTS_DOC_EMAIL];
        [defaults synchronize];
        return operator;
    } else {
        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfURL:self.doctorDictionaryURL];
        return [[MLOperator alloc] initWithDictionary:dict];
    }
}

- (NSURL *)doctorSignatureURL {
    return [[self documentDirectory] URLByAppendingPathComponent:DOC_SIGNATURE_FILENAME];
}

- (void)setDoctorSignature:(NSData *)image {
    NSString *filePath = [[self doctorSignatureURL] path];
    [image writeToFile:filePath atomically:YES];
}

- (NSImage*)doctorSignature {
    NSString *filePath = [[self doctorSignatureURL] path];
    return [[NSImage alloc] initWithContentsOfFile:filePath];
}

# pragma mark - Prescription

// At 3.4.11, the amk files are put under path like this:
// "Documents/<patient unique id>/xxxx.amk"
// However on iOS it's "Documents/amk/<patient unique id>/xxxx.amk"
// It wasn't a problem until we have to sync with iCloud.
// Lets migrate to "amk" directory.
- (void)migrateToAMKDirectory {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *doc = [MLUtilities documentsDirectory];
    NSError *error = nil;
    NSArray<NSString *> *docFiles = [manager contentsOfDirectoryAtPath:doc error:&error];
    if (error) {
        NSLog(@"migrate amk error: %@ ", error);
        return;
    }
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    for (NSString *docFile in docFiles) {
        NSNumber *num = [formatter numberFromString:docFile];
        if (!num) {
            continue;
        }
        NSUInteger uniquePatientId = [num unsignedIntegerValue];
        if (![docFile isEqualToString:[NSString stringWithFormat:@"%lu", uniquePatientId]]){
            // Make sure we do not parse the number wrongly
            continue;
        }
        [manager moveItemAtPath:[doc stringByAppendingPathComponent:docFile]
                         toPath:[[self localAmkBaseDirectory] stringByAppendingPathComponent:docFile]
                          error:&error];
        if (error) {
            NSLog(@"Error when moving amk files %@", error);
        }
    }
}

- (NSURL *)amkBaseDirectory {
    if (self.currentSource == MLPersistenceSourceICloud) {
        NSURL *url = [[self documentDirectory] URLByAppendingPathComponent:@"amk"];
        [[NSFileManager defaultManager] createDirectoryAtURL:url
                                 withIntermediateDirectories:YES
                                                  attributes:nil
                                                       error:nil];
        return url;
    }
    return [NSURL fileURLWithPath:[self localAmkBaseDirectory]];
}

- (NSURL *)amkDirectoryForPatient:(NSString*)uid {
    NSURL *amk = [self amkBaseDirectory];
    NSURL *patientAmk = [amk URLByAppendingPathComponent:uid];
    if (![[NSFileManager defaultManager] fileExistsAtPath:[patientAmk path]])
    {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:[patientAmk path]
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
        if (error) {
            NSLog(@"error creating directory: %@", error.localizedDescription);
            patientAmk = nil;
        } else {
            NSLog(@"Created patient directory: %@", patientAmk);
        }
    }

    return patientAmk;
}

// Create the directory if it doesn't exist
- (NSString *) localAmkBaseDirectory
{
    NSString *amk = [[MLUtilities documentsDirectory] stringByAppendingPathComponent:@"amk"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:amk])
    {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:amk
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
        if (error) {
            NSLog(@"error creating directory: %@", error.localizedDescription);
            amk = nil;
        }
    }
    return amk;
}

# pragma mark - Patient

- (NSString *)addPatient:(MLPatient *)patient {
    return [self addPatient:patient updateICloud:YES];
}

- (NSString *)addPatient:(MLPatient *)patient updateICloud:(BOOL)updateICloud {
    NSString *uuidStr = [patient generateUniqueID];
    patient.uniqueId = uuidStr;

    NSManagedObjectContext *context = [[self coreDataContainer] viewContext];
    PatientModel *pm = [NSEntityDescription insertNewObjectForEntityForName:@"Patient"
                                                     inManagedObjectContext:context];

    [pm importFromPatient:patient timestamp: [NSDate new]];

    NSError *error = nil;
    [context save:&error];
    if (error != nil) {
        NSLog(@"Cannot create patient %@", error);
    }
    if (updateICloud) {
        [self.patientSync generatePatientFile:patient forICloud:nil];
    }
    return uuidStr;
}

- (NSString *)upsertPatient:(MLPatient *)patient {
    return [self upsertPatient:patient updateICloud:YES];
}
- (NSString *)upsertPatient:(MLPatient *)patient updateICloud:(BOOL)updateICloud {
    return [self upsertPatient:patient withTimestamp:[NSDate date] updateICloud:updateICloud];
}

- (NSString *)upsertPatient:(MLPatient *)patient withTimestamp:(NSDate*)date updateICloud:(BOOL)updateICloud {
    NSError *error = nil;
    if (patient.uniqueId.length) {
        PatientModel *p = [self getPatientModelWithUniqueID:patient.uniqueId];
        if (p != nil) {
            p.weightKg = patient.weightKg;
            p.heightCm = patient.heightCm;
            p.zipCode = patient.zipCode;
            p.city = patient.city;
            p.country = patient.country;
            p.postalAddress = patient.postalAddress;
            p.phoneNumber = patient.phoneNumber;
            p.emailAddress = patient.emailAddress;
            p.gender = patient.gender;
            p.timestamp = date;
            p.bagNumber = patient.bagNumber;
            p.healthCardNumber = patient.healthCardNumber;
            p.healthCardExpiry = patient.healthCardExpiry;
            p.insuranceGLN = patient.insuranceGLN;
            [[self.coreDataContainer viewContext] save:&error];
            if (error != nil) {
                NSLog(@"Cannot update patient %@", error);
            }
            if (updateICloud) {
                [self.patientSync generatePatientFile:patient forICloud:nil];
            }
            return patient.uniqueId;
        }
    }
    return [self addPatient:patient updateICloud:updateICloud];
}

- (BOOL)deletePatient:(MLPatient *)patient {
    return [self deletePatient:patient updateICloud:YES];
}

- (BOOL)deletePatient:(MLPatient *)patient updateICloud:(BOOL)updateICloud {
    if (!patient.uniqueId.length) {
        return NO;
    }
    PatientModel *pm = [self getPatientModelWithUniqueID:patient.uniqueId];
    if (!pm) {
        return NO;
    }
    
    NSURL *amkDir = [self amkDirectoryForPatient:patient.uniqueId];
    [[NSFileManager defaultManager] removeItemAtURL:amkDir error:nil];

    NSManagedObjectContext *context = [self.coreDataContainer viewContext];
    [context deleteObject:pm];
    [context save:nil];
    
    if (updateICloud) {
        [self.patientSync deletePatientFileForICloud:patient];
    }
    return YES;
}

- (NSArray<MLPatient *> *)getAllPatients {
    NSError *error = nil;
    NSManagedObjectContext *context = [[self coreDataContainer] viewContext];

    NSFetchRequest *req = [PatientModel fetchRequest];
    req.sortDescriptors = @[
        [NSSortDescriptor sortDescriptorWithKey:@"familyName" ascending:YES]
    ];

    NSArray<PatientModel*> *pm = [context executeFetchRequest:req error:&error];
    if (error != nil) {
        NSLog(@"Cannot get all patients %@", error);
    }
    return [pm valueForKey:@"toPatient"];
}

- (NSFetchedResultsController *)resultsControllerForAllPatients {
    NSManagedObjectContext *context = [self.coreDataContainer viewContext];
    NSFetchRequest *fetchRequest = [PatientModel fetchRequest];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"familyName" ascending:YES];
    fetchRequest.sortDescriptors = @[sortDescriptor];

    NSFetchedResultsController *controller = [[NSFetchedResultsController alloc]
            initWithFetchRequest:fetchRequest
            managedObjectContext:context
            sectionNameKeyPath:nil
            cacheName:nil];
    return controller;
}

- (NSArray *)searchPatientsWithKeyword:(NSString *)key
{
    NSArray *searchKeys = [key componentsSeparatedByString:@" "];
    if (![searchKeys count]) {
        return @[];
    }
    
    NSFetchRequest *req = [PatientModel fetchRequest];
    NSMutableArray<NSPredicate *> *predicates = [NSMutableArray array];
    for (NSString *searchKey in searchKeys) {
        if (searchKey.length == 0) {
            continue;
        }
        NSPredicate *p = [NSPredicate predicateWithFormat:@"familyName BEGINSWITH[cd] %@ OR givenName BEGINSWITH[cd] %@ OR city BEGINSWITH[cd] %@ OR zipCode BEGINSWITH[cd] %@", searchKey, searchKey, searchKey, searchKey];
        [predicates addObject:p];
    }
    req.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
    NSError *error = nil;
    NSArray<PatientModel *> *patientModels = [[[self coreDataContainer] viewContext] executeFetchRequest:req error:&error];
    if (error != nil) {
        NSLog(@"Cannot search patients %@", error);
    }
    return [patientModels valueForKey:@"toPatient"];
}

- (PatientModel *)getPatientModelWithUniqueID:(NSString *)uniqueID {
    NSError *error = nil;
    NSManagedObjectContext *context = [[self coreDataContainer] viewContext];
    NSFetchRequest *req = [PatientModel fetchRequest];
    req.predicate = [NSPredicate predicateWithFormat:@"uniqueId == %@", uniqueID];
    req.fetchLimit = 1;
    NSArray<PatientModel *> *patientModels = [context executeFetchRequest:req error:&error];
    return [patientModels firstObject];
}

- (MLPatient *) getPatientWithUniqueID:(NSString *)uniqueID {
    return [[self getPatientModelWithUniqueID:uniqueID] toPatient];
}

# pragma mark - Favourites

- (NSURL *)favouritesFile {
    return [[self documentDirectory] URLByAppendingPathComponent:@"favourites"];
}

- (void)migrateFromOldFavourites {
    NSString *oldFile = [@"~/Library/Preferences/data" stringByExpandingTildeInPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:oldFile]) {
        [[NSFileManager defaultManager] moveItemAtPath:oldFile
                                                toPath:[[self favouritesFile] path]
                                                 error:nil];
    }
}

# pragma mark - Patient Migration

- (void)migratePatientSqliteToCoreData {
    NSManagedObjectContext *context = [self.coreDataContainer newBackgroundContext];
    [context performBlock:^{
        LegacyPatientDBAdapter *adapter = [[LegacyPatientDBAdapter alloc] init];
        if (![adapter openDatabase]) return;
        NSArray<MLPatient *> *patients = [adapter getAllPatients];
        if (@available(macOS 10.15, *)) {
            NSMutableArray *dicts = [NSMutableArray arrayWithCapacity:patients.count];
            for (MLPatient *patient in patients) {
                NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                if (patient.birthDate != nil)     dict[@"birthDate"] = patient.birthDate;
                if (patient.city != nil)          dict[@"city"] = patient.city;
                if (patient.country != nil)       dict[@"country"] = patient.country;
                if (patient.emailAddress != nil)  dict[@"emailAddress"] = patient.emailAddress;
                if (patient.familyName != nil)    dict[@"familyName"] = patient.familyName;
                if (patient.gender != nil)        dict[@"gender"] = patient.gender;
                if (patient.givenName != nil)     dict[@"givenName"] = patient.givenName;
                if (patient.heightCm != 0)        dict[@"heightCm"] = @(patient.heightCm);
                if (patient.phoneNumber != nil)   dict[@"phoneNumber"] = patient.phoneNumber;
                if (patient.postalAddress != nil) dict[@"postalAddress"] = patient.postalAddress;
                if (patient.uniqueId != nil)      dict[@"uniqueId"] = patient.uniqueId;
                if (patient.weightKg != 0)        dict[@"weightKg"] = @(patient.weightKg);
                if (patient.zipCode != nil)       dict[@"zipCode"] = patient.zipCode;
                dict[@"timestamp"] = [NSDate date];
                [dicts addObject:dict];
            }
            NSBatchInsertRequest *req = [[NSBatchInsertRequest alloc] initWithEntity:[PatientModel entity]
                                                                             objects:dicts];
            NSError *error = nil;
            [context executeRequest:req error:&error];
            if (error != nil) {
                NSLog(@"Cannot migrate %@", error);
                return;
            }
        } else {
            for (MLPatient *patient in patients) {
                [self addPatient:patient];
            }
        }
        NSString *dbPath = [adapter dbPath];
        [[NSFileManager defaultManager] removeItemAtPath:dbPath error:nil];
    }];
}

@end
