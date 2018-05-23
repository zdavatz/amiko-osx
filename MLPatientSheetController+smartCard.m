//
//  MLPatientSheetController+smartCard.m
//  AmiKo
//
//  Created by Alex Bettarini on 21/05/2018.
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import <CryptoTokenKit/CryptoTokenKit.h>
#import "MLPatientSheetController+smartCard.h"

@implementation MLPatientSheetController (smartCard)

#pragma mark - Notifications

- (void) newHealthCardData:(NSNotification *)notification
{
    NSDictionary *d = [notification object];
    //NSLog(@"%s %@", __FUNCTION__, d);

    // UI API must be called on the main thread
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self resetAllFields];
    });

    // Create patient hash
    MLPatient *patient = [[MLPatient alloc] init];
    patient.familyName = [d objectForKey:@"family_name"];
    patient.givenName = [d objectForKey:@"given_name"];
    patient.birthDate = [d objectForKey:@"birth_date"];
    patient.gender = [d objectForKey:@"gender"];
    
    NSString *uuidStr = [patient generateUniqueID];
    //NSLog(@"patient %@, uuidStr %@", patient, uuidStr);
    // TODO: if the ID exists in the patient_db just select it

    // otherwise call onNewPatient and pre-fill some fields with the dictionary
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self setAllFields:patient];
    });
}

@end
