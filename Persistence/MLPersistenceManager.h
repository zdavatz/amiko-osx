//
//  MLPersistenceManager.h
//  AmiKoDesitin
//
//  Created by b123400 on 2020/03/14.
//  Copyright © 2020 Ywesee GmbH. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>
#import "MLOperator.h"
#import "MLPatient.h"
#import "MLHINTokens.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MLPersistenceSource) {
    MLPersistenceSourceLocal = 0,
    MLPersistenceSourceICloud = 1,
};

@interface MLPersistenceManager : NSObject

@property (nonatomic, readonly) MLPersistenceSource currentSource;

+ (instancetype) shared;
+ (BOOL)supportICloud;
- (NSURL *)iCloudDocumentDirectory;

- (void)setCurrentSourceToICloud;
- (void)setCurrentSourceToLocalWithDeleteICloud:(BOOL)deleteFilesOnICloud;

- (BOOL)hadSetupMedidataInvoiceXMLDirectory;
- (NSURL *)medidataInvoiceXMLDirectory;
- (void)setMedidataInvoiceXMLDirectory:(NSURL *)url;
- (BOOL)hadSetupMedidataInvoiceResponseXMLDirectory;
- (NSURL *)medidataInvoiceResponseXMLDirectory;
- (void)setMedidataInvoiceResponseXMLDirectory:(NSURL *)url;

- (void)setHINSDSTokens:(MLHINTokens * _Nullable)tokens;
- (MLHINTokens * _Nullable)HINSDSTokens;
- (void)setHINADSwissTokens:(MLHINTokens * _Nullable)tokens;
- (MLHINTokens * _Nullable)HINADSwissTokens;

- (void)setHINADSwissAuthHandle:(NSString *)authHandle;
- (NSString *)HINADSwissAuthHandle;

# pragma mark - Doctor

- (NSURL *)doctorDictionaryURL;
- (void)setDoctor:(MLOperator *)operator;
- (MLOperator *)doctor;
- (void)setDoctorSignature:(NSData *)image;
- (NSImage *)doctorSignature;
- (NSURL *)doctorSignatureURL;

# pragma mark - Prescription

- (NSURL *)amkBaseDirectory;
- (NSURL *)amkDirectoryForPatient:(NSString*)uid;
#pragma mark - Patient

- (NSString *)addPatient:(MLPatient *)patient;
- (NSString *)upsertPatient:(MLPatient *)patient;
- (BOOL)deletePatient:(MLPatient *)patient;

- (NSArray<MLPatient *> *) getAllPatients;
- (NSArray *)searchPatientsWithKeyword:(NSString *)key;
- (MLPatient *) getPatientWithUniqueID:(NSString *)uniqueID;
- (NSFetchedResultsController *)resultsControllerForAllPatients;

#pragma mark - Favourites

- (NSURL *)favouritesFile;

@end

NS_ASSUME_NONNULL_END
