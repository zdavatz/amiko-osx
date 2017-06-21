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
#import "MLCellPackagesView.h"
#import "MLCustomTableRowView.h"
#import "MLColors.h"

@implementation MLItemCellView
{
    @private
    NSArray *listOfPackages;
    NSTrackingArea *trackingArea;
}

@synthesize favoritesCheckBox;
@synthesize packagesView;

@synthesize packagesStr;
@synthesize numPackages;

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
    
    [self createTrackingArea];
    
    // Sets title text color
    [self.textField setTextColor:[NSColor mainTextFieldGray]];
}

- (void) createTrackingArea
{
    int opts = (NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways);
    trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds]
                                                                options:opts
                                                                  owner:self
                                                               userInfo:nil];
    [self addTrackingArea:trackingArea];
    
    /*
    NSPoint mouseLocation = [[self window] mouseLocationOutsideOfEventStream];
    mouseLocation = [self convertPoint: mouseLocation
                              fromView: nil];
    
    if (NSPointInRect(mouseLocation, [self bounds])) {
        [self mouseEntered: nil];
    } else {
        [self mouseExited: nil];
    }
    */
}

- (void) updateTrackingAreas
{
    // Called when view is scrolled.
    [self removeTrackingArea:trackingArea];
    [self createTrackingArea];
    [super updateTrackingAreas]; // Needed, according to the NSView documentation
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
- (NSView *) tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row: (NSInteger)row
{
    if (tableView == self.packagesView) {
        listOfPackages = [packagesStr componentsSeparatedByString:@"\n"];
        if (row < [listOfPackages count]) {
            NSString *str = [NSString stringWithFormat:@"%@", listOfPackages[row]];
            MLCellPackagesView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
            [cellView.textField setStringValue:str];
            // Set colors
            if ([str rangeOfString:@", O]"].location == NSNotFound) {
                if ([cellView.textField.stringValue rangeOfString:@", G]"].location == NSNotFound) {
                    // Anything else ...
                    [cellView.textField setTextColor:[NSColor typicalGray]];
                } else {
                    // Generika
                    [cellView.textField setTextColor:[NSColor typicalGreen]];
                }
            } else {
                // Original
                [cellView.textField setTextColor:[NSColor typicalRed]];
            }
            
            return cellView;
        }
    }
    return nil;
}

- (void) tableViewSelectionDidChange:(NSNotification *)notification
{
    if ([notification object] == self.packagesView) {
        [self.packagesView reloadData];
    }
}

@end

