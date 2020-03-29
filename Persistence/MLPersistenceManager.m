//
//  MLPersistenceManager.m
//  AmiKoDesitin
//
//  Created by b123400 on 2020/03/14.
//  Copyright © 2020 Ywesee GmbH. All rights reserved.
//

#import "MLPersistenceManager.h"
#import "MLUtilities.h"
#import "MLiCloudToLocalMigration.h"

#define KEY_PERSISTENCE_SOURCE @"KEY_PERSISTENCE_SOURCE"

@interface MLPersistenceManager () <MLiCloudToLocalMigrationDelegate>

@property (nonatomic, strong) MLiCloudToLocalMigration *iCloudToLocalMigration;

- (void)migrateToICloud;
- (void)migrateToLocal:(BOOL)deleteFilesOnICloud;
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
    }
    return self;
}

+ (BOOL)supportICloud {
    return [[NSFileManager defaultManager] ubiquityIdentityToken] != nil;
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


# pragma mark - Migration Local -> iCloud

- (void)migrateToICloud {
    if (self.currentSource == MLPersistenceSourceICloud) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{

        [self doctor]; // Migrate to file based doctor storage
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

- (void)setDoctorSignature:(NSData *)image {
    NSString *filePath = [[[self documentDirectory] URLByAppendingPathComponent:DOC_SIGNATURE_FILENAME] path];
    [image writeToFile:filePath atomically:YES];
}

- (NSImage*)doctorSignature {
    NSString *filePath = [[[self documentDirectory] URLByAppendingPathComponent:DOC_SIGNATURE_FILENAME] path];
    return [[NSImage alloc] initWithContentsOfFile:filePath];
}



@end
