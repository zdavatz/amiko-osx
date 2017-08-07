/*

Copyright (c) 2017 Max Lungarella <cybrmx@gmail.com>

Created on 27/07/2017.

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

#import "MLEditableTextField.h"

@implementation MLEditableTextField

- (void)_commonInit
{
    self.drawsBackground = YES;
    self.delegate = self;
}

- (void)mouseDown:(NSEvent *)theEvent
{
    if (theEvent.clickCount == 2 && !self.isEditable)
        [self beginEditing];
    else
        [super mouseDown:theEvent];
}

- (void)beginEditing
{
    self.editable = YES;
    self.backgroundColor = [NSColor whiteColor];
    self.selectable = YES;
    
    [self selectText:nil];
    self.needsDisplay = YES;
}

- (void)endEditing
{
    self.editable = NO;
    self.backgroundColor = [NSColor clearColor];
    self.selectable = NO;
    
    self.needsDisplay = YES;
}

- (void)controlTextDidEndEditing:(NSNotification *)notification
{
    [self endEditing];
}

@end
