//
//  Wait.h
//  AmiKo
//
//  Created by Alex Bettarini on 13/12/2018.
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface Wait : NSWindowController <NSWindowDelegate>

@property (weak) IBOutlet NSTextField *text;
@property (weak) IBOutlet NSTextField *secondaryText;
@property (weak) IBOutlet NSProgressIndicator *progress;

@property () BOOL cancel;

- (id) initWithString:(NSString*) str;
- (void) incrementBy:(double) delta;
- (void) setSubtitle:(NSString*) str;

@end

NS_ASSUME_NONNULL_END
