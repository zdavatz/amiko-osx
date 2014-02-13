/*
 
 Copyright (c) 2014 Max Lungarella <cybrmx@gmail.com>
 
 Created on 06/02/2014.
 
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

#import "MLCustomWebView.h"

@implementation MLCustomWebView

- (id) initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        ///
        /*
        mTextFinder = [[NSTextFinder alloc] init];
        [mTextFinder setClient:self];  // myWebView implements the <NSTextFinderClient> protocol
        [mTextFinder setIncrementalSearchingEnabled:YES];
        [mTextFinder setFindBarContainer:[self scrollView]];
        [[self scrollView] setFindBarPosition:NSScrollViewFindBarPositionAboveContent];
        [[self scrollView] setFindBarVisible:YES];
        [mTextFinder cancelFindIndicator];
        [mTextFinder performAction:NSTextFinderActionSetSearchString];
        
        [self showFinderInterface];
        */
        ///
    }
    return self;
}

- (void) drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	
    // Drawing code here.
}

#pragma mark - NSTextFinderClient methods
- (void) performTextFinderAction:(id)sender
{
    NSLog(@"perform action");
}

@end
