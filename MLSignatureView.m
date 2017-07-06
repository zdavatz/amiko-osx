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

#import "MLSignatureView.h"

@implementation MLSignatureView
{
    NSBezierPath *signaturePath;
}

/*
 In case you generate the table cell view manually
 Note: not called if interface is generated with IB!
 */
- (id) initWithFrame:(NSRect)rect
{
    self = [super initWithFrame:rect];
    if (self) {
        //
    }
    
    return self;
}

- (void) awakeFromNib
{
    // Create a path object
    signaturePath = [NSBezierPath bezierPath];
    signaturePath.lineWidth = 2.0f;
    signaturePath.lineCapStyle = NSRoundLineCapStyle;
    
    [self clear];
}

- (void) clear
{
    if (signaturePath!=nil) {
        [signaturePath removeAllPoints];
        [self setNeedsDisplay:YES];
    }
}

- (BOOL) acceptsFirstResponder
{
    return YES;
}

/*
 Opaque content drawing can allow some optimizations to happen. The default value is NO.
 */
- (BOOL) isOpaque
{
    return YES;
}

- (void) mouseDown:(NSEvent *)theEvent
{
    NSPoint loc = [theEvent locationInWindow];
    loc.x -= [self frame].origin.x;
    loc.y -= [self frame].origin.y;
    
    [signaturePath moveToPoint:loc];
}

- (void) mouseDragged:(NSEvent *)theEvent
{
    NSPoint loc = [theEvent locationInWindow];
    loc.x -= [self frame].origin.x;
    loc.y -= [self frame].origin.y;
    
    [signaturePath lineToPoint:loc];
    [self setNeedsDisplay:YES];
}


- (void) drawRect:(NSRect)rect
{
    NSRect bounds = [self bounds];
    NSBezierPath *background = [NSBezierPath bezierPathWithRect:bounds];
    [[NSColor whiteColor] set];
    [background fill];
    
    [[NSColor blackColor] set];
    [signaturePath stroke];
}

@end
