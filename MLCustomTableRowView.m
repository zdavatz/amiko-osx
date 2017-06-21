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

#import "MLCustomTableRowView.h"
#import "MLColors.h"

@implementation MLCustomTableRowView

@synthesize rowIndex = _rowIndex;
@synthesize color;
@synthesize radius;

/*
 In case you generate the view manually
 */
- (id) initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        color = [NSColor selectBlue];
        radius = 0;
    }
    
    return self;
}

- (void) setEmphasized:(BOOL)emphasized
{
    // This avoids an "emphasized" font when row/cell is selected in a source list that has first responder status.
}

- (void) drawSelectionInRect:(NSRect)dirtyRect
{
    // Check the selectionHighlightStyle, in case it was set to None
    if (self.selectionHighlightStyle != NSTableViewSelectionHighlightStyleNone) {
        // We want a hard-crisp stroke, and stroking 1 pixel will border half on one side and half on another, so we offset by the 0.5 to handle this
        /*
        NSRect selectionRect = NSInsetRect(self.bounds, 5.5, 5.5);
        [[NSColor colorWithCalibratedWhite:.72 alpha:1.0] setStroke];
        [[NSColor colorWithCalibratedWhite:.82 alpha:1.0] setFill];
        NSBezierPath *selectionPath = [NSBezierPath bezierPathWithRoundedRect:selectionRect xRadius:10 yRadius:10];
        [selectionPath fill];
        [selectionPath stroke];
        */
        NSRect selectionRect = NSInsetRect(self.bounds, 0.0, 0.0);
        // Define gradient colors
        NSColor* gradientStartColor = color;
        NSColor* gradientEndColor = color;
        // Gradient Declarations
        NSGradient* gradient = [[NSGradient alloc] initWithStartingColor:gradientStartColor endingColor:gradientEndColor];
        // Rounded Rectangle Drawing
        NSBezierPath *roundedRectanglePath = [NSBezierPath bezierPathWithRoundedRect:selectionRect xRadius:radius yRadius:radius];
        [gradient drawInBezierPath:roundedRectanglePath angle:90];
    }
}

@end
