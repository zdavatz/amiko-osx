//
//  MLPrescriptionTableView.h
//  AmiKo
//
//  Created by Alex Bettarini on 7 May 2018
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MLPrescriptionTableView : NSTableView
{
    NSMutableArray *topBorderRows;
    NSMutableArray *bottomBorderRows;
}

@property NSString *patient;
@property NSString *doctor;
@property NSImage *signature;
@property NSString *placeDate;

@end
