/*
 
 Copyright (c) 2013 Max Lungarella <cybrmx@gmail.com>
 
 Created on 08/09/2013.
 
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

#import <QuartzCore/QuartzCore.h>
#import "MLSplashScreen.h"

@implementation MLSplashScreen
{
    float m_alpha;
    float m_delta;
    
    /*
    NSImage *m_sourceImage;
    CIImage *m_inputImage;
    */
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
    /*
    m_sourceImage = [self image];
    m_inputImage = [CIImage imageWithData:[m_sourceImage TIFFRepresentation]];
    */
    m_alpha = 2.0;
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
        
        /*
        CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
        [filter setValue:m_inputImage forKey:@"inputImage"];
        [filter setValue:[NSNumber numberWithFloat:10*m_alpha] forKey:@"inputRadius"];
        CIImage *outputImage = [filter valueForKey:@"outputImage"];
        
        NSRect outputImageRect = NSRectFromCGRect([outputImage extent]);
        NSImage* blurredImage = [[NSImage alloc] initWithSize:outputImageRect.size];
        [blurredImage lockFocus];
        [outputImage drawAtPoint:NSZeroPoint fromRect:outputImageRect
                       operation:NSCompositeCopy fraction:1.0];
        [blurredImage unlockFocus];

        [self setImage:blurredImage];
        */
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
