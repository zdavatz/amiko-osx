//
//  MLProgressSheetController.m
//  AmiKo
//
//  Created by Max on 26/01/2014.
//  Copyright (c) 2014 Ywesee GmbH. All rights reserved.
//

#import "MLProgressSheetController.h"
#import "MLMainWindowController.h"

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

- (IBAction) onCancelPressed:(id)sender
{
    mDownloadInProgress = NO;
    
}

- (void) show:(NSWindow *)window
{
    if (!mProgressPanel) {
        NSString *splashPath = nil;
        // Load xib file
        [NSBundle loadNibNamed:@"MLProgressSheet" owner:self];
 
        if ([APP_NAME isEqualToString:@"AmiKo"])
            splashPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"amikoosx_splash_1000x670.png"];
        else if ([APP_NAME isEqualToString:@"AmiKo-zR"])
            splashPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Zur_Rose_1000x670px.png"];
        else if ([APP_NAME isEqualToString:@"CoMed"])
            splashPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"comedosx_splash_1000x670.png"];
        else if ([APP_NAME isEqualToString:@"CoMed-zR"])
            splashPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Zur_Rose_1000x670px.png"];
        else
            splashPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"amikoosx_splash_1000x670.png"];
   
        NSImage *splash = [[NSImage alloc] initWithContentsOfFile:splashPath];
        [mSplashImage setImage:splash];
    }
    
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

- (void) update:(long)value max:(long long)maxValue
{
    NSString *msg = [NSString stringWithFormat:@"Downloading... %ld kB out of %lld kB", value/1000, maxValue/1000];
    [mDownloadMsg setStringValue:msg];
    int percent = (int)((double)value/maxValue*100.0);
    NSString *percentMsg = [NSString stringWithFormat:@"%d%%", percent];
    [mDownloadPercent setStringValue:percentMsg];
    [mProgressIndicator setDoubleValue:percent];
}

@end
