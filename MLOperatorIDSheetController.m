/*
 
 Copyright (c) 2017 Max Lungarella <cybrmx@gmail.com>
 
 Created on 06/07/2017.
 
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

#import "MLOperatorIDSheetController.h"

@implementation MLOperatorIDSheetController
{
    @private
    NSModalSession mModalSession;
}

- (id) init
{
    if (self = [super init]) {
        return self;
    }
    return nil;
}

- (IBAction) onCancel:(id)sender
{
    [self remove];
}

- (IBAction) onSaveOperator:(id)sender
{

}

- (IBAction) onClearSignature:(id)sender
{
    [mSignView clear];
}

- (void) show:(NSWindow *)window
{
    if (!mPanel) {
        // Load xib file
        [NSBundle loadNibNamed:@"MLAmiKoOperatorIDSheet" owner:self];
    }
    
    [NSApp beginSheet:mPanel modalForWindow:window modalDelegate:self didEndSelector:nil contextInfo:nil];
    
    // Show the dialog
    [mPanel makeKeyAndOrderFront:self];
    
    // Start modal session
    mModalSession = [NSApp beginModalSessionForWindow:mPanel];
    [NSApp runModalSession:mModalSession];
    
    // Other types of initializations go here...
}

- (void) remove
{
    [NSApp endModalSession:mModalSession];
    [NSApp endSheet:mPanel];
    [mPanel orderOut:nil];
    [mPanel close];
}

@end
