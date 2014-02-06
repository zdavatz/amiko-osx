//
//  MLProgressSheetController.h
//  AmiKo
//
//  Created by Max on 26/01/2014.
//  Copyright (c) 2014 Ywesee GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MLProgressSheetController : NSWindowController
{
    IBOutlet NSWindow *mProgressPanel;
    IBOutlet NSImageCell *mSplashImage;
    IBOutlet NSTextField *mDownloadMsg;
    IBOutlet NSTextField *mDownloadPercent;
    IBOutlet NSProgressIndicator *mProgressIndicator;
    
    bool mDownloadInProgress;
}

@property (nonatomic, assign) bool mDownloadInProgress;

- (IBAction) onCancelPressed: (id)sender;

- (void) show: (NSWindow *)window;
- (void) remove;
- (void) update: (long)value max: (long long)maxValue;

@end
