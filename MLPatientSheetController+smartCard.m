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

- (void) newSmartCardData:(NSNotification *)notification
{
    NSLog(@"%s %@", __FUNCTION__, notification);
    //[self resetAllFields]; // Main Thread Checker: UI API called on a background thread: -[NSTextField setBackgroundColor:]
}

@end
