//
//  MLButtonCell.m
//  AmiKo
//
//  Created by b123400 on 2020/10/01.
//  Copyright © 2020 Ywesee GmbH. All rights reserved.
//

#import "MLButtonCell.h"

@implementation MLButtonCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    [super drawWithFrame:cellFrame inView:controlView];
    if (self.selected) {
        [[NSColor colorWithRed:90/255.0 green:164/255.0 blue:194/255.0 alpha:1] set];
        
        NSBezierPath* line = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(cellFrame, 2, 2) xRadius:2 yRadius:2];
        [line setLineWidth: 3.0f];
        [line stroke];
    }
}

@end
