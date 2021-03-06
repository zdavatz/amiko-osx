/*
 
 Copyright (c) 2013 Max Lungarella <cybrmx@gmail.com>
 
 Created on 24/08/2013.
 
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

#import "MLItemCellView.h"

#import "MLMainWindowController.h"
#import "MLCellPackagesView.h"
#import "MLCustomTableRowView.h"
#import "MLColors.h"
#import "MLPrescriptionItem.h"
#import "MLUtilities.h"

@implementation MLItemCellView
{
    @private
    NSArray *listOfPackages;
    NSTrackingArea *trackingArea;
    NSString *selectedPackage;
}

@synthesize favoritesCheckBox;
@synthesize packagesView;

@synthesize selectedMedi;
@synthesize packagesStr;
@synthesize numPackages;
@synthesize showContextualMenu;

/*
 In case you generate the table cell view manually
 */
- (id) initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
  
    return self;
}

- (void) setBackgroundStyle:(NSBackgroundStyle)backgroundStyle
{
    [super setBackgroundStyle:backgroundStyle];
}

- (void) drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];

    // Sets transparent background color
    [self.packagesView setBackgroundColor:[NSColor clearColor]];
    [[self.packagesView enclosingScrollView] setDrawsBackground:NO];
    
    // Sets title text color
    [self.textField setTextColor:[NSColor mainTextFieldGray]];
}

- (NSTableRowView *) tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
    if (row>=0) {
        MLCustomTableRowView *rowView = [[MLCustomTableRowView alloc] initWithFrame:NSZeroRect];
        rowView.color = [NSColor lightYellow];
        rowView.radius = 6;
        [rowView setRowIndex:row];
        return rowView;
    }
    return nil;
}

/**
 - NSTableViewDataSource -
 Get number of rows of a table view
 */
- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView
{
    if (tableView == self.packagesView) {
        listOfPackages = [packagesStr componentsSeparatedByString:@"\n"];
        numPackages = [listOfPackages count];
        return numPackages;
    }
    return 0;
}

- (CGFloat) tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    if (tableView == self.packagesView) {
        NSFont *subTextFont = [NSFont boldSystemFontOfSize:11.0f];
        CGSize subTextSize = NSSizeFromCGSize([listOfPackages[row] sizeWithAttributes:[NSDictionary dictionaryWithObject:subTextFont
                                                                                                      forKey:NSFontAttributeName]]);
        return subTextSize.height;
    }
    return 0.0f;
}

/**
 - NSTableViewDataDelegate -
 Update tableviews (search result and section titles)
 */
- (NSView *) tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (tableView == self.packagesView) {
        listOfPackages = [packagesStr componentsSeparatedByString:@"\n"];
        if (row < [listOfPackages count]) {
            NSString *str = [NSString stringWithFormat:@"%@", listOfPackages[row]];
            MLCellPackagesView *packageCellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
            [packageCellView.textField setStringValue:str];
            // Set colors
            if ([str rangeOfString:@", O]"].location == NSNotFound) {
                if ([packageCellView.textField.stringValue rangeOfString:@", G]"].location == NSNotFound) {
                    // Anything else ...
                    [packageCellView.textField setTextColor:[NSColor typicalGray]];
                } else {
                    // Generika
                    [packageCellView.textField setTextColor:[NSColor typicalGreen]];
                }
            } else {
                // Original
                [packageCellView.textField setTextColor:[NSColor typicalRed]];
            }
            
            return packageCellView;
        }
    }
    return nil;
}

- (void) tableViewSelectionDidChange:(NSNotification *)notification
{
    if ([notification object] == self.packagesView) {
        NSInteger row = [[notification object] selectedRow];
        if (showContextualMenu) {
            if (row < [listOfPackages count]) {
                // Generates contextual menu
                NSMenu *ctxtMenu = [[NSMenu alloc] initWithTitle:@"Contextual Menu"];
                selectedPackage = listOfPackages[row];
                [ctxtMenu insertItemWithTitle:selectedPackage action:nil keyEquivalent:@"" atIndex:0];

                // Populate all menu items
                [ctxtMenu insertItemWithTitle: NSLocalizedString(@"Prescription", nil)
                                       action: @selector(selectBasket:)
                                keyEquivalent: @""
                                      atIndex: 1];
                // Place menu on the screen
                [ctxtMenu popUpMenuPositioningItem:nil atLocation:[NSEvent mouseLocation] inView:nil];
            }
        } else if (self.onSubtitlePressed) {
            self.onSubtitlePressed(row);
        }
        [self.packagesView reloadData];
    }
}

- (void) selectBasket:(id)sender
{
    if (selectedPackage != nil && selectedMedi != nil) {
        // Note: could be replaced by a target-action design pattern (less clear, IMHO)
        NSResponder* r = [self nextResponder];
        while (![r isKindOfClass: [MLMainWindowController class]])
            r = [r nextResponder];

        MLMainWindowController* vc = (MLMainWindowController*)r;
        MLMedication *m = [vc getMediWithId:[selectedMedi medId]];
        NSInteger packageIndex = [listOfPackages indexOfObject:selectedPackage];
        [vc addPackageAtIndex:packageIndex ofMedToPrescriptionCart:m];
        
        [vc pushToMedBasket: m];
    }
}

@end

