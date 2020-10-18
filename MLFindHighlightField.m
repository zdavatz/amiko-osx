//
//  MLFuckField.m
//  AmiKo
//
//  Created by b123400 on 2020/10/15.
//  Copyright © 2020 Ywesee GmbH. All rights reserved.
//

#import "MLFindHighlightField.h"

@implementation MLFindHighlightField

- (void)drawRect:(NSRect)dirtyRect {
    if (self.isDrawingFindIndicator) {
        // When it's in searching mode, the background is always yellow
        // so we need to force it to black for all occasion, even if it's dark mode.
        NSColor *c = self.textColor;
        self.textColor = [NSColor blackColor];
        [super drawRect:dirtyRect];
        self.textColor = c;
    } else {
        [super drawRect:dirtyRect];
    }
}

@end
