//
//  MLPrescriptionView.h
//  AmiKo
//
//  Created by b123400 on 2020/10/15.
//  Copyright © 2020 Ywesee GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface MLPrescriptionView : NSView<NSTextFinderBarContainer>

@property (nonatomic, weak) IBOutlet NSView *textFinderContainerView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *textFinderContainerViewHeight;

@end

NS_ASSUME_NONNULL_END
