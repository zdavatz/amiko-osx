//
//  MLADSwissOAuthWindowController.m
//  AmiKo
//
//  Created by b123400 on 2023/07/06.
//  Copyright © 2023 Ywesee GmbH. All rights reserved.
//

#import "MLADSwissOAuthWindowController.h"
#import "MLHINClient.h"
#import "MLPersistenceManager.h"

@interface MLADSwissOAuthWindowController ()

@end

@implementation MLADSwissOAuthWindowController

- (NSURL *)authURL {
    return [[MLHINClient shared] authURLForADSwiss];
}

- (void)receivedTokens:(id)tokens {
    [[MLPersistenceManager shared] setHINADSwissTokens:tokens];
    typeof(self) __weak _self = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.window.sheetParent endSheet:self.window
                               returnCode:NSModalResponseOK];
    });
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

@end
