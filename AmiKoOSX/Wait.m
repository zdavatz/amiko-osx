//
//  Wait.m
//  AmiKo
//
//  Created by Alex Bettarini on 13/12/2018.
//  Copyright © 2018 Ywesee GmbH. All rights reserved.
//

#import "Wait.h"

@interface Wait ()

@end

@implementation Wait

- (instancetype) initWithString:(NSString*) str
{
    self = [super initWithWindowNibName:@"Wait"];
    
    [[self window] setAnimationBehavior: NSWindowAnimationBehaviorNone];
    
    [[self window] center];
    [[self window] setLevel: NSModalPanelWindowLevel];
    if (str)
        [self.text setStringValue:str];

    [self.secondaryText setHidden:YES];

    self.cancel = NO;

    return self;
}

- (void) setSubtitle:(NSString*) str
{
    if (str)
        [self.secondaryText setStringValue:str];
    
    [self.secondaryText setHidden:NO];
}

- (void)incrementBy:(double)delta
{
    [self.progress incrementBy:delta];
}

#pragma mark - NSWindowController overloads

- (IBAction)showWindow:(nullable id)sender
{
    [super showWindow: sender];
    [[self window] makeKeyAndOrderFront: sender];
    [[self window] setDelegate: self];
    
    [[self window] display];
    [[self window] flushWindow];
    [[self window] makeKeyAndOrderFront: sender];
}

//- (void)close
//{
//
//}

@end
