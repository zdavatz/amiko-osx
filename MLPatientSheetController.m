/*
 
 Copyright (c) 2017 Max Lungarella <cybrmx@gmail.com>
 
 Created on 21/06/2017.
 
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

#import "MLPatientSheetController.h"
#import "MLMainWindowController.h"

@implementation MLPatientSheetController
{
    @private
    NSModalSession mModalSession;
    NSArray *nameArray;
}

- (id) init
{
    nameArray = [NSArray arrayWithObjects: @"Jill Valentine", @"Peter Griffin", @"Meg Griffin", @"Jack Lolwut",
                        @"Mike Roflcoptor", @"Cindy Woods", @"Jessica Windmill", @"Alexander The Great",
                        @"Sarah Peterson", @"Scott Scottland", @"Geoff Fanta", @"Amanda Pope", @"Michael Meyers",
                        @"Richard Biggus", @"Montey Python", @"Mike Wut", @"Fake Person", @"Chair",
                        nil];

    if (self = [super init]) {
        return self;
    }
    return nil;
}

- (IBAction) onCancelPressed:(id)sender
{
    [self remove];
}

- (IBAction) onConfirmPressed:(id)sender
{
}

- (void) show:(NSWindow *)window
{
    if (!mPanel) {
        // Load xib file
        [NSBundle loadNibNamed:@"MLPatientSheet" owner:self];
    }
    
    [NSApp beginSheet:mPanel modalForWindow:window modalDelegate:self didEndSelector:nil contextInfo:nil];
   
    // Show the dialog
    [mPanel makeKeyAndOrderFront:self];
    
    // Start modal session
    mModalSession = [NSApp beginModalSessionForWindow:mPanel];
    [NSApp runModalSession:mModalSession];
}

- (void) remove
{
    [NSApp endModalSession:mModalSession];
    [NSApp endSheet:mPanel];
    [mPanel orderOut:nil];
    [mPanel close];
}

/**
 - NSTableViewDataSource -
 */
- (NSInteger) numberOfRowsInTableView: (NSTableView *)tableView
{
    return [nameArray count];
}

/**
 - NSTableViewDataDelegate -
 */
- (NSView *) tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    cellView.textField.stringValue = nameArray[row];
    return cellView;
}


@end
