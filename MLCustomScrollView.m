/*
 
 Copyright (c) 2017 Max Lungarella <cybrmx@gmail.com>
 
 Created on 20/06/2017.
 
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

#import "MLCustomScrollView.h"

@implementation MyScrollView

/*
 In case you generate the view manually
 */
- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        [self hideScrollers];
    }
    
    return self;
}

- (void) awakeFromNib
{
    [self hideScrollers];
}

- (void) hideScrollers
{
    // Hide the scrollers. You may want to do this if you're syncing the scrolling this NSScrollView with another one.
    [self setHasHorizontalScroller:NO];
    [self setHasVerticalScroller:NO];
}

- (void) scrollWheel:(NSEvent *)theEvent
{
    /*
     Make sure that this "disabled" scrollView will pass the scroll event up to the outer scrollView 
     and its scrolling will not get stuck down inside its subviews.
    */
    [self.nextResponder scrollWheel:theEvent];
    // Do nothing: disable scrolling altogether
}

@end
