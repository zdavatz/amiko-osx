//
//  MLPrescriptionView.m
//  AmiKo
//
//  Created by b123400 on 2020/10/15.
//  Copyright © 2020 Ywesee GmbH. All rights reserved.
//

#import "MLPrescriptionView.h"

@implementation MLPrescriptionView {
    NSView *_findBarView;
    BOOL _findBarVisible;
    CGFloat _findBarHeight;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    _findBarHeight = 32;
    return [super initWithCoder:coder];
}

- (void)findBarViewDidChangeHeight {
    _findBarHeight = self.findBarView.frame.size.height;
    self.textFinderContainerViewHeight.constant = _findBarHeight;
    CGSize barSize = self.findBarView.frame.size;
    self.findBarView.frame = CGRectMake(0, 0, self.frame.size.width, barSize.height);
}

- (NSView*)findBarView {
    return _findBarView;
}

- (void)setFindBarView:(NSView *)findBarView {
    _findBarView = findBarView;
    [self.textFinderContainerView addSubview:findBarView];
}

- (void)setFindBarVisible:(BOOL)findBarVisible {
    _findBarVisible = findBarVisible;
    if (findBarVisible) {
        self.textFinderContainerViewHeight.constant = _findBarHeight;
    } else {
        self.textFinderContainerViewHeight.constant = 0;
    }
}

- (BOOL)isFindBarVisible {
    return _findBarVisible;
}

- (NSView *)contentView {
    return self;
}

@end
