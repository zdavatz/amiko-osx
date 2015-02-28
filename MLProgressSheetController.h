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
- (void) updateMsg:(NSString *)msg;

@end
