//
//  MLHINOAuthWindowController.h
//  AmiKo
//
//  Created by b123400 on 2023/06/27.
//  Copyright © 2023 Ywesee GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MLHINClient.h";

NS_ASSUME_NONNULL_BEGIN

@interface MLHINOAuthWindowController : NSWindowController

- (NSURL *)authURL;
- (void)receivedTokens:(MLHINTokens *)tokens;
- (void)displayError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
