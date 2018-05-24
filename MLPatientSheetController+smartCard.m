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

    // Create patient from health card data (incomplete dictionary)
    MLPatient *incompletePatient = [[MLPatient alloc] init];
    [incompletePatient importFromDict:d];
    NSLog(@"patient %@", incompletePatient);

    // If the ID exists in the patient_db just select it
    
    MLPatient *existingPatient = [self retrievePatientWithUniqueID:incompletePatient.uniqueId];
    //NSLog(@"%s existing patient from DB:%@", __FUNCTION__, existingPatient);
    if (existingPatient) {
        // Search the table view
        NSInteger n = [self numberOfRowsInTableView:mTableView];
        for (int i=0; i<n; i++) {
            MLPatient *p = [self getContactAtRow:i];
            //NSLog(@"Line %d, %i/%ld, %@", __LINE__, i+1, (long)n, p);
            if ([p.uniqueId isEqualToString:incompletePatient.uniqueId]) {
                //NSLog(@"found at %d", i);

                dispatch_sync(dispatch_get_main_queue(), ^{
                    // UI API must be called on the main thread

                    // Select it in the table view
                    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:i];
                    [mTableView selectRowIndexes:indexSet byExtendingSelection:NO];
                    [mTableView scrollRowToVisible:[mTableView selectedRow]];
#if 1
                    // Simulate double-click in mTableView to close panel
                    [self setSelectedPatient:existingPatient];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"MLPrescriptionPatientChanged" object:self];
                    [self remove];
#endif
                });

                break;
            }
        }

//        dispatch_sync(dispatch_get_main_queue(), ^{
//            [self setAllFields:existingPatient];
//        });
        return;
    }

    // Just pre-fill some fields with the dictionary
    dispatch_sync(dispatch_get_main_queue(), ^{
        // UI API must be called on the main thread
        // TODO: maybe call onNewPatient
        [self setAllFields:incompletePatient];
    });
}

@end
