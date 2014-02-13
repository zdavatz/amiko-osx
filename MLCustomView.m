//
//  MLView.m
//  AmiKo
//
//  Created by Max on 07/02/2014.
//  Copyright (c) 2014 Ywesee GmbH. All rights reserved.
//

#import "MLCustomView.h"

@implementation NSView (ScrollView)

- (NSScrollView *) scrollView
{
    if ([self isKindOfClass:[NSScrollView class]]) {
        return (NSScrollView *)self;
    }
    
    if ([self.subviews count] == 0) {
        return nil;
    }
    
    for (NSView *subview in self.subviews) {
        NSView *scrollView = [subview scrollView];
        if (scrollView != nil) {
            return (NSScrollView *)scrollView;
        }
    }
    return nil;
}

@end
