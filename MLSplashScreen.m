/*
 
 Copyright (c) 2013 Max Lungarella <cybrmx@gmail.com>
 
 Created on 08/09/2013.
 
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

#import "MLSplashScreen.h"

@implementation MLSplashScreen
{
    float m_alpha;
    float m_delta;
}

- (id) initWithFrame: (NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        NSLog(@"%s", __FUNCTION__);
    }
    
    return self;
}

- (void) awakeFromNib
{
    m_alpha = 3.0;
    m_delta = 0.01;
    [self fadeOutAndRemove];
}

/** Handle mouse click event (mouse down)
 */
- (void) mouseDown: (NSEvent *)theEvent
{
    m_delta = 0.05;
    [self fadeOutAndRemove];
}

- (void) fadeOutAndRemove
{
    if (m_alpha>0.05) {
        m_alpha -= m_delta;
        [self setAlphaValue:m_alpha];
        [NSTimer scheduledTimerWithTimeInterval:0.01
                                         target:self
                                       selector:@selector(fadeOutAndRemove)
                                       userInfo:nil
                                        repeats:NO];
    } else {
        [self removeFromSuperview];
    }
}

@end
