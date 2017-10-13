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

#import "MLMainWindowController.h"
#import "MLItemCellView.h"
#import "MLCellPackagesView.h"
#import "MLCustomTableRowView.h"
#import "MLColors.h"
#import "MLPrescriptionItem.h"

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
        if (showContextualMenu == true) {
            NSInteger row = [[notification object] selectedRow];
            if (row < [listOfPackages count]) {
                // Generates contextual menu
                NSMenu *ctxtMenu = [[NSMenu alloc] initWithTitle:@"Contextual Menu"];
                selectedPackage = listOfPackages[row];
                [ctxtMenu insertItemWithTitle:selectedPackage action:nil keyEquivalent:@"" atIndex:0];
                // Populate all menu items
                NSMenuItem *menuItem = [ctxtMenu insertItemWithTitle:@"Rezept" action:@selector(selectBasket:) keyEquivalent:@"" atIndex:1];
                [menuItem setRepresentedObject:[NSNumber numberWithInt:0]];
                /*
                 menuItem = [ctxtMenu insertItemWithTitle:@"Rezept 2" action:@selector(selectBasket:) keyEquivalent:@"" atIndex:2];
                 [menuItem setRepresentedObject:[NSNumber numberWithInt:1]];
                 menuItem = [ctxtMenu insertItemWithTitle:@"Rezept 3" action:@selector(selectBasket:) keyEquivalent:@"" atIndex:3];
                 [menuItem setRepresentedObject:[NSNumber numberWithInt:2]];
                 */
                // Place menu on the screen
                [ctxtMenu popUpMenuPositioningItem:nil atLocation:[NSEvent mouseLocation] inView:nil];
            }
        }
        [self.packagesView reloadData];
    }
}

- (void) selectBasket:(id)sender
{
    if (selectedPackage != nil && selectedMedi != nil) {
        NSNumber *selectedBasket = (NSNumber *)[sender representedObject];
        NSInteger n = [selectedBasket intValue];
        
        // Note: could be replaced by a target-action design pattern (less clear, IMHO)
        NSResponder* r = [self nextResponder];
        while (![r isKindOfClass: [MLMainWindowController class]])
            r = [r nextResponder];
        MLMainWindowController* vc = (MLMainWindowController*)r;
        
        MLPrescriptionItem *item = [[MLPrescriptionItem alloc] init];
        item.fullPackageInfo = selectedPackage;
        item.mid = selectedMedi.medId;

        // Extract EAN/GTIN
        MLMedication *m = [vc getShortMediWithId:[selectedMedi medId]];
        if (m != nil) {
            NSArray *listOfPackInfos = [[m packInfo] componentsSeparatedByString:@"\n"];
            NSArray *listOfPacks = [[m packages] componentsSeparatedByString:@"\n"];
            NSString *eanCode = @"";
            NSInteger row = 0;
            for (NSString *s in listOfPackInfos) {
                if ([s containsString:selectedPackage]) {
                    NSString *package = [listOfPacks objectAtIndex:row];
                    NSArray *p = [package componentsSeparatedByString:@"|"];
                    eanCode = [p objectAtIndex:9];
                    break;
                }
                row++;
            }
            item.eanCode = eanCode;
        }
        
        NSArray *titleComponents = [selectedPackage componentsSeparatedByString:@"["];
        titleComponents = [titleComponents[0] componentsSeparatedByString:@","];
        if ([titleComponents count]>0) {
            item.title = titleComponents[0];
            if ([titleComponents count]>2) {
                item.price = [NSString stringWithFormat:@"%@ CHF", titleComponents[2]];
                item.price = [item.price stringByReplacingOccurrencesOfString:@"ev.nn.i.H. " withString:@""];
                item.price = [item.price stringByReplacingOccurrencesOfString:@"PP " withString:@""];
            } else {
                item.price = @"";
            }
            [vc addItem:item toPrescriptionCartWithId:n];
        }
    }
}

@end

