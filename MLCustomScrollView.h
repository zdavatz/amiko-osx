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

#import <Cocoa/Cocoa.h>

@interface MyScrollView : NSScrollView

- (id) initWithFrame:(NSRect)frameRect;     // In case you generate the scroll view manually
- (void) awakeFromNib;                      // In case you generate the scroll view via IB
- (void) hideScrollers;                     // Programmatically hide the scrollers, so it works all the time
- (void) scrollWheel:(NSEvent *)theEvent;   // Disable scrolling

@end
