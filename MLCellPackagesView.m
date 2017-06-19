/*
 
 Copyright (c) 2017 Max Lungarella <cybrmx@gmail.com>
 
 Created on 14/06/2017.
 
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

#import "MLCellPackagesView.h"
#import "MLColors.h"

@implementation MLCellPackagesView
{
    @private
    NSColor *saveColor;
    NSTextField *textField;
    BOOL first;
}

- (id) initWithFrame: (NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        first = false;
    }
    return self;
}

- (void) setBackgroundStyle: (NSBackgroundStyle)backgroundStyle
{
    [super setBackgroundStyle:backgroundStyle];
}

- (void) drawRect: (NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                                options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow )
                                                                  owner:self
                                                               userInfo:nil];
    [self addTrackingArea:trackingArea];
    
    /*
    self.wantsLayer = YES;
    self.layer.backgroundColor = [[NSColor redColor] CGColor];
    */
}

- (void) mouseEntered: (NSEvent *)theEvent
{
    if (first == false) {
        saveColor = self.textField.textColor;
        [self.textField setTextColor:[NSColor mainTextFieldBlue]];
        [[NSCursor pointingHandCursor] set];
        first = true;
    }
}

- (void) mouseExited: (NSEvent *)theEvent
{
    if (first == true) {
        [self.textField setTextColor:saveColor];
        [[NSCursor arrowCursor] set];
        first = false;
    }
}

@end
