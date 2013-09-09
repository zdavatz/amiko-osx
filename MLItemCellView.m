/*
 
 Copyright (c) 2013 Max Lungarella <cybrmx@gmail.com>
 
 Created on 24/08/2013.
 
 This file is part of AMiKoOSX.
 
 AmiKoDesitin is free software: you can redistribute it and/or modify
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

@implementation MLItemCellView

@synthesize favoritesCheckBox;
@synthesize detailTextField;

- (id) initWithFrame: (NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void) setBackgroundStyle: (NSBackgroundStyle)backgroundStyle
{
    [super setBackgroundStyle:backgroundStyle];
    /*
    self.detailTextField.textColor = [NSColor colorWithCalibratedRed:20/255.0 green:20/255.0 blue:20/255.0 alpha:1.0];
     */
}

- (void) drawRect: (NSRect)dirtyRect
{
    // Sets title text color
    NSColor *textColor = [NSColor colorWithCalibratedRed:(20/255.0) green:(20/255.0) blue:(20/255.0) alpha:1.0];
    [self.textField setTextColor:textColor];
    // Sets detail text color
    /*
    NSColor *detailTextColor = [NSColor colorWithCalibratedRed:(255/255.0) green:(128/255.0) blue:(128/255.0) alpha:1.0];
    [self.detailTextField setTextColor:detailTextColor];
    */
}

- (void) setDetailTextColor: (NSColor *)color
{
    self.detailTextField.textColor = color;
}


@end

