/*
 
 Copyright (c) 2014 Max Lungarella <cybrmx@gmail.com>
 
 Created on 26/01/2014.
 
 This file is part of AmiKo for OSX.
 
 AmiKo for OSX is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.
 
 ------------------------------------------------------------------------ */

#import "MLProgressSheetController.h"
#import "MLMainWindowController.h"

@implementation MLProgressSheetController
{
    @private
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
        else if ([APP_NAME isEqualToString:@"AmiKo-Desitin"])
            splashPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"amikodesitin_splash_1000x670.png"];
        else if ([APP_NAME isEqualToString:@"CoMed"])
            splashPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"comedosx_splash_1000x670.png"];
        else if ([APP_NAME isEqualToString:@"CoMed-zR"])
            splashPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Zur_Rose_1000x670px.png"];
        else if ([APP_NAME isEqualToString:@"CoMed-Desitin"])
            splashPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"comeddesitin_splash_1000x670.png"];
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

    [mProgressIndicator setStyle:NSProgressIndicatorBarStyle]; // NSProgressIndicatorSpinningStyle];
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
    NSString *msg = [NSString stringWithFormat:@"Downloading update... %ld MiB out of %lld MiB", (long)(value/1e6), (long long)(maxValue/1e6)];
    CGFloat fontSize = [NSFont systemFontSize];
    [mDownloadMsg setFont:[NSFont userFixedPitchFontOfSize:fontSize]];
    [mDownloadMsg setStringValue:msg];
    int percent = (int)((double)value/maxValue*100.0);
    NSString *percentMsg = [NSString stringWithFormat:@"%d%%", percent];
    [mDownloadPercent setFont:[NSFont userFixedPitchFontOfSize:fontSize]];
    [mDownloadPercent setStringValue:percentMsg];
    [mProgressIndicator setDoubleValue:percent];
}

- (void) updateMsg:(NSString *)msg
{
    [mDownloadMsg setStringValue:msg];
}

@end
