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
    if (self.selected) {
        [[NSColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:224/255.0 alpha:1] set];
        NSBezierPath *background = [NSBezierPath bezierPathWithRoundedRect:cellFrame xRadius:3 yRadius:3];
        [background fill];
        
        self.attributedTitle = [[NSAttributedString alloc] initWithString:self.title attributes:@{
            NSForegroundColorAttributeName: [NSColor darkGrayColor]
        }];
        
        [super drawWithFrame:cellFrame inView:controlView];
        
        [[NSColor colorWithRed:90/255.0 green:164/255.0 blue:194/255.0 alpha:1] set];
        NSBezierPath* line = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(cellFrame, 1, 1) xRadius:2 yRadius:2];
        [line setLineWidth: 2.0f];
        [line stroke];
    } else {
        self.attributedTitle = [[NSAttributedString alloc] initWithString:self.title];
        [super drawWithFrame:cellFrame inView:controlView];
    }
}

@end
