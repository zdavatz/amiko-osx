//
//  MLProgressSheetController.m
//  AmiKo
//
//  Created by Max on 26/01/2014.
//  Copyright (c) 2014 Ywesee GmbH. All rights reserved.
//

#import "MLProgressSheetController.h"

@implementation MLProgressSheetController
{
    NSModalSession mModalSession;
}

@synthesize mDownloadInProgress;

- (id) init
{
    if (self = [super init]) {
        mDownloadInProgress = YES;
        return self;
    }
    return nil;
}

- (IBAction) onCancelPressed: (id)sender
{
    mDownloadInProgress = NO;
    
}

- (void) show: (NSWindow *)window
{
    if (!mProgressPanel)
        [NSBundle loadNibNamed:@"MLProgressSheet" owner:self];
    
    [NSApp beginSheet:mProgressPanel
       modalForWindow:window
        modalDelegate:self
       didEndSelector:nil
          contextInfo:nil];

    [mProgressIndicator setStyle:NSProgressIndicatorPreferredSmallThickness];
    [mProgressIndicator setIndeterminate:NO];
    
    // Show the dialog
    [mProgressPanel makeKeyAndOrderFront:self];
    
    // Start modal session
    mModalSession = [NSApp beginModalSessionForWindow:mProgressPanel];
    [NSApp runModalSession:mModalSession];
    
}

- (void) remove
{
    [NSApp endModalSession:mModalSession];
    [NSApp endSheet:mProgressPanel];
    [mProgressPanel orderOut:nil];
    [mProgressPanel close];
}

- (void) update: (long)value max:(long long)maxValue
{
    NSString *msg = [NSString stringWithFormat:@"Downloading... %ld kB out of %lld kB", value/1000, maxValue/1000];
    [mDownloadMsg setStringValue:msg];
    int percent = (int)((double)value/maxValue*100.0);
    NSString *percentMsg = [NSString stringWithFormat:@"%d%%", percent];
    [mDownloadPercent setStringValue:percentMsg];
    [mProgressIndicator setDoubleValue:percent];
}

@end
