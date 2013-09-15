/*
 
 Copyright (c) 2013 Max Lungarella <cybrmx@gmail.com>
 
 Created on 24/08/2013.
 
 This file is part of AMiKoOSX.
 
 AmiKoOSX is free software: you can redistribute it and/or modify
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

#import "MLCustomTableRowView.h"

@implementation MLCustomTableRowView

@synthesize rowIndex = _rowIndex;

- (id) initWithFrame: (NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

/*
- (void)drawRect:(NSRect)dirtyRect
{
    // Draw row rectangle here ...
}
*/

- (void) drawSelectionInRect: (NSRect)dirtyRect
{
    // Draw selected row rectangle here
    if (self.selectionHighlightStyle != NSTableViewSelectionHighlightStyleNone) {
        NSRect selectionRect = NSInsetRect(self.bounds, 0.0, 0.0);
        /* 
        [[NSColor colorWithCalibratedRed:228/255.0 green:228/255.0 blue:255/255.0 alpha:1.0] setStroke];
        [[NSColor colorWithCalibratedRed:228/255.0 green:228/255.0 blue:255/255.0 alpha:1.0] setFill];
         
        NSBezierPath *selectionPath = [NSBezierPath bezierPathWithRoundedRect:selectionRect xRadius:8 yRadius:8];
        [selectionPath fill];
        [selectionPath stroke];
        */
        // Define gradient colors
        NSColor* gradientStartColor = [NSColor colorWithCalibratedRed:210/255.0 green:210/255.0 blue:230/255.0 alpha:1.0];
        NSColor* gradientEndColor = [NSColor colorWithCalibratedRed:230/255.0 green:230/255.0 blue:255/255.0 alpha:1.0];
        // Gradient Declarations
        NSGradient* gradient = [[NSGradient alloc] initWithStartingColor:gradientStartColor endingColor:gradientEndColor];
        // Rounded Rectangle Drawing
        NSBezierPath *roundedRectanglePath = [NSBezierPath bezierPathWithRoundedRect:selectionRect xRadius:8 yRadius:8];
        [gradient drawInBezierPath:roundedRectanglePath angle:90];
    }
}

@end
