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
    MLPatient *incompletePatient = [[MLPatient alloc] init];
    incompletePatient.familyName = [d objectForKey:@"family_name"];
    incompletePatient.givenName = [d objectForKey:@"given_name"];
    incompletePatient.birthDate = [d objectForKey:@"birth_date"];
    incompletePatient.gender = [d objectForKey:@"gender"];
    
    NSString *uuidStr = [incompletePatient generateUniqueID];
    //NSLog(@"patient %@, uuidStr %@", patient, uuidStr);
    // TODO: if the ID exists in the patient_db just select it
    
    MLPatient *existingPatient = [mPatientDb getPatientWithUniqueID:uuidStr];
    //NSLog(@"%s existing patient from DB:%@", __FUNCTION__, existingPatient);
    if (existingPatient) {
        // Search the table view
        NSInteger n = [self numberOfRowsInTableView:mTableView];
        for (int i=0; i<n; i++) {
            MLPatient *p = [self getContactAtRow:i];
            //NSLog(@"Line %d, %i/%ld, %@", __LINE__, i+1, (long)n, p);
            if ([p.uniqueId isEqualToString:uuidStr]) {
                //NSLog(@"found at %d", i);
                // TODO select it in the table view
                dispatch_sync(dispatch_get_main_queue(), ^{
                    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:i];
                    [mTableView selectRowIndexes:indexSet byExtendingSelection:NO];
                });
                break;
            }
        }

//        dispatch_sync(dispatch_get_main_queue(), ^{
//            [self setAllFields:existingPatient];
//        });
        return;
    }

    // Pre-fill some fields with the dictionary
    dispatch_sync(dispatch_get_main_queue(), ^{
        // TODO: maybe call onNewPatient
        [self setAllFields:incompletePatient];
    });
}

@end
