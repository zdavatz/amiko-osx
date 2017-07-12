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
    NSBezierPath *_signaturePath;
    NSImage *_image;
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
    _signaturePath = [NSBezierPath bezierPath];
    _signaturePath.lineWidth = 2.0f;
    _signaturePath.lineCapStyle = NSRoundLineCapStyle;
    
    [self setWantsLayer:YES];
    
    [self clear];
}

- (void) clear
{
    if (_image!=nil) {
        _image = nil;
        [self setNeedsLayout:YES];
    }
    if (_signaturePath!=nil) {
        [_signaturePath removeAllPoints];
        [self setNeedsDisplay:YES];
    }
}

- (void) setSignature:(NSImage *)image
{
    _image = image;
    [self setNeedsDisplay:YES];
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
    
    [_signaturePath moveToPoint:loc];
}

- (void) mouseDragged:(NSEvent *)theEvent
{
    NSPoint loc = [theEvent locationInWindow];
    loc.x -= [self frame].origin.x;
    loc.y -= [self frame].origin.y;
    
    [_signaturePath lineToPoint:loc];
    [self setNeedsDisplay:YES];
}

- (void) drawRect:(NSRect)rect
{
    NSRect bounds = [self bounds];
    NSBezierPath *background = [NSBezierPath bezierPathWithRect:bounds];
    [[NSColor whiteColor] set];
    [background fill];

    if (_image!=nil) {
        // [_image drawInRect:[self bounds]];
        [self drawInRectAspectFill:_image];
    }
    
    [[NSColor blackColor] set];
    [_signaturePath stroke];
}

- (void) drawInRectAspectFill:(NSImage *)img
{
    NSRect recto = [self bounds];
    CGSize targetSize = recto.size;

    // This fits
    if (targetSize.width <= CGSizeZero.width && targetSize.height <= CGSizeZero.height ) {
        return [img drawInRect:recto];
    }
    
    float widthRatio = targetSize.width / img.size.width;
    float heightRatio = targetSize.height / img.size.height;
    float scalingFactor = fmin(widthRatio, heightRatio);    // fmax() -> fills space up
    
    CGSize newSize = CGSizeMake(img.size.width  * scalingFactor, img.size.height * scalingFactor);
    CGPoint origin = CGPointMake((targetSize.width - newSize.width)/2, (targetSize.height - newSize.height)/2);
    
    return [img drawInRect:CGRectMake(origin.x, origin.y, newSize.width, newSize.height)];
}

- (NSData *) getSignaturePNG
{
    NSData *data = [self dataWithPDFInsideRect:[self bounds]];
    NSImage *img = [[NSImage alloc] initWithData:data];
    NSData *tiffPresentation = [img TIFFRepresentation];
    NSBitmapImageRep *rep = [NSBitmapImageRep imageRepWithData:tiffPresentation];

    NSDictionary* props = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
    NSData *pngData = [rep representationUsingType:NSPNGFileType properties:props];
    
    return pngData;
}

@end
